import 'package:speakeng/core/constants.dart';

/// Pure logic validator for audio recording duration.
///
/// Validates that audio duration falls within acceptable bounds
/// defined in [AppConstants]. No external dependencies.
class AudioDurationValidator {
  AudioDurationValidator._();

  /// Minimum acceptable audio duration.
  static const minDuration = AppConstants.minAudioDuration;

  /// Maximum acceptable audio duration.
  static const maxDuration = AppConstants.maxAudioDuration;

  /// Validates the given [duration] against min/max bounds.
  ///
  /// Returns an error message string if invalid, or `null` if valid.
  /// - Duration < 1 second → too short
  /// - Duration > 60 seconds → too long
  /// - Duration in [1, 60] seconds → valid (null)
  static String? validate(Duration duration) {
    if (duration < minDuration) {
      return 'Bản ghi quá ngắn. Hãy ghi từ 2–10 giây.';
    }
    if (duration > maxDuration) {
      return 'Bản ghi quá dài. Hãy ghi từ 2–10 giây.';
    }
    return null;
  }

  /// Returns `true` if the [duration] is within valid bounds.
  static bool isValid(Duration duration) => validate(duration) == null;
}
