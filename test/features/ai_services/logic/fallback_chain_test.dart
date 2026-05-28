import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/ai_services/logic/fallback_chain.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';

void main() {
  group('FallbackChain.sort', () {
    final online = _FakeProvider(const ProviderInfo(
      id: 'online',
      serviceType: ServiceType.tts,
      connectionType: ConnectionType.online,
      quotaLimit: 1000,
      qualityRank: 0,
    ));
    final offline = _FakeProvider(const ProviderInfo(
      id: 'offline',
      serviceType: ServiceType.tts,
      connectionType: ConnectionType.offline,
      qualityRank: 1,
    ));

    test('offlineOnly filters out online providers', () {
      final result = FallbackChain.sort(
        providers: [online, offline],
        strategy: FallbackStrategy.offlineOnly,
        isOnline: true,
        getInfo: (p) => p.info,
      );
      expect(result.length, 1);
      expect(result.first.info.id, 'offline');
    });

    test('freeFirst puts offline (free) before online (quota)', () {
      final result = FallbackChain.sort(
        providers: [online, offline],
        strategy: FallbackStrategy.freeFist,
        isOnline: true,
        getInfo: (p) => p.info,
      );
      expect(result.first.info.id, 'offline');
    });

    test('qualityFirst sorts by qualityRank ascending', () {
      final result = FallbackChain.sort(
        providers: [offline, online],
        strategy: FallbackStrategy.qualityFirst,
        isOnline: true,
        getInfo: (p) => p.info,
      );
      expect(result.first.info.id, 'online'); // rank 0
    });

    test('empty list returns empty', () {
      final result = FallbackChain.sort<_FakeProvider>(
        providers: [],
        strategy: FallbackStrategy.freeFist,
        isOnline: true,
        getInfo: (p) => p.info,
      );
      expect(result, isEmpty);
    });
  });

  group('FallbackChain.execute', () {
    test('returns first successful result', () async {
      final result = await FallbackChain.execute(
        chain: [1, 2, 3],
        action: (p) async => 'result_$p',
      );
      expect(result, 'result_1');
    });

    test('falls back on failure', () async {
      var attempts = 0;
      final result = await FallbackChain.execute(
        chain: [1, 2, 3],
        action: (p) async {
          attempts++;
          if (p < 3) throw Exception('fail');
          return 'success';
        },
      );
      expect(result, 'success');
      expect(attempts, 3);
    });

    test('throws last error when all fail', () async {
      expect(
        () => FallbackChain.execute(
          chain: [1, 2],
          action: (p) async => throw Exception('error_$p'),
        ),
        throwsException,
      );
    });

    test('throws StateError on empty chain', () async {
      expect(
        () => FallbackChain.execute<int, String>(
          chain: [],
          action: (p) async => '',
        ),
        throwsStateError,
      );
    });
  });
}

class _FakeProvider {
  _FakeProvider(this.info);
  final ProviderInfo info;
}
