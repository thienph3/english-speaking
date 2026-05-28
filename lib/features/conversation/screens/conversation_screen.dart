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
import 'package:speakeng/features/conversation/widgets/conversation_bottom_actions.dart';
import 'package:speakeng/features/conversation/widgets/typing_indicator.dart';
import 'package:speakeng/shared/services/audio_service.dart';

/// Màn hình hội thoại AI.
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

    ref.listen<ConversationState>(conversationProvider, (prev, next) {
      if (next is ConversationSpeaking && next.cachedAudioPath != null) {
        _playTtsAudio(next.cachedAudioPath!);
      }
    });

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
                '$turnCount/${AppConstants.maxConversationTurns}',
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
            ConversationBottomActions(
              hints: widget.scenario.hints,
              onRecord: () => _handleRecordPress(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(ConversationState state) {
    final messages = _getMessages(state);
    final showTyping =
        state is ConversationTranscribing || state is ConversationThinking;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: messages.length + (showTyping ? 1 : 0),
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

  Future<void> _handleRecordPress(ConversationState state) async {
    if (state is ConversationRecording) {
      await _stopAndSubmit();
    } else if (state is ConversationSpeaking || state is ConversationError) {
      ref.read(conversationProvider.notifier).startRecording();
      final dir = await getTemporaryDirectory();
      await _audioService.startRecording(
        '${dir.path}/conversation_recording.wav',
      );
    }
  }

  Future<void> _stopAndSubmit() async {
    final path = await _audioService.stopRecording();
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
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

  Future<void> _playTtsAudio(String path) async {
    await _audioService.loadAudio(path);
    await _audioService.play();
    _scrollToBottom();
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
}
