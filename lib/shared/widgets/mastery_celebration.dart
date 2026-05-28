import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';

/// Shows a celebration animation when mastery is achieved.
/// Auto-dismisses after 2 seconds via [onDone] callback.
class MasteryCelebration extends StatefulWidget {
  const MasteryCelebration({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<MasteryCelebration> createState() => _MasteryCelebrationState();
}

class _MasteryCelebrationState extends State<MasteryCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đã master! 🎉',
            style: AppTypography.h2.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
