import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';

/// Widget hiển thị 2 nút phát audio Before / After cạnh nhau.
///
/// Cho phép User nghe lại bản ghi âm đầu tiên (before) và bản ghi
/// khi đạt mastery (after) để so sánh sự tiến bộ.
class BeforeAfterPlayer extends StatelessWidget {
  /// URL hoặc path của bản ghi "before" (null nếu chưa có).
  final String? beforeUrl;

  /// URL hoặc path của bản ghi "after" (null nếu chưa có).
  final String? afterUrl;

  /// Callback khi nhấn nút Before.
  final VoidCallback? onPlayBefore;

  /// Callback khi nhấn nút After.
  final VoidCallback? onPlayAfter;

  /// Đang phát audio nào ('before', 'after', hoặc null).
  final String? currentlyPlaying;

  const BeforeAfterPlayer({
    super.key,
    this.beforeUrl,
    this.afterUrl,
    this.onPlayBefore,
    this.onPlayAfter,
    this.currentlyPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PlayButton(
            label: 'Before',
            icon: Icons.play_arrow_rounded,
            isAvailable: beforeUrl != null,
            isPlaying: currentlyPlaying == 'before',
            onPressed: onPlayBefore,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _PlayButton(
            label: 'After',
            icon: Icons.play_arrow_rounded,
            isAvailable: afterUrl != null,
            isPlaying: currentlyPlaying == 'after',
            onPressed: onPlayAfter,
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isAvailable;
  final bool isPlaying;
  final VoidCallback? onPressed;

  const _PlayButton({
    required this.label,
    required this.icon,
    required this.isAvailable,
    required this.isPlaying,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAvailable
        ? AppColors.primary
        : AppColors.textSecondary;

    return Semantics(
      label: '$label recording',
      button: true,
      enabled: isAvailable,
      child: Material(
        color: isPlaying
            ? AppColors.primaryLight
            : AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
        child: InkWell(
          onTap: isAvailable ? onPressed : null,
          borderRadius: AppRadius.md,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPlaying ? Icons.pause_rounded : icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.button.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
