import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/state/view_state.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AuthRepository {}

void main() {
  late _Repository repository;
  late AuthCubit cubit;

  setUp(() {
    repository = _Repository();
    cubit = AuthCubit(repository);
  });
  tearDown(() => cubit.close());

  test('KIT-T16: each action reaches the repository once', () async {
    when(
      () => repository.signIn(identifier: 'a', password: 'b'),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.signUp(name: 'n', email: 'e', phone: 'p', password: 'w'),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.verifyCode('1'),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.requestPasswordReset('a'),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.resetPassword(identifier: 'a', code: '1', password: 'w'),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.completeProfile(name: 'n'),
    ).thenAnswer((_) async => const Right(unit));

    await cubit.signIn(identifier: 'a', password: 'b');
    await cubit.signUp(name: 'n', email: 'e', phone: 'p', password: 'w');
    await cubit.verifyCode('1');
    await cubit.requestPasswordReset('a');
    await cubit.resetPassword(identifier: 'a', code: '1', password: 'w');
    await cubit.completeProfile(name: 'n');

    expect(cubit.state, const ViewState<Unit>.success(unit));
    verify(() => repository.signIn(identifier: 'a', password: 'b')).called(1);
    verify(
      () => repository.signUp(name: 'n', email: 'e', phone: 'p', password: 'w'),
    ).called(1);
    verify(() => repository.verifyCode('1')).called(1);
    verify(() => repository.requestPasswordReset('a')).called(1);
    verify(
      () => repository.resetPassword(identifier: 'a', code: '1', password: 'w'),
    ).called(1);
    verify(() => repository.completeProfile(name: 'n')).called(1);
  });

  test('KIT-T16: a failure is the failure state', () async {
    when(
      () => repository.signIn(identifier: 'a', password: 'b'),
    ).thenAnswer((_) async => const Left(Unauthorized()));
    await cubit.signIn(identifier: 'a', password: 'b');
    expect(cubit.state.failure, const Unauthorized());
  });

  test(
    'KIT-T16: a second submit while one is in flight sends nothing',
    () async {
      final first = Completer<Either<Failure, Unit>>();
      when(
        () => repository.signIn(identifier: 'a', password: 'b'),
      ).thenAnswer((_) => first.future);
      final one = cubit.signIn(identifier: 'a', password: 'b');
      await cubit.signIn(identifier: 'a', password: 'b');
      await cubit.requestPasswordReset('a');
      first.complete(const Right(unit));
      await one;
      verify(() => repository.signIn(identifier: 'a', password: 'b')).called(1);
      verifyNever(() => repository.requestPasswordReset(any()));
      expect(cubit.state, const ViewState<Unit>.success(unit));
    },
  );

  test('KIT-T16: a new submit is allowed after a failure', () async {
    when(
      () => repository.signIn(identifier: 'a', password: 'b'),
    ).thenAnswer((_) async => const Left(NoConnection()));
    await cubit.signIn(identifier: 'a', password: 'b');
    await cubit.signIn(identifier: 'a', password: 'b');
    verify(() => repository.signIn(identifier: 'a', password: 'b')).called(2);
  });
}
