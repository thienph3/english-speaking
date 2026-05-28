import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/placement/providers/placement_provider.dart';
import 'package:speakeng/shared/services/content_service.dart';
import 'package:speakeng/shared/widgets/recording_button.dart';

/// Card hiển thị câu placement test với difficulty badge và score.
class PlacementSentenceCard extends StatelessWidget {
  const PlacementSentenceCard({
    super.key,
    required this.sentence,
    required this.status,
    this.score,
  });

  final PlacementSentence sentence;
  final PlacementStatus status;
  final double? score;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _buildDifficultyBadge(),
            const SizedBox(height: AppSpacing.md),
            Text(
              sentence.text,
              style: AppTypography.sentence,
              textAlign: TextAlign.center,
            ),
            if (status == PlacementStatus.showingScore && score != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildScore(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    final color = switch (sentence.difficulty) {
      'easy' => AppColors.correct,
      'medium' => AppColors.needsWork,
      'hard' => AppColors.wrong,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        sentence.difficulty.toUpperCase(),
        style: AppTypography.label.copyWith(color: color),
      ),
    );
  }

  Widget _buildScore() {
    final color = score! >= 80
        ? AppColors.correct
        : score! >= 50
            ? AppColors.needsWork
            : AppColors.wrong;
    return Text(
      '${score!.toStringAsFixed(0)}%',
      style: AppTypography.h1.copyWith(color: color),
    );
  }
}

/// Action area cho placement: record button hoặc "Tiếp tục" button.
class PlacementActionArea extends StatelessWidget {
  const PlacementActionArea({
    super.key,
    required this.status,
    required this.onRecord,
    required this.onNext,
  });

  final PlacementStatus status;
  final VoidCallback onRecord;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (status == PlacementStatus.showingScore) {
      return ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
        child: const Text('Tiếp tục', style: AppTypography.button),
      );
    }
    if (status == PlacementStatus.processing) {
      return const CircularProgressIndicator();
    }
    return Column(
      children: [
        Text(
          'Đọc to câu trên',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        RecordingButton(
          state: status == PlacementStatus.recording
              ? RecordingButtonState.recording
              : RecordingButtonState.idle,
          onPressed: onRecord,
        ),
      ],
    );
  }
}
