/// The one source of "now" for new code. Inject it, so a test can fix time.
abstract interface class AppClock {
  DateTime now();
}

class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
