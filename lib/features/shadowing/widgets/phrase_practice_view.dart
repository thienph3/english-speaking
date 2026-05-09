import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';

/// Hiển thị tiến trình luyện phrase-by-phrase.
///
/// Hiển thị phrase hiện tại đang luyện, progress indicator,
/// và chuyển sang luyện toàn câu khi hoàn thành tất cả phrases.
class PhrasePracticeView extends StatelessWidget {
  const PhrasePracticeView({
    super.key,
    required this.phrases,
    required this.currentIndex,
    required this.fullSentence,
    required this.isFullSentenceMode,
  });

  final List<String> phrases;
  final int currentIndex;
  final String fullSentence;
  final bool isFullSentenceMode;

  @override
  Widget build(BuildContext context) {
    if (isFullSentenceMode) {
      return _buildFullSentenceView();
    }
    return _buildPhraseView();
  }

  Widget _buildPhraseView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProgressIndicator(),
        const SizedBox(height: AppSpacing.lg),
        _buildCurrentPhrase(),
        const SizedBox(height: AppSpacing.md),
        _buildFullSentencePreview(),
      ],
    );
  }

  Widget _buildFullSentenceView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCompleteBadge(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          fullSentence,
          style: AppTypography.sentence.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Luyện toàn câu',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(phrases.length, (index) {
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.success
                : isCurrent
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
          ),
        );
      }),
    );
  }

  Widget _buildCurrentPhrase() {
    return Text(
      phrases[currentIndex],
      style: AppTypography.sentence.copyWith(
        color: AppColors.primary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFullSentencePreview() {
    return Text.rich(
      TextSpan(
        children: _buildHighlightedSpans(),
      ),
      textAlign: TextAlign.center,
    );
  }

  List<InlineSpan> _buildHighlightedSpans() {
    return phrases.asMap().entries.map((entry) {
      final index = entry.key;
      final phrase = entry.value;
      final isActive = index == currentIndex;
      final separator = index < phrases.length - 1 ? ' ' : '';
      return TextSpan(
        text: '$phrase$separator',
        style: AppTypography.bodyMedium.copyWith(
          color: isActive
              ? AppColors.primary
              : AppColors.textSecondary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      );
    }).toList();
  }

  Widget _buildCompleteBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        '✓ Hoàn thành tất cả cụm từ',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
