import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/shadowing/logic/phrase_splitter.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';
import 'package:speakeng/features/shadowing/providers/phrase_mode_provider.dart';
import 'package:speakeng/features/shadowing/providers/shadowing_provider.dart';
import 'package:speakeng/features/shadowing/providers/shadowing_state.dart';
import 'package:speakeng/features/shadowing/widgets/phoneme_tip_card.dart';
import 'package:speakeng/features/shadowing/widgets/phrase_mode_toggle.dart';
import 'package:speakeng/features/shadowing/widgets/phrase_practice_view.dart';
import 'package:speakeng/features/shadowing/widgets/shadowing_widgets.dart';
import 'package:speakeng/shared/widgets/recording_button.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_extractSituation(state) ?? 'Shadowing'),
        elevation: 0,
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ),
          child: Column(
            children: [
              Expanded(
                child: _buildContent(state, phraseState),
              ),
              _buildBottomActions(ref, state, phraseState),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    ShadowingState state,
    PhraseModeState phraseState,
  ) {
    return switch (state) {
      ShadowingInitial() => _buildLoadingContent(),
      ShadowingLoaded(:final sentence) =>
        _buildSentenceContent(sentence, phraseState),
      ShadowingPlaying(:final sentence) =>
        _buildSentenceContent(sentence, phraseState, isPlaying: true),
      ShadowingRecording(:final sentence) =>
        _buildSentenceContent(sentence, phraseState),
      ShadowingProcessing() => _buildProcessingContent(),
      ShadowingResult(:final sentence, :final result) => Builder(
          builder: (context) => ResultContent(
            sentenceText: sentence.text,
            accuracy: result.accuracyScore,
            fluency: result.fluencyScore,
            completeness: result.completenessScore,
            words: result.words,
            onWordTap: (word) => showPhonemeDetailSheet(context, word),
          ),
        ),
      ShadowingError(:final error) => _buildErrorContent(
          error.userMessage,
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

  Widget _buildLoadingContent() {
    return const Center(
      child: Text('Đang tải câu...', style: AppTypography.bodyLarge),
    );
  }

  Widget _buildProcessingContent() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Đang phân tích...', style: AppTypography.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String message) {
    return Center(
      child: Text(
        message,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomActions(
    WidgetRef ref,
    ShadowingState state,
    PhraseModeState phraseState,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPhraseToggle(ref, state),
        const SizedBox(height: AppSpacing.sm),
        _buildActionButtons(ref, state),
        const SizedBox(height: AppSpacing.sm),
        _buildRecordButton(ref, state, phraseState),
      ],
    );
  }

  Widget _buildPhraseToggle(WidgetRef ref, ShadowingState state) {
    final sentence = _extractSentence(state);
    if (sentence == null) return const SizedBox.shrink();
    if (!PhraseSplitter.supportsPhrasePractice(sentence)) {
      return const SizedBox.shrink();
    }
    final phraseState = ref.watch(phraseModeProvider);
    return PhraseModeToggle(
      isEnabled: phraseState.isEnabled,
      onToggle: () =>
          ref.read(phraseModeProvider.notifier).toggle(sentence),
    );
  }

  Widget _buildActionButtons(WidgetRef ref, ShadowingState state) {
    return switch (state) {
      ShadowingLoaded() || ShadowingPlaying() => PlayButton(ref: ref),
      ShadowingResult() || ShadowingError() => RetryButton(ref: ref),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildRecordButton(
    WidgetRef ref,
    ShadowingState state,
    PhraseModeState phraseState,
  ) {
    return RecordingButton(
      state: _mapRecordButtonState(state),
      onPressed: () => _onRecordPressed(ref, state, phraseState),
    );
  }

  RecordingButtonState _mapRecordButtonState(ShadowingState state) {
    return switch (state) {
      ShadowingRecording() => RecordingButtonState.recording,
      ShadowingLoaded() || ShadowingPlaying() => RecordingButtonState.idle,
      _ => RecordingButtonState.disabled,
    };
  }

  void _onRecordPressed(
    WidgetRef ref,
    ShadowingState state,
    PhraseModeState phraseState,
  ) {
    final notifier = ref.read(shadowingProvider.notifier);
    switch (state) {
      case ShadowingLoaded() || ShadowingPlaying():
        notifier.startRecording();
      case ShadowingRecording():
        notifier.stopAndSubmit('/tmp/recording.wav');
        // Trong phrase mode, advance sau khi submit thành công
        if (phraseState.isEnabled && !phraseState.isFullSentenceMode) {
          ref.read(phraseModeProvider.notifier).advanceToNextPhrase();
        }
      default:
        break;
    }
  }

  String? _extractSituation(ShadowingState state) {
    return _extractSentence(state)?.situation;
  }

  Sentence? _extractSentence(ShadowingState state) {
    return switch (state) {
      ShadowingLoaded(:final sentence) => sentence,
      ShadowingPlaying(:final sentence) => sentence,
      ShadowingRecording(:final sentence) => sentence,
      ShadowingProcessing(:final sentence) => sentence,
      ShadowingResult(:final sentence) => sentence,
      _ => null,
    };
  }
}
