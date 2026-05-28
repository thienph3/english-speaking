import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';

void main() {
  group('PronunciationResult', () {
    test('fromJson parses full result', () {
      final json = {
        'accuracyScore': 85.5,
        'fluencyScore': 90.0,
        'completenessScore': 100.0,
        'words': [
          {
            'word': 'hello',
            'accuracyScore': 95.0,
            'errorType': null,
            'phonemes': [
              {'phoneme': 'h', 'accuracyScore': 100.0},
              {'phoneme': 'ɛ', 'accuracyScore': 90.0},
            ],
          },
          {
            'word': 'world',
            'accuracyScore': 60.0,
            'errorType': 'Mispronunciation',
            'phonemes': [
              {'phoneme': 'w', 'accuracyScore': 80.0},
              {'phoneme': 'ɜː', 'accuracyScore': 40.0},
            ],
          },
        ],
      };

      final result = PronunciationResult.fromJson(json);
      expect(result.accuracyScore, 85.5);
      expect(result.fluencyScore, 90.0);
      expect(result.completenessScore, 100.0);
      expect(result.words.length, 2);
      expect(result.words[0].word, 'hello');
      expect(result.words[0].phonemes.length, 2);
      expect(result.words[1].errorType, 'Mispronunciation');
    });

    test('WordResult fromJson with no error', () {
      final json = {
        'word': 'test',
        'accuracyScore': 88.0,
        'phonemes': <Map<String, dynamic>>[],
      };
      final w = WordResult.fromJson(json);
      expect(w.word, 'test');
      expect(w.accuracyScore, 88.0);
      expect(w.errorType, isNull);
      expect(w.phonemes, isEmpty);
    });

    test('PhonemeResult fromJson', () {
      final json = {'phoneme': 'θ', 'accuracyScore': 45.0};
      final p = PhonemeResult.fromJson(json);
      expect(p.phoneme, 'θ');
      expect(p.accuracyScore, 45.0);
    });
  });
}
