import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/di/modules/network_module.dart';
import 'package:kit_app/app/session_recovery.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/error/step_guard.dart';
import 'package:kit_app/core/logging/app_log.dart';
import 'package:kit_app/core/network/dio_client.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/stub_adapter.dart';

class _Cubit extends Mock implements SessionCubit {}

class _Recorder implements CrashReporter {
  final errors = <Object>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async => errors.add(error);

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}
}

/// Every line the kit writes goes through AppLog: redacted, by type, to the
/// crash reporter for an error, and nothing at all in a release build.
void main() {
  late List<String?> printed;
  late List<String> logged;
  late _Recorder reporter;

  setUp(() {
    printed = [];
    logged = [];
    reporter = _Recorder();
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message);
    AppLog.reporter = reporter;
    AppLog.sink = logged.add;
    addTearDown(() {
      debugPrint = original;
      AppLog.reset();
    });
  });

  _Cubit failingCubit() {
    final cubit = _Cubit();
    when(cubit.expire).thenThrow(StateError('token abc'));
    when(cubit.retryRestore).thenAnswer((_) async => true);
    when(() => cubit.state).thenReturn(
      const SessionState.authenticated(role: null, userStatus: null),
    );
    when(cubit.refresh).thenThrow(StateError('token abc'));
    return cubit;
  }

  final lines = <String, Future<void> Function()>{
    'a boot step failure': () async =>
        logStepFailure('storage', StateError('token abc')),
    'a session end whose reset fails': () => expireSession(failingCubit()),
    'a session recovery step that throws': () =>
        SessionRecovery(session: failingCubit()).tryAgain(),
  };

  for (final MapEntry(key: name, value: write) in lines.entries) {
    test('KIT-T15: $name prints nothing in a release build', () async {
      AppLog.release = true;
      await write();
      expect(printed, isEmpty);
      expect(logged, isEmpty);
    });

    test('KIT-T15: $name goes through AppLog, without the message', () async {
      await write();
      expect(printed, isEmpty);
      expect(logged, isNotEmpty);
      expect(logged.join('\n'), contains('StateError'));
      expect(logged.join('\n'), isNot(contains('token abc')));
    });
  }

  test('KIT-T15: the debug crash reporter prints through AppLog, and nothing '
      'in a release build', () async {
    const debug = DebugCrashReporter();
    await debug.recordError(StateError('x'), StackTrace.current);
    expect(printed, isEmpty);
    expect(logged.single, contains('Uncaught StateError'));
    logged.clear();
    AppLog.release = true;
    await debug.recordError(StateError('x'), StackTrace.current);
    expect(printed, isEmpty);
    expect(logged, isEmpty);
  });

  test('KIT-T15: a session end whose reset fails reaches the crash reporter '
      'by type', () async {
    await expireSession(failingCubit());
    expect(reporter.errors.single, isA<LoggedError>());
    expect((reporter.errors.single as LoggedError).type, 'StateError');
  });

  test(
    'KIT-T15: the debug network log goes through AppLog, redacted',
    () async {
      final dio = createDio(
        baseUrl: 'https://api.example.test',
        interceptors: const [],
        adapter: StubAdapter((_) async => jsonBody({'ok': true})),
      );
      await dio.get<void>(
        '/reset',
        queryParameters: {'token': 'abc123secret', 'email': 'sara@example.com'},
        options: Options(extra: {'otp': '482913'}),
      );
      expect(printed, isEmpty);
      final all = logged.join('\n');
      expect(all, contains('/reset'));
      expect(all, isNot(contains('abc123secret')));
      expect(all, isNot(contains('sara@example.com')));
      expect(all, isNot(contains('sara%40example.com')));
      expect(all, isNot(contains('482913')));
    },
  );

  test('KIT-T15: the debug network log is silent in a release build', () async {
    AppLog.release = true;
    final dio = createDio(
      baseUrl: 'https://api.example.test',
      interceptors: const [],
      adapter: StubAdapter((_) async => jsonBody({'ok': true})),
    );
    await dio.get<void>('/items');
    expect(printed, isEmpty);
    expect(logged, isEmpty);
  });
}
