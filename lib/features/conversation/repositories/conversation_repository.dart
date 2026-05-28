import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:speakeng/core/constants.dart';
import 'package:speakeng/features/ai_services/providers/orchestrator_provider.dart';
import 'package:speakeng/features/conversation/models/scenario.dart';

/// Provider cho ConversationRepository.
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository(ref.watch(orchestratorProvider));
});

/// Repository quản lý conversation qua Orchestrator.
///
/// Orchestrator tự động chọn provider (online/offline) cho TTS, STT, LLM.
class ConversationRepository {
  ConversationRepository(this._orchestrator);

  final AiOrchestrator _orchestrator;
  final List<Map<String, String>> _messages = [];

  /// Lịch sử tin nhắn hiện tại.
  List<Map<String, String>> get messages => List.unmodifiable(_messages);

  /// Số turn hiện tại (mỗi user message = 1 turn).
  int get currentTurn => _messages.where((m) => m['role'] == 'user').length;

  /// Reset conversation history.
  void reset() => _messages.clear();

  /// Thêm tin nhắn vào history.
  void addMessage(String role, String content) {
    _messages.add({'role': role, 'content': content});
  }

  /// Kiểm tra đã đạt giới hạn turns chưa.
  bool get isAtTurnLimit =>
      currentTurn >= AppConstants.maxConversationTurns;

  /// Gửi audio → nhận transcript text.
  Future<String> transcribe(Uint8List audio) async {
    return _orchestrator.transcribe(audio);
  }

  /// Gửi messages + systemPrompt → nhận AI response.
  Future<String> chat(
    List<Map<String, String>> messages,
    String systemPrompt,
  ) async {
    return _orchestrator.chat(
      messages: messages,
      systemPrompt: systemPrompt,
    );
  }

  /// Gửi text → nhận audio bytes.
  Future<Uint8List> textToSpeech(String text) async {
    return _orchestrator.synthesize(text);
  }

  /// Pre-cache audio cho first message của scenario.
  Future<String?> cacheFirstMessageAudio(Scenario scenario) async {
    try {
      final audioBytes = await textToSpeech(scenario.firstMessage);
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/scenario_${scenario.id}_first.mp3';
      final file = File(filePath);
      await file.writeAsBytes(audioBytes);
      return filePath;
    } catch (_) {
      return null;
    }
  }
}
