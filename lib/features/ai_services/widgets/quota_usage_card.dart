import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/ai_services/providers/orchestrator_provider.dart';

/// Hiển thị quota usage cho các online providers.
class QuotaUsageCard extends ConsumerWidget {
  const QuotaUsageCard({super.key});

  static const _providers = [
    ('TTS', 'supabase_tts', 10000),
    ('STT', 'supabase_stt', 18000),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.read(quotaTrackerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quota sử dụng', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            ..._providers.map((p) => _QuotaRow(
                  label: p.$1,
                  used: tracker.getUsage(p.$2),
                  limit: p.$3,
                )),
          ],
        ),
      ),
    );
  }
}

class _QuotaRow extends StatelessWidget {
  const _QuotaRow({
    required this.label,
    required this.used,
    required this.limit,
  });

  final String label;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final ratio = (used / limit).clamp(0.0, 1.0);
    final isNear = ratio >= 0.8;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.bodyMedium),
              Text(
                '$used / $limit',
                style: AppTypography.bodySmall.copyWith(
                  color: isNear ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: ratio,
            color: isNear ? AppColors.error : AppColors.primary,
            backgroundColor: AppColors.surfaceVariant,
          ),
        ],
      ),
    );
  }
}
