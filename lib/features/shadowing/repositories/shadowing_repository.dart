import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/core/constants.dart';
import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';
import 'package:speakeng/shared/services/supabase_service.dart';

/// Provider cho [ShadowingRepository].
final shadowingRepositoryProvider = Provider<ShadowingRepository>((ref) {
  return ShadowingRepository(ref.read(supabaseProvider));
});

/// Repository gọi Edge Function /pronounce để đánh giá phát âm.
///
/// Gửi audio file + reference_text dưới dạng FormData,
/// parse response thành [PronunciationResult].
class ShadowingRepository {
  ShadowingRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Gửi audio đến Edge Function /pronounce và trả về kết quả.
  ///
  /// Throws [ApiTimeoutError] nếu timeout > 10 giây.
  /// Throws [NetworkError] nếu mất kết nối.
  Future<PronunciationResult> pronounce({
    required String audioPath,
    required String referenceText,
  }) async {
    try {
      final audioBytes = await File(audioPath).readAsBytes();

      final response = await _supabase.functions
          .invoke(
            'pronounce',
            body: {
              'audio': audioBytes,
              'reference_text': referenceText,
            },
          )
          .timeout(AppConstants.apiTimeoutDuration);

      return _parseResponse(response.data as Map<String, dynamic>);
    } on TimeoutException {
      throw const ApiTimeoutError();
    } on SocketException {
      throw const NetworkError();
    }
  }

  /// Parse Azure Speech response thành [PronunciationResult].
  PronunciationResult _parseResponse(Map<String, dynamic> data) {
    final nBest = (data['NBest'] as List).first as Map<String, dynamic>;
    final assessment =
        nBest['PronunciationAssessment'] as Map<String, dynamic>;
    final wordsJson = nBest['Words'] as List;

    return PronunciationResult(
      accuracyScore: (assessment['AccuracyScore'] as num).toDouble(),
      fluencyScore: (assessment['FluencyScore'] as num).toDouble(),
      completenessScore:
          (assessment['CompletenessScore'] as num).toDouble(),
      words: wordsJson.map(_parseWord).toList(),
    );
  }

  /// Parse một word từ Azure response.
  WordResult _parseWord(dynamic wordJson) {
    final word = wordJson as Map<String, dynamic>;
    final assessment =
        word['PronunciationAssessment'] as Map<String, dynamic>;
    final phonemesJson = (word['Phonemes'] as List?) ?? [];

    return WordResult(
      word: word['Word'] as String,
      accuracyScore: (assessment['AccuracyScore'] as num).toDouble(),
      errorType: assessment['ErrorType'] as String?,
      phonemes: phonemesJson.map(_parsePhoneme).toList(),
    );
  }

  /// Parse một phoneme từ Azure response.
  PhonemeResult _parsePhoneme(dynamic phonemeJson) {
    final phoneme = phonemeJson as Map<String, dynamic>;
    final assessment =
        phoneme['PronunciationAssessment'] as Map<String, dynamic>;

    return PhonemeResult(
      phoneme: phoneme['Phoneme'] as String,
      accuracyScore: (assessment['AccuracyScore'] as num).toDouble(),
    );
  }
}
