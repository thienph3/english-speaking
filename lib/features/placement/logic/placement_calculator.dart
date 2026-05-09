/// Pure business logic cho Placement Test.
///
/// KHÔNG import Flutter, Riverpod, Supabase.
/// Input → Output, dễ test.
class PlacementCalculator {
  PlacementCalculator._();

  /// Tính mức khởi đầu từ danh sách điểm accuracy.
  ///
  /// - avg ≥ 80 → 'medium_hard'
  /// - 50 ≤ avg < 80 → 'easy_medium'
  /// - avg < 50 → 'easy'
  ///
  /// [scores] phải có ít nhất 1 phần tử.
  static String calculateLevel(List<double> scores) {
    assert(scores.isNotEmpty, 'Scores must not be empty');
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    if (avg >= 80) return 'medium_hard';
    if (avg >= 50) return 'easy_medium';
    return 'easy';
  }

  /// Tính điểm trung bình từ danh sách scores.
  static double calculateAverage(List<double> scores) {
    assert(scores.isNotEmpty, 'Scores must not be empty');
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}
