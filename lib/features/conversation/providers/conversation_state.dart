import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:speakeng/features/conversation/models/scenario.dart';

part 'conversation_state.freezed.dart';

/// Trạng thái của conversation flow.
///
/// Sử dụng freezed unions để biểu diễn các trạng thái rời rạc
/// trong quá trình hội thoại AI.
@freezed
sealed class ConversationState with _$ConversationState {
  /// Chưa bắt đầu hội thoại.
  const factory ConversationState.idle() = ConversationIdle;

  /// Đang ghi âm giọng user.
  const factory ConversationState.recording({
    required Scenario scenario,
    required List<Map<String, String>> messages,
    required int turnCount,
    required List<int> responseTimes,
    String? cachedAudioPath,
  }) = ConversationRecording;

  /// Đang transcribe audio → text.
  const factory ConversationState.transcribing({
    required Scenario scenario,
    required List<Map<String, String>> messages,
    required int turnCount,
    required List<int> responseTimes,
    String? cachedAudioPath,
  }) = ConversationTranscribing;

  /// Đang chờ AI phản hồi (GPT-4o-mini).
  const factory ConversationState.thinking({
    required Scenario scenario,
    required List<Map<String, String>> messages,
    required int turnCount,
    required List<int> responseTimes,
    String? cachedAudioPath,
  }) = ConversationThinking;

  /// AI đang phát audio phản hồi.
  const factory ConversationState.speaking({
    required Scenario scenario,
    required List<Map<String, String>> messages,
    required int turnCount,
    required List<int> responseTimes,
    String? cachedAudioPath,
  }) = ConversationSpeaking;

  /// Hội thoại đã hoàn thành (đạt max turns).
  const factory ConversationState.completed({
    required Scenario scenario,
    required List<Map<String, String>> messages,
    required int turnCount,
    required List<int> responseTimes,
  }) = ConversationCompleted;

  /// Có lỗi xảy ra.
  const factory ConversationState.error({
    required String message,
    required Scenario scenario,
    required List<Map<String, String>> messages,
    required int turnCount,
    required List<int> responseTimes,
    String? cachedAudioPath,
  }) = ConversationError;
}
