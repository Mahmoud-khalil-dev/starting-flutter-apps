import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/boot/boot_steps.dart';

BootSteps _steps(
  List<String> log, {
  Completer<void>? background,
  String? failAt,
  bool Function(String name)? shouldFail,
  bool Function()? runAppThrows,
  void Function(Future<void> Function() retry)? onFailure,
}) {
  Future<void> Function() step(String name) => () async {
    log.add(name);
    if (shouldFail?.call(name) ?? name == failAt) throw StateError(name);
  };
  return BootSteps(
    dependencies: step('dependencies'),
    session: step('session'),
    runApp: () {
      log.add('runApp');
      if (runAppThrows?.call() ?? false) throw StateError('build');
    },
    background: () async {
      log.add('background');
      if (failAt == 'background') throw StateError('background');
      await background?.future;
    },
    runFailure: (retry) => onFailure?.call(retry),
  );
}

void main() {
  group('KIT-T10: boot order', () {
    test(
      'KIT-T10: the steps run in order, the app before the background',
      () async {
        final log = <String>[];
        await runBootSteps(_steps(log));
        expect(log, ['dependencies', 'session', 'runApp', 'background']);
      },
    );

    test('KIT-T10: background work is not awaited', () async {
      final log = <String>[];
      final never = Completer<void>();
      await runBootSteps(_steps(log, background: never));
      expect(log.last, 'background');
      expect(never.isCompleted, isFalse);
    });
  });

  group('KIT-T10: every boot step is guarded', () {
    test(
      'KIT-T10: runApp still runs when the background step throws',
      () async {
        final log = <String>[];
        await runBootSteps(_steps(log, failAt: 'background'));
        await Future<void>.delayed(Duration.zero);
        expect(log.where((e) => e == 'runApp'), hasLength(1));
        expect(log, ['dependencies', 'session', 'runApp', 'background']);
      },
    );

    for (final failAt in ['dependencies', 'session']) {
      test(
        'KIT-T10: $failAt failing shows the failure state, not runApp',
        () async {
          final log = <String>[];
          var failures = 0;
          await runBootSteps(
            _steps(log, failAt: failAt, onFailure: (_) => failures++),
          );
          expect(failures, 1);
          expect(log, isNot(contains('runApp')));
          expect(log, isNot(contains('background')));
        },
      );

      test(
        'KIT-T10: retry after $failAt failed runs the steps again',
        () async {
          final log = <String>[];
          late Future<void> Function() retry;
          final fail = <String>{failAt};
          final steps = _steps(
            log,
            failAt: failAt,
            shouldFail: fail.contains,
            onFailure: (r) => retry = r,
          );
          await runBootSteps(steps);
          expect(log, isNot(contains('runApp')));

          fail.clear();
          log.clear();
          await retry();

          expect(log.where((e) => e == 'runApp'), hasLength(1));
          expect(log.where((e) => e == 'background'), hasLength(1));
          expect(
            log,
            containsAllInOrder(['dependencies', 'session', 'runApp']),
          );
        },
      );
    }

    test(
      'KIT-T10: a throw from runApp itself goes to the failure state',
      () async {
        final log = <String>[];
        var failures = 0;
        await runBootSteps(
          _steps(log, runAppThrows: () => true, onFailure: (_) => failures++),
        );
        expect(failures, 1);
        expect(log, isNot(contains('background')));
      },
    );

    test(
      'KIT-T10: a throwing background step does not reach the zone',
      () async {
        final log = <String>[];
        final errors = <Object>[];
        await runZonedGuarded(() async {
          await runBootSteps(_steps(log, failAt: 'background'));
          await Future<void>.delayed(Duration.zero);
        }, (error, _) => errors.add(error));
        expect(errors, isEmpty);
        expect(log, contains('runApp'));
      },
    );

    test(
      'KIT-T10: a retry after runApp threw does not run the earlier steps again',
      () async {
        final log = <String>[];
        late Future<void> Function() retry;
        var throws = true;
        await runBootSteps(
          _steps(log, runAppThrows: () => throws, onFailure: (r) => retry = r),
        );
        throws = false;
        await retry();

        expect(log.where((e) => e == 'dependencies'), hasLength(1));
        expect(log.where((e) => e == 'session'), hasLength(1));
        expect(log.where((e) => e == 'runApp'), hasLength(2));
        expect(log.where((e) => e == 'background'), hasLength(1));
      },
    );

    test('KIT-T10: every failure goes to the log it was given', () async {
      final seen = <String>[];
      await runBootSteps(
        _steps(<String>[], failAt: 'session'),
        log: (step, _) => seen.add(step),
      );
      expect(seen, ['session']);
    });

    test('KIT-T10: a failing background step goes to the log', () async {
      final seen = <String>[];
      await runBootSteps(
        _steps(<String>[], failAt: 'background'),
        log: (step, _) => seen.add(step),
      );
      await Future<void>.delayed(Duration.zero);
      expect(seen, ['background']);
    });
  });
}
