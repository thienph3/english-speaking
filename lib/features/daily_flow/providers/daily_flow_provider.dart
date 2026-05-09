import 'package:flutter_riverpod/legacy.dart';

import 'package:speakeng/features/daily_flow/providers/daily_flow_state.dart';

/// Provider cho DailyFlowNotifier.
final dailyFlowProvider =
    StateNotifierProvider<DailyFlowNotifier, DailyFlowState>((ref) {
  return DailyFlowNotifier();
});

/// StateNotifier quản lý daily flow state machine.
///
/// Orchestrate: 3 shadowing → 1 conversation → summary.
/// Mỗi bước hoàn thành sẽ tự động chuyển sang bước tiếp theo.
class DailyFlowNotifier extends StateNotifier<DailyFlowState> {
  DailyFlowNotifier() : super(const DailyFlowState());

  /// Reset daily flow về trạng thái ban đầu.
  void reset() {
    state = const DailyFlowState();
  }

  /// Ghi nhận hoàn thành 1 câu shadowing.
  ///
  /// [accuracy] — điểm accuracy của câu vừa luyện.
  /// [mastered] — câu này có mới mastered không.
  void completeShadowing({
    required double accuracy,
    bool mastered = false,
  }) {
    final newScores = [...state.shadowingScores, accuracy];
    final newMastered = mastered ? state.newMastered + 1 : state.newMastered;
    final newCount = state.shadowingCompleted + 1;

    state = state.copyWith(
      shadowingCompleted: newCount,
      shadowingScores: newScores,
      newMastered: newMastered,
      currentStep: newCount >= 3
          ? DailyFlowStep.conversation
          : DailyFlowStep.shadowing,
    );
  }

  /// Ghi nhận hoàn thành hội thoại.
  ///
  /// [avgResponseTimeMs] — response time TB từ conversation.
  void completeConversation({required int avgResponseTimeMs}) {
    state = state.copyWith(
      conversationCompleted: true,
      avgResponseTimeMs: avgResponseTimeMs,
      currentStep: DailyFlowStep.summary,
    );
  }
}
