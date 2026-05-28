import 'package:speakeng/features/ai_services/models/service_types.dart';

/// Registry trung tâm quản lý tất cả AI providers.
///
/// Cho phép đăng ký, truy vấn providers theo ServiceType,
/// và lọc theo trạng thái/connection type.
class ProviderRegistry {
  final Map<ServiceType, List<dynamic>> _providers = {};

  /// Đăng ký một provider vào registry.
  void register(ServiceType type, dynamic provider) {
    _providers.putIfAbsent(type, () => []);
    _providers[type]!.add(provider);
  }

  /// Lấy tất cả providers đã đăng ký cho một ServiceType.
  List<T> getAll<T>(ServiceType type) {
    return (_providers[type] ?? []).cast<T>();
  }

  /// Lấy providers có trạng thái ready.
  List<T> getAvailable<T>(ServiceType type) {
    return getAll<T>(type).where((p) {
      final info = (p as dynamic).info as ProviderInfo;
      return info.isReady;
    }).toList();
  }

  /// Lấy chỉ online providers.
  List<T> getOnline<T>(ServiceType type) {
    return getAvailable<T>(type).where((p) {
      final info = (p as dynamic).info as ProviderInfo;
      return info.isOnline;
    }).toList();
  }

  /// Lấy chỉ offline providers.
  List<T> getOffline<T>(ServiceType type) {
    return getAvailable<T>(type).where((p) {
      final info = (p as dynamic).info as ProviderInfo;
      return info.isOffline;
    }).toList();
  }
}
