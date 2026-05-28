import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/shadowing/logic/sentence_selector.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';

void main() {
  final sentences = [
    _sentence('1', 'easy'),
    _sentence('2', 'easy'),
    _sentence('3', 'medium'),
    _sentence('4', 'medium'),
    _sentence('5', 'hard'),
  ];

  group('SentenceSelector', () {
    test('easy level returns only easy sentences', () {
      final result = SentenceSelector.getAvailableSentences(sentences, 'easy');
      expect(result.map((s) => s.difficulty).toSet(), {'easy'});
      expect(result.length, 2);
    });

    test('easy_medium returns easy and medium', () {
      final result =
          SentenceSelector.getAvailableSentences(sentences, 'easy_medium');
      expect(result.map((s) => s.difficulty).toSet(), {'easy', 'medium'});
      expect(result.length, 4);
    });

    test('medium_hard returns medium and hard', () {
      final result =
          SentenceSelector.getAvailableSentences(sentences, 'medium_hard');
      expect(result.map((s) => s.difficulty).toSet(), {'medium', 'hard'});
      expect(result.length, 3);
    });

    test('unknown level returns all', () {
      final result =
          SentenceSelector.getAvailableSentences(sentences, 'unknown');
      expect(result.length, 5);
    });

    test('empty list returns empty', () {
      final result = SentenceSelector.getAvailableSentences([], 'easy');
      expect(result, isEmpty);
    });
  });
}

Sentence _sentence(String id, String difficulty) => Sentence(
      id: id,
      text: 'test sentence with more than five words here',
      situation: 'test',
      phrases: [],
      targetGrammar: '',
      difficulty: difficulty,
    );
