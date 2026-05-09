import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/shared/services/supabase_service.dart';

/// Provider cho [PlacementRepository].
final placementRepositoryProvider = Provider<PlacementRepository>((ref) {
  return PlacementRepository(ref.read(supabaseProvider));
});

/// Repository lưu kết quả placement test vào Supabase.
///
/// Giao tiếp với bảng `user_profiles` để lưu/đọc trạng thái placement.
class PlacementRepository {
  PlacementRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Lưu kết quả placement vào bảng user_profiles.
  ///
  /// [avgAccuracy] — điểm trung bình accuracy từ 3 câu.
  /// [level] — mức khởi đầu: 'easy', 'easy_medium', 'medium_hard'.
  Future<void> savePlacementResult({
    required double avgAccuracy,
    required String level,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw const AuthError(message: 'Chưa đăng nhập');

      await _supabase.from('user_profiles').upsert({
        'user_id': userId,
        'placement_completed': true,
        'placement_avg_accuracy': avgAccuracy,
        'starting_level': level,
      }).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiTimeoutError();
    } on SocketException {
      throw const NetworkError();
    }
  }

  /// Kiểm tra user đã hoàn thành placement chưa.
  ///
  /// Trả về `true` nếu đã hoàn thành, `false` nếu chưa.
  Future<bool> hasCompletedPlacement() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('user_profiles')
          .select('placement_completed')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (response == null) return false;
      return response['placement_completed'] as bool? ?? false;
    } on TimeoutException {
      throw const ApiTimeoutError();
    } on SocketException {
      throw const NetworkError();
    }
  }
}
