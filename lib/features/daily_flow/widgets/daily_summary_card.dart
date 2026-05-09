import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/daily_flow/providers/daily_flow_state.dart';

/// Card hiển thị tóm tắt kết quả daily flow.
class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({super.key, required this.state});

  final DailyFlowState state;

  @override
  Widget build(BuildContext context) {
    final avgAccuracy = state.shadowingScores.isEmpty
        ? 0.0
        : state.shadowingScores.reduce((a, b) => a + b) /
            state.shadowingScores.length;
    final responseTimeSec =
        (state.avgResponseTimeMs / 1000).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Kết quả hôm nay', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Câu mới mastered: ${state.newMastered}',
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Accuracy TB: ${avgAccuracy.toStringAsFixed(0)}%',
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Response time: ${responseTimeSec}s',
            style: AppTypography.bodyLarge,
          ),
        ],
      ),
    );
  }
}
