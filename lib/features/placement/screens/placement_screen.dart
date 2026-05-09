import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:speakeng/core/router.dart';
import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/placement/providers/placement_provider.dart';
import 'package:speakeng/shared/services/audio_service.dart';
import 'package:speakeng/shared/widgets/recording_button.dart';

/// Màn hình Mini Placement Test.
///
/// Hiển thị 3 câu tuần tự (easy → medium → hard).
/// Mỗi câu: hiển thị text → user ghi âm → gửi /pronounce → hiển thị score.
/// Sau 3 câu: tính level, lưu Supabase, chuyển sang daily flow.
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  late final AudioService _audioService;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placementProvider);

    ref.listen<PlacementState>(placementProvider, (prev, next) {
      if (next.status == PlacementStatus.completed) {
        ref.read(placementCompletedProvider.notifier).state = true;
        context.go('/');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra trình độ'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _buildBody(state),
        ),
      ),
    );
  }

  Widget _buildBody(PlacementState state) {
    return switch (state.status) {
      PlacementStatus.loading => _buildLoading(),
      PlacementStatus.error => _buildError(state),
      PlacementStatus.completed => _buildCompleted(state),
      _ => _buildTestContent(state),
    };
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(PlacementState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state.errorMessage ?? 'Đã xảy ra lỗi.',
            style: AppTypography.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => ref.read(placementProvider.notifier).retry(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestContent(PlacementState state) {
    return Column(
      children: [
        _buildProgress(state),
        const SizedBox(height: AppSpacing.xl),
        _buildSentenceCard(state),
        const Spacer(),
        _buildActionArea(state),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildProgress(PlacementState state) {
    final total = state.sentences.length;
    final current = state.currentIndex + 1;
    return Column(
      children: [
        Text(
          'Câu $current / $total',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: current / total,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildSentenceCard(PlacementState state) {
    if (state.sentences.isEmpty) return const SizedBox.shrink();
    final sentence = state.sentences[state.currentIndex];
    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _buildDifficultyBadge(sentence.difficulty),
            const SizedBox(height: AppSpacing.md),
            Text(
              sentence.text,
              style: AppTypography.sentence,
              textAlign: TextAlign.center,
            ),
            if (state.status == PlacementStatus.showingScore) ...[
              const SizedBox(height: AppSpacing.md),
              _buildScoreDisplay(state.currentScore ?? 0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    final color = switch (difficulty) {
      'easy' => AppColors.correct,
      'medium' => AppColors.needsWork,
      'hard' => AppColors.wrong,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: AppTypography.label.copyWith(color: color),
      ),
    );
  }

  Widget _buildScoreDisplay(double score) {
    final color = score >= 80
        ? AppColors.correct
        : score >= 50
            ? AppColors.needsWork
            : AppColors.wrong;
    return Text(
      '${score.toStringAsFixed(0)}%',
      style: AppTypography.h1.copyWith(color: color),
    );
  }

  Widget _buildActionArea(PlacementState state) {
    if (state.status == PlacementStatus.showingScore) {
      return ElevatedButton(
        onPressed: () => ref.read(placementProvider.notifier).nextSentence(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
        child: const Text('Tiếp tục', style: AppTypography.button),
      );
    }
    if (state.status == PlacementStatus.processing) {
      return const CircularProgressIndicator();
    }
    return Column(
      children: [
        Text(
          'Đọc to câu trên',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        RecordingButton(
          state: state.status == PlacementStatus.recording
              ? RecordingButtonState.recording
              : RecordingButtonState.idle,
          onPressed: _handleRecordPress,
        ),
      ],
    );
  }

  Widget _buildCompleted(PlacementState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 64, color: AppColors.success),
          const SizedBox(height: AppSpacing.md),
          Text('Hoàn thành!', style: AppTypography.h1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Trình độ: ${_levelLabel(state.level ?? '')}',
            style: AppTypography.bodyLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _handleRecordPress() async {
    final notifier = ref.read(placementProvider.notifier);
    final currentState = ref.read(placementProvider);

    if (currentState.status == PlacementStatus.recording) {
      final path = await _audioService.stopRecording();
      if (path != null) {
        await notifier.submitRecording(path);
      }
    } else {
      _recordingPath = '/tmp/placement_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioService.startRecording(_recordingPath!);
      notifier.startRecording();
    }
  }

  String _levelLabel(String level) {
    return switch (level) {
      'easy' => 'Cơ bản',
      'easy_medium' => 'Cơ bản - Trung bình',
      'medium_hard' => 'Trung bình - Nâng cao',
      _ => level,
    };
  }
}
