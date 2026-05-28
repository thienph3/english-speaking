import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/core/api_call_helper.dart';
import 'package:speakeng/core/constants.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/pronunciation_provider.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';

/// Pronunciation provider gọi Supabase Edge Function /pronounce (Azure Speech).
class SupabasePronunciationProvider implements PronunciationProvider {
  SupabasePronunciationProvider(this._supabase);

  final SupabaseClient _supabase;

  @override
  ProviderInfo get info => const ProviderInfo(
        id: 'supabase_pronunciation',
        serviceType: ServiceType.pronunciation,
        connectionType: ConnectionType.online,
        quotaLimit: 500000,
        quotaCycle: QuotaCycle.monthly,
        qualityRank: 0,
      );

  @override
  Future<PronunciationResponse> assess({
    required Uint8List audio,
    required String referenceText,
  }) async {
    return ApiCallHelper.execute(() async {
      final response = await _supabase.functions
          .invoke('pronounce', body: {
            'audio': audio.toList(),
            'reference_text': referenceText,
          })
          .timeout(AppConstants.apiTimeoutDuration);

      final data = response.data as Map<String, dynamic>;
      final result = _parseResponse(data);

      return PronunciationResponse(
        result: result,
        detail: PronunciationDetail.phonemeLevel,
        providerId: info.id,
      );
    });
  }

  PronunciationResult _parseResponse(Map<String, dynamic> data) {
    final nBest = (data['NBest'] as List).first as Map<String, dynamic>;
    final assessment =
        nBest['PronunciationAssessment'] as Map<String, dynamic>;
    final wordsJson = nBest['Words'] as List;

    return PronunciationResult(
      accuracyScore: (assessment['AccuracyScore'] as num).toDouble(),
      fluencyScore: (assessment['FluencyScore'] as num).toDouble(),
      completenessScore: (assessment['CompletenessScore'] as num).toDouble(),
      words: wordsJson.map(_parseWord).toList(),
    );
  }

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
