import 'dart:typed_data';

/// Encode/decode WAV audio (16-bit PCM mono).
///
/// Pure utility — no dependencies.
class WavCodec {
  WavCodec._();

  /// Encode Float32List samples → WAV bytes (16-bit PCM mono).
  static Uint8List encode(Float32List samples, int sampleRate) {
    final dataSize = samples.length * 2;
    final fileSize = 44 + dataSize;
    final buffer = ByteData(fileSize);

    // RIFF header
    buffer.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    buffer.setUint32(4, fileSize - 8, Endian.little);
    buffer.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    buffer.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    buffer.setUint32(36, 0x64617461, Endian.big); // "data"
    buffer.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      buffer.setInt16(44 + i * 2, (clamped * 32767).toInt(), Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Decode WAV bytes → Float32List PCM samples.
  ///
  /// Assumes standard 44-byte header, 16-bit mono PCM.
  static Float32List decode(Uint8List wavBytes) {
    final byteData = ByteData.sublistView(wavBytes);
    const headerSize = 44;
    final numSamples = (wavBytes.length - headerSize) ~/ 2;
    final samples = Float32List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final intSample = byteData.getInt16(headerSize + i * 2, Endian.little);
      samples[i] = intSample / 32768.0;
    }

    return samples;
  }
}
