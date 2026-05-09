import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';

/// Chat bubble hiển thị tin nhắn trong conversation.
///
/// - AI messages: left-aligned, surfaceVariant background
/// - User messages: right-aligned, primaryLight background
/// - Max width: 80% of screen width
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  /// Nội dung tin nhắn.
  final String text;

  /// True nếu là tin nhắn của user, false nếu là AI.
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryLight : AppColors.surfaceVariant,
          borderRadius: AppRadius.lg,
        ),
        child: Text(
          text,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
