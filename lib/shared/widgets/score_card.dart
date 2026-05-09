import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';

/// Hiển thị 3 metrics phát âm (accuracy, fluency, completeness)
/// dưới dạng Row với label + giá trị phần trăm.
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.accuracy,
    required this.fluency,
    required this.completeness,
  });

  final double accuracy;
  final double fluency;
  final double completeness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ScoreItem(label: 'Accuracy', value: accuracy),
          _ScoreItem(label: 'Fluency', value: fluency),
          _ScoreItem(label: 'Completeness', value: completeness),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  const _ScoreItem({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${value.round()}%',
          style: AppTypography.h2.copyWith(color: _scoreColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color get _scoreColor {
    if (value >= 80) return AppColors.correct;
    if (value >= 50) return AppColors.needsWork;
    return AppColors.wrong;
  }
}
