import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeng/features/daily_flow/providers/daily_flow_provider.dart';
import 'package:speakeng/features/daily_flow/providers/daily_flow_state.dart';
import 'package:speakeng/features/daily_flow/screens/daily_flow_screen.dart';
import 'package:speakeng/shared/services/prefs_service.dart';

void main() {
  group('DailyFlowScreen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PrefsService.initialize();
    });

    Widget buildApp({DailyFlowState? initialState}) {
      return ProviderScope(
        overrides: [
          if (initialState != null)
            dailyFlowProvider.overrideWith(
              (ref) => DailyFlowNotifier()
                ..completeShadowing(accuracy: 0) // dummy to trigger override
            ),
        ],
        child: const MaterialApp(home: DailyFlowScreen()),
      );
    }

    testWidgets('shows greeting text', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Should show one of the greetings
      final hasGreeting = find.textContaining('Chào').evaluate().isNotEmpty;
      expect(hasGreeting, true);
    });

    testWidgets('shows shadowing progress', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.textContaining('Shadowing'), findsOneWidget);
    });

    testWidgets('shows conversation progress', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.textContaining('Hội thoại'), findsOneWidget);
    });

    testWidgets('shows CTA button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('CTA shows "Bắt đầu luyện" initially', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Bắt đầu luyện'), findsOneWidget);
    });
  });
}
