import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/orchestrator_provider.dart';
import 'package:speakeng/features/ai_services/services/connectivity_service.dart';
import 'package:speakeng/features/ai_services/widgets/model_download_card.dart';
import 'package:speakeng/features/ai_services/widgets/quota_usage_card.dart';

/// Màn hình Settings — bật/tắt offline mode và xem trạng thái provider.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineMode = ref.watch(offlineModeProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final strategy = ref.watch(fallbackStrategyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Cài đặt'), elevation: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Trạng thái kết nối
            _ConnectivityCard(isOnline: isOnline),
            const SizedBox(height: 16),

            // Quota usage
            const QuotaUsageCard(),
            const SizedBox(height: 16),

            // Offline mode toggle
            _OfflineToggleCard(
              offlineMode: offlineMode,
              onChanged: (value) {
                ref.read(offlineModeProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),

            // Fallback strategy selector
            _StrategyCard(
              strategy: strategy,
              enabled: !offlineMode,
              onChanged: (value) {
                ref.read(fallbackStrategyProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 24),

            // Offline models section
            const Text(
              'Offline Models',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 8),
            ModelDownloadCard(
              title: 'TTS — Piper English',
              subtitle: '~30 MB • Đọc câu tiếng Anh offline',
              icon: Icons.record_voice_over,
              checkReady: (m) => m.isTtsReady,
              download: (m, onProgress) =>
                  m.downloadTtsModel(onProgress: onProgress),
            ),
            const SizedBox(height: 8),
            ModelDownloadCard(
              title: 'STT — Whisper Tiny',
              subtitle: '~40 MB • Nhận diện giọng nói offline',
              icon: Icons.mic,
              checkReady: (m) => m.isSttReady,
              download: (m, onProgress) =>
                  m.downloadSttModel(onProgress: onProgress),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectivityCard extends StatelessWidget {
  const _ConnectivityCard({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          isOnline ? Icons.wifi : Icons.wifi_off,
          color: isOnline ? AppColors.success : AppColors.error,
        ),
        title: Text(isOnline ? 'Đang kết nối' : 'Không có mạng'),
        subtitle: Text(
          isOnline
              ? 'Sử dụng AI services online'
              : 'Chỉ dùng được offline providers',
        ),
      ),
    );
  }
}

class _OfflineToggleCard extends StatelessWidget {
  const _OfflineToggleCard({
    required this.offlineMode,
    required this.onChanged,
  });
  final bool offlineMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.offline_bolt),
        title: const Text('Chế độ offline'),
        subtitle: const Text(
          'Chỉ sử dụng AI chạy trên thiết bị',
        ),
        value: offlineMode,
        onChanged: onChanged,
      ),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  const _StrategyCard({
    required this.strategy,
    required this.enabled,
    required this.onChanged,
  });
  final FallbackStrategy strategy;
  final bool enabled;
  final ValueChanged<FallbackStrategy> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = FallbackStrategy.values
        .where((s) => s != FallbackStrategy.offlineOnly)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chiến lược chọn provider',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SegmentedButton<FallbackStrategy>(
              segments: options
                  .map((s) => ButtonSegment(
                        value: s,
                        label: Text(_strategyLabel(s)),
                      ))
                  .toList(),
              selected: {strategy},
              onSelectionChanged: enabled
                  ? (selected) => onChanged(selected.first)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              _strategyDesc(strategy),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _strategyLabel(FallbackStrategy s) {
    switch (s) {
      case FallbackStrategy.freeFist:
        return 'Ưu tiên miễn phí';
      case FallbackStrategy.qualityFirst:
        return 'Ưu tiên chất lượng';
      case FallbackStrategy.offlineOnly:
        return 'Chỉ offline';
    }
  }

  String _strategyDesc(FallbackStrategy s) {
    switch (s) {
      case FallbackStrategy.freeFist:
        return 'Dùng free tier trước, trả phí khi hết';
      case FallbackStrategy.qualityFirst:
        return 'Dùng provider tốt nhất bất kể chi phí';
      case FallbackStrategy.offlineOnly:
        return 'Chỉ dùng model trên thiết bị';
    }
  }
}
