import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';
import 'package:speakeng/features/shadowing/providers/shadowing_provider.dart';
import 'package:speakeng/features/shadowing/widgets/word_feedback_chip.dart';
import 'package:speakeng/shared/widgets/score_card.dart';

/// Hiển thị text câu shadowing ở giữa màn hình.
class SentenceDisplay extends StatelessWidget {
  const SentenceDisplay({
    super.key,
    required this.text,
    this.isPlaying = false,
  });

  final String text;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: AppTypography.sentence.copyWith(
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Nút Play audio mẫu.
class PlayButton extends StatelessWidget {
  const PlayButton({super.key, required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () =>
          ref.read(shadowingProvider.notifier).startPlaying(),
      icon: const Icon(Icons.play_arrow),
      label: const Text('Nghe mẫu'),
    );
  }
}

/// Nút Retry (thử lại).
class RetryButton extends StatelessWidget {
  const RetryButton({super.key, required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => ref.read(shadowingProvider.notifier).retry(),
      icon: const Icon(Icons.refresh),
      label: const Text('Thử lại'),
    );
  }
}

/// Hiển thị kết quả phát âm với WordFeedbackWrap và ScoreCard.
class ResultContent extends StatelessWidget {
  const ResultContent({
    super.key,
    required this.sentenceText,
    required this.accuracy,
    required this.fluency,
    required this.completeness,
    this.words = const [],
    this.onWordTap,
  });

  final String sentenceText;
  final double accuracy;
  final double fluency;
  final double completeness;
  final List<WordResult> words;

  /// Callback khi user tap vào từ đỏ/vàng.
  final void Function(WordResult word)? onWordTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          if (words.isNotEmpty)
            WordFeedbackWrap(words: words, onWordTap: onWordTap)
          else
            Text(
              sentenceText,
              style: AppTypography.sentence,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.lg),
          ScoreCard(
            accuracy: accuracy,
            fluency: fluency,
            completeness: completeness,
          ),
        ],
      ),
    );
  }
}
