import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_flow_state.freezed.dart';

/// Các bước trong daily flow.
enum DailyFlowStep { shadowing, conversation, summary }

/// Trạng thái của daily flow state machine.
///
/// Quản lý tiến trình: 3 shadowing → 1 conversation → summary.
@freezed
sealed class DailyFlowState with _$DailyFlowState {
  const DailyFlowState._();

  const factory DailyFlowState({
    /// Bước hiện tại trong daily flow.
    @Default(DailyFlowStep.shadowing) DailyFlowStep currentStep,

    /// Số câu shadowing đã hoàn thành (0–3).
    @Default(0) int shadowingCompleted,

    /// Hội thoại đã hoàn thành chưa.
    @Default(false) bool conversationCompleted,

    /// Danh sách accuracy scores từ shadowing.
    @Default([]) List<double> shadowingScores,

    /// Response time trung bình từ conversation (ms).
    @Default(0) int avgResponseTimeMs,

    /// Số câu mới mastered trong session này.
    @Default(0) int newMastered,
  }) = _DailyFlowState;

  /// Bước tiếp theo dựa trên trạng thái hiện tại.
  DailyFlowStep get nextStep {
    if (shadowingCompleted < 3) return DailyFlowStep.shadowing;
    if (!conversationCompleted) return DailyFlowStep.conversation;
    return DailyFlowStep.summary;
  }

  /// Daily flow đã hoàn thành chưa.
  bool get isComplete =>
      shadowingCompleted >= 3 && conversationCompleted;
}
