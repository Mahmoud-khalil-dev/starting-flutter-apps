import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_app/app/session_recovery.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/logging/app_log.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/startup_decision.dart';
import 'package:kit_app/core/widgets/startup_gate.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

class _MockSessionCubit extends Mock implements SessionCubit {}

void main() {
  /// The decision the splash makes for a session that stays unsettled.
  StartupAction unsettled({
    required bool resumed,
    required Duration sinceResume,
  }) => startupDecision(
    status: SessionStatus.unknown,

    resumed: resumed,
    sinceResume: sinceResume,
  );

  final retryBody = l10nFor('en').startupRetryBody;
  final retryAction = l10nFor('en').startupRetryAction;

  Future<void> pumpGate(
    WidgetTester tester, {
    required StartupDecisionSource decide,
    VoidCallback? onRoute,
    Future<void> Function()? onTryAgain,
  }) => pumpApp(
    tester,
    StartupGate(
      decide: decide,
      onRoute: onRoute ?? () {},
      onTryAgain: onTryAgain ?? () async {},
    ),
    settle: false,
  );

  testWidgets(
    'KIT-T10: the notice appears 5 s after the app is resumed, not before',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpGate(tester, decide: unsettled);

      await tester.pump(const Duration(seconds: 4));
      expect(find.text(retryBody), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text(retryBody), findsOneWidget);
    },
  );

  testWidgets(
    'KIT-T10: the wait is not counted while the app is in the background',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpGate(tester, decide: unsettled);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text(retryBody), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text(retryBody), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(retryBody), findsOneWidget);
    },
  );

  testWidgets(
    'KIT-T10: Try again calls the recovery, hides the notice and restarts the wait',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      var tries = 0;
      await pumpGate(
        tester,
        decide: unsettled,
        onTryAgain: () async => tries++,
      );
      await tester.pump(const Duration(seconds: 6));
      expect(find.text(retryBody), findsOneWidget);

      await tester.tap(find.text(retryAction));
      await tester.pump();
      expect(tries, 1);
      expect(find.text(retryBody), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text(retryBody), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text(retryBody), findsOneWidget);
    },
  );

  testWidgets('KIT-T10: the gate routes once when the session settles', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var settled = false;
    var routed = 0;
    await pumpGate(
      tester,
      decide: ({required resumed, required sinceResume}) =>
          settled ? StartupAction.route : StartupAction.hold,
      onRoute: () => routed++,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(routed, 0);

    settled = true;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 3));
    expect(routed, 1);
  });

  test(
    'KIT-T10: bootstrap registers the recovery where the splash reads it',
    () {
      final locator = GetIt.asNewInstance();
      expect(locator.isRegistered<SessionRecovery>(), isFalse);

      final recovery = registerSessionRecovery(
        locator,
        session: _MockSessionCubit(),
      );

      expect(locator<SessionRecovery>(), same(recovery));
    },
  );
  testWidgets(
    'KIT-T15: a failing Try again goes to AppLog by type: reported, and '
    'silent in a release build',
    (tester) async {
      final reported = <Object>[];
      final printed = <String?>[];
      AppLog.release = true;
      AppLog.reporter = _Recorder(reported);
      addTearDown(AppLog.reset);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpGate(
        tester,
        decide: unsettled,
        onTryAgain: () async => throw StateError('token abc'),
      );
      await tester.pump(const Duration(seconds: 6));
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message);
      try {
        await tester.tap(find.text(retryAction));
        await tester.pump();
      } finally {
        debugPrint = original;
      }
      expect(printed, isEmpty);
      expect(reported.single, isA<LoggedError>());
      expect((reported.single as LoggedError).type, 'StateError');
      expect('${reported.single}', isNot(contains('token abc')));
    },
  );
}

class _Recorder implements CrashReporter {
  _Recorder(this.errors);

  final List<Object> errors;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async => errors.add(error);

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}
}
