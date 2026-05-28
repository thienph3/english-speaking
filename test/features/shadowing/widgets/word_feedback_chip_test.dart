import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';
import 'package:speakeng/features/shadowing/widgets/word_feedback_chip.dart';

void main() {
  group('WordFeedbackChip', () {
    testWidgets('displays word text', (tester) async {
      final word = WordResult(
        word: 'hello',
        accuracyScore: 90,
        phonemes: [],
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: WordFeedbackChip(wordResult: word)),
      ));

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('green word is not tappable', (tester) async {
      var tapped = false;
      final word = WordResult(
        word: 'good',
        accuracyScore: 85,
        phonemes: [],
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WordFeedbackChip(
            wordResult: word,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('good'));
      expect(tapped, false);
    });

    testWidgets('red word is tappable', (tester) async {
      var tapped = false;
      final word = WordResult(
        word: 'think',
        accuracyScore: 30,
        phonemes: [],
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WordFeedbackChip(
            wordResult: word,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('think'));
      expect(tapped, true);
    });

    testWidgets('yellow word is tappable', (tester) async {
      var tapped = false;
      final word = WordResult(
        word: 'world',
        accuracyScore: 60,
        phonemes: [],
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WordFeedbackChip(
            wordResult: word,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('world'));
      expect(tapped, true);
    });
  });
}
