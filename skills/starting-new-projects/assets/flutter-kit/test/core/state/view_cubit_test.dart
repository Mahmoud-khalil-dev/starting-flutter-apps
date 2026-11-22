import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/state/safe_cubit.dart';
import 'package:kit_app/core/state/view_cubit.dart';
import 'package:kit_app/core/state/view_state.dart';

class _Counter extends SafeCubit<int> {
  _Counter() : super(0);

  void bump() => emit(state + 1);
}

void main() {
  test('KIT-T14: a safe Cubit ignores an emit after close', () async {
    final counter = _Counter();
    await counter.close();
    expect(counter.bump, returnsNormally);
    expect(counter.state, 0);
  });

  test('KIT-T14: run emits loading, then success', () async {
    final cubit = ViewCubit<List<int>>();
    addTearDown(cubit.close);
    final states = <ViewState<List<int>>>[];
    final sub = cubit.stream.listen(states.add);
    addTearDown(sub.cancel);
    await cubit.run(() async => const Right([1, 2]));
    await pumpEventQueue();
    expect(states, const [
      ViewState<List<int>>.loading(),
      ViewState<List<int>>.success([1, 2]),
    ]);
  });

  test('KIT-T14: an empty answer is the empty state', () async {
    final cubit = ViewCubit<List<int>>();
    addTearDown(cubit.close);
    await cubit.run(
      () async => const Right(<int>[]),
      isEmpty: (list) => list.isEmpty,
    );
    expect(cubit.state.status, ViewStatus.empty);
  });

  test('KIT-T14: a failure keeps the data already shown', () async {
    final cubit = ViewCubit<int>();
    addTearDown(cubit.close);
    await cubit.run(() async => const Right(7));
    await cubit.run(() async => const Left(NoConnection()));
    expect(
      cubit.state,
      const ViewState<int>.failure(NoConnection(), previous: 7),
    );
  });

  test('KIT-T14: only the latest run lands', () async {
    final cubit = ViewCubit<int>();
    addTearDown(cubit.close);
    final slow = Completer<Either<Failure, int>>();
    final first = cubit.run(() => slow.future);
    await cubit.run(() async => const Right(2));
    slow.complete(const Right(1));
    await first;
    expect(cubit.state.data, 2);
  });

  test('KIT-T14: an answer after close is dropped, not thrown', () async {
    final cubit = ViewCubit<int>();
    final slow = Completer<Either<Failure, int>>();
    final pending = cubit.run(() => slow.future);
    await cubit.close();
    slow.complete(const Right(1));
    await expectLater(pending, completes);
  });
}
