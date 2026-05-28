import 'dart:typed_data';

import 'package:speakeng/features/ai_services/models/service_types.dart';

/// Interface cho TTS provider.
///
/// Mỗi implementation (ElevenLabs, OpenAI, Kokoro offline...)
/// phải implement interface này.
abstract class TtsProvider {
  ProviderInfo get info;

  /// Chuyển text thành audio bytes.
  Future<Uint8List> synthesize(String text);
}
