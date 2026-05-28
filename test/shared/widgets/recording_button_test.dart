import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/shared/widgets/recording_button.dart';

void main() {
  group('RecordingButton', () {
    testWidgets('has 72x72 size', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecordingButton(
            state: RecordingButtonState.idle,
            onPressed: () {},
          ),
        ),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 72);
      expect(sizedBox.height, 72);
    });

    testWidgets('idle state is tappable', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecordingButton(
            state: RecordingButtonState.idle,
            onPressed: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, true);
    });

    testWidgets('disabled state is not tappable', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecordingButton(
            state: RecordingButtonState.disabled,
            onPressed: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, false);
    });

    testWidgets('shows mic icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecordingButton(
            state: RecordingButtonState.idle,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecordingButton(
            state: RecordingButtonState.recording,
            onPressed: () {},
          ),
        ),
      ));

      expect(
        find.bySemanticsLabel('Đang ghi âm, nhấn để dừng'),
        findsOneWidget,
      );
    });
  });
}
