import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/placement/providers/placement_provider.dart';
import 'package:speakeng/features/placement/widgets/placement_widgets.dart';
import 'package:speakeng/shared/services/content_service.dart';

void main() {
  group('PlacementSentenceCard', () {
    const sentence = PlacementSentence(
      id: '1',
      text: 'Hello world',
      difficulty: 'easy',
    );

    testWidgets('displays sentence text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PlacementSentenceCard(
            sentence: sentence,
            status: PlacementStatus.ready,
          ),
        ),
      ));

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('displays difficulty badge', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PlacementSentenceCard(
            sentence: sentence,
            status: PlacementStatus.ready,
          ),
        ),
      ));

      expect(find.text('EASY'), findsOneWidget);
    });

    testWidgets('shows score when status is showingScore', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PlacementSentenceCard(
            sentence: sentence,
            status: PlacementStatus.showingScore,
            score: 85,
          ),
        ),
      ));

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('hides score when status is ready', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PlacementSentenceCard(
            sentence: sentence,
            status: PlacementStatus.ready,
            score: 85,
          ),
        ),
      ));

      expect(find.text('85%'), findsNothing);
    });
  });

  group('PlacementActionArea', () {
    testWidgets('shows record button when ready', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PlacementActionArea(
            status: PlacementStatus.ready,
            onRecord: () {},
            onNext: () {},
          ),
        ),
      ));

      expect(find.text('Đọc to câu trên'), findsOneWidget);
    });

    testWidgets('shows continue button when showingScore', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PlacementActionArea(
            status: PlacementStatus.showingScore,
            onRecord: () {},
            onNext: () {},
          ),
        ),
      ));

      expect(find.text('Tiếp tục'), findsOneWidget);
    });

    testWidgets('shows spinner when processing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PlacementActionArea(
            status: PlacementStatus.processing,
            onRecord: () {},
            onNext: () {},
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
