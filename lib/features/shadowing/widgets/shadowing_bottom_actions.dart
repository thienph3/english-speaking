import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/shadowing/logic/phrase_splitter.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';
import 'package:speakeng/features/shadowing/providers/phrase_mode_provider.dart';
import 'package:speakeng/features/shadowing/providers/shadowing_provider.dart';
import 'package:speakeng/features/shadowing/providers/shadowing_state.dart';
import 'package:speakeng/features/shadowing/widgets/phrase_mode_toggle.dart';
import 'package:speakeng/features/shadowing/widgets/shadowing_widgets.dart';
import 'package:speakeng/shared/widgets/recording_button.dart';

/// Bottom actions cho shadowing screen: phrase toggle + play/retry + record.
class ShadowingBottomActions extends ConsumerWidget {
  const ShadowingBottomActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shadowingProvider);
    final phraseState = ref.watch(phraseModeProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPhraseToggle(ref, state),
        const SizedBox(height: AppSpacing.sm),
        _buildActionButtons(ref, state),
        const SizedBox(height: AppSpacing.sm),
        RecordingButton(
          state: _mapRecordButtonState(state),
          onPressed: () => _onRecordPressed(ref, state, phraseState),
        ),
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
        if (phraseState.isEnabled && !phraseState.isFullSentenceMode) {
          ref.read(phraseModeProvider.notifier).advanceToNextPhrase();
        }
      default:
        break;
    }
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
