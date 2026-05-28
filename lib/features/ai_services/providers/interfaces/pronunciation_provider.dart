import 'dart:typed_data';

import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';

/// Mức độ chi tiết của kết quả pronunciation.
enum PronunciationDetail { phonemeLevel, wordLevel }

/// Kết quả pronunciation kèm metadata.
class PronunciationResponse {
  const PronunciationResponse({
    required this.result,
    required this.detail,
    required this.providerId,
  });

  final PronunciationResult result;
  final PronunciationDetail detail;
  final String providerId;
}

/// Interface cho Pronunciation Assessment provider.
abstract class PronunciationProvider {
  ProviderInfo get info;

  /// Đánh giá phát âm từ audio bytes + reference text.
  Future<PronunciationResponse> assess({
    required Uint8List audio,
    required String referenceText,
  });
}
