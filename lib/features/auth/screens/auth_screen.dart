import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/auth/providers/auth_provider.dart';
import 'package:speakeng/features/auth/widgets/auth_form_widgets.dart';

/// Provider quản lý trạng thái toggle Login/Register.
final isLoginModeProvider = StateProvider<bool>((ref) => true);

/// Provider cho email input.
final emailProvider = StateProvider<String>((ref) => '');

/// Provider cho password input.
final passwordProvider = StateProvider<String>((ref) => '');

/// Màn hình xác thực (Login/Register).
///
/// Tuân theo Screen Layout Pattern: Scaffold + SafeArea +
/// Padding(horizontal: AppSpacing.md) + Column(Expanded + fixed bottom).
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLogin = ref.watch(isLoginModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _buildContent(isLogin, authState, ref),
                ),
              ),
              AuthSubmitButton(isLogin: isLogin, authState: authState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isLogin, AuthState authState, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'SpeakEng',
          style: AppTypography.h1.copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Luyện phát âm tiếng Anh mỗi ngày',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          isLogin ? 'Đăng nhập' : 'Đăng ký',
          style: AppTypography.h2,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AuthEmailField(),
        const SizedBox(height: AppSpacing.md),
        const AuthPasswordField(),
        if (authState.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          AuthErrorMessage(message: authState.errorMessage!),
        ],
        const SizedBox(height: AppSpacing.md),
        AuthToggleModeButton(isLogin: isLogin),
      ],
    );
  }
}
