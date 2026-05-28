import 'package:flutter/material.dart';

/// Fade in + slide up animation (from 20px below), 300ms easeOut.
class AnimatedScoreReveal extends StatefulWidget {
  const AnimatedScoreReveal({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedScoreReveal> createState() => _AnimatedScoreRevealState();
}

class _AnimatedScoreRevealState extends State<AnimatedScoreReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // ~20px below
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}
