import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/error/step_guard.dart';

class _Reporter implements CrashReporter {
  final errors = <(Object, StackTrace?, bool)>[];
  StateError? throws;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    errors.add((error, stack, fatal));
    if (throws != null) throw throws!;
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}
}

void main() {
  group('KIT-T9: guardStep', () {
    test('KIT-T9: a step that finishes returns true', () async {
      var ran = false;
      final ok = await guardStep('x', () async => ran = true);
      expect(ok, isTrue);
      expect(ran, isTrue);
    });

    test('KIT-T9: a throwing step returns false and does not throw', () async {
      final seen = <(String, Object)>[];
      final ok = await guardStep(
        'x',
        () async => throw StateError('secret detail'),
        log: (step, error) => seen.add((step, error)),
      );
      expect(ok, isFalse);
      expect(seen.single.$1, 'x');
      expect(seen.single.$2, isA<StateError>());
    });

    test(
      'KIT-T9: a step that throws before its first await is caught',
      () async {
        final ok = await guardStep(
          'x',
          () => throw StateError('sync'),
          log: (_, _) {},
        );
        expect(ok, isFalse);
      },
    );

    test('KIT-T9: the default log holds the type, never the message', () async {
      final lines = <String?>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => lines.add(message);
      addTearDown(() => debugPrint = original);

      await guardStep(
        'legacy state',
        () async => throw StateError('token abc'),
      );

      expect(lines, ['[warn] Boot step legacy state failed: StateError']);
      expect(lines.single, isNot(contains('token abc')));
    });

    test('KIT-T9: logStepFailure writes the type only', () {
      final lines = <String?>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => lines.add(message);
      addTearDown(() => debugPrint = original);

      logStepFailure('storage', const FormatException('user@example.com'));

      expect(lines, ['[warn] Boot step storage failed: FormatException']);
    });
  });

  group('KIT-T9: stepFailureReporter', () {
    setUp(() {
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) {};
      addTearDown(() => debugPrint = original);
    });

    test('KIT-T9: a failed step is a non-fatal with step and type only', () {
      final reporter = _Reporter();
      stepFailureReporter(() => reporter)(
        'legacy state',
        StateError('token abc user@example.com'),
      );

      final (error, stack, fatal) = reporter.errors.single;
      expect(fatal, isFalse);
      expect(stack, StackTrace.empty);
      expect(error, isA<BootStepFailure>());
      expect(error.toString(), 'Boot step legacy state failed: StateError');
      expect(error.toString(), isNot(contains('token abc')));
    });

    test('KIT-T9: the reporter is read when the step fails, not before', () {
      var reporter = _Reporter();
      final log = stepFailureReporter(() => reporter);
      final later = reporter = _Reporter();
      log('session', StateError('x'));
      expect(later.errors, hasLength(1));
    });

    test('KIT-T9: nothing extra when crash reporting is the failed step', () {
      final reporter = _Reporter();
      final log = stepFailureReporter(() => reporter);
      log('crash reporting', StateError('x'));
      expect(reporter.errors, isEmpty);
    });

    test('KIT-T9: a reporter that throws never stops the boot', () async {
      final reporter = _Reporter()..throws = StateError('reporter down');
      final log = stepFailureReporter(() => reporter);
      log('session', StateError('x'));
      await Future<void>.delayed(Duration.zero);
      final broken = stepFailureReporter(() => throw StateError('no reporter'));
      broken('session', StateError('x'));
      expect(reporter.errors, hasLength(1));
    });
  });
}
