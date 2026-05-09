import 'package:speakeng/features/shadowing/models/sentence.dart';

/// Chia câu shadowing thành cụm từ để luyện phrase-by-phrase.
///
/// Pure static class — KHÔNG import Flutter/Riverpod.
/// Dùng sentence.phrases nếu có, ngược lại chia theo chunks 3 từ.
class PhraseSplitter {
  PhraseSplitter._();

  /// Chia câu thành danh sách cụm từ.
  ///
  /// - Nếu [sentence.phrases] non-empty → trả về phrases đó.
  /// - Ngược lại → chia text thành chunks 3 từ.
  static List<String> split(Sentence sentence) {
    if (sentence.phrases.isNotEmpty) {
      return sentence.phrases;
    }
    return _chunkByWords(sentence.text, 3);
  }

  /// Kiểm tra câu có hỗ trợ luyện phrase-by-phrase không.
  ///
  /// Chỉ hỗ trợ khi câu có nhiều hơn 5 từ.
  static bool supportsPhrasePractice(Sentence sentence) =>
      sentence.text.split(' ').length > 5;

  /// Chia text thành chunks có [chunkSize] từ mỗi chunk.
  static List<String> _chunkByWords(String text, int chunkSize) {
    final words = text.split(' ');
    final chunks = <String>[];
    for (var i = 0; i < words.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, words.length);
      chunks.add(words.sublist(i, end).join(' '));
    }
    return chunks;
  }
}
