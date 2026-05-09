import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/shadowing/logic/word_color_mapper.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';

/// Hiển thị một từ với màu sắc theo accuracy score.
///
/// - Green: phát âm tốt (≥ 80%)
/// - Yellow: cần cải thiện (50–79%)
/// - Red: phát âm sai (< 50%) — thêm underline cho accessibility
///
/// Tap vào từ đỏ/vàng → gọi [onTap] callback (cho bottom sheet tương lai).
class WordFeedbackChip extends StatelessWidget {
  const WordFeedbackChip({
    super.key,
    required this.wordResult,
    this.onTap,
  });

  final WordResult wordResult;

  /// Callback khi user tap vào từ đỏ/vàng.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = WordColorMapper.mapColor(wordResult.accuracyScore);
    final isInteractive = color != WordColor.green;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: GestureDetector(
        onTap: isInteractive ? onTap : null,
        child: Semantics(
          label: _semanticLabel(color),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _backgroundColor(color),
              borderRadius: AppRadius.sm,
            ),
            child: Text(
              wordResult.word,
              style: AppTypography.sentenceWord.copyWith(
                color: _textColor(color),
                decoration: _needsUnderline(color)
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: _textColor(color),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Accessibility: underline cho từ sai (red và yellow).
  bool _needsUnderline(WordColor color) => color != WordColor.green;

  Color _backgroundColor(WordColor color) {
    return switch (color) {
      WordColor.green => AppColors.correct.withValues(alpha: 0.1),
      WordColor.yellow => AppColors.needsWork.withValues(alpha: 0.1),
      WordColor.red => AppColors.wrong.withValues(alpha: 0.1),
    };
  }

  Color _textColor(WordColor color) {
    return switch (color) {
      WordColor.green => AppColors.correct,
      WordColor.yellow => AppColors.needsWork,
      WordColor.red => AppColors.wrong,
    };
  }

  String _semanticLabel(WordColor color) {
    final quality = switch (color) {
      WordColor.green => 'phát âm tốt',
      WordColor.yellow => 'cần cải thiện',
      WordColor.red => 'phát âm sai',
    };
    return '${wordResult.word}, $quality';
  }
}

/// Hiển thị danh sách từ feedback dạng Wrap layout.
///
/// Dùng sau khi có kết quả pronunciation assessment.
class WordFeedbackWrap extends StatelessWidget {
  const WordFeedbackWrap({
    super.key,
    required this.words,
    this.onWordTap,
  });

  final List<WordResult> words;

  /// Callback khi user tap vào từ đỏ/vàng.
  final void Function(WordResult word)? onWordTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (final word in words)
          WordFeedbackChip(
            wordResult: word,
            onTap: () => onWordTap?.call(word),
          ),
      ],
    );
  }
}
