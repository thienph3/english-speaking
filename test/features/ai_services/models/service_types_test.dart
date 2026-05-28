import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';

void main() {
  group('ProviderInfo', () {
    test('isOnline/isOffline', () {
      const online = ProviderInfo(
        id: 'a',
        serviceType: ServiceType.tts,
        connectionType: ConnectionType.online,
      );
      const offline = ProviderInfo(
        id: 'b',
        serviceType: ServiceType.tts,
        connectionType: ConnectionType.offline,
      );
      expect(online.isOnline, true);
      expect(online.isOffline, false);
      expect(offline.isOnline, false);
      expect(offline.isOffline, true);
    });

    test('isReady', () {
      const ready = ProviderInfo(
        id: 'a',
        serviceType: ServiceType.stt,
        connectionType: ConnectionType.online,
        status: ProviderStatus.ready,
      );
      const notReady = ProviderInfo(
        id: 'b',
        serviceType: ServiceType.stt,
        connectionType: ConnectionType.online,
        status: ProviderStatus.notDownloaded,
      );
      expect(ready.isReady, true);
      expect(notReady.isReady, false);
    });

    test('hasUnlimitedQuota', () {
      const unlimited = ProviderInfo(
        id: 'a',
        serviceType: ServiceType.tts,
        connectionType: ConnectionType.offline,
      );
      const limited = ProviderInfo(
        id: 'b',
        serviceType: ServiceType.tts,
        connectionType: ConnectionType.online,
        quotaLimit: 1000,
      );
      expect(unlimited.hasUnlimitedQuota, true);
      expect(limited.hasUnlimitedQuota, false);
    });

    test('copyWith updates status', () {
      const info = ProviderInfo(
        id: 'a',
        serviceType: ServiceType.tts,
        connectionType: ConnectionType.offline,
        status: ProviderStatus.notDownloaded,
      );
      final updated = info.copyWith(status: ProviderStatus.ready);
      expect(updated.status, ProviderStatus.ready);
      expect(updated.id, 'a');
    });
  });
}
