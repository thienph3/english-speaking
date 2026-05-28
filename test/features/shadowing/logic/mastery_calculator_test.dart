import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/progress/models/sentence_progress.dart';
import 'package:speakeng/features/shadowing/logic/mastery_calculator.dart';

void main() {
  group('MasteryCalculator', () {
    final base = SentenceProgress(
      userId: 'u1',
      sentenceId: 's1',
      correctStreak: 0,
      bestAccuracy: 0,
    );

    group('updateProgress', () {
      test('accuracy >= 80 increments streak', () {
        final result = MasteryCalculator.updateProgress(base, 85);
        expect(result.correctStreak, 1);
      });

      test('accuracy < 80 resets streak to 0', () {
        final withStreak = base.copyWith(correctStreak: 2);
        final result = MasteryCalculator.updateProgress(withStreak, 70);
        expect(result.correctStreak, 0);
      });

      test('updates bestAccuracy when new score is higher', () {
        final result = MasteryCalculator.updateProgress(base, 90);
        expect(result.bestAccuracy, 90);
      });

      test('keeps bestAccuracy when new score is lower', () {
        final withBest = base.copyWith(bestAccuracy: 95);
        final result = MasteryCalculator.updateProgress(withBest, 80);
        expect(result.bestAccuracy, 95);
      });

      test('exactly 80 increments streak', () {
        final result = MasteryCalculator.updateProgress(base, 80);
        expect(result.correctStreak, 1);
      });
    });

    group('isMastered', () {
      test('streak >= 3 is mastered', () {
        final mastered = base.copyWith(correctStreak: 3);
        expect(MasteryCalculator.isMastered(mastered), true);
      });

      test('streak < 3 is not mastered', () {
        final notMastered = base.copyWith(correctStreak: 2);
        expect(MasteryCalculator.isMastered(notMastered), false);
      });
    });
  });
}
