import 'package:flutter_riverpod/legacy.dart';

import 'package:speakeng/features/progress/models/daily_metrics.dart';
import 'package:speakeng/features/progress/repositories/progress_repository.dart';

/// State cho progress dashboard.
class ProgressState {
  const ProgressState({
    this.sentencesMastered = 0,
    this.thisWeekMetrics = const [],
    this.lastWeekMetrics = const [],
    this.isLoading = false,
    this.error,
  });

  final int sentencesMastered;
  final List<DailyMetrics> thisWeekMetrics;
  final List<DailyMetrics> lastWeekMetrics;
  final bool isLoading;
  final String? error;

  ProgressState copyWith({
    int? sentencesMastered,
    List<DailyMetrics>? thisWeekMetrics,
    List<DailyMetrics>? lastWeekMetrics,
    bool? isLoading,
    String? error,
  }) {
    return ProgressState(
      sentencesMastered: sentencesMastered ?? this.sentencesMastered,
      thisWeekMetrics: thisWeekMetrics ?? this.thisWeekMetrics,
      lastWeekMetrics: lastWeekMetrics ?? this.lastWeekMetrics,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Accuracy TB tuần này.
  double get thisWeekAvgAccuracy {
    if (thisWeekMetrics.isEmpty) return 0;
    final sum = thisWeekMetrics.fold<double>(
      0,
      (acc, m) => acc + m.avgAccuracy,
    );
    return sum / thisWeekMetrics.length;
  }

  /// Accuracy TB tuần trước.
  double get lastWeekAvgAccuracy {
    if (lastWeekMetrics.isEmpty) return 0;
    final sum = lastWeekMetrics.fold<double>(
      0,
      (acc, m) => acc + m.avgAccuracy,
    );
    return sum / lastWeekMetrics.length;
  }

  /// Response time TB tuần này (ms).
  double get thisWeekAvgResponseTime {
    if (thisWeekMetrics.isEmpty) return 0;
    final sum = thisWeekMetrics.fold<int>(
      0,
      (acc, m) => acc + m.avgResponseTimeMs,
    );
    return sum / thisWeekMetrics.length;
  }

  /// Response time TB tuần trước (ms).
  double get lastWeekAvgResponseTime {
    if (lastWeekMetrics.isEmpty) return 0;
    final sum = lastWeekMetrics.fold<int>(
      0,
      (acc, m) => acc + m.avgResponseTimeMs,
    );
    return sum / lastWeekMetrics.length;
  }
}

/// Provider cho ProgressNotifier.
final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  return ProgressNotifier(ref.read(progressRepositoryProvider));
});

/// StateNotifier quản lý progress dashboard state.
class ProgressNotifier extends StateNotifier<ProgressState> {
  ProgressNotifier(this._repository) : super(const ProgressState());

  final ProgressRepository _repository;

  /// Load tất cả metrics cho dashboard.
  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final mastered = await _repository.countMasteredSentences();
      final thisWeekStart = _getWeekStart(DateTime.now());
      final lastWeekStart =
          thisWeekStart.subtract(const Duration(days: 7));

      final thisWeek = await _repository.getWeekMetrics(thisWeekStart);
      final lastWeek = await _repository.getWeekMetrics(lastWeekStart);

      state = state.copyWith(
        sentencesMastered: mastered,
        thisWeekMetrics: thisWeek,
        lastWeekMetrics: lastWeek,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải dữ liệu tiến bộ.',
      );
    }
  }

  /// Tính ngày đầu tuần (Monday).
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 = Monday
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }
}
