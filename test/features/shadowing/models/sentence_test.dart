import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';

void main() {
  group('Sentence', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'ordering_food_001',
        'text': "I'd like a latte, please.",
        'situation': 'ordering_food',
        'phrases': ["I'd like", "a latte", "please"],
        'target_grammar': 'would like + noun',
        'difficulty': 'easy',
        'audio_asset_path': 'assets/voices/ordering_food_001.mp3',
      };
      final s = Sentence.fromJson(json);
      expect(s.id, 'ordering_food_001');
      expect(s.text, "I'd like a latte, please.");
      expect(s.situation, 'ordering_food');
      expect(s.phrases, ["I'd like", "a latte", "please"]);
      expect(s.targetGrammar, 'would like + noun');
      expect(s.difficulty, 'easy');
      expect(s.audioAssetPath, 'assets/voices/ordering_food_001.mp3');
    });

    test('fromJson handles null audioAssetPath', () {
      final json = {
        'id': '1',
        'text': 'Hello world',
        'situation': 'test',
        'phrases': <String>[],
        'target_grammar': '',
        'difficulty': 'easy',
      };
      final s = Sentence.fromJson(json);
      expect(s.audioAssetPath, isNull);
    });

    test('supportsPhrasePractice true when > 5 words', () {
      final s = Sentence(
        id: '1',
        text: 'one two three four five six',
        situation: 'test',
        phrases: [],
        targetGrammar: '',
        difficulty: 'easy',
      );
      expect(s.supportsPhrasePractice, true);
    });

    test('supportsPhrasePractice false when <= 5 words', () {
      final s = Sentence(
        id: '1',
        text: 'one two three',
        situation: 'test',
        phrases: [],
        targetGrammar: '',
        difficulty: 'easy',
      );
      expect(s.supportsPhrasePractice, false);
    });

    test('toJson roundtrip', () {
      final s = Sentence(
        id: 'x',
        text: 'Hello',
        situation: 'greet',
        phrases: ['Hello'],
        targetGrammar: 'greeting',
        difficulty: 'easy',
      );
      final json = s.toJson();
      final s2 = Sentence.fromJson(json);
      expect(s2, s);
    });
  });
}
