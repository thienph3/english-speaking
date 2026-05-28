import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/progress/models/sentence_progress.dart';

void main() {
  group('SentenceProgress', () {
    test('isMastered true when streak >= 3', () {
      final p = SentenceProgress(
        userId: 'u1',
        sentenceId: 's1',
        correctStreak: 3,
      );
      expect(p.isMastered, true);
    });

    test('isMastered false when streak < 3', () {
      final p = SentenceProgress(
        userId: 'u1',
        sentenceId: 's1',
        correctStreak: 2,
      );
      expect(p.isMastered, false);
    });

    test('copyWith preserves other fields', () {
      final p = SentenceProgress(
        userId: 'u1',
        sentenceId: 's1',
        correctStreak: 2,
        bestAccuracy: 85,
      );
      final updated = p.copyWith(correctStreak: 3);
      expect(updated.correctStreak, 3);
      expect(updated.bestAccuracy, 85);
      expect(updated.userId, 'u1');
    });
  });
}
