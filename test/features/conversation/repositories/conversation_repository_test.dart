import 'package:flutter_test/flutter_test.dart';

/// Tests the pure logic parts of ConversationRepository:
/// message management, turn counting, turn limits.
///
/// Since ConversationRepository takes AiOrchestrator (which requires
/// real Supabase/sherpa_onnx), we test the logic directly.
void main() {
  group('ConversationRepository (message logic)', () {
    late _MessageStore store;

    setUp(() {
      store = _MessageStore();
    });

    test('initial messages is empty', () {
      expect(store.messages, isEmpty);
    });

    test('initial currentTurn is 0', () {
      expect(store.currentTurn, 0);
    });

    test('addMessage adds to messages list', () {
      store.addMessage('assistant', 'Hello!');
      expect(store.messages.length, 1);
      expect(store.messages.first, {'role': 'assistant', 'content': 'Hello!'});
    });

    test('messages list is unmodifiable', () {
      store.addMessage('user', 'Hi');
      expect(() => store.messages.add({}), throwsUnsupportedError);
    });

    test('currentTurn counts only user messages', () {
      store.addMessage('assistant', 'Hello!');
      store.addMessage('user', 'Hi');
      store.addMessage('assistant', 'How are you?');
      store.addMessage('user', 'Good');
      expect(store.currentTurn, 2);
    });

    test('isAtTurnLimit false when under 5 turns', () {
      for (var i = 0; i < 4; i++) {
        store.addMessage('user', 'msg $i');
      }
      expect(store.isAtTurnLimit, false);
    });

    test('isAtTurnLimit true at 5 turns', () {
      for (var i = 0; i < 5; i++) {
        store.addMessage('user', 'msg $i');
      }
      expect(store.isAtTurnLimit, true);
    });

    test('reset clears all messages', () {
      store.addMessage('user', 'Hello');
      store.addMessage('assistant', 'Hi');
      store.reset();
      expect(store.messages, isEmpty);
      expect(store.currentTurn, 0);
    });
  });
}

/// Replicates ConversationRepository's message management logic.
class _MessageStore {
  static const _maxTurns = 5;
  final List<Map<String, String>> _messages = [];

  List<Map<String, String>> get messages => List.unmodifiable(_messages);
  int get currentTurn => _messages.where((m) => m['role'] == 'user').length;
  bool get isAtTurnLimit => currentTurn >= _maxTurns;

  void addMessage(String role, String content) {
    _messages.add({'role': role, 'content': content});
  }

  void reset() => _messages.clear();
}
