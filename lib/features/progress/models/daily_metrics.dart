import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_metrics.freezed.dart';
part 'daily_metrics.g.dart';

/// Metrics luyện tập hàng ngày của User.
///
/// Lưu trữ số câu đã luyện, số câu mastered, accuracy TB,
/// và response time TB cho mỗi ngày.
@freezed
abstract class DailyMetrics with _$DailyMetrics {
  const factory DailyMetrics({
    /// ID của User.
    required String userId,

    /// Ngày ghi nhận metrics.
    required DateTime date,

    /// Số câu đã luyện trong ngày.
    @Default(0) int sentencesPracticed,

    /// Số câu mới mastered trong ngày.
    @Default(0) int sentencesMastered,

    /// Accuracy trung bình trong ngày (0–100).
    @Default(0) double avgAccuracy,

    /// Response time trung bình (ms) trong ngày.
    @Default(0) int avgResponseTimeMs,
  }) = _DailyMetrics;

  factory DailyMetrics.fromJson(Map<String, dynamic> json) =>
      _$DailyMetricsFromJson(json);
}
