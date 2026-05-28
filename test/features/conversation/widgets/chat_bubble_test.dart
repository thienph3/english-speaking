import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/conversation/widgets/chat_bubble.dart';

void main() {
  group('ChatBubble', () {
    testWidgets('displays text content', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatBubble(text: 'Hello world', isUser: false),
        ),
      ));

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('user bubble aligns right', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatBubble(text: 'Hi', isUser: true),
        ),
      ));

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('AI bubble aligns left', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatBubble(text: 'Hi', isUser: false),
        ),
      ));

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);
    });
  });
}
