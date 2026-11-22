import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/time/app_clock.dart';

import '../../helpers/fixed_clock.dart';

void main() {
  group('KIT-T9: AppClock', () {
    test('SystemClock reads the wall clock', () {
      final before = DateTime.now();
      final now = const SystemClock().now();
      expect(now.isBefore(before), isFalse);
    });

    test('FixedClock holds still until advanced', () {
      final clock = FixedClock(DateTime.utc(2026, 11, 20, 9));
      expect(clock.now(), DateTime.utc(2026, 11, 20, 9));
      clock.advance(const Duration(hours: 2));
      expect(clock.now(), DateTime.utc(2026, 11, 20, 11));
    });
  });
}
