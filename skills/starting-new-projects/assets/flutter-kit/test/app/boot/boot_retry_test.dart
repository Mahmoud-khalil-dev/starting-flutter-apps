import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/boot/boot_retry.dart';

void main() {
  group('KIT-T10: singleFlight', () {
    test('KIT-T10: a second tap while a retry runs is ignored', () async {
      var runs = 0;
      final gate = Completer<void>();
      final tap = singleFlight(() async {
        runs++;
        await gate.future;
      });

      final first = tap();
      await tap();
      expect(runs, 1);
      gate.complete();
      await first;
    });

    test('KIT-T10: the next tap works once the retry has finished', () async {
      var runs = 0;
      final tap = singleFlight(() async => runs++);
      await tap();
      await tap();
      expect(runs, 2);
    });

    test('KIT-T10: the guard is released when a retry throws', () async {
      var runs = 0;
      final tap = singleFlight(() async {
        runs++;
        if (runs == 1) throw StateError('x');
      });
      await expectLater(tap(), throwsStateError);
      await tap();
      expect(runs, 2);
    });
  });

  group('KIT-T10: freshDependencies', () {
    test(
      'KIT-T10: the locator is reset before the graph is registered',
      () async {
        final log = <String>[];
        await freshDependencies(
          reset: () async => log.add('reset'),
          init: () async => log.add('init'),
        )();
        expect(log, ['reset', 'init']);
      },
    );

    test(
      'KIT-T10: a reset that throws does not stop the registration',
      () async {
        final log = <String>[];
        await freshDependencies(
          reset: () async => throw StateError('x'),
          init: () async => log.add('init'),
        )();
        expect(log, ['init']);
      },
    );

    test('KIT-T10: a failing registration still fails the step', () async {
      await expectLater(
        freshDependencies(
          reset: () async {},
          init: () async => throw StateError('deps'),
        )(),
        throwsStateError,
      );
    });
  });
}
