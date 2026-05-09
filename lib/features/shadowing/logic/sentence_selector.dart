import 'package:speakeng/features/shadowing/models/sentence.dart';

/// Chọn câu shadowing phù hợp với level của user.
///
/// Pure logic class — KHÔNG import Flutter/Riverpod.
/// Dùng kết quả placement (starting_level) để lọc câu theo difficulty.
class SentenceSelector {
  /// Lọc danh sách câu theo level của user.
  ///
  /// - level 'easy' → chỉ difficulty 'easy'
  /// - level 'easy_medium' → difficulty 'easy' hoặc 'medium'
  /// - level 'medium_hard' → difficulty 'medium' hoặc 'hard'
  /// - default → tất cả difficulties
  static List<Sentence> getAvailableSentences(
    List<Sentence> allSentences,
    String userLevel,
  ) {
    final allowedDifficulties = _getAllowedDifficulties(userLevel);
    return allSentences
        .where((s) => allowedDifficulties.contains(s.difficulty))
        .toList();
  }

  /// Trả về tập hợp difficulty được phép cho mỗi level.
  static Set<String> _getAllowedDifficulties(String level) {
    switch (level) {
      case 'easy':
        return {'easy'};
      case 'easy_medium':
        return {'easy', 'medium'};
      case 'medium_hard':
        return {'medium', 'hard'};
      default:
        return {'easy', 'medium', 'hard'};
    }
  }
}
