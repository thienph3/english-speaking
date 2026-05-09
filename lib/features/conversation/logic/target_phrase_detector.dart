/// Phát hiện target phrases trong transcript hội thoại.
///
/// Pure static class — KHÔNG import Flutter/Riverpod.
class TargetPhraseDetector {
  TargetPhraseDetector._();

  /// Kiểm tra transcript có chứa target phrases không (case-insensitive).
  ///
  /// Trả về Map với key là phrase, value là true nếu transcript chứa phrase.
  static Map<String, bool> detectUsage(
    String transcript,
    List<String> targetPhrases,
  ) {
    final lowerTranscript = transcript.toLowerCase();
    return {
      for (final phrase in targetPhrases)
        phrase: lowerTranscript.contains(phrase.toLowerCase()),
    };
  }

  /// Tính tỷ lệ sử dụng target phrases (0.0 – 1.0).
  ///
  /// Trả về 0.0 nếu usage map rỗng.
  static double usageRate(Map<String, bool> usage) {
    if (usage.isEmpty) return 0.0;
    final used = usage.values.where((v) => v).length;
    return used / usage.length;
  }
}
