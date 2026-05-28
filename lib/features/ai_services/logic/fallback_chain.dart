import 'package:speakeng/features/ai_services/models/service_types.dart';

/// Sắp xếp danh sách providers theo FallbackStrategy.
///
/// Pure logic, không có side effects.
class FallbackChain {
  /// Sắp xếp providers theo strategy.
  ///
  /// [providers] — danh sách providers cần sắp xếp.
  /// [strategy] — chiến lược ưu tiên.
  /// [isOnline] — device có đang online không.
  static List<T> sort<T>({
    required List<T> providers,
    required FallbackStrategy strategy,
    required bool isOnline,
    required ProviderInfo Function(T) getInfo,
  }) {
    if (providers.isEmpty) return [];

    switch (strategy) {
      case FallbackStrategy.offlineOnly:
        return providers
            .where((p) => getInfo(p).isOffline)
            .toList();

      case FallbackStrategy.freeFist:
        final sorted = List<T>.from(providers);
        sorted.sort((a, b) {
          final infoA = getInfo(a);
          final infoB = getInfo(b);
          // Offline (free) trước online có quota
          if (infoA.isOffline && infoB.isOnline) return -1;
          if (infoA.isOnline && infoB.isOffline) return 1;
          // Unlimited quota trước limited
          if (infoA.hasUnlimitedQuota && !infoB.hasUnlimitedQuota) return -1;
          if (!infoA.hasUnlimitedQuota && infoB.hasUnlimitedQuota) return 1;
          return 0;
        });
        return sorted;

      case FallbackStrategy.qualityFirst:
        final sorted = List<T>.from(providers);
        sorted.sort((a, b) {
          final infoA = getInfo(a);
          final infoB = getInfo(b);
          return infoA.qualityRank.compareTo(infoB.qualityRank);
        });
        return sorted;
    }
  }

  /// Thực thi request với fallback chain.
  ///
  /// Thử từng provider theo thứ tự, nếu fail thì chuyển sang provider tiếp.
  /// Throw exception cuối cùng nếu tất cả đều fail.
  static Future<R> execute<T, R>({
    required List<T> chain,
    required Future<R> Function(T provider) action,
  }) async {
    Object? lastError;

    for (final provider in chain) {
      try {
        return await action(provider);
      } catch (e) {
        lastError = e;
        continue;
      }
    }

    if (lastError != null) {
      // ignore: only_throw_errors
      throw lastError;
    }
    throw StateError('No providers available');
  }
}
