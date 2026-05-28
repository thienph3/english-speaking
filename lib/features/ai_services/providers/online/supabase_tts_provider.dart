import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/core/constants.dart';
import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/tts_provider.dart';

/// TTS provider gọi Supabase Edge Function /tts (ElevenLabs + OpenAI fallback).
class SupabaseTtsProvider implements TtsProvider {
  SupabaseTtsProvider(this._supabase);

  final SupabaseClient _supabase;

  @override
  ProviderInfo get info => const ProviderInfo(
        id: 'supabase_tts',
        serviceType: ServiceType.tts,
        connectionType: ConnectionType.online,
        quotaLimit: 10000,
        quotaCycle: QuotaCycle.monthly,
        qualityRank: 0,
      );

  @override
  Future<Uint8List> synthesize(String text) async {
    try {
      final response = await _supabase.functions
          .invoke('tts', body: {'text': text})
          .timeout(AppConstants.apiTimeoutDuration);

      return Uint8List.fromList(response.data as List<int>);
    } on TimeoutException {
      throw const ApiTimeoutError();
    } on SocketException {
      throw const NetworkError();
    }
  }
}
