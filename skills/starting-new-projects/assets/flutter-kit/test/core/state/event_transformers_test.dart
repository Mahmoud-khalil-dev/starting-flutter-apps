import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/state/event_transformers.dart';

Stream<int> _same(int event) => Stream.value(event);

void main() {
  test('KIT-T14: debounce passes only the last event of a burst', () {
    fakeAsync((async) {
      final input = StreamController<int>();
      final out = <int>[];
      debounce<int>(searchDebounce)(input.stream, _same).listen(out.add);
      input
        ..add(1)
        ..add(2);
      async.elapse(const Duration(milliseconds: 200));
      input.add(3);
      async.elapse(const Duration(milliseconds: 299));
      expect(out, isEmpty);
      async
        ..elapse(const Duration(milliseconds: 1))
        ..flushMicrotasks();
      expect(out, [3]);
    });
  });

  test('KIT-T14: throttle passes the first event and drops the window', () {
    fakeAsync((async) {
      final input = StreamController<int>();
      final out = <int>[];
      throttle<int>(const Duration(milliseconds: 300))(
        input.stream,
        _same,
      ).listen(out.add);
      input.add(1);
      async
        ..flushMicrotasks()
        ..elapse(const Duration(milliseconds: 100));
      input.add(2);
      async.elapse(const Duration(milliseconds: 200));
      input.add(3);
      async.flushMicrotasks();
      expect(out, [1, 3]);
    });
  });

  test('KIT-T14: closing a Bloc drops a pending debounced event', () {
    fakeAsync((async) {
      final out = <int>[];
      final bloc = _EchoBloc(debounce<int>(searchDebounce), out)..add(1);
      async.flushMicrotasks();
      unawaited(bloc.close());
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 1));
      expect(out, isEmpty);
      expect(async.nonPeriodicTimerCount, 0);
    });
  });

  test('KIT-T14: closing a Bloc leaves no throttle timer behind', () {
    fakeAsync((async) {
      final out = <int>[];
      final bloc = _EchoBloc(throttle<int>(const Duration(seconds: 1)), out)
        ..add(1);
      async.flushMicrotasks();
      expect(out, [1]);
      unawaited(bloc.close());
      async.flushMicrotasks();
      expect(async.nonPeriodicTimerCount, 0);
    });
  });
}

class _EchoBloc extends Bloc<int, int> {
  _EchoBloc(EventTransformer<int> transformer, List<int> out) : super(0) {
    on<int>((event, emit) => out.add(event), transformer: transformer);
  }
}
