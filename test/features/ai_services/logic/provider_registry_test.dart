import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/ai_services/logic/provider_registry.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/has_provider_info.dart';

void main() {
  late ProviderRegistry registry;

  setUp(() => registry = ProviderRegistry());

  group('ProviderRegistry', () {
    test('register and getAll returns providers', () {
      final p = _FakeProvider('a', ServiceType.tts);
      registry.register(ServiceType.tts, p);
      expect(registry.getAll<_FakeProvider>(ServiceType.tts), [p]);
    });

    test('getAll returns empty for unregistered type', () {
      expect(registry.getAll<_FakeProvider>(ServiceType.llm), isEmpty);
    });

    test('multiple providers for same type', () {
      final p1 = _FakeProvider('a', ServiceType.stt);
      final p2 = _FakeProvider('b', ServiceType.stt);
      registry.register(ServiceType.stt, p1);
      registry.register(ServiceType.stt, p2);
      expect(registry.getAll<_FakeProvider>(ServiceType.stt).length, 2);
    });

    test('getAvailable filters out non-ready providers', () {
      final ready = _FakeProvider('a', ServiceType.tts);
      final notReady = _FakeProvider(
        'b',
        ServiceType.tts,
        status: ProviderStatus.notDownloaded,
      );
      registry.register(ServiceType.tts, ready);
      registry.register(ServiceType.tts, notReady);
      final available = registry.getAvailable<_FakeProvider>(ServiceType.tts);
      expect(available.length, 1);
      expect(available.first.info.id, 'a');
    });

    test('getOnline returns only online providers', () {
      final online = _FakeProvider('on', ServiceType.tts);
      final offline = _FakeProvider(
        'off',
        ServiceType.tts,
        connection: ConnectionType.offline,
      );
      registry.register(ServiceType.tts, online);
      registry.register(ServiceType.tts, offline);
      final result = registry.getOnline<_FakeProvider>(ServiceType.tts);
      expect(result.length, 1);
      expect(result.first.info.id, 'on');
    });

    test('getOffline returns only offline providers', () {
      final online = _FakeProvider('on', ServiceType.tts);
      final offline = _FakeProvider(
        'off',
        ServiceType.tts,
        connection: ConnectionType.offline,
      );
      registry.register(ServiceType.tts, online);
      registry.register(ServiceType.tts, offline);
      final result = registry.getOffline<_FakeProvider>(ServiceType.tts);
      expect(result.length, 1);
      expect(result.first.info.id, 'off');
    });
  });
}

class _FakeProvider implements HasProviderInfo {
  _FakeProvider(
    String id,
    ServiceType type, {
    ConnectionType connection = ConnectionType.online,
    ProviderStatus status = ProviderStatus.ready,
  }) : info = ProviderInfo(
          id: id,
          serviceType: type,
          connectionType: connection,
          status: status,
        );

  @override
  final ProviderInfo info;
}
