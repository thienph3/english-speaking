import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/progress/providers/progress_provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressProvider.notifier).loadProgress();
    });
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
          _buildMasteredCard(state),
          const SizedBox(height: AppSpacing.md),
          _buildAccuracyCard(state),
          const SizedBox(height: AppSpacing.md),
          _buildResponseTimeCard(state),
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
