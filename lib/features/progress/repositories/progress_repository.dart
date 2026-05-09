import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/progress/models/daily_metrics.dart';
import 'package:speakeng/features/progress/models/sentence_progress.dart';
import 'package:speakeng/shared/services/supabase_service.dart';

/// Provider cho ProgressRepository.
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.read(supabaseProvider));
});

/// Repository CRUD cho sentence_progress và daily_metrics.
///
/// Giao tiếp với Supabase PostgreSQL qua client SDK.
class ProgressRepository {
  ProgressRepository(this._supabase);

  final SupabaseClient _supabase;

  String get _userId => _supabase.auth.currentUser!.id;

  /// Lấy progress của một sentence.
  Future<SentenceProgress?> getSentenceProgress(String sentenceId) async {
    try {
      final data = await _supabase
          .from('sentence_progress')
          .select()
          .eq('user_id', _userId)
          .eq('sentence_id', sentenceId)
          .maybeSingle();

      if (data == null) return null;
      return _mapToSentenceProgress(data);
    } on SocketException {
      throw const NetworkError();
    }
  }

  /// Lấy tất cả sentence progress của user.
  Future<List<SentenceProgress>> getAllProgress() async {
    try {
      final data = await _supabase
          .from('sentence_progress')
          .select()
          .eq('user_id', _userId);

      return data.map(_mapToSentenceProgress).toList();
    } on SocketException {
      throw const NetworkError();
    }
  }

  /// Upsert sentence progress (insert hoặc update).
  Future<void> upsertSentenceProgress(SentenceProgress progress) async {
    try {
      await _supabase.from('sentence_progress').upsert({
        'user_id': _userId,
        'sentence_id': progress.sentenceId,
        'correct_streak': progress.correctStreak,
        'best_accuracy': progress.bestAccuracy,
        'last_practiced': progress.lastPracticed?.toIso8601String(),
      });
    } on SocketException {
      throw const NetworkError();
    }
  }

  /// Lấy daily metrics cho một ngày cụ thể.
  Future<DailyMetrics?> getDailyMetrics(DateTime date) async {
    try {
      final dateStr = _formatDate(date);
      final data = await _supabase
          .from('daily_metrics')
          .select()
          .eq('user_id', _userId)
          .eq('date', dateStr)
          .maybeSingle();

      if (data == null) return null;
      return _mapToDailyMetrics(data);
    } on SocketException {
      throw const NetworkError();
    }
  }

  /// Lấy daily metrics cho khoảng thời gian (tuần).
  Future<List<DailyMetrics>> getWeekMetrics(DateTime weekStart) async {
    try {
      final startStr = _formatDate(weekStart);
      final endStr = _formatDate(weekStart.add(const Duration(days: 6)));

      final data = await _supabase
          .from('daily_metrics')
          .select()
          .eq('user_id', _userId)
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date');

      return data.map(_mapToDailyMetrics).toList();
    } on SocketException {
      throw const NetworkError();
    }
  }

  /// Upsert daily metrics.
  Future<void> upsertDailyMetrics(DailyMetrics metrics) async {
    try {
      await _supabase.from('daily_metrics').upsert({
        'user_id': _userId,
        'date': _formatDate(metrics.date),
        'sentences_practiced': metrics.sentencesPracticed,
        'sentences_mastered': metrics.sentencesMastered,
        'avg_accuracy': metrics.avgAccuracy,
        'avg_response_time_ms': metrics.avgResponseTimeMs,
      });
    } on SocketException {
      throw const NetworkError();
    }
  }

  /// Đếm tổng số sentences đã mastered.
  Future<int> countMasteredSentences() async {
    try {
      final data = await _supabase
          .from('sentence_progress')
          .select('sentence_id')
          .eq('user_id', _userId)
          .gte('correct_streak', 3);

      return (data as List).length;
    } on SocketException {
      throw const NetworkError();
    }
  }

  SentenceProgress _mapToSentenceProgress(Map<String, dynamic> data) {
    return SentenceProgress(
      userId: data['user_id'] as String,
      sentenceId: data['sentence_id'] as String,
      correctStreak: data['correct_streak'] as int? ?? 0,
      bestAccuracy: (data['best_accuracy'] as num?)?.toDouble() ?? 0,
      lastPracticed: data['last_practiced'] != null
          ? DateTime.parse(data['last_practiced'] as String)
          : null,
    );
  }

  DailyMetrics _mapToDailyMetrics(Map<String, dynamic> data) {
    return DailyMetrics(
      userId: data['user_id'] as String,
      date: DateTime.parse(data['date'] as String),
      sentencesPracticed: data['sentences_practiced'] as int? ?? 0,
      sentencesMastered: data['sentences_mastered'] as int? ?? 0,
      avgAccuracy: (data['avg_accuracy'] as num?)?.toDouble() ?? 0,
      avgResponseTimeMs: data['avg_response_time_ms'] as int? ?? 0,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
