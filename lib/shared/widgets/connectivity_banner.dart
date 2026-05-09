import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';

/// Banner hiển thị khi mất kết nối internet.
///
/// Đặt ở top của screen, hiển thị thông báo offline
/// và vô hiệu hóa các tính năng cần mạng.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({
    super.key,
    required this.isOffline,
    this.message = 'Mất kết nối internet',
  });

  /// Có đang offline không.
  final bool isOffline;

  /// Thông báo hiển thị.
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.error,
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            color: AppColors.textOnPrimary,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
