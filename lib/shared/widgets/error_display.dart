import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';

/// Widget hiển thị lỗi với nút retry.
///
/// Reusable across tất cả screens khi có lỗi xảy ra.
/// Hiển thị icon, message, và optional retry button.
class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Thông báo lỗi hiển thị cho user.
  final String message;

  /// Callback khi user nhấn nút retry. Null = ẩn nút.
  final VoidCallback? onRetry;

  /// Icon hiển thị phía trên message.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.md,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
