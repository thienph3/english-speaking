import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:speakeng/core/constants.dart';
import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/conversation/models/scenario.dart';
import 'package:speakeng/features/conversation/providers/conversation_provider.dart';
import 'package:speakeng/features/conversation/providers/conversation_state.dart';
import 'package:speakeng/features/conversation/widgets/chat_bubble.dart';
import 'package:speakeng/features/conversation/widgets/typing_indicator.dart';
import 'package:speakeng/shared/services/audio_service.dart';
import 'package:speakeng/shared/widgets/recording_button.dart';

/// Màn hình hội thoại AI.
///
/// Hiển thị chat bubbles, typing indicator, nút ghi âm,
/// turn counter trong AppBar, và nút gợi ý.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.scenario});

  final Scenario scenario;

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _scrollController = ScrollController();
  late final AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationProvider.notifier).startScenario(widget.scenario);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider);
    final turnCount = _getTurnCount(state);
    final maxTurns = AppConstants.maxConversationTurns;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.scenario.situation),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text(
                '$turnCount/$maxTurns',
                style: AppTypography.h3,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildChatList(state)),
            _buildBottomActions(state),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(ConversationState state) {
    final messages = _getMessages(state);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: messages.length + (_showTyping(state) ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final msg = messages[index];
          return ChatBubble(
            text: msg['content'] ?? '',
            isUser: msg['role'] == 'user',
          );
        }
        return const TypingIndicator();
      },
    );
  }

  Widget _buildBottomActions(ConversationState state) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildHintButton(state),
          RecordingButton(
            state: _getRecordingButtonState(state),
            onPressed: () => _handleRecordPress(state),
          ),
        ],
      ),
    );
  }

  Widget _buildHintButton(ConversationState state) {
    final turnCount = _getTurnCount(state);
    final hintIndex = turnCount.clamp(0, widget.scenario.hints.length - 1);

    return TextButton.icon(
      onPressed: () => _showHint(hintIndex),
      icon: const Text('💡', style: TextStyle(fontSize: 20)),
      label: Text(
        'Gợi ý',
        style: AppTypography.button.copyWith(color: AppColors.primary),
      ),
    );
  }

  void _showHint(int hintIndex) {
    if (widget.scenario.hints.isEmpty) return;

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
            Text(
              widget.scenario.hints[hintIndex],
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRecordPress(ConversationState state) async {
    if (state is ConversationRecording) {
      await _stopAndSubmit();
    } else if (state is ConversationSpeaking || state is ConversationError) {
      _startRecording();
    }
  }

  void _startRecording() {
    ref.read(conversationProvider.notifier).startRecording();
    _startAudioRecording();
  }

  Future<void> _startAudioRecording() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/conversation_recording.wav';
    await _audioService.startRecording(path);
  }

  Future<void> _stopAndSubmit() async {
    final path = await _audioService.stopRecording();
    if (path == null) return;

    final file = File(path);
    final bytes = await file.readAsBytes();
    await ref.read(conversationProvider.notifier).submitRecording(bytes);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _getTurnCount(ConversationState state) {
    return switch (state) {
      ConversationRecording(turnCount: final t) => t,
      ConversationTranscribing(turnCount: final t) => t,
      ConversationThinking(turnCount: final t) => t,
      ConversationSpeaking(turnCount: final t) => t,
      ConversationCompleted(turnCount: final t) => t,
      ConversationError(turnCount: final t) => t,
      _ => 0,
    };
  }

  List<Map<String, String>> _getMessages(ConversationState state) {
    return switch (state) {
      ConversationRecording(messages: final m) => m,
      ConversationTranscribing(messages: final m) => m,
      ConversationThinking(messages: final m) => m,
      ConversationSpeaking(messages: final m) => m,
      ConversationCompleted(messages: final m) => m,
      ConversationError(messages: final m) => m,
      _ => [],
    };
  }

  bool _showTyping(ConversationState state) {
    return state is ConversationTranscribing || state is ConversationThinking;
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
