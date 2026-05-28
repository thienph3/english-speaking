import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'package:speakeng/features/ai_services/models/service_types.dart';
import 'package:speakeng/features/ai_services/providers/interfaces/tts_provider.dart';
import 'package:speakeng/features/ai_services/services/model_manager.dart';

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

    // Convert Float32List PCM → 16-bit WAV bytes
    return _encodeWav(audio.samples, audio.sampleRate);
  }

  /// Encode Float32List samples thành WAV format (16-bit PCM).
  Uint8List _encodeWav(Float32List samples, int sampleRate) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2; // 16-bit = 2 bytes per sample
    final fileSize = 44 + dataSize;

    final buffer = ByteData(fileSize);

    // WAV header
    buffer.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    buffer.setUint32(4, fileSize - 8, Endian.little);
    buffer.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    buffer.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    buffer.setUint32(16, 16, Endian.little); // chunk size
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buffer.setUint16(32, 2, Endian.little); // block align
    buffer.setUint16(34, 16, Endian.little); // bits per sample
    buffer.setUint32(36, 0x64617461, Endian.big); // "data"
    buffer.setUint32(40, dataSize, Endian.little);

    // Convert float samples to 16-bit PCM
    for (var i = 0; i < numSamples; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final intSample = (clamped * 32767).toInt();
      buffer.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Giải phóng native resources.
  void dispose() {
    _tts?.free();
    _tts = null;
  }
}
