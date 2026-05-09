import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, GoTrueClient, User;

import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/shared/services/supabase_service.dart';

/// Provider cho AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(supabaseAuthProvider));
});

/// Repository xử lý xác thực người dùng qua Supabase Auth.
///
/// Cung cấp signUp, signIn, signOut và stream auth state changes.
/// Throw [AuthError] hoặc [NetworkError] khi có lỗi.
class AuthRepository {
  AuthRepository(this._auth);

  final GoTrueClient _auth;

  /// Đăng ký tài khoản mới bằng email và password.
  ///
  /// Throw [AuthError] nếu email đã tồn tại hoặc password yếu.
  /// Throw [NetworkError] nếu mất kết nối.
  Future<User> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthError(message: 'Đăng ký thất bại. Vui lòng thử lại.');
      }
      return user;
    } on AuthException catch (e) {
      throw AuthError(message: _mapAuthMessage(e.message));
    } on SocketException {
      throw const NetworkError();
    } on TimeoutException {
      throw const NetworkError();
    }
  }

  /// Đăng nhập bằng email và password.
  ///
  /// Throw [AuthError] nếu sai thông tin đăng nhập.
  /// Throw [NetworkError] nếu mất kết nối.
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthError(message: 'Đăng nhập thất bại. Vui lòng thử lại.');
      }
      return user;
    } on AuthException catch (e) {
      throw AuthError(message: _mapAuthMessage(e.message));
    } on SocketException {
      throw const NetworkError();
    } on TimeoutException {
      throw const NetworkError();
    }
  }

  /// Đăng xuất user hiện tại.
  ///
  /// Throw [NetworkError] nếu mất kết nối.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on SocketException {
      throw const NetworkError();
    } on TimeoutException {
      throw const NetworkError();
    }
  }

  /// Stream theo dõi thay đổi trạng thái xác thực.
  Stream<supabase.AuthState> get authStateChanges =>
      _auth.onAuthStateChange;

  /// User hiện tại (null nếu chưa đăng nhập).
  User? get currentUser => _auth.currentUser;

  /// Map Supabase auth error message sang tiếng Việt.
  String _mapAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already registered') ||
        lower.contains('already exists')) {
      return 'Email đã được đăng ký. Vui lòng đăng nhập.';
    }
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (lower.contains('weak password') ||
        lower.contains('password')) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    if (lower.contains('invalid email')) {
      return 'Email không hợp lệ.';
    }
    return 'Lỗi xác thực: $message';
  }
}
