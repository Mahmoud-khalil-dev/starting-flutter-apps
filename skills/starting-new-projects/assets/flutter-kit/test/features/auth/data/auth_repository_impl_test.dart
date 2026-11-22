import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_user.dart';
import 'package:kit_app/features/auth/data/models/auth_result.dart';
import 'package:kit_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kit_app/features/auth/data/sources/auth_remote_source.dart';
import 'package:mocktail/mocktail.dart';

class _Remote extends Mock implements AuthRemoteSource {}

class _Session extends Mock implements SessionRepository {}

const Map<String, Object> _user = {
  'id': 7,
  'name': 'Sara',
  'status': 'active',
  'role': 'member',
};

void main() {
  late _Remote remote;
  late _Session session;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _Remote();
    session = _Session();
    repository = AuthRepositoryImpl(remote, session);
    when(
      () => session.start(
        token: any(named: 'token'),
        user: any(named: 'user'),
      ),
    ).thenAnswer((_) async {});
    when(() => session.generation).thenReturn(0);
    when(
      () => session.saveUser(any(), generation: any(named: 'generation')),
    ).thenAnswer((_) async {});
  });

  test('KIT-T16: a sign-in answer starts the session', () async {
    when(
      () => remote.signIn(identifier: 'a@b.co', password: 'secret1a'),
    ).thenAnswer(
      (_) async => {
        'data': {'token': 'session-token', 'user': _user},
      },
    );
    expect(
      await repository.signIn(identifier: 'a@b.co', password: 'secret1a'),
      const Right<Failure, Unit>(unit),
    );
    verify(() => session.start(token: 'session-token', user: _user)).called(1);
  });

  test('KIT-T16: a sign-up answer starts the session', () async {
    when(
      () => remote.signUp(
        name: 'Sara',
        email: 'a@b.co',
        phone: '0501234567',
        password: 'secret1a',
      ),
    ).thenAnswer(
      (_) async => {
        'data': {'token': 'session-token', 'user': _user},
      },
    );
    expect(
      await repository.signUp(
        name: 'Sara',
        email: 'a@b.co',
        phone: '0501234567',
        password: 'secret1a',
      ),
      const Right<Failure, Unit>(unit),
    );
    verify(() => session.start(token: 'session-token', user: _user)).called(1);
  });

  test('KIT-T16: an answer without a token is an unknown failure', () async {
    when(
      () => remote.signIn(
        identifier: any(named: 'identifier'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => {'data': <String, Object?>{}});
    expect(
      await repository.signIn(identifier: 'x', password: 'y'),
      const Left<Failure, Unit>(UnknownFailure()),
    );
    verifyNever(
      () => session.start(
        token: any(named: 'token'),
        user: any(named: 'user'),
      ),
    );
  });

  test('KIT-T16: a 401 on sign-in is Unauthorized, not a sign-out', () async {
    final options = RequestOptions(path: '/sign-in');
    when(
      () => remote.signIn(
        identifier: any(named: 'identifier'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: 401),
      ),
    );
    final result = await repository.signIn(identifier: 'x', password: 'y');
    expect(result.fold((f) => f, (_) => null), isA<Unauthorized>());
  });

  test('KIT-T16: a verified code saves the returned user', () async {
    when(() => remote.verifyCode('1234')).thenAnswer(
      (_) async => {
        'data': {'user': _user},
      },
    );
    expect(
      await repository.verifyCode('1234'),
      const Right<Failure, Unit>(unit),
    );
    verify(() => session.saveUser(_user, generation: 0)).called(1);
  });

  test('KIT-T16: a verified code with no user refreshes the profile', () async {
    when(() => remote.verifyCode('1234')).thenAnswer((_) async => null);
    when(
      session.refresh,
    ).thenAnswer((_) async => Right(SessionUser.fromJson(_user)!));
    expect(
      await repository.verifyCode('1234'),
      const Right<Failure, Unit>(unit),
    );
    verify(session.refresh).called(1);
  });

  test('KIT-T16: a failed refresh after a code is the failure', () async {
    when(
      () => remote.completeProfile(name: 'Sara'),
    ).thenAnswer((_) async => null);
    when(session.refresh).thenAnswer((_) async => const Left(NoConnection()));
    expect(
      await repository.completeProfile(name: 'Sara'),
      const Left<Failure, Unit>(NoConnection()),
    );
  });

  test('KIT-T16: resend and reset touch no session', () async {
    when(() => remote.resendCode()).thenAnswer((_) async => null);
    when(
      () => remote.requestPasswordReset('a@b.co'),
    ).thenAnswer((_) async => null);
    when(
      () => remote.resetPassword(
        identifier: 'a@b.co',
        code: '1234',
        password: 'secret1a',
      ),
    ).thenAnswer((_) async => null);
    expect(await repository.resendCode(), const Right<Failure, Unit>(unit));
    expect(
      await repository.requestPasswordReset('a@b.co'),
      const Right<Failure, Unit>(unit),
    );
    expect(
      await repository.resetPassword(
        identifier: 'a@b.co',
        code: '1234',
        password: 'secret1a',
      ),
      const Right<Failure, Unit>(unit),
    );
    verifyZeroInteractions(session);
  });

  test('KIT-T16: an auth result needs both a token and a user', () {
    expect(AuthResult.fromBody(null), isNull);
    expect(
      AuthResult.fromBody({
        'data': {'token': '', 'user': _user},
      }),
      isNull,
    );
    expect(
      AuthResult.fromBody({
        'data': {'token': 't', 'user': _user},
      }),
      const AuthResult(token: 't', user: _user),
    );
  });

  group('KIT-T16: code just sent', () {
    const signUpArgs = (
      name: 'Sara',
      email: 'a@b.co',
      phone: '+100',
      password: 'secret1a',
    );

    Future<void> signUp() => repository.signUp(
      name: signUpArgs.name,
      email: signUpArgs.email,
      phone: signUpArgs.phone,
      password: signUpArgs.password,
    );

    test('a cold repository holds no fresh code', () {
      expect(repository.takeCodeJustSent(), isFalse);
    });

    test('a sign-up is a fresh code, taken once', () async {
      when(
        () => remote.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {'token': 't', 'user': _user},
        },
      );
      await signUp();
      expect(repository.takeCodeJustSent(), isTrue);
      expect(repository.takeCodeJustSent(), isFalse);
    });

    test('a failed sign-up leaves no fresh code', () async {
      when(
        () => remote.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
        ),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));
      await signUp();
      expect(repository.takeCodeJustSent(), isFalse);
    });

    test('forgetting drops a fresh code', () async {
      when(
        () => remote.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {'token': 't', 'user': _user},
        },
      );
      await signUp();
      repository.forgetCodeJustSent();
      expect(repository.takeCodeJustSent(), isFalse);
    });

    test('a fresh code goes stale after the cooldown', () async {
      var now = DateTime(2026);
      final timed = AuthRepositoryImpl(remote, session, now: () => now);
      when(
        () => remote.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {'token': 't', 'user': _user},
        },
      );
      await timed.signUp(
        name: 'Sara',
        email: 'a@b.co',
        phone: '+100',
        password: 'secret1a',
      );
      now = now.add(const Duration(minutes: 2));
      expect(timed.takeCodeJustSent(), isFalse);
    });
  });
}
