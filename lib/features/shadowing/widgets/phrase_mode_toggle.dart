import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';

/// Toggle button cho chế độ luyện theo cụm từ.
///
/// Chỉ hiển thị khi câu có > 5 từ (supportsPhrasePractice).
/// Hiển thị "Luyện theo cụm từ" với icon và trạng thái on/off.
class PhraseModeToggle extends StatelessWidget {
  const PhraseModeToggle({
    super.key,
    required this.isEnabled,
    required this.onToggle,
  });

  final bool isEnabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primaryLight : AppColors.surfaceVariant,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: isEnabled ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.segment,
              size: 18,
              color: isEnabled
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Luyện theo cụm từ',
              style: AppTypography.bodyMedium.copyWith(
                color: isEnabled
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight:
                    isEnabled ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
