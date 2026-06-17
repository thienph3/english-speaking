import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';
import 'package:speakeng/features/shadowing/providers/shadowing_state.dart';

/// Minimal notifier that replicates ShadowingNotifier logic
/// without real dependencies (AudioService, ShadowingRepository).
class _TestShadowingNotifier {
  _TestShadowingNotifier(this._pronounceFn);

  final Future<PronunciationResult> Function(String, String) _pronounceFn;
  ShadowingState state = const ShadowingState.initial();

  void loadSentence(Sentence sentence) {
    state = ShadowingState.loaded(sentence);
  }

  void startRecording() {
    final sentence = _currentSentence;
    if (sentence == null) return;
    state = ShadowingState.recording(sentence);
  }

  Future<void> stopAndSubmit(String audioPath) async {
    final sentence = _currentSentence;
    if (sentence == null) return;
    state = ShadowingState.processing(sentence);
    try {
      final result = await _pronounceFn(audioPath, sentence.text);
      state = ShadowingState.result(sentence, result);
    } on AppError catch (error) {
      state = ShadowingState.error(error);
    }
  }

  void retry() {
    final sentence = _currentSentence;
    if (sentence == null) {
      state = const ShadowingState.initial();
      return;
    }
    state = ShadowingState.loaded(sentence);
  }

  Sentence? get _currentSentence {
    return switch (state) {
      ShadowingLoaded(:final sentence) => sentence,
      ShadowingPlaying(:final sentence) => sentence,
      ShadowingRecording(:final sentence) => sentence,
      ShadowingProcessing(:final sentence) => sentence,
      ShadowingResult(:final sentence) => sentence,
      _ => null,
    };
  }
}

final _testSentence = Sentence(
  id: 'test_001',
  text: "I'd like a latte, please.",
  situation: 'ordering_food',
  phrases: ["I'd like", "a latte", "please"],
  targetGrammar: 'would like + noun',
  difficulty: 'easy',
  audioAssetPath: 'assets/voices/test_001.mp3',
);

final _testResult = PronunciationResult(
  accuracyScore: 85,
  fluencyScore: 90,
  completenessScore: 100,
  words: [
    WordResult(word: 'I', accuracyScore: 95, phonemes: []),
    WordResult(word: 'like', accuracyScore: 80, phonemes: []),
  ],
);

void main() {
  group('ShadowingNotifier (state machine logic)', () {
    late _TestShadowingNotifier notifier;

    setUp(() {
      notifier = _TestShadowingNotifier(
        (path, text) async => _testResult,
      );
    });

    test('initial state is ShadowingState.initial', () {
      expect(notifier.state, const ShadowingState.initial());
    });

    test('loadSentence transitions to loaded', () {
      notifier.loadSentence(_testSentence);
      expect(notifier.state, ShadowingState.loaded(_testSentence));
    });

    test('startRecording transitions to recording', () {
      notifier.loadSentence(_testSentence);
      notifier.startRecording();
      expect(notifier.state, ShadowingState.recording(_testSentence));
    });

    test('startRecording does nothing from initial', () {
      notifier.startRecording();
      expect(notifier.state, const ShadowingState.initial());
    });

    test('stopAndSubmit transitions processing → result on success', () async {
      notifier.loadSentence(_testSentence);
      notifier.startRecording();
      await notifier.stopAndSubmit('/tmp/test.wav');
      expect(notifier.state, ShadowingState.result(_testSentence, _testResult));
    });

    test('stopAndSubmit transitions processing → error on failure', () async {
      notifier = _TestShadowingNotifier(
        (path, text) async => throw const ApiTimeoutError(),
      );
      notifier.loadSentence(_testSentence);
      notifier.startRecording();
      await notifier.stopAndSubmit('/tmp/test.wav');
      expect(notifier.state, isA<ShadowingError>());
    });

    test('retry from result transitions back to loaded', () async {
      notifier.loadSentence(_testSentence);
      notifier.startRecording();
      await notifier.stopAndSubmit('/tmp/test.wav');
      notifier.retry();
      expect(notifier.state, ShadowingState.loaded(_testSentence));
    });

    test('retry from initial stays initial', () {
      notifier.retry();
      expect(notifier.state, const ShadowingState.initial());
    });
  });
}
