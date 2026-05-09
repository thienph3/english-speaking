import 'package:flutter/material.dart';

import 'package:speakeng/core/constants.dart';
import 'package:speakeng/core/theme.dart';

/// Compact speed selector widget cho audio playback.
///
/// Hiển thị SegmentedButton với 3 tốc độ (0.7x, 1.0x, 1.2x).
/// Stateless — nhận [currentSpeed] và [onChanged] qua constructor.
///
/// Sử dụng [AppConstants.speedOptions] cho danh sách tốc độ.
class SpeedSelector extends StatelessWidget {
  const SpeedSelector({
    super.key,
    required this.currentSpeed,
    required this.onChanged,
  });

  /// Tốc độ hiện tại đang được chọn.
  final double currentSpeed;

  /// Callback khi user chọn tốc độ mới.
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<double>(
      segments: AppConstants.speedOptions
          .map(
            (speed) => ButtonSegment<double>(
              value: speed,
              label: Text(
                '${speed}x',
                style: AppTypography.label.copyWith(
                  color: speed == currentSpeed
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          )
          .toList(),
      selected: {currentSpeed},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) {
          onChanged(selected.first);
        }
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surfaceVariant;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textOnPrimary;
          }
          return AppColors.textSecondary;
        }),
        side: WidgetStateProperty.all(BorderSide.none),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        minimumSize: WidgetStateProperty.all(const Size(48, 32)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
