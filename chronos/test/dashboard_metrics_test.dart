import 'package:flutter_test/flutter_test.dart';
import 'package:chronos/src/features/dashboard/presentation/dashboard_metrics.dart';

void main() {
  test('time left fractions are between 0 and 1', () {
    final today = timeLeftFractionToday();
    final week = timeLeftFractionWeek();
    final month = timeLeftFractionMonth();

    expect(today, inInclusiveRange(0.0, 1.0));
    expect(week, inInclusiveRange(0.0, 1.0));
    expect(month, inInclusiveRange(0.0, 1.0));
  });
}
