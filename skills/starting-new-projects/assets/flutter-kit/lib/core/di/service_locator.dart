import 'package:get_it/get_it.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/telemetry/analytics_sink.dart';
import 'package:kit_app/core/telemetry/recording_mask.dart';

/// The app's service locator. Only `lib/app` (the composition root) reads
/// it; Cubits get their dependencies through constructors.
final GetIt sl = GetIt.instance;

/// Drops every registration, so the composition root can build the graph
/// again: a boot retry, or a test that starts from nothing. The app's own
/// [CrashReporter], [AnalyticsSink] and [RecordingMasker] are kept, because a project registers
/// them before boot and nothing re-registers them on a retry.
Future<void> resetLocator({GetIt? locator}) async {
  final target = locator ?? sl;
  final reporter = target.isRegistered<CrashReporter>()
      ? target<CrashReporter>()
      : null;
  final sink = target.isRegistered<AnalyticsSink>()
      ? target<AnalyticsSink>()
      : null;
  final masker = target.isRegistered<RecordingMasker>()
      ? target<RecordingMasker>()
      : null;
  await target.reset();
  if (masker != null) target.registerSingleton<RecordingMasker>(masker);
  if (reporter != null) target.registerSingleton<CrashReporter>(reporter);
  if (sink != null) target.registerSingleton<AnalyticsSink>(sink);
}

/// Registers the no-op [CrashReporter] and [AnalyticsSink], and the
/// identity [RecordingMasker], unless the app
/// already registered its own. Call it from the composition root before the
/// graph is built; a project's own registration goes in ahead of it. It
/// fills [locator], or the app's [sl] when none is given.
void registerTelemetryDefaults({GetIt? locator}) {
  final target = locator ?? sl;
  if (!target.isRegistered<CrashReporter>()) {
    target.registerSingleton<CrashReporter>(const NoopCrashReporter());
  }
  if (!target.isRegistered<AnalyticsSink>()) {
    target.registerSingleton<AnalyticsSink>(const NoopAnalyticsSink());
  }
  if (!target.isRegistered<RecordingMasker>()) {
    target.registerSingleton<RecordingMasker>(unmasked);
  }
}
