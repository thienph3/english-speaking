import 'package:speakeng/features/ai_services/providers/interfaces/has_provider_info.dart';

/// Interface cho LLM (chat) provider.
abstract class LlmProvider extends HasProviderInfo {

  /// Gửi messages + system prompt, nhận response text.
  Future<String> chat({
    required List<Map<String, String>> messages,
    required String systemPrompt,
  });
}
