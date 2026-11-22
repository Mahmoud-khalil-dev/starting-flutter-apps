import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/boot/background_boot.dart';

Future<void> _run(List<String> log, {Set<String> fail = const {}}) =>
    runBackgroundBoot(
      registerRecovery: () {
        log.add('recovery');
        if (fail.contains('recovery')) throw StateError('recovery');
      },
      wireLifecycle: () {
        log.add('wire');
        if (fail.contains('wire')) throw StateError('connectivity lookup');
      },
      work: () async {
        log.add('work');
        if (fail.contains('work')) throw StateError('work');
      },
      refresh: () async {
        log.add('refresh');
      },
    );

void main() {
  group('KIT-T10: the background boot step', () {
    test(
      'KIT-T10: it runs in order: recovery, wiring, work, refresh',
      () async {
        final log = <String>[];
        await _run(log);
        expect(log, ['recovery', 'wire', 'work', 'refresh']);
      },
    );

    test('KIT-T10: session recovery is registered even when the connectivity '
        'lookup throws', () async {
      final log = <String>[];
      await _run(log, fail: {'wire'});
      expect(log.first, 'recovery');
      expect(log, containsAllInOrder(['recovery', 'wire', 'work', 'refresh']));
    });

    test('KIT-T10: no wiring without a recovery to wire', () async {
      final log = <String>[];
      await _run(log, fail: {'recovery'});
      expect(log, ['recovery', 'work', 'refresh']);
    });

    test('KIT-T10: the refresh still runs when the work throws', () async {
      final log = <String>[];
      await _run(log, fail: {'work'});
      expect(log.last, 'refresh');
    });
  });
}
