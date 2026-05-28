import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/shadowing/logic/phrase_splitter.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';

void main() {
  group('PhraseSplitter', () {
    test('uses sentence.phrases when available', () {
      final s = Sentence(
        id: '1',
        text: "I'd like a latte please",
        situation: 'test',
        phrases: ["I'd like", "a latte", "please"],
        targetGrammar: '',
        difficulty: 'easy',
      );
      expect(PhraseSplitter.split(s), ["I'd like", "a latte", "please"]);
    });

    test('chunks by 3 words when no phrases', () {
      final s = Sentence(
        id: '2',
        text: 'one two three four five six seven',
        situation: 'test',
        phrases: [],
        targetGrammar: '',
        difficulty: 'easy',
      );
      expect(PhraseSplitter.split(s), [
        'one two three',
        'four five six',
        'seven',
      ]);
    });

    test('supportsPhrasePractice true when > 5 words', () {
      final s = Sentence(
        id: '3',
        text: 'one two three four five six',
        situation: 'test',
        phrases: [],
        targetGrammar: '',
        difficulty: 'easy',
      );
      expect(PhraseSplitter.supportsPhrasePractice(s), true);
    });

    test('supportsPhrasePractice false when <= 5 words', () {
      final s = Sentence(
        id: '4',
        text: 'one two three four five',
        situation: 'test',
        phrases: [],
        targetGrammar: '',
        difficulty: 'easy',
      );
      expect(PhraseSplitter.supportsPhrasePractice(s), false);
    });
  });
}
