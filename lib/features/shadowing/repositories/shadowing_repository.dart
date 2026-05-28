import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/features/ai_services/providers/interfaces/pronunciation_provider.dart';
import 'package:speakeng/features/ai_services/providers/orchestrator_provider.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';

/// Provider cho [ShadowingRepository].
final shadowingRepositoryProvider = Provider<ShadowingRepository>((ref) {
  return ShadowingRepository(ref.watch(orchestratorProvider));
});

/// Repository gọi Orchestrator để đánh giá phát âm.
///
/// Orchestrator tự động chọn provider phù hợp (Azure Speech online
/// hoặc wav2vec2 offline) dựa trên connectivity và strategy.
class ShadowingRepository {
  ShadowingRepository(this._orchestrator);

  final AiOrchestrator _orchestrator;

  /// Gửi audio đến Orchestrator và trả về kết quả pronunciation.
  ///
  /// [audioPath] — đường dẫn file WAV đã ghi.
  /// [referenceText] — câu gốc để so sánh.
  Future<PronunciationResult> pronounce({
    required String audioPath,
    required String referenceText,
  }) async {
    final audioBytes = await File(audioPath).readAsBytes();

    final response = await _orchestrator.assess(
      audio: audioBytes,
      referenceText: referenceText,
    );

    return response.result;
  }

  /// Kiểm tra kết quả có phoneme-level detail không.
  ///
  /// Nếu dùng offline provider (wav2vec2), chỉ có word-level.
  Future<PronunciationResponse> pronounceWithDetail({
    required String audioPath,
    required String referenceText,
  }) async {
    final audioBytes = await File(audioPath).readAsBytes();

    return _orchestrator.assess(
      audio: audioBytes,
      referenceText: referenceText,
    );
  }
}
