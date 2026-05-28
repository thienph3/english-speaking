import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/core/api_call_helper.dart';
import 'package:speakeng/core/constants.dart';
import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/llm_provider.dart';

/// LLM provider gọi Supabase Edge Function /chat.
class SupabaseLlmProvider implements LlmProvider {
  SupabaseLlmProvider(this._supabase);

  final SupabaseClient _supabase;

  @override
  ProviderInfo get info => const ProviderInfo(
        id: 'supabase_llm',
        serviceType: ServiceType.llm,
        connectionType: ConnectionType.online,
        qualityRank: 0,
      );

  @override
  Future<String> chat({
    required List<Map<String, String>> messages,
    required String systemPrompt,
  }) async {
    return ApiCallHelper.execute(() async {
      final response = await _supabase.functions
          .invoke('chat', body: {
            'messages': messages,
            'scenario': {'system_prompt': systemPrompt},
          })
          .timeout(AppConstants.apiTimeoutDuration);

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      final message = choices[0]['message'] as Map<String, dynamic>;
      return message['content'] as String;
    });
  }
}
