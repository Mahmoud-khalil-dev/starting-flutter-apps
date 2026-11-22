import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/di/service_locator.dart';
import 'package:kit_app/core/telemetry/analytics_sink.dart';
import 'package:kit_app/core/telemetry/recording_mask.dart';

void main() {
  tearDown(sl.reset);

  test(
    'KIT-T9: resetLocator drops registrations so the graph can rebuild',
    () async {
      sl.registerSingleton<String>('first');
      expect(sl.isRegistered<String>(), isTrue);
      await resetLocator();
      expect(sl.isRegistered<String>(), isFalse);
      // Registering again after a reset must not throw a duplicate error.
      sl.registerSingleton<String>('second');
      expect(sl<String>(), 'second');
    },
  );

  test('KIT-T9: the telemetry defaults are no-ops and yield to the app', () {
    registerTelemetryDefaults();
    expect(sl<CrashReporter>(), isA<NoopCrashReporter>());
    expect(sl<AnalyticsSink>(), isA<NoopAnalyticsSink>());
  });

  test('KIT-T9: a registration made first is not replaced', () {
    sl.registerSingleton<CrashReporter>(const DebugCrashReporter());
    registerTelemetryDefaults();
    expect(sl<CrashReporter>(), isA<DebugCrashReporter>());
    expect(sl<AnalyticsSink>(), isA<NoopAnalyticsSink>());
  });

  test('KIT-T10: the defaults fill the locator given, not the global one', () {
    final other = GetIt.asNewInstance();
    registerTelemetryDefaults(locator: other);
    expect(other<CrashReporter>(), isA<NoopCrashReporter>());
    expect(other<AnalyticsSink>(), isA<NoopAnalyticsSink>());
    expect(sl.isRegistered<CrashReporter>(), isFalse);
  });

  test('KIT-T10: a reset keeps the project reporter and sink', () async {
    final locator = GetIt.asNewInstance();
    const reporter = DebugCrashReporter();
    const sink = NoopAnalyticsSink();
    locator
      ..registerSingleton<CrashReporter>(reporter)
      ..registerSingleton<AnalyticsSink>(sink)
      ..registerSingleton<String>('dropped');
    await resetLocator(locator: locator);
    expect(locator<CrashReporter>(), same(reporter));
    expect(locator<AnalyticsSink>(), same(sink));
    expect(locator.isRegistered<String>(), isFalse);
  });

  test('KIT-T11: the recording masker defaults to unmasked and yields', () {
    registerTelemetryDefaults();
    expect(sl<RecordingMasker>(), same(unmasked));
  });

  test(
    'KIT-T11: a masker registered first is kept, and survives a reset',
    () async {
      final locator = GetIt.asNewInstance();
      Widget mask(Widget child) => child;
      locator.registerSingleton<RecordingMasker>(mask);
      registerTelemetryDefaults(locator: locator);
      expect(locator<RecordingMasker>(), same(mask));
      await resetLocator(locator: locator);
      expect(locator<RecordingMasker>(), same(mask));
    },
  );
}
