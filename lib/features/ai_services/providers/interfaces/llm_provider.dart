import 'package:speakeng/features/ai_services/models/service_types.dart';

/// Interface cho LLM (chat) provider.
abstract class LlmProvider {
  ProviderInfo get info;

  /// Gửi messages + system prompt, nhận response text.
  Future<String> chat({
    required List<Map<String, String>> messages,
    required String systemPrompt,
  });
}
