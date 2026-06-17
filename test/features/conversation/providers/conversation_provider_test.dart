import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/core/constants.dart';
import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/conversation/models/scenario.dart';
import 'package:speakeng/features/conversation/providers/conversation_state.dart';

final _testScenario = Scenario(
  id: 'order_coffee',
  situation: 'Ordering at a coffee shop',
  aiRole: 'barista',
  firstMessage: 'Hi! What can I get for you today?',
  targetPhrases: ["I'd like", "Could I have"],
  targetGrammar: ['polite requests'],
  hints: ['Try: I\'d like a...'],
  systemPrompt: 'You are a friendly barista.',
);

/// Minimal notifier replicating ConversationNotifier logic without
/// real orchestrator/path_provider dependencies.
class _TestConversationNotifier {
  _TestConversationNotifier({
    this.transcribeResult = "I'd like a latte please",
    this.chatResult = 'Great choice! What size?',
    this.shouldFailTranscribe = false,
  });

  final String transcribeResult;
  final String chatResult;
  final bool shouldFailTranscribe;

  ConversationState state = const ConversationState.idle();
  final List<Map<String, String>> _messages = [];
  int get _currentTurn => _messages.where((m) => m['role'] == 'user').length;

  Future<void> startScenario(Scenario scenario) async {
    _messages.clear();
    _messages.add({'role': 'assistant', 'content': scenario.firstMessage});

    state = ConversationState.speaking(
      scenario: scenario,
      messages: List.unmodifiable(_messages),
      turnCount: 0,
      responseTimes: [],
      cachedAudioPath: null,
    );
  }

  void startRecording() {
    if (state is! ConversationSpeaking) return;
    final s = state as ConversationSpeaking;
    state = ConversationState.recording(
      scenario: s.scenario,
      messages: s.messages,
      turnCount: s.turnCount,
      responseTimes: s.responseTimes,
      cachedAudioPath: s.cachedAudioPath,
    );
  }

  Future<void> submitRecording(Uint8List audio) async {
    if (state is! ConversationRecording) return;
    final s = state as ConversationRecording;
    final updatedTimes = [...s.responseTimes, 1000];

    state = ConversationState.transcribing(
      scenario: s.scenario,
      messages: List.unmodifiable(_messages),
      turnCount: _currentTurn,
      responseTimes: updatedTimes,
      cachedAudioPath: s.cachedAudioPath,
    );

    try {
      if (shouldFailTranscribe) throw const TranscriptionError();
      _messages.add({'role': 'user', 'content': transcribeResult});

      state = ConversationState.thinking(
        scenario: s.scenario,
        messages: List.unmodifiable(_messages),
        turnCount: _currentTurn,
        responseTimes: updatedTimes,
        cachedAudioPath: s.cachedAudioPath,
      );

      _messages.add({'role': 'assistant', 'content': chatResult});

      if (_currentTurn >= AppConstants.maxConversationTurns) {
        state = ConversationState.completed(
          scenario: s.scenario,
          messages: List.unmodifiable(_messages),
          turnCount: _currentTurn,
          responseTimes: updatedTimes,
        );
        return;
      }

      state = ConversationState.speaking(
        scenario: s.scenario,
        messages: List.unmodifiable(_messages),
        turnCount: _currentTurn,
        responseTimes: updatedTimes,
        cachedAudioPath: null,
      );
    } on AppError catch (e) {
      state = ConversationState.error(
        message: e.userMessage,
        scenario: s.scenario,
        messages: List.unmodifiable(_messages),
        turnCount: _currentTurn,
        responseTimes: updatedTimes,
        cachedAudioPath: null,
      );
    }
  }

  void endConversation() {
    final scenario = switch (state) {
      ConversationSpeaking(:final scenario) => scenario,
      ConversationRecording(:final scenario) => scenario,
      _ => null,
    };
    if (scenario == null) return;
    state = ConversationState.completed(
      scenario: scenario,
      messages: List.unmodifiable(_messages),
      turnCount: _currentTurn,
      responseTimes: [],
    );
  }
}

void main() {
  group('ConversationNotifier (state machine logic)', () {
    late _TestConversationNotifier notifier;

    setUp(() {
      notifier = _TestConversationNotifier();
    });

    test('initial state is idle', () {
      expect(notifier.state, const ConversationState.idle());
    });

    test('startScenario transitions to speaking', () async {
      await notifier.startScenario(_testScenario);
      expect(notifier.state, isA<ConversationSpeaking>());
      final s = notifier.state as ConversationSpeaking;
      expect(s.scenario, _testScenario);
      expect(s.turnCount, 0);
      expect(s.messages.length, 1);
      expect(s.messages.first['content'], _testScenario.firstMessage);
    });

    test('startRecording transitions to recording', () async {
      await notifier.startScenario(_testScenario);
      notifier.startRecording();
      expect(notifier.state, isA<ConversationRecording>());
    });

    test('submitRecording full flow → speaking', () async {
      await notifier.startScenario(_testScenario);
      notifier.startRecording();
      await notifier.submitRecording(Uint8List.fromList([1, 2, 3]));

      expect(notifier.state, isA<ConversationSpeaking>());
      final s = notifier.state as ConversationSpeaking;
      expect(s.turnCount, 1); // 1 user message
      expect(s.messages.length, 3); // first + user + ai
    });

    test('endConversation transitions to completed', () async {
      await notifier.startScenario(_testScenario);
      notifier.endConversation();
      expect(notifier.state, isA<ConversationCompleted>());
      final s = notifier.state as ConversationCompleted;
      expect(s.scenario, _testScenario);
    });

    test('transcribe error transitions to error state', () async {
      notifier = _TestConversationNotifier(shouldFailTranscribe: true);
      await notifier.startScenario(_testScenario);
      notifier.startRecording();
      await notifier.submitRecording(Uint8List.fromList([1, 2, 3]));
      expect(notifier.state, isA<ConversationError>());
    });

    test('completes after max turns (5)', () async {
      await notifier.startScenario(_testScenario);
      for (var i = 0; i < 5; i++) {
        notifier.startRecording();
        await notifier.submitRecording(Uint8List.fromList([1, 2, 3]));
        if (notifier.state is ConversationCompleted) break;
      }
      expect(notifier.state, isA<ConversationCompleted>());
    });
  });
}
