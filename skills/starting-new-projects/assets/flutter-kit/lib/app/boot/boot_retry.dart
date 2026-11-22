import 'package:kit_app/core/error/step_guard.dart';

/// Wraps a retry so a second tap while it runs is ignored, and the next tap
/// works once it has finished, even if it threw.
Future<void> Function() singleFlight(Future<void> Function() run) {
  var running = false;
  return () async {
    if (running) return;
    running = true;
    try {
      await run();
    } finally {
      running = false;
    }
  };
}

/// The dependencies step. A failed earlier attempt may have registered part of
/// the graph, and get_it throws on a second registration, so the locator is
/// reset first. A failing reset is logged and the registration still runs;
/// a failing registration still fails the step.
Future<void> Function() freshDependencies({
  required Future<void> Function() reset,
  required Future<void> Function() init,
}) => () async {
  await guardStep('locator reset', reset);
  await init();
};
