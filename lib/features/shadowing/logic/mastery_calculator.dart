import 'package:speakeng/core/constants.dart';
import 'package:speakeng/features/progress/models/sentence_progress.dart';

/// Tính toán mastery cho shadowing sentences.
///
/// Pure static class — KHÔNG import Flutter/Riverpod.
/// Logic: accuracy ≥ 80 → streak + 1, < 80 → reset.
/// Mastered khi streak ≥ 3.
class MasteryCalculator {
  MasteryCalculator._();

  /// Cập nhật progress sau mỗi lần luyện.
  ///
  /// [current] — progress hiện tại của sentence.
  /// [newAccuracy] — điểm accuracy mới (0–100).
  static SentenceProgress updateProgress(
    SentenceProgress current,
    double newAccuracy,
  ) {
    final newStreak = newAccuracy >= AppConstants.accuracyGoodThreshold
        ? current.correctStreak + 1
        : 0;
    final newBest = newAccuracy > current.bestAccuracy
        ? newAccuracy
        : current.bestAccuracy;

    return current.copyWith(
      correctStreak: newStreak,
      bestAccuracy: newBest,
      lastPracticed: DateTime.now(),
    );
  }

  /// Kiểm tra sentence đã mastered chưa.
  static bool isMastered(SentenceProgress progress) {
    return progress.correctStreak >= AppConstants.masteryStreakRequired;
  }
}
