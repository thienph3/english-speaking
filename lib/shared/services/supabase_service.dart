import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/core/constants.dart';

/// Provider cho Supabase client instance.
///
/// Supabase phải được khởi tạo trước khi sử dụng provider này
/// (gọi [SupabaseService.initialize] trong main.dart).
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider cho GoTrueClient (Supabase Auth).
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return ref.read(supabaseProvider).auth;
});

/// Service khởi tạo và quản lý kết nối Supabase.
class SupabaseService {
  SupabaseService._();

  /// Khởi tạo Supabase SDK với URL và anon key từ AppConstants.
  ///
  /// Phải được gọi một lần duy nhất trong main() trước runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }
}
