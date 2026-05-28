import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/tts_provider.dart';
import 'package:speakeng/features/ai_services/services/model_manager.dart';
import 'package:speakeng/shared/services/wav_codec.dart';

/// Offline TTS provider dùng sherpa_onnx với Piper VITS model.
///
/// Model: en_US-lessac-medium (~30MB).
/// Cần gọi [initialize] trước khi dùng [synthesize].
class SherpaOnnxTtsProvider implements TtsProvider {
  SherpaOnnxTtsProvider(this._modelManager);

  final ModelManager _modelManager;
  sherpa.OfflineTts? _tts;

  @override
  ProviderInfo get info => ProviderInfo(
        id: 'sherpa_tts',
        serviceType: ServiceType.tts,
        connectionType: ConnectionType.offline,
        qualityRank: 1,
      );

  /// Khởi tạo TTS engine với model files đã download.
  Future<void> initialize() async {
    if (_tts != null) return;

    final modelPath = await _modelManager.getModelPath(
      ModelManager.ttsModelFiles[0],
    );
    final tokensPath = await _modelManager.getModelPath(
      ModelManager.ttsModelFiles[1],
    );
    final dataDir = await _modelManager.getModelPath(
      ModelManager.ttsModelFiles[2],
    );

    final config = sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        vits: sherpa.OfflineTtsVitsModelConfig(
          model: modelPath,
          tokens: tokensPath,
          dataDir: dataDir,
        ),
        numThreads: 2,
        debug: false,
      ),
    );

    _tts = sherpa.OfflineTts(config);
  }

  @override
  Future<Uint8List> synthesize(String text) async {
    if (_tts == null) await initialize();

    final audio = _tts!.generate(text: text, speed: 1.0);
    return WavCodec.encode(audio.samples, audio.sampleRate);
  }

  /// Giải phóng native resources.
  void dispose() {
    _tts?.free();
    _tts = null;
  }
}
