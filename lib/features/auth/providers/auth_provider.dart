import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/auth/providers/auth_state.dart';
import 'package:speakeng/features/auth/repositories/auth_repository.dart';

export 'package:speakeng/features/auth/providers/auth_state.dart';

/// Provider cho AuthNotifier (quản lý auth state).
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// StateNotifier quản lý trạng thái xác thực.
///
/// Lắng nghe auth state changes từ Supabase và cung cấp
/// các methods signUp, signIn, signOut cho UI.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState.initial()) {
    _init();
  }

  final AuthRepository _repository;
  StreamSubscription<supabase.AuthState>? _authSub;

  void _init() {
    final currentUser = _repository.currentUser;
    if (currentUser != null) {
      state = AuthState.authenticated(user: currentUser);
    } else {
      state = const AuthState.unauthenticated();
    }
    _listenAuthChanges();
  }

  void _listenAuthChanges() {
    _authSub = _repository.authStateChanges.listen((event) {
      final session = event.session;
      if (event.event == supabase.AuthChangeEvent.signedIn &&
          session != null) {
        state = AuthState.authenticated(user: session.user);
      } else if (event.event == supabase.AuthChangeEvent.signedOut) {
        state = const AuthState.unauthenticated();
      }
    });
  }

  /// Đăng ký tài khoản mới.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(user: user);
    } on AppError catch (e) {
      state = AuthState.error(message: e.userMessage);
    }
  }

  /// Đăng nhập bằng email và password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(user: user);
    } on AppError catch (e) {
      state = AuthState.error(message: e.userMessage);
    }
  }

  /// Đăng xuất user hiện tại.
  Future<void> signOut() async {
    try {
      await _repository.signOut();
      state = const AuthState.unauthenticated();
    } on AppError catch (e) {
      state = AuthState.error(message: e.userMessage);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
