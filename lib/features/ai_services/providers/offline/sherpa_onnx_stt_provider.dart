import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/stt_provider.dart';
import 'package:speakeng/features/ai_services/services/model_manager.dart';
import 'package:speakeng/shared/services/wav_codec.dart';

/// Offline STT provider dùng sherpa_onnx với Whisper tiny.en model.
///
/// Model: whisper tiny.en int8 (~40MB).
/// Cần gọi [initialize] trước khi dùng [transcribe].
class SherpaOnnxSttProvider implements SttProvider {
  SherpaOnnxSttProvider(this._modelManager);

  final ModelManager _modelManager;
  sherpa.OfflineRecognizer? _recognizer;

  @override
  ProviderInfo get info => ProviderInfo(
        id: 'sherpa_stt',
        serviceType: ServiceType.stt,
        connectionType: ConnectionType.offline,
        qualityRank: 1,
      );

  /// Khởi tạo STT engine với model files đã download.
  Future<void> initialize() async {
    if (_recognizer != null) return;

    final encoderPath = await _modelManager.getModelPath(
      ModelManager.sttModelFiles[0],
    );
    final decoderPath = await _modelManager.getModelPath(
      ModelManager.sttModelFiles[1],
    );
    final tokensPath = await _modelManager.getModelPath(
      ModelManager.sttModelFiles[2],
    );

    final config = sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: encoderPath,
          decoder: decoderPath,
          language: 'en',
          task: 'transcribe',
        ),
        tokens: tokensPath,
        modelType: 'whisper',
        numThreads: 2,
        debug: false,
      ),
    );

    _recognizer = sherpa.OfflineRecognizer(config);
  }

  @override
  Future<String> transcribe(Uint8List audio) async {
    if (_recognizer == null) await initialize();

    final samples = WavCodec.decode(audio);

    final stream = _recognizer!.createStream();
    stream.acceptWaveform(samples: samples, sampleRate: 16000);
    _recognizer!.decode(stream);

    final result = _recognizer!.getResult(stream);
    stream.free();

    return result.text.trim();
  }

  /// Giải phóng native resources.
  void dispose() {
    _recognizer?.free();
    _recognizer = null;
  }
}
