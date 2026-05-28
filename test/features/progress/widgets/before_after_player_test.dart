import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/progress/widgets/before_after_player.dart';

void main() {
  group('BeforeAfterPlayer', () {
    testWidgets('shows Before and After labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BeforeAfterPlayer()),
      ));

      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
    });

    testWidgets('before button calls onPlayBefore when url available',
        (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BeforeAfterPlayer(
            beforeUrl: 'http://example.com/before.wav',
            onPlayBefore: () => called = true,
          ),
        ),
      ));

      await tester.tap(find.text('Before'));
      expect(called, true);
    });

    testWidgets('before button disabled when no url', (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BeforeAfterPlayer(
            onPlayBefore: () => called = true,
          ),
        ),
      ));

      await tester.tap(find.text('Before'));
      expect(called, false);
    });

    testWidgets('shows pause icon when currently playing', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: BeforeAfterPlayer(
            beforeUrl: 'http://x.com/a.wav',
            currentlyPlaying: 'before',
          ),
        ),
      ));

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });
  });
}
