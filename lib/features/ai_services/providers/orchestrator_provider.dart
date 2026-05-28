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

/// Provider chính cho AI Service Orchestrator.
final orchestratorProvider = Provider<AiOrchestrator>((ref) {
  final supabase = ref.read(supabaseProvider);
  final isOnline = ref.watch(isOnlineProvider);
  final offlineMode = ref.watch(offlineModeProvider);
  final quotaTracker = ref.read(quotaTrackerProvider);

  final strategy = offlineMode
      ? FallbackStrategy.offlineOnly
      : ref.watch(fallbackStrategyProvider);

  return AiOrchestrator(
    supabase: supabase,
    isOnline: isOnline,
    strategy: strategy,
    quotaTracker: quotaTracker,
  );
});

/// Orchestrator trung tâm điều phối tất cả AI service requests.
///
/// Tự động chọn provider phù hợp dựa trên:
/// - Connectivity state (online/offline)
/// - FallbackStrategy (free_first, quality_first, offline_only)
/// - Provider availability
class AiOrchestrator {
  AiOrchestrator({
    required SupabaseClient supabase,
    required this.isOnline,
    required this.strategy,
    required this.quotaTracker,
  }) {
    _registry = ProviderRegistry();
    _registerProviders(supabase);
  }

  final bool isOnline;
  final FallbackStrategy strategy;
  final QuotaTracker quotaTracker;
  late final ProviderRegistry _registry;

  void _registerProviders(SupabaseClient supabase) {
    // Online providers
    _registry.register(ServiceType.tts, SupabaseTtsProvider(supabase));
    _registry.register(ServiceType.stt, SupabaseSttProvider(supabase));
    _registry.register(ServiceType.llm, SupabaseLlmProvider(supabase));
    _registry.register(
      ServiceType.pronunciation,
      SupabasePronunciationProvider(supabase),
    );

    // Offline providers
    final modelManager = ModelManager();
    _registry.register(
      ServiceType.tts,
      SherpaOnnxTtsProvider(modelManager),
    );
    _registry.register(
      ServiceType.stt,
      SherpaOnnxSttProvider(modelManager),
    );
  }

  /// Text-to-Speech: chuyển text thành audio bytes.
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

  /// Speech-to-Text: chuyển audio thành transcript.
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

  /// LLM Chat: gửi messages, nhận response.
  Future<String> chat({
    required List<Map<String, String>> messages,
    required String systemPrompt,
  }) async {
    final providers = _getChain<LlmProvider>(ServiceType.llm);
    return FallbackChain.execute(
      chain: providers,
      action: (p) async {
        final result = await p.chat(messages: messages, systemPrompt: systemPrompt);
        await quotaTracker.record(p.info.id);
        return result;
      },
    );
  }

  /// Pronunciation Assessment: đánh giá phát âm.
  Future<PronunciationResponse> assess({
    required Uint8List audio,
    required String referenceText,
  }) async {
    final providers =
        _getChain<PronunciationProvider>(ServiceType.pronunciation);
    return FallbackChain.execute(
      chain: providers,
      action: (p) async {
        final result = await p.assess(audio: audio, referenceText: referenceText);
        await quotaTracker.record(p.info.id);
        return result;
      },
    );
  }

  /// Lấy fallback chain đã sort theo strategy cho một ServiceType.
  List<T> _getChain<T>(ServiceType type) {
    var providers = _registry.getAvailable<T>(type);

    // Nếu offline → lọc bỏ online providers
    if (!isOnline) {
      providers = providers.where((p) {
        final info = (p as dynamic).info as ProviderInfo;
        return info.isOffline;
      }).toList();
    }

    // Lọc bỏ providers đã hết quota
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
