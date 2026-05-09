import 'package:freezed_annotation/freezed_annotation.dart';

part 'sentence_progress.freezed.dart';
part 'sentence_progress.g.dart';

/// Tiến bộ luyện tập của User cho một Sentence cụ thể.
///
/// Theo dõi correct streak (số lần đạt accuracy ≥ 80% liên tiếp),
/// best accuracy đạt được, và thời điểm luyện gần nhất.
@freezed
abstract class SentenceProgress with _$SentenceProgress {
  const SentenceProgress._();

  const factory SentenceProgress({
    /// ID của User.
    required String userId,

    /// ID của Sentence đang theo dõi.
    required String sentenceId,

    /// Số lần đạt accuracy ≥ 80% liên tiếp.
    @Default(0) int correctStreak,

    /// Điểm accuracy cao nhất đạt được.
    @Default(0) double bestAccuracy,

    /// Thời điểm luyện tập gần nhất.
    DateTime? lastPracticed,
  }) = _SentenceProgress;

  /// Sentence đã được master hay chưa.
  /// Mastered khi correct streak ≥ 3.
  bool get isMastered => correctStreak >= 3;

  factory SentenceProgress.fromJson(Map<String, dynamic> json) =>
      _$SentenceProgressFromJson(json);
}
