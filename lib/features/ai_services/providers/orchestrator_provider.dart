import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/features/ai_services/logic/fallback_chain.dart';
import 'package:speakeng/features/ai_services/logic/provider_registry.dart';
import 'package:speakeng/features/ai_services/logic/quota_tracker.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/llm_provider.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/pronunciation_provider.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/stt_provider.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/tts_provider.dart';
import 'package:speakeng/features/ai_services/providers/offline/sherpa_onnx_stt_provider.dart';
import 'package:speakeng/features/ai_services/providers/offline/sherpa_onnx_tts_provider.dart';
import 'package:speakeng/features/ai_services/providers/online/supabase_llm_provider.dart';
import 'package:speakeng/features/ai_services/providers/online/supabase_pronunciation_provider.dart';
import 'package:speakeng/features/ai_services/providers/online/supabase_stt_provider.dart';
import 'package:speakeng/features/ai_services/providers/online/supabase_tts_provider.dart';
import 'package:speakeng/features/ai_services/services/connectivity_service.dart';
import 'package:speakeng/features/ai_services/services/model_manager.dart';
import 'package:speakeng/shared/services/supabase_service.dart';

/// Provider cho FallbackStrategy hiện tại (user có thể thay đổi).
final fallbackStrategyProvider =
    StateProvider<FallbackStrategy>((ref) => FallbackStrategy.freeFist);

/// Provider cho offline mode toggle.
final offlineModeProvider = StateProvider<bool>((ref) => false);

/// Provider cho QuotaTracker singleton.
final quotaTrackerProvider = Provider<QuotaTracker>((ref) => QuotaTracker());

/// Provider chính cho AI Service Orchestrator (singleton).
///
/// Orchestrator is created once and reuses providers across
/// connectivity/strategy changes. Only strategy and connectivity
/// are updated — native resources are not recreated.
final orchestratorProvider = Provider<AiOrchestrator>((ref) {
  final supabase = ref.read(supabaseProvider);
  final quotaTracker = ref.read(quotaTrackerProvider);

  final orchestrator = AiOrchestrator(
    supabase: supabase,
    quotaTracker: quotaTracker,
  );

  // Reactively update mutable fields without recreating
  orchestrator.isOnline = ref.watch(isOnlineProvider);
  final offlineMode = ref.watch(offlineModeProvider);
  orchestrator.strategy = offlineMode
      ? FallbackStrategy.offlineOnly
      : ref.watch(fallbackStrategyProvider);

  ref.onDispose(() => orchestrator.dispose());

  return orchestrator;
});

/// Orchestrator trung tâm điều phối tất cả AI service requests.
///
/// Singleton — tạo một lần, cập nhật strategy/connectivity qua setter.
/// Native resources (sherpa_onnx) được giải phóng khi dispose.
class AiOrchestrator {
  AiOrchestrator({
    required SupabaseClient supabase,
    required this.quotaTracker,
  }) {
    _registerProviders(supabase);
  }

  bool isOnline = true;
  FallbackStrategy strategy = FallbackStrategy.freeFist;
  final QuotaTracker quotaTracker;
  final _registry = ProviderRegistry();

  late final SherpaOnnxTtsProvider _offlineTts;
  late final SherpaOnnxSttProvider _offlineStt;

  void _registerProviders(SupabaseClient supabase) {
    _registry.register(ServiceType.tts, SupabaseTtsProvider(supabase));
    _registry.register(ServiceType.stt, SupabaseSttProvider(supabase));
    _registry.register(ServiceType.llm, SupabaseLlmProvider(supabase));
    _registry.register(
      ServiceType.pronunciation,
      SupabasePronunciationProvider(supabase),
    );

    final modelManager = ModelManager();
    _offlineTts = SherpaOnnxTtsProvider(modelManager);
    _offlineStt = SherpaOnnxSttProvider(modelManager);
    _registry.register(ServiceType.tts, _offlineTts);
    _registry.register(ServiceType.stt, _offlineStt);
  }

  /// Giải phóng native resources.
  void dispose() {
    _offlineTts.dispose();
    _offlineStt.dispose();
  }

  Future<Uint8List> synthesize(String text) async {
    final providers = _getChain<TtsProvider>(ServiceType.tts);
    return FallbackChain.execute(
      chain: providers,
      action: (p) async {
        final result = await p.synthesize(text);
        await quotaTracker.record(p.info.id);
        return result;
      },
    );
  }

  Future<String> transcribe(Uint8List audio) async {
    final providers = _getChain<SttProvider>(ServiceType.stt);
    return FallbackChain.execute(
      chain: providers,
      action: (p) async {
        final result = await p.transcribe(audio);
        await quotaTracker.record(p.info.id);
        return result;
      },
    );
  }

  Future<String> chat({
    required List<Map<String, String>> messages,
    required String systemPrompt,
  }) async {
    final providers = _getChain<LlmProvider>(ServiceType.llm);
    return FallbackChain.execute(
      chain: providers,
      action: (p) async {
        final result =
            await p.chat(messages: messages, systemPrompt: systemPrompt);
        await quotaTracker.record(p.info.id);
        return result;
      },
    );
  }

  Future<PronunciationResponse> assess({
    required Uint8List audio,
    required String referenceText,
  }) async {
    final providers =
        _getChain<PronunciationProvider>(ServiceType.pronunciation);
    return FallbackChain.execute(
      chain: providers,
      action: (p) async {
        final result =
            await p.assess(audio: audio, referenceText: referenceText);
        await quotaTracker.record(p.info.id);
        return result;
      },
    );
  }

  List<T> _getChain<T>(ServiceType type) {
    var providers = _registry.getAvailable<T>(type);

    if (!isOnline) {
      providers = providers.where((p) {
        final info = (p as dynamic).info as ProviderInfo;
        return info.isOffline;
      }).toList();
    }

    providers = providers.where((p) {
      final info = (p as dynamic).info as ProviderInfo;
      return !quotaTracker.isExceeded(info);
    }).toList();

    return FallbackChain.sort<T>(
      providers: providers,
      strategy: strategy,
      isOnline: isOnline,
      getInfo: (p) => (p as dynamic).info as ProviderInfo,
    );
  }
}
