import 'package:kit_app/core/error/step_guard.dart';

/// The work after the first frame, each part guarded so one failure never
/// skips the next. Session recovery is registered first and on its own: the
/// splash's Try again and the resume re-read depend on it, and
/// nothing about connectivity may stop it. The wiring needs it, so it is
/// skipped when the recovery failed to register.
Future<void> runBackgroundBoot({
  required void Function() registerRecovery,
  required void Function() wireLifecycle,
  required Future<void> Function() work,
  required Future<void> Function() refresh,
  void Function(String step, Object error) log = logStepFailure,
}) async {
  final registered = await guardStep('session recovery', () async {
    registerRecovery();
  }, log: log);
  if (registered) {
    await guardStep('session lifecycle', () async {
      wireLifecycle();
    }, log: log);
  }
  await guardStep('background work', work, log: log);
  await guardStep('session refresh', refresh, log: log);
}
