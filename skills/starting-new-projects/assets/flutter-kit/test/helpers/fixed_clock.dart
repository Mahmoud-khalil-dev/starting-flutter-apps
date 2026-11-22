import 'package:kit_app/core/time/app_clock.dart';

/// A clock that moves only when a test says so.
class FixedClock implements AppClock {
  FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
}
