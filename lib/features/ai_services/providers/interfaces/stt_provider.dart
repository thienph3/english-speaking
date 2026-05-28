import 'dart:typed_data';

import 'package:speakeng/features/ai_services/models/service_types.dart';

/// Interface cho STT (Speech-to-Text) provider.
abstract class SttProvider {
  ProviderInfo get info;

  /// Chuyển audio bytes thành text transcript.
  Future<String> transcribe(Uint8List audio);
}
