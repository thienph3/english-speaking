/// Tính trung bình response time từ danh sách (ms).
///
/// Pure static class — KHÔNG import Flutter/Riverpod.
/// KHÔNG giữ mutable state.
class ResponseTimeCalculator {
  ResponseTimeCalculator._();

  /// Tính trung bình response time.
  ///
  /// Trả về 0 nếu danh sách rỗng.
  /// [responseTimes] — danh sách thời gian phản hồi tính bằng ms.
  static double average(List<int> responseTimes) {
    if (responseTimes.isEmpty) return 0;
    final sum = responseTimes.reduce((a, b) => a + b);
    return sum / responseTimes.length;
  }
}
