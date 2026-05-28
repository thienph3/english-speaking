import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeng/features/daily_flow/providers/daily_flow_provider.dart';
import 'package:speakeng/features/daily_flow/providers/daily_flow_state.dart';

void main() {
  group('DailyFlowNotifier', () {
    late DailyFlowNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifier = DailyFlowNotifier();
    });

    test('initial state is shadowing step 0', () {
      expect(notifier.state.currentStep, DailyFlowStep.shadowing);
      expect(notifier.state.shadowingCompleted, 0);
    });

    test('completeShadowing increments count', () {
      notifier.completeShadowing(accuracy: 85);
      expect(notifier.state.shadowingCompleted, 1);
      expect(notifier.state.shadowingScores, [85]);
    });

    test('completeShadowing tracks mastered', () {
      notifier.completeShadowing(accuracy: 90, mastered: true);
      expect(notifier.state.newMastered, 1);
    });

    test('after 3 shadowing transitions to conversation', () {
      notifier.completeShadowing(accuracy: 80);
      notifier.completeShadowing(accuracy: 85);
      notifier.completeShadowing(accuracy: 90);
      expect(notifier.state.currentStep, DailyFlowStep.conversation);
      expect(notifier.state.shadowingCompleted, 3);
    });

    test('completeConversation transitions to summary', () {
      notifier.completeShadowing(accuracy: 80);
      notifier.completeShadowing(accuracy: 80);
      notifier.completeShadowing(accuracy: 80);
      notifier.completeConversation(avgResponseTimeMs: 2500);
      expect(notifier.state.currentStep, DailyFlowStep.summary);
      expect(notifier.state.conversationCompleted, true);
      expect(notifier.state.avgResponseTimeMs, 2500);
      expect(notifier.state.isComplete, true);
    });

    test('reset clears all state', () {
      notifier.completeShadowing(accuracy: 80);
      notifier.reset();
      expect(notifier.state.shadowingCompleted, 0);
      expect(notifier.state.currentStep, DailyFlowStep.shadowing);
    });
  });
}
