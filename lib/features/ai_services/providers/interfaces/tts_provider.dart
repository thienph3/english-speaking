import 'dart:typed_data';

import 'package:speakeng/features/ai_services/providers/interfaces/has_provider_info.dart';

/// Interface cho TTS provider.
///
/// Mỗi implementation (ElevenLabs, OpenAI, Kokoro offline...)
/// phải implement interface này.
abstract class TtsProvider extends HasProviderInfo {

  /// Chuyển text thành audio bytes.
  Future<Uint8List> synthesize(String text);
}
