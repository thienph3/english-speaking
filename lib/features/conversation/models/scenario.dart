import 'package:freezed_annotation/freezed_annotation.dart';

part 'scenario.freezed.dart';
part 'scenario.g.dart';

/// Kịch bản hội thoại AI cho conversation practice.
///
/// Mỗi scenario có tình huống, vai trò AI, target phrases,
/// và system prompt để điều khiển hành vi AI.
@freezed
abstract class Scenario with _$Scenario {
  const factory Scenario({
    /// ID duy nhất của scenario.
    required String id,

    /// Mô tả tình huống hội thoại.
    required String situation,

    /// Vai trò của AI trong hội thoại.
    @JsonKey(name: 'ai_role') required String aiRole,

    /// Tin nhắn đầu tiên AI gửi cho user.
    @JsonKey(name: 'first_message') required String firstMessage,

    /// Đường dẫn audio pre-cached cho first message.
    @JsonKey(name: 'first_message_audio_path') String? firstMessageAudioPath,

    /// Danh sách cụm từ mục tiêu user nên sử dụng.
    @JsonKey(name: 'target_phrases') required List<String> targetPhrases,

    /// Danh sách ngữ pháp mục tiêu.
    @JsonKey(name: 'target_grammar') required List<String> targetGrammar,

    /// Số lượt hội thoại tối đa.
    @JsonKey(name: 'max_turns') @Default(5) int maxTurns,

    /// Danh sách gợi ý cho user.
    required List<String> hints,

    /// System prompt gửi cho GPT-4o-mini.
    @JsonKey(name: 'system_prompt') required String systemPrompt,
  }) = _Scenario;

  factory Scenario.fromJson(Map<String, dynamic> json) =>
      _$ScenarioFromJson(json);
}
