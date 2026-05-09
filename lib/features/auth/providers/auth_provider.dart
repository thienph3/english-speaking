import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/auth/repositories/auth_repository.dart';

/// Trạng thái xác thực của ứng dụng.
enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

/// State class cho auth.
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

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
  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  final AuthRepository _repository;
  StreamSubscription<supabase.AuthState>? _authSub;

  /// Khởi tạo: check user hiện tại và listen auth changes.
  void _init() {
    final currentUser = _repository.currentUser;
    if (currentUser != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: currentUser,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
    _listenAuthChanges();
  }

  /// Lắng nghe stream auth state changes từ Supabase.
  void _listenAuthChanges() {
    _authSub = _repository.authStateChanges.listen((event) {
      final authEvent = event.event;
      final session = event.session;
      if (authEvent == supabase.AuthChangeEvent.signedIn &&
          session != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
        );
      } else if (authEvent == supabase.AuthChangeEvent.signedOut) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  /// Đăng ký tài khoản mới.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AuthError catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.userMessage,
      );
    } on NetworkError catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.userMessage,
      );
    }
  }

  /// Đăng nhập bằng email và password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AuthError catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.userMessage,
      );
    } on NetworkError catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.userMessage,
      );
    }
  }

  /// Đăng xuất user hiện tại.
  Future<void> signOut() async {
    try {
      await _repository.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } on NetworkError catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.userMessage,
      );
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
