import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kit_app/core/logging/app_log.dart';

/// Where uncaught errors go. The kit ships [NoopCrashReporter] and
/// [DebugCrashReporter]; a project writes an implementation for its crash
/// service and registers it in place of the no-op.
abstract interface class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  });

  Future<void> recordFlutterError(FlutterErrorDetails details);
}

/// The default: reports nothing and prints nothing.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}
}

/// Print only, for development builds: through AppLog, so the line is
/// redacted and a release build prints nothing.
class DebugCrashReporter implements CrashReporter {
  const DebugCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async => AppLog.warn('Uncaught ${error.runtimeType}: $error\n$stack');

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!AppLog.release) FlutterError.presentError(details);
  }
}

/// Routes Flutter and platform errors to the current reporter. [ignore]
/// drops known noise, such as an assertion a plugin raises on its own.
/// Uncaught platform errors are fatal; a Flutter error does not end the
/// process, so it is not.
void installErrorHandlers(
  CrashReporter Function() reporter, {
  required bool Function(FlutterErrorDetails details) ignore,
}) {
  FlutterError.onError = (details) {
    if (ignore(details)) return;
    unawaited(reporter().recordFlutterError(details));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(reporter().recordError(error, stack, fatal: true));
    return true;
  };
}

/// The reporter bootstrap uses until the graph gives it the project's: the
/// printing one in development, the no-op in a release build, so an early
/// boot failure never prints its text and stack there.
CrashReporter bootReporter({bool release = kReleaseMode}) =>
    release ? const NoopCrashReporter() : const DebugCrashReporter();
