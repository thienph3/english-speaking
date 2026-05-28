import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/daily_flow/providers/daily_flow_provider.dart';
import 'package:speakeng/features/daily_flow/providers/daily_flow_state.dart';
import 'package:speakeng/features/daily_flow/providers/daily_sentences_provider.dart';
import 'package:speakeng/features/daily_flow/widgets/daily_summary_card.dart';

/// Màn hình chính Daily Flow.
///
/// Hiển thị greeting, progress steps, quick stats,
/// và nút CTA để bắt đầu luyện tập.
class DailyFlowScreen extends ConsumerWidget {
  const DailyFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyFlowProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: const Text('SpeakEng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => context.push('/progress'),
            tooltip: 'Tiến bộ',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _buildGreeting(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildProgressSteps(state),
                      const SizedBox(height: AppSpacing.lg),
                      if (state.isComplete) DailySummaryCard(state: state),
                    ],
                  ),
                ),
              ),
              _buildCta(context, state, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Chào buổi sáng! 👋'
        : hour < 18
            ? 'Chào buổi chiều! 👋'
            : 'Chào buổi tối! 👋';

    return Text(greeting, style: AppTypography.h1);
  }

  Widget _buildProgressSteps(DailyFlowState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hôm nay:', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        _StepRow(
          label: 'Shadowing (${state.shadowingCompleted}/3)',
          isActive: state.currentStep == DailyFlowStep.shadowing,
          isCompleted: state.shadowingCompleted >= 3,
        ),
        const SizedBox(height: AppSpacing.sm),
        _StepRow(
          label: 'Hội thoại (${state.conversationCompleted ? 1 : 0}/1)',
          isActive: state.currentStep == DailyFlowStep.conversation,
          isCompleted: state.conversationCompleted,
        ),
        const SizedBox(height: AppSpacing.sm),
        _StepRow(
          label: 'Tóm tắt',
          isActive: state.currentStep == DailyFlowStep.summary,
          isCompleted: state.isComplete,
        ),
      ],
    );
  }

  Widget _buildCta(BuildContext context, DailyFlowState state, WidgetRef ref) {
    final label = _getCtaLabel(state);
    final enabled = !state.isComplete;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? () => _handleCta(context, state, ref) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            disabledBackgroundColor: AppColors.surfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
          ),
          child: Text(label, style: AppTypography.button),
        ),
      ),
    );
  }

  String _getCtaLabel(DailyFlowState state) {
    if (state.isComplete) return 'Hoàn thành! 🎉';
    if (state.nextStep == DailyFlowStep.conversation) {
      return 'Bắt đầu hội thoại';
    }
    if (state.shadowingCompleted == 0) return 'Bắt đầu luyện';
    return 'Luyện câu ${state.shadowingCompleted + 1}/3';
  }

  void _handleCta(BuildContext context, DailyFlowState state, WidgetRef ref) {
    switch (state.nextStep) {
      case DailyFlowStep.shadowing:
        final sentences = ref.read(dailySentencesProvider).value ?? [];
        if (sentences.isEmpty) return;
        final idx = state.shadowingCompleted.clamp(0, sentences.length - 1);
        context.push('/shadowing/${sentences[idx].id}');
      case DailyFlowStep.conversation:
        context.push('/conversation/daily');
      case DailyFlowStep.summary:
        break;
    }
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  final String label;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final icon = isCompleted
        ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
        : isActive
            ? const Icon(
                Icons.radio_button_on, color: AppColors.primary, size: 20)
            : const Icon(
                Icons.radio_button_off, color: AppColors.missed, size: 20);

    final textStyle = isActive
        ? AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)
        : AppTypography.bodyLarge;

    return Row(
      children: [
        icon,
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: textStyle),
      ],
    );
  }
}
