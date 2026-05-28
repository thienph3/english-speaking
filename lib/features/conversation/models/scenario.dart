import 'package:freezed_annotation/freezed_annotation.dart';

part 'scenario.freezed.dart';
part 'scenario.g.dart';

/// Loại scenario: thường xuyên hoặc sự kiện có thời hạn.
enum ScenarioCategory { common, event }

/// Kịch bản hội thoại AI cho conversation practice.
///
/// - [common]: scenarios luôn hiển thị (daily life, work, travel)
/// - [event]: scenarios chỉ hiển thị trong khoảng thời gian nhất định
///   (trade shows, conferences, trips)
///
/// Khi migrate lên backend, server trả về scenarios filtered by date.
@freezed
abstract class Scenario with _$Scenario {
  const Scenario._();

  const factory Scenario({
    required String id,
    required String situation,
    @JsonKey(name: 'ai_role') required String aiRole,
    @JsonKey(name: 'first_message') required String firstMessage,
    @JsonKey(name: 'first_message_audio_path') String? firstMessageAudioPath,
    @JsonKey(name: 'target_phrases') required List<String> targetPhrases,
    @JsonKey(name: 'target_grammar') required List<String> targetGrammar,
    @JsonKey(name: 'max_turns') @Default(5) int maxTurns,
    required List<String> hints,
    @JsonKey(name: 'system_prompt') required String systemPrompt,

    /// Phân loại: 'common' (mặc định) hoặc 'event'.
    @Default(ScenarioCategory.common) ScenarioCategory category,

    /// Ngày bắt đầu hiển thị (ISO 8601). Null = luôn hiển thị.
    @JsonKey(name: 'available_from') String? availableFrom,

    /// Ngày kết thúc hiển thị (ISO 8601). Null = không hết hạn.
    @JsonKey(name: 'available_until') String? availableUntil,

    /// Tên sự kiện (cho UI grouping).
    @JsonKey(name: 'event_name') String? eventName,
  }) = _Scenario;

  /// Scenario có đang available tại thời điểm hiện tại không.
  bool get isAvailableNow {
    final now = DateTime.now();
    if (availableFrom != null) {
      if (now.isBefore(DateTime.parse(availableFrom!))) return false;
    }
    if (availableUntil != null) {
      if (now.isAfter(DateTime.parse(availableUntil!))) return false;
    }
    return true;
  }

  factory Scenario.fromJson(Map<String, dynamic> json) =>
      _$ScenarioFromJson(json);
}
