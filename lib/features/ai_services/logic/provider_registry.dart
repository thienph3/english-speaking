import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/has_provider_info.dart';

/// Registry trung tâm quản lý tất cả AI providers.
///
/// Cho phép đăng ký, truy vấn providers theo ServiceType,
/// và lọc theo trạng thái/connection type.
class ProviderRegistry {
  final Map<ServiceType, List<HasProviderInfo>> _providers = {};

  /// Đăng ký một provider vào registry.
  void register(ServiceType type, HasProviderInfo provider) {
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
      return (p as HasProviderInfo).info.isReady;
    }).toList();
  }

  /// Lấy chỉ online providers.
  List<T> getOnline<T>(ServiceType type) {
    return getAvailable<T>(type).where((p) {
      return (p as HasProviderInfo).info.isOnline;
    }).toList();
  }

  /// Lấy chỉ offline providers.
  List<T> getOffline<T>(ServiceType type) {
    return getAvailable<T>(type).where((p) {
      return (p as HasProviderInfo).info.isOffline;
    }).toList();
  }
}
