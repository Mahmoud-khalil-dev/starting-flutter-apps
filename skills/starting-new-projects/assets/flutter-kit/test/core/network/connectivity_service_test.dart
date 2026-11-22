import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/connectivity_service.dart';

/// Answers in order; the last answer repeats.
class _Probe {
  _Probe(this.answers);

  final List<bool> answers;
  int calls = 0;

  Future<bool> call() async => answers[min(calls++, answers.length - 1)];
}

({
  ConnectivityService service,
  StreamController<Object?> changes,
  List<ConnectionStatus> seen,
})
_setup(_Probe probe) {
  final changes = StreamController<Object?>();
  final service = ConnectivityService(
    changes: changes.stream,
    probe: probe.call,
  );
  final seen = <ConnectionStatus>[];
  service.statusChanges.listen(seen.add);
  return (service: service, changes: changes, seen: seen);
}

void main() {
  group('KIT-T9: ConnectivityService', () {
    test('the first check runs at start', () {
      fakeAsync((async) {
        final probe = _Probe([false]);
        final s = _setup(probe);
        unawaited(s.service.start());
        async.flushMicrotasks();
        expect(probe.calls, 1);
        expect(s.service.status, ConnectionStatus.offline);
        expect(s.service.isOnline, isFalse);
        expect(s.seen, [ConnectionStatus.offline]);
      });
    });

    test(
      'change events are debounced into one probe and never decide alone',
      () {
        fakeAsync((async) {
          final probe = _Probe([true]);
          final s = _setup(probe);
          unawaited(s.service.start());
          async.flushMicrotasks();
          for (var i = 0; i < 3; i++) {
            s.changes.add([ConnectivityResult.none]);
            async.elapse(const Duration(milliseconds: 500));
          }
          expect(probe.calls, 1);
          async.elapse(const Duration(seconds: 2));
          expect(probe.calls, 2);
          expect(s.service.status, ConnectionStatus.online);
        });
      },
    );

    test('offline re-probes every 15 s until online', () {
      fakeAsync((async) {
        final probe = _Probe([false, false, true]);
        final s = _setup(probe);
        unawaited(s.service.start());
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 15));
        expect(probe.calls, 2);
        expect(s.service.status, ConnectionStatus.offline);
        async.elapse(const Duration(seconds: 15));
        expect(probe.calls, 3);
        expect(s.service.status, ConnectionStatus.online);
        async.elapse(const Duration(seconds: 60));
        expect(probe.calls, 3);
        expect(s.seen, [ConnectionStatus.offline, ConnectionStatus.online]);
      });
    });

    test('two timeouts in the last five requests mean unstable', () {
      fakeAsync((async) {
        final s = _setup(_Probe([true]));
        unawaited(s.service.start());
        async.flushMicrotasks();
        s.service
          ..recordRequest(outcome: RequestOutcome.timedOut)
          ..recordRequest(outcome: RequestOutcome.ok)
          ..recordRequest(outcome: RequestOutcome.timedOut);
        expect(s.service.status, ConnectionStatus.unstable);
        expect(s.service.isOnline, isTrue);
        s.service
          ..recordRequest(outcome: RequestOutcome.ok)
          ..recordRequest(outcome: RequestOutcome.ok);
        expect(s.service.status, ConnectionStatus.unstable);
        s.service.recordRequest(outcome: RequestOutcome.ok);
        expect(s.service.status, ConnectionStatus.online);
      });
    });

    test('KIT-T9: a timed-out request never turns offline into online', () {
      fakeAsync((async) {
        final s = _setup(_Probe([false]));
        unawaited(s.service.start());
        async.flushMicrotasks();
        s.service.recordRequest(outcome: RequestOutcome.timedOut);
        expect(s.service.status, ConnectionStatus.offline);
      });
    });

    test(
      'KIT-T9: a failed request with no network does not turn offline to online',
      () {
        fakeAsync((async) {
          final s = _setup(_Probe([false]));
          unawaited(s.service.start());
          async.flushMicrotasks();
          s.service.recordRequest(outcome: RequestOutcome.failed);
          expect(s.service.status, ConnectionStatus.offline);
          s.service.recordRequest(outcome: RequestOutcome.ok);
          expect(s.service.status, ConnectionStatus.online);
        });
      },
    );

    test('KIT-T9: a successful request turns offline into online', () {
      fakeAsync((async) {
        final s = _setup(_Probe([false]));
        unawaited(s.service.start());
        async.flushMicrotasks();
        s.seen.clear();
        s.service.recordRequest(outcome: RequestOutcome.ok);
        async.flushMicrotasks();
        expect(s.service.status, ConnectionStatus.online);
        expect(s.seen, [ConnectionStatus.online]);
      });
    });

    test('paused ignores events and stops re-probing; resume rechecks', () {
      fakeAsync((async) {
        final probe = _Probe([false, true]);
        final s = _setup(probe);
        unawaited(s.service.start());
        async.flushMicrotasks();
        s.service.pause();
        s.changes.add([ConnectivityResult.wifi]);
        async.elapse(const Duration(seconds: 60));
        expect(probe.calls, 1);
        s.service.resume();
        async.elapse(const Duration(seconds: 2));
        expect(probe.calls, 2);
        expect(s.service.status, ConnectionStatus.online);
      });
    });
    test('dispose stops probing, events, resume and emits', () {
      fakeAsync((async) {
        final probe = _Probe([false]);
        final s = _setup(probe);
        unawaited(s.service.start());
        async.flushMicrotasks();
        unawaited(s.service.dispose());
        async.flushMicrotasks();
        s.service.resume();
        s.changes.add([ConnectivityResult.wifi]);
        async.elapse(const Duration(seconds: 60));
        expect(probe.calls, 1);
        expect(s.seen, [ConnectionStatus.offline]);
      });
    });

    test('dispose during a probe: no emit and no error when it completes', () {
      fakeAsync((async) {
        final gate = Completer<bool>();
        final changes = StreamController<Object?>();
        final service = ConnectivityService(
          changes: changes.stream,
          probe: () => gate.future,
        );
        final seen = <ConnectionStatus>[];
        service.statusChanges.listen(seen.add);
        unawaited(service.start());
        async.flushMicrotasks();
        unawaited(service.dispose());
        async.flushMicrotasks();
        gate.complete(false);
        async.elapse(const Duration(seconds: 60));
        expect(seen, isEmpty);
        expect(service.status, ConnectionStatus.online);
      });
    });
  });

  test('KIT-T9: a request that finishes after dispose records nothing', () {
    fakeAsync((async) {
      final s = _setup(_Probe([true]));
      unawaited(s.service.start());
      async.flushMicrotasks();
      unawaited(s.service.dispose());
      async.flushMicrotasks();
      s.service
        ..recordRequest(outcome: RequestOutcome.timedOut)
        ..recordRequest(outcome: RequestOutcome.timedOut);
      async.flushMicrotasks();
      expect(s.service.status, ConnectionStatus.online);
      expect(s.seen, isEmpty);
    });
  });
}
