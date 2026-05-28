import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Provider cho ModelManager singleton.
final modelManagerProvider = Provider<ModelManager>((ref) => ModelManager());

/// Quản lý download và lưu trữ model files cho offline TTS/STT.
///
/// Models được download từ HuggingFace và lưu vào app documents directory.
class ModelManager {
  static const _baseUrl =
      'https://huggingface.co/csukuangfj/sherpa-onnx-models/resolve/main';

  /// TTS model: Piper en_US-lessac-medium (VITS).
  static const ttsModelFiles = [
    'vits-piper-en_US-lessac-medium/en_US-lessac-medium.onnx',
    'vits-piper-en_US-lessac-medium/tokens.txt',
    'vits-piper-en_US-lessac-medium/espeak-ng-data',
  ];

  /// STT model: Whisper tiny.en (int8).
  static const sttModelFiles = [
    'sherpa-onnx-whisper-tiny.en/tiny.en-encoder.int8.onnx',
    'sherpa-onnx-whisper-tiny.en/tiny.en-decoder.int8.onnx',
    'sherpa-onnx-whisper-tiny.en/tiny.en-tokens.txt',
  ];

  String? _modelsDir;

  /// Đường dẫn thư mục chứa models.
  Future<String> get modelsDir async {
    if (_modelsDir != null) return _modelsDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _modelsDir = '${appDir.path}/sherpa_models';
    return _modelsDir!;
  }

  /// Kiểm tra TTS model đã download chưa.
  Future<bool> get isTtsReady async {
    final dir = await modelsDir;
    final modelFile = File('$dir/${ttsModelFiles[0]}');
    return modelFile.existsSync();
  }

  /// Kiểm tra STT model đã download chưa.
  Future<bool> get isSttReady async {
    final dir = await modelsDir;
    final modelFile = File('$dir/${sttModelFiles[0]}');
    return modelFile.existsSync();
  }

  /// Download TTS model files từ HuggingFace.
  Future<void> downloadTtsModel({
    void Function(double progress)? onProgress,
  }) async {
    await _downloadFiles(ttsModelFiles, onProgress: onProgress);
  }

  /// Download STT model files từ HuggingFace.
  Future<void> downloadSttModel({
    void Function(double progress)? onProgress,
  }) async {
    await _downloadFiles(sttModelFiles, onProgress: onProgress);
  }

  /// Lấy đường dẫn tuyệt đối cho một model file.
  Future<String> getModelPath(String relativePath) async {
    final dir = await modelsDir;
    return '$dir/$relativePath';
  }

  Future<void> _downloadFiles(
    List<String> files, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await modelsDir;
    final client = HttpClient();

    try {
      for (var i = 0; i < files.length; i++) {
        final filePath = '$dir/${files[i]}';
        final file = File(filePath);

        if (file.existsSync()) {
          onProgress?.call((i + 1) / files.length);
          continue;
        }

        await file.parent.create(recursive: true);

        final url = '$_baseUrl/${files[i]}';
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();

        if (response.statusCode != 200) {
          throw HttpException('Failed to download: $url');
        }

        final sink = file.openWrite();
        await response.pipe(sink);

        onProgress?.call((i + 1) / files.length);
      }
    } finally {
      client.close();
    }
  }
}
