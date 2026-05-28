import 'dart:typed_data';

import 'package:speakeng/features/ai_services/providers/interfaces/has_provider_info.dart';

/// Interface cho STT (Speech-to-Text) provider.
abstract class SttProvider extends HasProviderInfo {

  /// Chuyển audio bytes thành text transcript.
  Future<String> transcribe(Uint8List audio);
}
