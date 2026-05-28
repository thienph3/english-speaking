import 'package:speakeng/features/conversation/providers/conversation_state.dart';

/// Extension helpers để extract common fields từ ConversationState.
extension ConversationStateHelpers on ConversationState {
  int get turnCount => switch (this) {
        ConversationRecording(turnCount: final t) => t,
        ConversationTranscribing(turnCount: final t) => t,
        ConversationThinking(turnCount: final t) => t,
        ConversationSpeaking(turnCount: final t) => t,
        ConversationCompleted(turnCount: final t) => t,
        ConversationError(turnCount: final t) => t,
        _ => 0,
      };

  List<Map<String, String>> get messages => switch (this) {
        ConversationRecording(messages: final m) => m,
        ConversationTranscribing(messages: final m) => m,
        ConversationThinking(messages: final m) => m,
        ConversationSpeaking(messages: final m) => m,
        ConversationCompleted(messages: final m) => m,
        ConversationError(messages: final m) => m,
        _ => [],
      };

  bool get isTyping =>
      this is ConversationTranscribing || this is ConversationThinking;
}
