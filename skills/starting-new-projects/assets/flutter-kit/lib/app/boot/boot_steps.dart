import 'dart:async';

import 'package:kit_app/core/error/step_guard.dart';

/// The start-up order: the dependencies and the saved session must be ready
/// before runApp, because the widget tree reads them from its first frame.
/// Native services a project adds (push, calls) belong before [dependencies]
/// or between [session] and [runApp], guarded the same way.
class BootSteps {
  const BootSteps({
    required this.dependencies,
    required this.session,
    required this.runApp,
    required this.background,
    required this.runFailure,
  });

  final Future<void> Function() dependencies;
  final Future<void> Function() session;
  final void Function() runApp;

  /// Not awaited: nothing in it may delay the first frame.
  final Future<void> Function() background;

  /// Shows the calm failure screen when an essential step failed (the
  /// dependencies or the session), with a Try again that runs [runBootSteps]
  /// once more.
  final void Function(Future<void> Function() retry) runFailure;
}

/// Every step is guarded: a failing step is logged (type only) and the boot
/// goes on, and the app always starts. Only the dependencies and the session
/// are essential; without them the app cannot build, so a failure there shows
/// the failure screen instead of the app. Its Try again runs the whole
/// sequence again.
Future<void> runBootSteps(
  BootSteps steps, {
  void Function(String step, Object error) log = logStepFailure,
}) async {
  Future<bool> guard(String step, Future<void> Function() run) =>
      guardStep(step, run, log: log);
  final ready =
      await guard('dependencies', steps.dependencies) &&
      await guard('session', steps.session);
  if (!ready) return steps.runFailure(() => runBootSteps(steps, log: log));
  return _startApp(steps, log);
}

/// The last part: build the app, then the background work. A throw from
/// runApp retries only this part, never the steps before it: a native
/// service started by an earlier step must not be started twice.
Future<void> _startApp(
  BootSteps steps,
  void Function(String step, Object error) log,
) async {
  try {
    steps.runApp();
  } on Object catch (error) {
    log('runApp', error);
    return steps.runFailure(() => _startApp(steps, log));
  }
  unawaited(guardStep('background', steps.background, log: log));
}
