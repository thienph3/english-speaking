import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/shared/widgets/speed_selector.dart';

void main() {
  group('SpeedSelector', () {
    testWidgets('displays all speed options', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpeedSelector(
            currentSpeed: 1.0,
            onChanged: (_) {},
          ),
        ),
      ));

      expect(find.text('0.7x'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.text('1.2x'), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      double? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpeedSelector(
            currentSpeed: 1.0,
            onChanged: (v) => selected = v,
          ),
        ),
      ));

      await tester.tap(find.text('0.7x'));
      await tester.pumpAndSettle();
      expect(selected, 0.7);
    });
  });
}
