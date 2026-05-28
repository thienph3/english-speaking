import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/progress/models/sentence_progress.dart';
import 'package:speakeng/features/progress/repositories/progress_repository.dart';

/// Provider loads all sentence progress for the current user.
final allSentenceProgressProvider =
    FutureProvider<List<SentenceProgress>>((ref) {
  return ref.read(progressRepositoryProvider).getAllProgress();
});

/// Card hiển thị danh sách câu đã luyện tập với accuracy.
class SentenceListCard extends ConsumerWidget {
  const SentenceListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProgress = ref.watch(allSentenceProgressProvider);

    return asyncProgress.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📋 Câu đã luyện', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: AppSpacing.md),
                itemBuilder: (_, i) => _buildItem(items[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(SentenceProgress item) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(item.sentenceId, style: AppTypography.bodyMedium),
          ),
          Text(
            '${item.bestAccuracy.toStringAsFixed(0)}%',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (item.isMastered)
            const Icon(Icons.check_circle, color: AppColors.success, size: 20)
          else
            const SizedBox(width: 20),
        ],
      ),
    );
  }
}
