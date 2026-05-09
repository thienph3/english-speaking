import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';

/// Card hiển thị một mục feedback (text đơn).
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  final String icon;
  final String title;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon $title', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          Text(content, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}

/// Card hiển thị danh sách feedback items.
class FeedbackListCard extends StatelessWidget {
  const FeedbackListCard({
    super.key,
    required this.icon,
    required this.title,
    required this.items,
    required this.color,
  });

  final String icon;
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon $title', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('• $item', style: AppTypography.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card hiển thị mức độ sử dụng target phrases.
class PhraseUsageCard extends StatelessWidget {
  const PhraseUsageCard({super.key, required this.usage});

  final Map<String, bool> usage;

  @override
  Widget build(BuildContext context) {
    final usedCount = usage.values.where((v) => v).length;
    final total = usage.length;

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
          Text(
            '🎯 Target phrases ($usedCount/$total)',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: usage.entries.map((e) {
              return Chip(
                label: Text(e.key, style: AppTypography.bodySmall),
                backgroundColor: e.value
                    ? AppColors.correct.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                side: BorderSide(
                  color: e.value ? AppColors.correct : AppColors.missed,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
