import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import 'package:speakeng/core/constants.dart';

/// Service wrapping audio recording ([record] package) and playback
/// ([just_audio] package).
///
/// Provides:
/// - WAV recording at 16kHz mono (per [AppConstants])
/// - Playback with play, pause, stop, and speed control
/// - Stream of recording amplitude for UI visualization
class AudioService {
  AudioService()
      : _recorder = AudioRecorder(),
        _player = AudioPlayer();

  final AudioRecorder _recorder;
  final AudioPlayer _player;

  // ---------------------------------------------------------------------------
  // Recording
  // ---------------------------------------------------------------------------

  /// Whether the recorder is currently recording.
  Future<bool> get isRecording => _recorder.isRecording();

  /// Starts recording audio in WAV format at 16kHz mono.
  ///
  /// [path] is the file path where the WAV file will be saved.
  /// Throws if microphone permission is not granted.
  Future<void> startRecording(String path) async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw RecordingPermissionError();
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: AppConstants.audioSampleRate,
        numChannels: AppConstants.audioChannels,
        bitRate: 256000,
      ),
      path: path,
    );
  }

  /// Stops the current recording and returns the file path.
  ///
  /// Returns `null` if no recording was in progress.
  Future<String?> stopRecording() async {
    return _recorder.stop();
  }

  /// Cancels the current recording without saving.
  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }

  /// Stream of amplitude values during recording for UI visualization.
  Stream<Amplitude> get amplitudeStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  /// Current playback state stream.
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Current playback position stream.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Total duration of the loaded audio (null if not loaded).
  Duration? get duration => _player.duration;

  /// Whether audio is currently playing.
  bool get isPlaying => _player.playing;

  /// Loads an audio file from [path] for playback.
  ///
  /// Returns the total duration of the audio file.
  Future<Duration?> loadAudio(String path) async {
    return _player.setFilePath(path);
  }

  /// Loads audio from a URL for playback.
  ///
  /// Returns the total duration of the audio.
  Future<Duration?> loadUrl(String url) async {
    return _player.setUrl(url);
  }

  /// Loads audio from Flutter asset bundle for playback.
  ///
  /// [assetPath] — path relative to project root (e.g., "assets/voices/id.mp3").
  /// Returns the total duration of the audio.
  Future<Duration?> loadAsset(String assetPath) async {
    return _player.setAsset(assetPath);
  }

  /// Starts or resumes playback.
  Future<void> play() async {
    await _player.play();
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Stops playback and resets position to the beginning.
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  /// Sets playback speed.
  ///
  /// Supported values from [AppConstants.speedOptions]: 0.7, 1.0, 1.2.
  Future<void> setSpeed(double speed) async {
    assert(
      AppConstants.speedOptions.contains(speed),
      'Speed must be one of ${AppConstants.speedOptions}',
    );
    await _player.setSpeed(speed);
  }

  /// Seeks to a specific [position] in the audio.
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Releases all resources held by the recorder and player.
  ///
  /// Call this when the service is no longer needed.
  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}

/// Error thrown when microphone permission is not granted.
class RecordingPermissionError implements Exception {
  @override
  String toString() => 'Microphone permission not granted.';
}
