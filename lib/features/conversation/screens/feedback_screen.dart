import 'package:flutter/material.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/conversation/logic/response_time_calculator.dart';
import 'package:speakeng/features/conversation/logic/target_phrase_detector.dart';
import 'package:speakeng/features/conversation/models/conversation_feedback.dart';
import 'package:speakeng/features/conversation/widgets/feedback_cards.dart';

/// Màn hình hiển thị feedback sau hội thoại AI.
///
/// Hiển thị: grammar_errors, vocabulary_suggestions,
/// positive, improve, target_phrases usage, avg response time.
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({
    super.key,
    required this.feedback,
    required this.targetPhrases,
    required this.userTranscripts,
    required this.responseTimes,
    this.onDone,
  });

  final ConversationFeedback feedback;
  final List<String> targetPhrases;
  final List<String> userTranscripts;
  final List<int> responseTimes;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final combinedTranscript = userTranscripts.join(' ');
    final phraseUsage = TargetPhraseDetector.detectUsage(
      combinedTranscript,
      targetPhrases,
    );
    final avgTime = ResponseTimeCalculator.average(responseTimes);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(elevation: 0, title: const Text('Phản hồi hội thoại')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _buildSections(phraseUsage, avgTime),
                ),
              ),
              _buildDoneButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSections(Map<String, bool> phraseUsage, double avgTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        if (feedback.positive.isNotEmpty)
          FeedbackCard(
            icon: '✅',
            title: 'Điểm tốt',
            content: feedback.positive,
            color: AppColors.success,
          ),
        const SizedBox(height: AppSpacing.md),
        if (feedback.improve.isNotEmpty)
          FeedbackCard(
            icon: '💡',
            title: 'Cần cải thiện',
            content: feedback.improve,
            color: AppColors.needsWork,
          ),
        const SizedBox(height: AppSpacing.md),
        if (feedback.grammarErrors.isNotEmpty)
          FeedbackListCard(
            icon: '📝',
            title: 'Lỗi ngữ pháp',
            items: feedback.grammarErrors,
            color: AppColors.wrong,
          ),
        const SizedBox(height: AppSpacing.md),
        if (feedback.vocabularySuggestions.isNotEmpty)
          FeedbackListCard(
            icon: '📚',
            title: 'Gợi ý từ vựng',
            items: feedback.vocabularySuggestions,
            color: AppColors.primary,
          ),
        const SizedBox(height: AppSpacing.md),
        if (targetPhrases.isNotEmpty)
          PhraseUsageCard(usage: phraseUsage),
        const SizedBox(height: AppSpacing.md),
        FeedbackCard(
          icon: '⏱️',
          title: 'Thời gian phản hồi TB',
          content: '${(avgTime / 1000).toStringAsFixed(1)}s',
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildDoneButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
          ),
          child: const Text('Hoàn thành', style: AppTypography.button),
        ),
      ),
    );
  }
}
