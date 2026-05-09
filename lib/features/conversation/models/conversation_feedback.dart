import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_feedback.freezed.dart';
part 'conversation_feedback.g.dart';

/// Phản hồi chi tiết sau hội thoại AI.
///
/// Được parse từ JSON response của GPT-4o-mini
/// khi hội thoại kết thúc.
@freezed
abstract class ConversationFeedback with _$ConversationFeedback {
  const factory ConversationFeedback({
    /// Danh sách lỗi ngữ pháp user mắc phải.
    @JsonKey(name: 'grammar_errors')
    @Default([])
    List<String> grammarErrors,

    /// Gợi ý từ vựng để cải thiện.
    @JsonKey(name: 'vocabulary_suggestions')
    @Default([])
    List<String> vocabularySuggestions,

    /// Điểm tích cực trong hội thoại.
    @Default('') String positive,

    /// Điểm cần cải thiện.
    @Default('') String improve,
  }) = _ConversationFeedback;

  factory ConversationFeedback.fromJson(Map<String, dynamic> json) =>
      _$ConversationFeedbackFromJson(json);
}
