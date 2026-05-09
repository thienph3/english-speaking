import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/core/constants.dart';
import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/conversation/models/scenario.dart';
import 'package:speakeng/shared/services/supabase_service.dart';

/// Provider cho ConversationRepository.
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository(ref.read(supabaseProvider));
});

/// Repository quản lý giao tiếp với Edge Functions cho conversation.
///
/// Gọi /transcribe, /chat, /tts qua Supabase functions.invoke().
/// Quản lý conversation history và giới hạn turns.
class ConversationRepository {
  ConversationRepository(this._supabase);

  final SupabaseClient _supabase;
  final List<Map<String, String>> _messages = [];

  /// Lịch sử tin nhắn hiện tại.
  List<Map<String, String>> get messages => List.unmodifiable(_messages);

  /// Số turn hiện tại (mỗi cặp user+assistant = 1 turn).
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

  /// Gửi audio đến /transcribe → nhận transcript text.
  Future<String> transcribe(Uint8List audio) async {
    try {
      final response = await _supabase.functions
          .invoke(
            'transcribe',
            body: {'audio': audio.toList()},
          )
          .timeout(AppConstants.apiTimeoutDuration);

      final data = response.data as Map<String, dynamic>;
      return data['text'] as String;
    } on TimeoutException {
      throw const ApiTimeoutError();
    } on SocketException {
      throw const NetworkError();
    }
  }

  /// Gửi messages + systemPrompt đến /chat → nhận AI response.
  Future<String> chat(
    List<Map<String, String>> messages,
    String systemPrompt,
  ) async {
    try {
      final response = await _supabase.functions
          .invoke(
            'chat',
            body: {
              'messages': messages,
              'scenario': {'system_prompt': systemPrompt},
            },
          )
          .timeout(AppConstants.apiTimeoutDuration);

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      final message = choices[0]['message'] as Map<String, dynamic>;
      return message['content'] as String;
    } on TimeoutException {
      throw const ApiTimeoutError();
    } on SocketException {
      throw const NetworkError();
    }
  }

  /// Gửi text đến /tts → nhận audio bytes.
  Future<Uint8List> textToSpeech(String text) async {
    try {
      final response = await _supabase.functions
          .invoke('tts', body: {'text': text})
          .timeout(AppConstants.apiTimeoutDuration);

      return Uint8List.fromList(response.data as List<int>);
    } on TimeoutException {
      throw const ApiTimeoutError();
    } on SocketException {
      throw const NetworkError();
    } catch (_) {
      throw const TtsError();
    }
  }

  /// Pre-cache audio cho first message của scenario.
  ///
  /// Tải TTS audio và lưu vào local file.
  /// Trả về đường dẫn file đã cache.
  Future<String?> cacheFirstMessageAudio(Scenario scenario) async {
    try {
      final audioBytes = await textToSpeech(scenario.firstMessage);
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/scenario_${scenario.id}_first.mp3';
      final file = File(filePath);
      await file.writeAsBytes(audioBytes);
      return filePath;
    } catch (_) {
      // Nếu cache thất bại, trả về null — app sẽ fallback hiển thị text
      return null;
    }
  }
}
