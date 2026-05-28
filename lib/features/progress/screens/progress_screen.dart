import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/conversation/repositories/feedback_repository.dart';
import 'package:speakeng/features/progress/providers/progress_provider.dart';
import 'package:speakeng/features/progress/widgets/before_after_player.dart';
import 'package:speakeng/features/progress/widgets/sentence_list_card.dart';
import 'package:speakeng/shared/services/audio_service.dart';
import 'package:speakeng/shared/widgets/empty_state.dart';

/// Màn hình Progress Dashboard.
///
/// Hiển thị: sentences mastered, avg accuracy, avg response time,
/// so sánh tuần này vs tuần trước.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  final _audioService = AudioService();
  String? _currentlyPlaying;
  String? _beforeUrl;
  String? _afterUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressProvider.notifier).loadProgress();
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(elevation: 0, title: const Text('Tiến bộ')),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(state),
      ),
    );
  }

  Widget _buildContent(ProgressState state) {
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, style: AppTypography.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () =>
                  ref.read(progressProvider.notifier).loadProgress(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.sentencesMastered == 0)
            const EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Chưa có dữ liệu',
              subtitle: 'Hoàn thành bài luyện đầu tiên để xem tiến bộ!',
            )
          else ...[
            _buildMasteredCard(state),
            const SizedBox(height: AppSpacing.md),
            _buildAccuracyCard(state),
            const SizedBox(height: AppSpacing.md),
            _buildResponseTimeCard(state),
          ],
          const SizedBox(height: AppSpacing.lg),
          const SentenceListCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildFeedbackHistoryButton(),
          const SizedBox(height: AppSpacing.lg),
          _buildBeforeAfterSection(),
        ],
      ),
    );
  }

  Widget _buildMasteredCard(ProgressState state) {
    return _MetricCard(
      icon: '🏆',
      title: 'Câu đã master',
      value: '${state.sentencesMastered}',
      subtitle: 'trên 100 câu',
    );
  }

  Widget _buildAccuracyCard(ProgressState state) {
    final thisWeek = state.thisWeekAvgAccuracy;
    final lastWeek = state.lastWeekAvgAccuracy;
    final diff = thisWeek - lastWeek;

    return _MetricCard(
      icon: '🎯',
      title: 'Accuracy TB',
      value: '${thisWeek.toStringAsFixed(0)}%',
      subtitle: _buildDiffText(diff, '%'),
      diffPositive: diff >= 0,
    );
  }

  Widget _buildResponseTimeCard(ProgressState state) {
    final thisWeek = state.thisWeekAvgResponseTime / 1000;
    final lastWeek = state.lastWeekAvgResponseTime / 1000;
    final diff = thisWeek - lastWeek;

    return _MetricCard(
      icon: '⏱️',
      title: 'Response time TB',
      value: '${thisWeek.toStringAsFixed(1)}s',
      subtitle: _buildDiffText(-diff, 's'),
      diffPositive: diff <= 0,
    );
  }

  String _buildDiffText(double diff, String unit) {
    if (diff == 0) return 'Không thay đổi so với tuần trước';
    final sign = diff > 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)}$unit so với tuần trước';
  }

  Widget _buildFeedbackHistoryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final feedbacks =
              await ref.read(savedFeedbacksProvider.future);
          if (!mounted) return;
          if (feedbacks.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chưa có feedback nào.')),
            );
            return;
          }
          context.push('/feedback', extra: {
            'feedback': feedbacks.last,
            'targetPhrases': <String>[],
            'userTranscripts': <String>[],
            'responseTimes': <int>[],
          });
        },
        icon: const Icon(Icons.history),
        label: const Text('Lịch sử feedback'),
      ),
    );
  }

  Widget _buildBeforeAfterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🎧 So sánh trước / sau', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        BeforeAfterPlayer(
          beforeUrl: _beforeUrl,
          afterUrl: _afterUrl,
          currentlyPlaying: _currentlyPlaying,
          onPlayBefore: _beforeUrl != null ? () => _play('before') : null,
          onPlayAfter: _afterUrl != null ? () => _play('after') : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_beforeUrl == null && _afterUrl == null)
          Text(
            'Bản ghi sẽ xuất hiện khi bạn master câu đầu tiên',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Future<void> _play(String which) async {
    if (_currentlyPlaying == which) {
      await _audioService.stop();
      setState(() => _currentlyPlaying = null);
      return;
    }
    final url = which == 'before' ? _beforeUrl! : _afterUrl!;
    await _audioService.loadUrl(url);
    await _audioService.play();
    setState(() => _currentlyPlaying = which);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.diffPositive,
  });

  final String icon;
  final String title;
  final String value;
  final String subtitle;
  final bool? diffPositive;

  @override
  Widget build(BuildContext context) {
    final subtitleColor = diffPositive == null
        ? AppColors.textSecondary
        : diffPositive!
            ? AppColors.success
            : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon $title', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.h1),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }
}
