import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/core/theme.dart';
import 'package:speakeng/features/ai_services/services/model_manager.dart';

/// Trạng thái download của một model.
enum _DownloadState { notDownloaded, downloading, ready, error }

/// Card hiển thị trạng thái và cho phép download offline model.
class ModelDownloadCard extends ConsumerStatefulWidget {
  const ModelDownloadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.checkReady,
    required this.download,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Future<bool> Function(ModelManager manager) checkReady;
  final Future<void> Function(
    ModelManager manager,
    void Function(double) onProgress,
  ) download;

  @override
  ConsumerState<ModelDownloadCard> createState() => _ModelDownloadCardState();
}

class _ModelDownloadCardState extends ConsumerState<ModelDownloadCard> {
  _DownloadState _state = _DownloadState.notDownloaded;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final manager = ref.read(modelManagerProvider);
    final ready = await widget.checkReady(manager);
    if (mounted) {
      setState(() {
        _state = ready ? _DownloadState.ready : _DownloadState.notDownloaded;
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0;
      _error = null;
    });

    try {
      final manager = ref.read(modelManagerProvider);
      await widget.download(manager, (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) setState(() => _state = _DownloadState.ready);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _state = _DownloadState.error;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(widget.icon, size: 32, color: _iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildInfo()),
            _buildAction(),
          ],
        ),
      ),
    );
  }

  Color get _iconColor => switch (_state) {
        _DownloadState.ready => AppColors.success,
        _DownloadState.error => AppColors.error,
        _ => AppColors.textSecondary,
      };

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: AppTypography.h3),
        const SizedBox(height: 2),
        Text(widget.subtitle, style: AppTypography.bodySmall),
        if (_state == _DownloadState.downloading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _progress),
        ],
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(
            'Lỗi tải xuống. Thử lại?',
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildAction() {
    return switch (_state) {
      _DownloadState.ready => const Icon(
          Icons.check_circle,
          color: AppColors.success,
        ),
      _DownloadState.downloading => const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      _ => IconButton(
          onPressed: _startDownload,
          icon: const Icon(Icons.download),
          tooltip: 'Tải xuống',
        ),
    };
  }
}
