import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/shared/services/audio_duration_validator.dart';

void main() {
  group('AudioDurationValidator', () {
    test('valid duration returns null', () {
      expect(AudioDurationValidator.validate(const Duration(seconds: 5)), isNull);
      expect(AudioDurationValidator.validate(const Duration(seconds: 1)), isNull);
      expect(AudioDurationValidator.validate(const Duration(seconds: 60)), isNull);
    });

    test('too short returns error message', () {
      expect(
        AudioDurationValidator.validate(const Duration(milliseconds: 500)),
        isNotNull,
      );
    });

    test('too long returns error message', () {
      expect(
        AudioDurationValidator.validate(const Duration(seconds: 61)),
        isNotNull,
      );
    });

    test('isValid returns bool', () {
      expect(AudioDurationValidator.isValid(const Duration(seconds: 5)), true);
      expect(AudioDurationValidator.isValid(const Duration(milliseconds: 100)), false);
    });
  });
}
