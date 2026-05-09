import 'package:freezed_annotation/freezed_annotation.dart';

part 'pronunciation_result.freezed.dart';
part 'pronunciation_result.g.dart';

/// Màu hiển thị cho từ dựa trên accuracy score.
///
/// - [green]: accuracy ≥ 80% — phát âm tốt
/// - [yellow]: accuracy 50%–79% — cần cải thiện
/// - [red]: accuracy < 50% — phát âm sai
enum WordColor { green, yellow, red }

/// Kết quả đánh giá phát âm tổng thể từ Azure Speech.
@freezed
abstract class PronunciationResult with _$PronunciationResult {
  const factory PronunciationResult({
    /// Điểm chính xác tổng thể (0–100).
    required double accuracyScore,

    /// Điểm lưu loát (0–100).
    required double fluencyScore,

    /// Điểm hoàn chỉnh (0–100).
    required double completenessScore,

    /// Kết quả chi tiết cho từng từ.
    required List<WordResult> words,
  }) = _PronunciationResult;

  factory PronunciationResult.fromJson(Map<String, dynamic> json) =>
      _$PronunciationResultFromJson(json);
}

/// Kết quả đánh giá phát âm cho một từ.
@freezed
abstract class WordResult with _$WordResult {
  const factory WordResult({
    /// Từ được đánh giá.
    required String word,

    /// Điểm chính xác của từ (0–100).
    required double accuracyScore,

    /// Loại lỗi (nếu có): "Mispronunciation", "Omission", "Insertion".
    String? errorType,

    /// Kết quả chi tiết cho từng phoneme trong từ.
    required List<PhonemeResult> phonemes,
  }) = _WordResult;

  factory WordResult.fromJson(Map<String, dynamic> json) =>
      _$WordResultFromJson(json);
}

/// Kết quả đánh giá phát âm cho một phoneme.
@freezed
abstract class PhonemeResult with _$PhonemeResult {
  const factory PhonemeResult({
    /// Ký hiệu IPA của phoneme.
    required String phoneme,

    /// Điểm chính xác của phoneme (0–100).
    required double accuracyScore,
  }) = _PhonemeResult;

  factory PhonemeResult.fromJson(Map<String, dynamic> json) =>
      _$PhonemeResultFromJson(json);
}
