import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/shared/widgets/score_card.dart';

void main() {
  group('ScoreCard', () {
    testWidgets('displays all three metrics', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ScoreCard(accuracy: 85, fluency: 70, completeness: 100),
        ),
      ));

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('Fluency'), findsOneWidget);
      expect(find.text('Completeness'), findsOneWidget);
    });

    testWidgets('rounds decimal values', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ScoreCard(accuracy: 85.7, fluency: 70.2, completeness: 99.9),
        ),
      ));

      expect(find.text('86%'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
