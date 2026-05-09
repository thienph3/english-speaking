import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';

/// Maps word accuracy scores to display colors.
///
/// Pure logic — no Flutter imports.
/// - accuracy ≥ 80 → green (phát âm tốt)
/// - accuracy 50–79 → yellow (cần cải thiện)
/// - accuracy < 50 → red (phát âm sai)
class WordColorMapper {
  WordColorMapper._();

  /// Map accuracy score → [WordColor].
  ///
  /// [accuracyScore] phải nằm trong khoảng [0, 100].
  static WordColor mapColor(double accuracyScore) {
    if (accuracyScore >= 80) return WordColor.green;
    if (accuracyScore >= 50) return WordColor.yellow;
    return WordColor.red;
  }
}
