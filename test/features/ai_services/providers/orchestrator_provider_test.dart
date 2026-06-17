import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeng/features/ai_services/logic/fallback_chain.dart';
import 'package:speakeng/features/ai_services/logic/provider_registry.dart';
import 'package:speakeng/features/ai_services/logic/quota_tracker.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/has_provider_info.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/tts_provider.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/stt_provider.dart';
import 'package:speakeng/shared/services/prefs_service.dart';

void main() {
  group('Orchestrator integration (Registry + FallbackChain + Quota)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PrefsService.initialize();
    });

    test('falls back to offline when online throws', () async {
      final online = _FakeTts('online_tts', ConnectionType.online,
          shouldFail: true);
      final offline = _FakeTts('offline_tts', ConnectionType.offline);

      final registry = ProviderRegistry();
      registry.register(ServiceType.tts, online);
      registry.register(ServiceType.tts, offline);

      final chain = registry.getAvailable<TtsProvider>(ServiceType.tts);
      final sorted = FallbackChain.sort<TtsProvider>(
        providers: chain,
        strategy: FallbackStrategy.qualityFirst,
        isOnline: true,
        getInfo: (p) => p.info,
      );

      final result = await FallbackChain.execute(
        chain: sorted,
        action: (p) => p.synthesize('hello'),
      );

      expect(result, isNotNull);
      expect(result.isNotEmpty, true);
    });

    test('excludes provider when quota exceeded', () async {
      final quotaTracker = QuotaTracker();
      await quotaTracker.load();

      final limited = _FakeTts('limited', ConnectionType.online,
          quotaLimit: 2);
      final unlimited = _FakeTts('unlimited', ConnectionType.online);

      // Exceed quota for limited provider
      await quotaTracker.record('limited');
      await quotaTracker.record('limited');

      final registry = ProviderRegistry();
      registry.register(ServiceType.tts, limited);
      registry.register(ServiceType.tts, unlimited);

      var providers = registry.getAvailable<TtsProvider>(ServiceType.tts);
      providers = providers.where((p) {
        return !quotaTracker.isExceeded(p.info);
      }).toList();

      expect(providers.length, 1);
      expect(providers.first.info.id, 'unlimited');
    });

    test('qualityFirst sorts by qualityRank ascending', () {
      final lowQuality = _FakeTts('low', ConnectionType.online,
          qualityRank: 5);
      final highQuality = _FakeTts('high', ConnectionType.online,
          qualityRank: 0);

      final sorted = FallbackChain.sort<TtsProvider>(
        providers: [lowQuality, highQuality],
        strategy: FallbackStrategy.qualityFirst,
        isOnline: true,
        getInfo: (p) => p.info,
      );

      expect(sorted.first.info.id, 'high');
      expect(sorted.last.info.id, 'low');
    });

    test('offline-only filters out online providers', () {
      final online = _FakeTts('online', ConnectionType.online);
      final offline = _FakeTts('offline', ConnectionType.offline);

      var providers = [online, offline];
      // Simulate isOnline=false: keep only offline
      providers = providers.where((p) => p.info.isOffline).toList();

      expect(providers.length, 1);
      expect(providers.first.info.id, 'offline');
    });

    test('freeFirst puts offline before online (paid)', () {
      final online = _FakeTts('paid', ConnectionType.online,
          quotaLimit: 1000);
      final offline = _FakeTts('free', ConnectionType.offline);

      final sorted = FallbackChain.sort<TtsProvider>(
        providers: [online, offline],
        strategy: FallbackStrategy.freeFist,
        isOnline: true,
        getInfo: (p) => p.info,
      );

      expect(sorted.first.info.id, 'free');
    });
  });
}

class _FakeTts implements TtsProvider {
  _FakeTts(
    this._id,
    this._connection, {
    this.shouldFail = false,
    int? quotaLimit,
    int qualityRank = 0,
  }) : info = ProviderInfo(
          id: _id,
          serviceType: ServiceType.tts,
          connectionType: _connection,
          quotaLimit: quotaLimit,
          qualityRank: qualityRank,
        );

  final String _id;
  final ConnectionType _connection;
  final bool shouldFail;

  @override
  final ProviderInfo info;

  @override
  Future<Uint8List> synthesize(String text) async {
    if (shouldFail) throw Exception('Provider $_id failed');
    return Uint8List.fromList([1, 2, 3]);
  }
}
