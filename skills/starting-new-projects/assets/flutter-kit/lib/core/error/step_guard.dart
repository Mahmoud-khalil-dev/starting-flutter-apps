import 'dart:async';

import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/logging/app_log.dart';

/// Writes `Boot step <step> failed: <error type>`. The type only, never the
/// message or the stack: either may hold user data (a token, a cached user).
void logStepFailure(String step, Object error) =>
    AppLog.warn('Boot step $step failed: ${error.runtimeType}');

/// Runs [run] so that nothing it throws escapes. Returns true when the step
/// finished, false when it threw (after [log] saw the step and the error).
/// A boot step must never stop the app from starting.
Future<bool> guardStep(
  String step,
  Future<void> Function() run, {
  void Function(String step, Object error) log = logStepFailure,
}) async {
  try {
    await run();
    return true;
  } on Object catch (error) {
    log(step, error);
    return false;
  }
}

/// What a failed boot step is recorded as: the step and the error type, never
/// the message or the stack.
class BootStepFailure implements Exception {
  const BootStepFailure(this.step, this.errorType);

  final String step;
  final Type errorType;

  @override
  String toString() => 'Boot step $step failed: $errorType';
}

/// The step whose failure leaves nothing to report with: the reporter is not
/// ready until crash reporting is up.
const _unreportable = {'crash reporting'};

/// The log bootstrap passes to the guard: [logStepFailure], plus a non-fatal
/// to the crash reporter carrying the step and the error type only. The
/// reporter is read when the step fails, because bootstrap swaps it in once
/// crash reporting is up. Reporting never throws into the boot.
void Function(String step, Object error) stepFailureReporter(
  CrashReporter Function() reporter,
) => (step, error) {
  logStepFailure(step, error);
  if (_unreportable.contains(step)) return;
  try {
    unawaited(
      reporter()
          .recordError(
            BootStepFailure(step, error.runtimeType),
            StackTrace.empty,
          )
          .catchError((Object _) {}),
    );
  } on Object {
    // Nothing more can be done; the line above already logged it.
  }
};
