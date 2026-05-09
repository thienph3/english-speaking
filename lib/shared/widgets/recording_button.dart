import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';

/// Trạng thái của nút ghi âm.
enum RecordingButtonState { idle, recording, disabled }

/// Nút ghi âm 72x72 circular với 3 trạng thái:
/// - [idle]: màu xanh primary, sẵn sàng ghi
/// - [recording]: màu đỏ + pulse animation
/// - [disabled]: màu xám, không tương tác được
class RecordingButton extends StatefulWidget {
  const RecordingButton({
    super.key,
    required this.state,
    required this.onPressed,
  });

  final RecordingButtonState state;
  final VoidCallback? onPressed;

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant RecordingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.state == RecordingButtonState.recording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncPulse();
    return Semantics(
      label: _semanticLabel,
      button: true,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: 72,
      height: 72,
      child: ElevatedButton(
        onPressed: _isEnabled ? widget.onPressed : null,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: _backgroundColor,
          disabledBackgroundColor: AppColors.missed,
          padding: EdgeInsets.zero,
        ),
        child: Icon(Icons.mic, color: AppColors.textOnPrimary, size: 32),
      ),
    );
  }

  bool get _isEnabled =>
      widget.state != RecordingButtonState.disabled;

  Color get _backgroundColor {
    return switch (widget.state) {
      RecordingButtonState.idle => AppColors.primary,
      RecordingButtonState.recording => AppColors.error,
      RecordingButtonState.disabled => AppColors.missed,
    };
  }

  String get _semanticLabel {
    return switch (widget.state) {
      RecordingButtonState.idle => 'Nhấn để ghi âm',
      RecordingButtonState.recording => 'Đang ghi âm, nhấn để dừng',
      RecordingButtonState.disabled => 'Nút ghi âm không khả dụng',
    };
  }
}
