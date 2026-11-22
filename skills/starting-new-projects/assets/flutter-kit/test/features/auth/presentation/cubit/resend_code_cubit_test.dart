import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kit_app/features/auth/presentation/cubit/resend_code_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AuthRepository {}

void main() {
  late _Repository repository;

  setUp(() => repository = _Repository());

  test('KIT-T16: the cooldown counts down once a second', () {
    fakeAsync((async) {
      final cubit = ResendCodeCubit(repository, cooldownTicks: 3)
        ..startCooldown();
      expect(cubit.state.left, const Duration(seconds: 3));
      expect(cubit.state.canSend, isFalse);
      async.elapse(const Duration(seconds: 3));
      expect(cubit.state.ticksLeft, 0);
      expect(cubit.state.canSend, isTrue);
      cubit.close();
    });
  });

  test('KIT-T16: begin waits when the repository holds a fresh code', () {
    fakeAsync((async) {
      when(repository.takeCodeJustSent).thenReturn(true);
      final cubit = ResendCodeCubit(repository, cooldownTicks: 3)..begin();
      expect(cubit.state.ticksLeft, 3);
      cubit.close();
    });
  });

  test('KIT-T16: begin with justSent leaves no flag behind', () {
    fakeAsync((async) {
      when(repository.takeCodeJustSent).thenReturn(true);
      ResendCodeCubit(repository).begin(justSent: true);
      verify(repository.takeCodeJustSent).called(1);
    });
  });

  test('KIT-T16: begin on a cold open allows a send at once', () {
    fakeAsync((async) {
      when(repository.takeCodeJustSent).thenReturn(false);
      final cubit = ResendCodeCubit(repository, cooldownTicks: 3)..begin();
      expect(cubit.state.canSend, isTrue);
      cubit.close();
    });
  });

  test('KIT-T16: a resend counts and starts the cooldown again', () {
    fakeAsync((async) {
      when(repository.resendCode).thenAnswer((_) async => const Right(unit));
      final cubit = ResendCodeCubit(repository, cooldownTicks: 2)..resend();
      async.flushMicrotasks();
      expect(cubit.state.sentCount, 1);
      expect(cubit.state.ticksLeft, 2);
      cubit.resend();
      async.flushMicrotasks();
      verify(repository.resendCode).called(1);
      cubit.close();
    });
  });

  test('KIT-T16: a failed resend keeps the button ready', () {
    fakeAsync((async) {
      when(
        repository.resendCode,
      ).thenAnswer((_) async => const Left(NoConnection()));
      final cubit = ResendCodeCubit(repository)..resend();
      async.flushMicrotasks();
      expect(cubit.state.failure, const NoConnection());
      expect(cubit.state.canSend, isTrue);
      cubit.close();
    });
  });

  test('KIT-T16: closing stops the countdown', () {
    fakeAsync((async) {
      ResendCodeCubit(repository, cooldownTicks: 5)
        ..startCooldown()
        ..close();
      async.elapse(const Duration(seconds: 10));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('KIT-T16: a new cooldown replaces the running one', () {
    fakeAsync((async) {
      final cubit = ResendCodeCubit(repository, cooldownTicks: 4)
        ..startCooldown();
      async.elapse(const Duration(seconds: 2));
      cubit.startCooldown();
      expect(cubit.state.ticksLeft, 4);
      expect(async.pendingTimers, hasLength(1));
      cubit.close();
    });
  });

  test('KIT-T16: a resend that finishes after close starts no timer', () {
    fakeAsync((async) {
      final answer = Completer<Either<Failure, Unit>>();
      when(repository.resendCode).thenAnswer((_) => answer.future);
      final cubit = ResendCodeCubit(repository, cooldownTicks: 5)..resend();
      async.flushMicrotasks();
      cubit.close();
      answer.complete(const Right(unit));
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('KIT-T16: starting a cooldown after close starts no timer', () {
    fakeAsync((async) {
      ResendCodeCubit(repository)
        ..close()
        ..startCooldown();
      expect(async.pendingTimers, isEmpty);
    });
  });
}
