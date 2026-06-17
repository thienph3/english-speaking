import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:speakeng/core/router.dart';
import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/placement/providers/placement_provider.dart';
import 'package:speakeng/features/placement/widgets/placement_widgets.dart';
import 'package:speakeng/shared/services/audio_service.dart';

/// Màn hình Mini Placement Test.
///
/// 3 câu tuần tự (easy → medium → hard) → tính level → lưu → chuyển daily flow.
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  late final AudioService _audioService;

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
      PlacementStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
      PlacementStatus.error => _buildError(state),
      PlacementStatus.completed => _buildCompleted(state),
      _ => _buildTestContent(state),
    };
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
    if (state.sentences.isEmpty) return const SizedBox.shrink();
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
        const SizedBox(height: AppSpacing.xl),
        PlacementSentenceCard(
          sentence: state.sentences[state.currentIndex],
          status: state.status,
          score: state.currentScore,
        ),
        const Spacer(),
        PlacementActionArea(
          status: state.status,
          onRecord: _handleRecordPress,
          onNext: () => ref.read(placementProvider.notifier).nextSentence(),
        ),
        const SizedBox(height: AppSpacing.lg),
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
      if (path != null) await notifier.submitRecording(path);
    } else {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/placement_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioService.startRecording(path);
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
