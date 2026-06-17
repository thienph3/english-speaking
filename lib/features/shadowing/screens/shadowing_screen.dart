import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';
import 'package:speakeng/features/shadowing/providers/phrase_mode_provider.dart';
import 'package:speakeng/features/shadowing/providers/shadowing_provider.dart';
import 'package:speakeng/features/shadowing/providers/shadowing_state.dart';
import 'package:speakeng/features/shadowing/widgets/phoneme_tip_card.dart';
import 'package:speakeng/features/shadowing/widgets/phrase_practice_view.dart';
import 'package:speakeng/features/shadowing/widgets/shadowing_bottom_actions.dart';
import 'package:speakeng/features/shadowing/widgets/shadowing_widgets.dart';
import 'package:speakeng/shared/services/content_service.dart';

/// Màn hình Shadowing: play audio → record → gửi → hiển thị kết quả.
///
/// Hỗ trợ phrase-by-phrase mode cho câu > 5 từ.
class ShadowingScreen extends ConsumerWidget {
  const ShadowingScreen({super.key, required this.sentenceId});

  final String sentenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shadowingProvider);
    final phraseState = ref.watch(phraseModeProvider);

    // Load sentence on first build if still initial
    if (state is ShadowingInitial) {
      _loadSentence(ref);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_extractSituation(state) ?? 'Shadowing'),
        elevation: 0,
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              Expanded(child: _buildContent(context, state, phraseState)),
              const ShadowingBottomActions(),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ShadowingState state,
    PhraseModeState phraseState,
  ) {
    return switch (state) {
      ShadowingInitial() => const Center(
          child: Text('Đang tải câu...', style: AppTypography.bodyLarge),
        ),
      ShadowingLoaded(:final sentence) =>
        _buildSentenceContent(sentence, phraseState),
      ShadowingPlaying(:final sentence) =>
        _buildSentenceContent(sentence, phraseState, isPlaying: true),
      ShadowingRecording(:final sentence) =>
        _buildSentenceContent(sentence, phraseState),
      ShadowingProcessing() => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.md),
              Text('Đang phân tích...', style: AppTypography.bodyLarge),
            ],
          ),
        ),
      ShadowingResult(:final sentence, :final result) => ResultContent(
          sentenceText: sentence.text,
          accuracy: result.accuracyScore,
          fluency: result.fluencyScore,
          completeness: result.completenessScore,
          words: result.words,
          onWordTap: (word) => showPhonemeDetailSheet(context, word),
        ),
      ShadowingError(:final error) => Center(
          child: Text(
            error.userMessage,
            style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
    };
  }

  Widget _buildSentenceContent(
    Sentence sentence,
    PhraseModeState phraseState, {
    bool isPlaying = false,
  }) {
    if (phraseState.isEnabled) {
      return PhrasePracticeView(
        phrases: phraseState.phrases,
        currentIndex: phraseState.currentPhraseIndex,
        fullSentence: sentence.text,
        isFullSentenceMode: phraseState.isFullSentenceMode,
      );
    }
    return SentenceDisplay(text: sentence.text, isPlaying: isPlaying);
  }

  String? _extractSituation(ShadowingState state) {
    return switch (state) {
      ShadowingLoaded(:final sentence) => sentence.situation,
      ShadowingPlaying(:final sentence) => sentence.situation,
      ShadowingRecording(:final sentence) => sentence.situation,
      ShadowingProcessing(:final sentence) => sentence.situation,
      ShadowingResult(:final sentence) => sentence.situation,
      _ => null,
    };
  }

  Future<void> _loadSentence(WidgetRef ref) async {
    final contentService = ContentService();
    final sentences = await contentService.getAllSentences();
    final match = sentences.where((s) => s.id == sentenceId).firstOrNull;
    if (match != null) {
      ref.read(shadowingProvider.notifier).loadSentence(match);
    }
  }
}
