/// Calendar units for time arithmetic a countdown counts days
/// in days, never in the motion tick that refreshes it.
abstract final class TimeUnits {
  static const day = Duration(days: 1);
  static const millisecond = Duration(milliseconds: 1);
  static const microsecond = Duration(microseconds: 1);
}
