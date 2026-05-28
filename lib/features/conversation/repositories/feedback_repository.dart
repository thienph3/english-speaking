import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:speakeng/features/conversation/models/conversation_feedback.dart';

const _key = 'saved_feedbacks';

/// Provider cho FeedbackRepository.
final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository();
});

/// Provider loads all saved feedbacks from SharedPreferences.
final savedFeedbacksProvider =
    FutureProvider<List<ConversationFeedback>>((ref) {
  return ref.read(feedbackRepositoryProvider).loadAll();
});

/// Repository lưu trữ ConversationFeedback vào SharedPreferences.
class FeedbackRepository {
  /// Lưu một feedback mới.
  Future<void> save(ConversationFeedback feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(jsonEncode(feedback.toJson()));
    await prefs.setStringList(_key, list);
  }

  /// Load tất cả feedbacks đã lưu.
  Future<List<ConversationFeedback>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list
        .map((s) => ConversationFeedback.fromJson(
              jsonDecode(s) as Map<String, dynamic>,
            ))
        .toList();
  }
}
