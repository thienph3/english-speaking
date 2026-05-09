import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/auth/providers/auth_provider.dart';
import 'package:speakeng/features/auth/screens/auth_screen.dart';

/// TextField cho email input.
class AuthEmailField extends ConsumerWidget {
  const AuthEmailField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (v) => ref.read(emailProvider.notifier).state = v,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'example@email.com',
        border: OutlineInputBorder(borderRadius: AppRadius.sm),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }
}

/// TextField cho password input.
class AuthPasswordField extends ConsumerWidget {
  const AuthPasswordField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (v) => ref.read(passwordProvider.notifier).state = v,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Mật khẩu',
        hintText: 'Ít nhất 6 ký tự',
        border: OutlineInputBorder(borderRadius: AppRadius.sm),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }
}

/// Hiển thị thông báo lỗi xác thực.
class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút toggle giữa Login và Register mode.
class AuthToggleModeButton extends ConsumerWidget {
  const AuthToggleModeButton({super.key, required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () {
        ref.read(isLoginModeProvider.notifier).state = !isLogin;
      },
      child: Text(
        isLogin
            ? 'Chưa có tài khoản? Đăng ký'
            : 'Đã có tài khoản? Đăng nhập',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
      ),
    );
  }
}

/// Nút submit (Đăng nhập/Đăng ký) cố định ở bottom.
class AuthSubmitButton extends ConsumerWidget {
  const AuthSubmitButton({
    super.key,
    required this.isLogin,
    required this.authState,
  });

  final bool isLogin;
  final AuthState authState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = authState.status == AuthStatus.loading;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: isLoading ? null : () => _submit(ref),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : Text(
                  isLogin ? 'Đăng nhập' : 'Đăng ký',
                  style: AppTypography.button.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
        ),
      ),
    );
  }

  void _submit(WidgetRef ref) {
    final email = ref.read(emailProvider).trim();
    final password = ref.read(passwordProvider).trim();

    if (isLogin) {
      ref.read(authProvider.notifier).signIn(email: email, password: password);
    } else {
      ref.read(authProvider.notifier).signUp(email: email, password: password);
    }
  }
}
