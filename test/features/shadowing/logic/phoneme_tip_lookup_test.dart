import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/shadowing/logic/phoneme_tip_lookup.dart';

void main() {
  group('PhonemeTipLookup', () {
    test('returns tip when accuracy < 80 and phoneme exists', () {
      final tip = PhonemeTipLookup.getTip('θ', 60);
      expect(tip, isNotNull);
      expect(tip, contains('lưỡi'));
    });

    test('returns null when accuracy >= 80', () {
      expect(PhonemeTipLookup.getTip('θ', 80), isNull);
      expect(PhonemeTipLookup.getTip('θ', 100), isNull);
    });

    test('returns null for unknown phoneme', () {
      expect(PhonemeTipLookup.getTip('x', 50), isNull);
    });

    test('all 11 phonemes have tips', () {
      expect(PhonemeTipLookup.vietnameseTips.length, 11);
    });
  });
}
