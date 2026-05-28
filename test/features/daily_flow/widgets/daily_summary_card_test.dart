import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/daily_flow/providers/daily_flow_state.dart';
import 'package:speakeng/features/daily_flow/widgets/daily_summary_card.dart';

void main() {
  group('DailySummaryCard', () {
    testWidgets('displays mastered count', (tester) async {
      const state = DailyFlowState(
        shadowingCompleted: 3,
        conversationCompleted: true,
        shadowingScores: [80, 90, 85],
        avgResponseTimeMs: 2500,
        newMastered: 2,
      );
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: DailySummaryCard(state: state)),
      ));

      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('displays average accuracy', (tester) async {
      const state = DailyFlowState(
        shadowingScores: [80, 90, 100],
        newMastered: 0,
        avgResponseTimeMs: 0,
      );
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: DailySummaryCard(state: state)),
      ));

      // avg = 90%
      expect(find.textContaining('90%'), findsOneWidget);
    });

    testWidgets('displays response time in seconds', (tester) async {
      const state = DailyFlowState(
        shadowingScores: [80],
        avgResponseTimeMs: 3100,
        newMastered: 0,
      );
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: DailySummaryCard(state: state)),
      ));

      expect(find.textContaining('3.1s'), findsOneWidget);
    });

    testWidgets('shows title', (tester) async {
      const state = DailyFlowState(shadowingScores: []);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: DailySummaryCard(state: state)),
      ));

      expect(find.textContaining('Kết quả hôm nay'), findsOneWidget);
    });
  });
}
