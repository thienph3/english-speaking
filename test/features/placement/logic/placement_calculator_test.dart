import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/placement/logic/placement_calculator.dart';

void main() {
  group('PlacementCalculator', () {
    group('calculateLevel', () {
      test('avg >= 80 returns medium_hard', () {
        expect(PlacementCalculator.calculateLevel([80, 90, 85]), 'medium_hard');
      });

      test('avg exactly 80 returns medium_hard', () {
        expect(PlacementCalculator.calculateLevel([80, 80, 80]), 'medium_hard');
      });

      test('avg 50-79 returns easy_medium', () {
        expect(PlacementCalculator.calculateLevel([50, 60, 70]), 'easy_medium');
      });

      test('avg exactly 50 returns easy_medium', () {
        expect(PlacementCalculator.calculateLevel([50, 50, 50]), 'easy_medium');
      });

      test('avg < 50 returns easy', () {
        expect(PlacementCalculator.calculateLevel([30, 40, 20]), 'easy');
      });

      test('single score works', () {
        expect(PlacementCalculator.calculateLevel([100]), 'medium_hard');
        expect(PlacementCalculator.calculateLevel([0]), 'easy');
      });
    });

    group('calculateAverage', () {
      test('returns correct average', () {
        expect(PlacementCalculator.calculateAverage([60, 80, 100]), 80.0);
      });

      test('single value returns itself', () {
        expect(PlacementCalculator.calculateAverage([75]), 75.0);
      });
    });
  });
}
