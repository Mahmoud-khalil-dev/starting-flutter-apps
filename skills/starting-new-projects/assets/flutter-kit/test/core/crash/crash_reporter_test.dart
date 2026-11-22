import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';

class _Recorder implements CrashReporter {
  final errors = <(Object, bool)>[];
  final flutterErrors = <FlutterErrorDetails>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async => errors.add((error, fatal));

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async =>
      flutterErrors.add(details);
}

void main() {
  test('KIT-T9: error handlers report, except ignored Flutter errors', () {
    final originalFlutter = FlutterError.onError;
    final originalPlatform = PlatformDispatcher.instance.onError;
    final recorder = _Recorder();
    try {
      installErrorHandlers(
        () => recorder,
        ignore: (d) => d.exceptionAsString().contains('ignored'),
      );
      FlutterError.onError!(
        FlutterErrorDetails(exception: StateError('ignored')),
      );
      FlutterError.onError!(FlutterErrorDetails(exception: StateError('real')));
      final handled = PlatformDispatcher.instance.onError!(
        StateError('async'),
        StackTrace.empty,
      );
      expect(recorder.flutterErrors, hasLength(1));
      expect(recorder.errors, hasLength(1));
      expect(recorder.errors.single.$2, isTrue, reason: 'uncaught is fatal');
      expect(handled, isTrue);
    } finally {
      FlutterError.onError = originalFlutter;
      PlatformDispatcher.instance.onError = originalPlatform;
    }
  });

  test(
    'KIT-T9: the no-op reporter accepts everything and prints nothing',
    () async {
      final lines = <String?>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => lines.add(message);
      addTearDown(() => debugPrint = original);
      const reporter = NoopCrashReporter();
      await reporter.recordError(
        StateError('x'),
        StackTrace.empty,
        fatal: true,
      );
      await reporter.recordFlutterError(
        FlutterErrorDetails(exception: StateError('y')),
      );
      expect(lines, isEmpty);
    },
  );

  test('KIT-T9: the debug reporter prints the error', () async {
    final lines = <String?>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => lines.add(message);
    addTearDown(() => debugPrint = original);
    await const DebugCrashReporter().recordError(
      StateError('boom'),
      StackTrace.empty,
    );
    expect(lines.single, contains('StateError'));
  });

  test('KIT-T9: before the graph exists, a release build reports to the '
      'no-op, never the printing reporter', () {
    expect(bootReporter(release: true), isA<NoopCrashReporter>());
    // Tests run as a debug build.
    expect(bootReporter(), isA<DebugCrashReporter>());
  });
}
