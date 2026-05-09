/// Pure lookup cho mẹo phát âm tiếng Việt.
///
/// KHÔNG phải service — chỉ là static data + function.
/// Cung cấp mẹo cho 11 phonemes mà người Việt thường phát sai.
class PhonemeTipLookup {
  PhonemeTipLookup._();

  /// Mẹo phát âm tiếng Việt cho 11 phonemes khó.
  static const Map<String, String> vietnameseTips = {
    'θ': 'Đặt lưỡi giữa 2 răng, thổi hơi ra nhẹ. Không phải /t/ hay /s/.',
    'ð': 'Đặt lưỡi giữa 2 răng, rung dây thanh. Không phải /d/ hay /z/.',
    'r': 'Cong lưỡi ra sau, KHÔNG chạm vòm miệng. Khác hoàn toàn "r" tiếng Việt.',
    'l': 'Đầu lưỡi chạm vòm miệng phía trước. Khác với /r/.',
    'ʃ': 'Môi tròn, lưỡi lùi ra sau. Giống "s" nhưng dày hơn.',
    'ʒ': 'Giống /ʃ/ nhưng rung dây thanh.',
    'z': 'Giống /s/ nhưng rung dây thanh. Tiếng Việt không có âm này.',
    'ŋ': 'Âm "ng" cuối từ — giữ nguyên, không thêm /g/ phía sau.',
    'p_final': 'Phụ âm cuối — ngậm môi, bật hơi nhẹ. Không nuốt âm.',
    't_final': 'Phụ âm cuối — đầu lưỡi chạm vòm, bật nhẹ. Không nuốt.',
    'k_final': 'Phụ âm cuối — cuống lưỡi chạm vòm mềm, bật nhẹ.',
  };

  /// Trả về mẹo cho phoneme có accuracy < 80%.
  ///
  /// Trả về null nếu:
  /// - [accuracy] ≥ 80 (phát âm đủ tốt)
  /// - [phoneme] không có trong bảng tips
  static String? getTip(String phoneme, double accuracy) {
    if (accuracy >= 80) return null;
    return vietnameseTips[phoneme];
  }
}
