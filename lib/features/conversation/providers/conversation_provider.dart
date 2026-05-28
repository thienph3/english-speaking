import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';

import 'package:speakeng/core/constants.dart';
import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/conversation/models/scenario.dart';
import 'package:speakeng/features/conversation/providers/conversation_state.dart';
import 'package:speakeng/features/conversation/repositories/conversation_repository.dart';

/// Provider cho ConversationNotifier.
final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  return ConversationNotifier(ref.read(conversationRepositoryProvider));
});

/// StateNotifier quản lý conversation flow.
///
/// Quản lý: scenario hiện tại, messages history, turn count,
/// response times, và cached audio path.
class ConversationNotifier extends StateNotifier<ConversationState> {
  ConversationNotifier(this._repository)
      : super(const ConversationState.idle());

  final ConversationRepository _repository;
  DateTime? _lastAiFinishTime;

  /// Bắt đầu scenario mới.
  ///
  /// Reset repository, thêm first message của AI vào history,
  /// và pre-cache audio nếu chưa có.
  Future<void> startScenario(Scenario scenario) async {
    _repository.reset();
    _repository.addMessage('assistant', scenario.firstMessage);

    final cachedPath = await _repository.cacheFirstMessageAudio(scenario);

    state = ConversationState.speaking(
      scenario: scenario,
      messages: _repository.messages,
      turnCount: 0,
      responseTimes: [],
      cachedAudioPath: cachedPath,
    );

    _lastAiFinishTime = DateTime.now();
  }

  /// Bắt đầu ghi âm user.
  void startRecording() {
    final current = state;
    if (current is ConversationSpeaking) {
      state = ConversationState.recording(
        scenario: current.scenario,
        messages: current.messages,
        turnCount: current.turnCount,
        responseTimes: current.responseTimes,
        cachedAudioPath: current.cachedAudioPath,
      );
    } else if (current is ConversationError) {
      state = ConversationState.recording(
        scenario: current.scenario,
        messages: current.messages,
        turnCount: current.turnCount,
        responseTimes: current.responseTimes,
        cachedAudioPath: current.cachedAudioPath,
      );
    }
  }

  /// Gửi recording audio để xử lý.
  ///
  /// Flow: transcribe → chat → tts (hoặc completed nếu đạt max turns).
  Future<void> submitRecording(Uint8List audioBytes) async {
    final current = state;
    if (current is! ConversationRecording) return;

    final responseTime = _calculateResponseTime();
    final updatedTimes = [...current.responseTimes, responseTime];

    state = ConversationState.transcribing(
      scenario: current.scenario,
      messages: current.messages,
      turnCount: current.turnCount,
      responseTimes: updatedTimes,
      cachedAudioPath: current.cachedAudioPath,
    );

    try {
      final transcript = await _repository.transcribe(audioBytes);
      _repository.addMessage('user', transcript);

      await _processChat(
        current.scenario,
        updatedTimes,
        current.cachedAudioPath,
      );
    } on AppError catch (e) {
      _setError(
        e.userMessage,
        current.scenario,
        updatedTimes,
        current.cachedAudioPath,
      );
    }
  }

  /// Kết thúc hội thoại sớm.
  void endConversation() {
    final scenario = _extractScenario();
    if (scenario == null) return;

    state = ConversationState.completed(
      scenario: scenario,
      messages: _repository.messages,
      turnCount: _repository.currentTurn,
      responseTimes: _extractResponseTimes(),
    );
  }

  Future<void> _processChat(
    Scenario scenario,
    List<int> responseTimes,
    String? cachedAudioPath,
  ) async {
    state = ConversationState.thinking(
      scenario: scenario,
      messages: _repository.messages,
      turnCount: _repository.currentTurn,
      responseTimes: responseTimes,
      cachedAudioPath: cachedAudioPath,
    );

    try {
      final aiResponse = await _repository.chat(
        _repository.messages,
        scenario.systemPrompt,
      );
      _repository.addMessage('assistant', aiResponse);

      if (_repository.currentTurn >= AppConstants.maxConversationTurns) {
        state = ConversationState.completed(
          scenario: scenario,
          messages: _repository.messages,
          turnCount: _repository.currentTurn,
          responseTimes: responseTimes,
        );
        return;
      }

      // TTS: synthesize AI response audio
      final audioPath = await _cacheAudio(aiResponse);

      state = ConversationState.speaking(
        scenario: scenario,
        messages: _repository.messages,
        turnCount: _repository.currentTurn,
        responseTimes: responseTimes,
        cachedAudioPath: audioPath,
      );

      _lastAiFinishTime = DateTime.now();
    } on AppError catch (e) {
      _setError(e.userMessage, scenario, responseTimes, cachedAudioPath);
    }
  }

  Future<String?> _cacheAudio(String text) async {
    try {
      final bytes = await _repository.textToSpeech(text);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/conv_tts_${DateTime.now().millisecondsSinceEpoch}.wav';
      await File(path).writeAsBytes(bytes);
      return path;
    } catch (_) {
      return null;
    }
  }

  int _calculateResponseTime() {
    if (_lastAiFinishTime == null) return 0;
    return DateTime.now().difference(_lastAiFinishTime!).inMilliseconds;
  }

  void _setError(
    String message,
    Scenario scenario,
    List<int> responseTimes,
    String? cachedAudioPath,
  ) {
    state = ConversationState.error(
      message: message,
      scenario: scenario,
      messages: _repository.messages,
      turnCount: _repository.currentTurn,
      responseTimes: responseTimes,
      cachedAudioPath: cachedAudioPath,
    );
  }

  Scenario? _extractScenario() {
    return switch (state) {
      ConversationRecording(:final scenario) => scenario,
      ConversationTranscribing(:final scenario) => scenario,
      ConversationThinking(:final scenario) => scenario,
      ConversationSpeaking(:final scenario) => scenario,
      ConversationError(:final scenario) => scenario,
      _ => null,
    };
  }

  List<int> _extractResponseTimes() {
    return switch (state) {
      ConversationRecording(:final responseTimes) => responseTimes,
      ConversationTranscribing(:final responseTimes) => responseTimes,
      ConversationThinking(:final responseTimes) => responseTimes,
      ConversationSpeaking(:final responseTimes) => responseTimes,
      ConversationError(:final responseTimes) => responseTimes,
      ConversationCompleted(:final responseTimes) => responseTimes,
      _ => [],
    };
  }
}
