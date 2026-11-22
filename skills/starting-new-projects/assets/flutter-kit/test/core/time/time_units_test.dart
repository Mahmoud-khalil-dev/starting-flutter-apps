import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/time/time_units.dart';

void main() {
  test('KIT-T9: the countdown counts days in a day, not in motion ticks', () {
    expect(TimeUnits.day, const Duration(days: 1));
    expect(TimeUnits.day * 3, const Duration(hours: 72));
  });
}
