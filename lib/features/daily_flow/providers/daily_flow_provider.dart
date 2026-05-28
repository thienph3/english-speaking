import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';

import 'package:speakeng/features/daily_flow/providers/daily_flow_state.dart';
import 'package:speakeng/shared/services/prefs_service.dart';

const _key = 'daily_flow_state';
const _dateKey = 'daily_flow_date';

/// Provider cho DailyFlowNotifier.
final dailyFlowProvider =
    StateNotifierProvider<DailyFlowNotifier, DailyFlowState>((ref) {
  return DailyFlowNotifier()..restore();
});

/// StateNotifier quản lý daily flow state machine.
///
/// Orchestrate: 3 shadowing → 1 conversation → summary.
/// Persist vào SharedPreferences, reset mỗi ngày mới.
class DailyFlowNotifier extends StateNotifier<DailyFlowState> {
  DailyFlowNotifier() : super(const DailyFlowState());

  /// Khôi phục state từ SharedPreferences.
  /// Reset nếu ngày đã thay đổi.
  Future<void> restore() async {
    final prefs = PrefsService.instance;
    final savedDate = prefs.getString(_dateKey);
    final today = _todayString();

    if (savedDate != today) {
      // Ngày mới → reset
      await prefs.remove(_key);
      await prefs.setString(_dateKey, today);
      return;
    }

    final json = prefs.getString(_key);
    if (json == null) return;

    final map = jsonDecode(json) as Map<String, dynamic>;
    state = DailyFlowState(
      shadowingCompleted: map['sc'] as int? ?? 0,
      conversationCompleted: map['cc'] as bool? ?? false,
      shadowingScores: (map['ss'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      avgResponseTimeMs: map['rt'] as int? ?? 0,
      newMastered: map['nm'] as int? ?? 0,
      currentStep: DailyFlowStep.values[map['step'] as int? ?? 0],
    );
  }

  /// Reset daily flow về trạng thái ban đầu.
  void reset() {
    state = const DailyFlowState();
    _persist();
  }

  /// Ghi nhận hoàn thành 1 câu shadowing.
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
    _persist();
  }

  /// Ghi nhận hoàn thành hội thoại.
  void completeConversation({required int avgResponseTimeMs}) {
    state = state.copyWith(
      conversationCompleted: true,
      avgResponseTimeMs: avgResponseTimeMs,
      currentStep: DailyFlowStep.summary,
    );
    _persist();
  }

  Future<void> _persist() async {
    final prefs = PrefsService.instance;
    await prefs.setString(_dateKey, _todayString());
    await prefs.setString(_key, jsonEncode({
      'sc': state.shadowingCompleted,
      'cc': state.conversationCompleted,
      'ss': state.shadowingScores,
      'rt': state.avgResponseTimeMs,
      'nm': state.newMastered,
      'step': state.currentStep.index,
    }));
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
