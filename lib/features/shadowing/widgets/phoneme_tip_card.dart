import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/shadowing/logic/phoneme_tip_lookup.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';

/// Card hiển thị chi tiết một phoneme sai + mẹo phát âm tiếng Việt.
///
/// Hiển thị:
/// - Ký hiệu phoneme (IPA)
/// - Accuracy score với màu tương ứng
/// - Mẹo phát âm tiếng Việt (nếu có)
class PhonemeTipCard extends StatelessWidget {
  const PhonemeTipCard({
    super.key,
    required this.phonemeResult,
  });

  final PhonemeResult phonemeResult;

  @override
  Widget build(BuildContext context) {
    final tip = PhonemeTipLookup.getTip(
      phonemeResult.phoneme,
      phonemeResult.accuracyScore,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhonemeSymbol(),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildContent(tip)),
        ],
      ),
    );
  }

  Widget _buildPhonemeSymbol() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _scoreColor.withValues(alpha: 0.1),
        borderRadius: AppRadius.sm,
      ),
      alignment: Alignment.center,
      child: Text(
        '/${phonemeResult.phoneme}/',
        style: AppTypography.h3.copyWith(color: _scoreColor),
      ),
    );
  }

  Widget _buildContent(String? tip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreRow(),
        if (tip != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            tip,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreRow() {
    return Row(
      children: [
        Text(
          'Accuracy: ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${phonemeResult.accuracyScore.toInt()}%',
          style: AppTypography.bodyMedium.copyWith(
            color: _scoreColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color get _scoreColor {
    if (phonemeResult.accuracyScore >= 80) return AppColors.correct;
    if (phonemeResult.accuracyScore >= 50) return AppColors.needsWork;
    return AppColors.wrong;
  }
}

/// Bottom sheet hiển thị tất cả phonemes của một từ + mẹo cho phonemes sai.
///
/// Được gọi khi user tap vào từ đỏ/vàng trong kết quả phát âm.
void showPhonemeDetailSheet(BuildContext context, WordResult wordResult) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _PhonemeDetailSheet(wordResult: wordResult),
  );
}

class _PhonemeDetailSheet extends StatelessWidget {
  const _PhonemeDetailSheet({required this.wordResult});

  final WordResult wordResult;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              const SizedBox(height: AppSpacing.md),
              _buildHeader(),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: wordResult.phonemes.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, index) => PhonemeTipCard(
                    phonemeResult: wordResult.phonemes[index],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.missed,
          borderRadius: AppRadius.full,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '"${wordResult.word}"',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Accuracy: ${wordResult.accuracyScore.toInt()}%',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
