import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/features/conversation/logic/response_time_calculator.dart';

void main() {
  group('ResponseTimeCalculator', () {
    test('returns average of values', () {
      expect(ResponseTimeCalculator.average([1000, 2000, 3000]), 2000.0);
    });

    test('returns 0 for empty list', () {
      expect(ResponseTimeCalculator.average([]), 0);
    });

    test('single value returns itself', () {
      expect(ResponseTimeCalculator.average([1500]), 1500.0);
    });
  });
}
