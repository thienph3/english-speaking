import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/conversation/logic/conversation_state_helpers.dart';
import 'package:speakeng/features/conversation/providers/conversation_provider.dart';
import 'package:speakeng/features/conversation/providers/conversation_state.dart';
import 'package:speakeng/shared/widgets/recording_button.dart';

/// Bottom actions cho conversation screen: hint button + record button.
class ConversationBottomActions extends ConsumerWidget {
  const ConversationBottomActions({
    super.key,
    required this.hints,
    required this.onRecord,
  });

  final List<String> hints;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildHintButton(context, state),
          RecordingButton(
            state: _getRecordingButtonState(state),
            onPressed: onRecord,
          ),
        ],
      ),
    );
  }

  Widget _buildHintButton(BuildContext context, ConversationState state) {
    final turnCount = state.turnCount;
    final hintIndex = turnCount.clamp(0, hints.length - 1);

    return TextButton.icon(
      onPressed: () => _showHint(context, hintIndex),
      icon: const Text('💡', style: TextStyle(fontSize: 20)),
      label: Text(
        'Gợi ý',
        style: AppTypography.button.copyWith(color: AppColors.primary),
      ),
    );
  }

  void _showHint(BuildContext context, int hintIndex) {
    if (hints.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💡 Gợi ý', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.md),
            Text(hints[hintIndex], style: AppTypography.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  RecordingButtonState _getRecordingButtonState(ConversationState state) {
    return switch (state) {
      ConversationRecording() => RecordingButtonState.recording,
      ConversationSpeaking() => RecordingButtonState.idle,
      ConversationError() => RecordingButtonState.idle,
      _ => RecordingButtonState.disabled,
    };
  }
}
