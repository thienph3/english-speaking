import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/shadowing/logic/word_color_mapper.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';

void main() {
  group('WordColorMapper', () {
    test('accuracy >= 80 returns green', () {
      expect(WordColorMapper.mapColor(80), WordColor.green);
      expect(WordColorMapper.mapColor(100), WordColor.green);
    });

    test('accuracy 50-79 returns yellow', () {
      expect(WordColorMapper.mapColor(50), WordColor.yellow);
      expect(WordColorMapper.mapColor(79), WordColor.yellow);
    });

    test('accuracy < 50 returns red', () {
      expect(WordColorMapper.mapColor(49), WordColor.red);
      expect(WordColorMapper.mapColor(0), WordColor.red);
    });
  });
}
