import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/daily_flow/providers/daily_flow_state.dart';

void main() {
  group('DailyFlowState', () {
    test('initial state has correct defaults', () {
      const state = DailyFlowState();
      expect(state.currentStep, DailyFlowStep.shadowing);
      expect(state.shadowingCompleted, 0);
      expect(state.conversationCompleted, false);
      expect(state.isComplete, false);
    });

    group('nextStep', () {
      test('returns shadowing when < 3 completed', () {
        const state = DailyFlowState(shadowingCompleted: 2);
        expect(state.nextStep, DailyFlowStep.shadowing);
      });

      test('returns conversation when 3 shadowing done', () {
        const state = DailyFlowState(shadowingCompleted: 3);
        expect(state.nextStep, DailyFlowStep.conversation);
      });

      test('returns summary when all done', () {
        const state = DailyFlowState(
          shadowingCompleted: 3,
          conversationCompleted: true,
        );
        expect(state.nextStep, DailyFlowStep.summary);
      });
    });

    group('isComplete', () {
      test('false when shadowing not done', () {
        const state = DailyFlowState(
          shadowingCompleted: 2,
          conversationCompleted: true,
        );
        expect(state.isComplete, false);
      });

      test('false when conversation not done', () {
        const state = DailyFlowState(shadowingCompleted: 3);
        expect(state.isComplete, false);
      });

      test('true when both done', () {
        const state = DailyFlowState(
          shadowingCompleted: 3,
          conversationCompleted: true,
        );
        expect(state.isComplete, true);
      });
    });
  });
}
