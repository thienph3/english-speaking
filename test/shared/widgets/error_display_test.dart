import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/shared/widgets/error_display.dart';

void main() {
  group('ErrorDisplay', () {
    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ErrorDisplay(message: 'Something went wrong')),
      ));

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorDisplay(message: 'Error', onRetry: () {}),
        ),
      ));

      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ErrorDisplay(message: 'Error')),
      ));

      expect(find.text('Thử lại'), findsNothing);
    });

    testWidgets('retry button calls onRetry', (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorDisplay(message: 'Error', onRetry: () => called = true),
        ),
      ));

      await tester.tap(find.text('Thử lại'));
      expect(called, true);
    });

    testWidgets('shows error icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ErrorDisplay(message: 'Error')),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
