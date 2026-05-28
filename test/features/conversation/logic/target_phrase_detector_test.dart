import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/conversation/logic/target_phrase_detector.dart';

void main() {
  group('TargetPhraseDetector', () {
    group('detectUsage', () {
      test('detects phrases case-insensitively', () {
        final result = TargetPhraseDetector.detectUsage(
          "I'd like a latte please",
          ["I'd like", "Could I have"],
        );
        expect(result["I'd like"], true);
        expect(result["Could I have"], false);
      });

      test('handles empty transcript', () {
        final result = TargetPhraseDetector.detectUsage('', ["hello"]);
        expect(result["hello"], false);
      });

      test('handles empty phrases list', () {
        final result = TargetPhraseDetector.detectUsage('hello', []);
        expect(result, isEmpty);
      });
    });

    group('usageRate', () {
      test('returns correct ratio', () {
        expect(
          TargetPhraseDetector.usageRate({'a': true, 'b': false}),
          0.5,
        );
      });

      test('all used returns 1.0', () {
        expect(
          TargetPhraseDetector.usageRate({'a': true, 'b': true}),
          1.0,
        );
      });

      test('none used returns 0.0', () {
        expect(
          TargetPhraseDetector.usageRate({'a': false, 'b': false}),
          0.0,
        );
      });

      test('empty map returns 0.0', () {
        expect(TargetPhraseDetector.usageRate({}), 0.0);
      });
    });
  });
}
