import 'package:freezed_annotation/freezed_annotation.dart';

part 'sentence.freezed.dart';
part 'sentence.g.dart';

/// Câu shadowing trong bộ nội dung luyện tập.
///
/// Mỗi câu thuộc một tình huống (situation), có độ khó (difficulty),
/// danh sách cụm từ (phrases), và ngữ pháp mục tiêu (targetGrammar).
@freezed
abstract class Sentence with _$Sentence {
  const Sentence._();

  const factory Sentence({
    /// ID duy nhất của câu.
    required String id,

    /// Nội dung câu tiếng Anh.
    required String text,

    /// Tình huống sử dụng (ví dụ: "ordering food", "asking directions").
    required String situation,

    /// Danh sách cụm từ để luyện phrase-by-phrase.
    required List<String> phrases,

    /// Ngữ pháp mục tiêu của câu.
    @JsonKey(name: 'target_grammar') required String targetGrammar,

    /// Độ khó: "easy", "medium", "hard".
    required String difficulty,

    /// Đường dẫn file audio mẫu (nếu có).
    @JsonKey(name: 'audio_asset_path') String? audioAssetPath,
  }) = _Sentence;

  /// Câu có hỗ trợ luyện theo cụm từ hay không.
  /// Chỉ hỗ trợ khi câu có nhiều hơn 5 từ.
  bool get supportsPhrasePractice => text.split(' ').length > 5;

  factory Sentence.fromJson(Map<String, dynamic> json) =>
      _$SentenceFromJson(json);
}
