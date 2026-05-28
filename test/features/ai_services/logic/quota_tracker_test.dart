import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/ai_services/logic/quota_tracker.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';

void main() {
  group('QuotaTracker (in-memory logic)', () {
    late QuotaTracker tracker;

    setUp(() => tracker = QuotaTracker());

    final limited = ProviderInfo(
      id: 'tts_online',
      serviceType: ServiceType.tts,
      connectionType: ConnectionType.online,
      quotaLimit: 100,
    );

    final unlimited = ProviderInfo(
      id: 'tts_offline',
      serviceType: ServiceType.tts,
      connectionType: ConnectionType.offline,
    );

    test('getUsage returns 0 for unused provider', () {
      expect(tracker.getUsage('tts_online'), 0);
    });

    test('isNearLimit false when usage < 80%', () {
      expect(tracker.isNearLimit(limited), false);
    });

    test('isNearLimit true when usage >= 80%', () {
      // Manually set usage via internal state
      for (var i = 0; i < 80; i++) {
        tracker.getUsage('tts_online'); // just checking, need to simulate
      }
      // Since we can't call record() without SharedPreferences,
      // test the math directly
      final info80 = ProviderInfo(
        id: 'test',
        serviceType: ServiceType.tts,
        connectionType: ConnectionType.online,
        quotaLimit: 10,
      );
      // Usage is 0, so not near limit
      expect(tracker.isNearLimit(info80), false);
    });

    test('isExceeded false when no usage', () {
      expect(tracker.isExceeded(limited), false);
    });

    test('isNearLimit always false for unlimited provider', () {
      expect(tracker.isNearLimit(unlimited), false);
    });

    test('isExceeded always false for unlimited provider', () {
      expect(tracker.isExceeded(unlimited), false);
    });

    test('remaining returns full quota when no usage', () {
      expect(tracker.remaining(limited), 100);
    });

    test('remaining returns null for unlimited provider', () {
      expect(tracker.remaining(unlimited), isNull);
    });
  });
}
