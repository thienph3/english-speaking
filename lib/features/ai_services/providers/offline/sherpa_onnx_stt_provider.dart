import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/stt_provider.dart';
import 'package:speakeng/features/ai_services/services/model_manager.dart';

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

    // Parse WAV header để lấy PCM samples
    final samples = _decodeWav(audio);

    final stream = _recognizer!.createStream();
    stream.acceptWaveform(samples: samples, sampleRate: 16000);
    _recognizer!.decode(stream);

    final result = _recognizer!.getResult(stream);
    stream.free();

    return result.text.trim();
  }

  /// Decode WAV bytes thành Float32List PCM samples.
  ///
  /// Giả sử input là 16-bit mono PCM WAV (format chuẩn từ record package).
  Float32List _decodeWav(Uint8List wavBytes) {
    final byteData = ByteData.sublistView(wavBytes);

    // Skip WAV header (44 bytes) → PCM data
    const headerSize = 44;
    final numSamples = (wavBytes.length - headerSize) ~/ 2;
    final samples = Float32List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final intSample = byteData.getInt16(headerSize + i * 2, Endian.little);
      samples[i] = intSample / 32768.0;
    }

    return samples;
  }

  /// Giải phóng native resources.
  void dispose() {
    _recognizer?.free();
    _recognizer = null;
  }
}
