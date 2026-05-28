import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/core/api_call_helper.dart';
import 'package:speakeng/core/constants.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/stt_provider.dart';

/// STT provider gọi Supabase Edge Function /transcribe.
class SupabaseSttProvider implements SttProvider {
  SupabaseSttProvider(this._supabase);

  final SupabaseClient _supabase;

  @override
  ProviderInfo get info => const ProviderInfo(
        id: 'supabase_stt',
        serviceType: ServiceType.stt,
        connectionType: ConnectionType.online,
        quotaLimit: 18000, // 300 phút = 18000 giây
        quotaCycle: QuotaCycle.monthly,
        qualityRank: 0,
      );

  @override
  Future<String> transcribe(Uint8List audio) async {
    return ApiCallHelper.execute(() async {
      final response = await _supabase.functions
          .invoke('transcribe', body: {'audio': audio.toList()})
          .timeout(AppConstants.apiTimeoutDuration);

      final data = response.data as Map<String, dynamic>;
      return data['text'] as String;
    });
  }
}
