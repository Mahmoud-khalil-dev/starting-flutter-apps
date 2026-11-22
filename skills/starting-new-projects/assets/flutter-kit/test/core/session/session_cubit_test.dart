import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/session_user.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements SessionRepository {}

class _MockSignOut extends Mock implements SignOutService {}

void main() {
  late _Repository repository;
  late _MockSignOut signOut;
  late StreamController<SessionSnapshot> controller;

  setUp(() {
    repository = _Repository();
    signOut = _MockSignOut();
    when(() => repository.token).thenReturn('test-token');
    controller = StreamController<SessionSnapshot>.broadcast();
    when(() => repository.changes).thenAnswer((_) => controller.stream);
  });

  tearDown(() => controller.close());

  blocTest<SessionCubit, SessionState>(
    'KIT-T10: a stored token restores an authenticated session',
    build: () {
      when(() => repository.restore()).thenAnswer(
        (_) async => const SessionSnapshot(
          token: 'jwt',
          role: AppRole.admin,
          userStatus: UserStatus.active,
        ),
      );
      return SessionCubit(repository, signOut);
    },
    act: (cubit) => cubit.restore(),
    expect: () => [
      const SessionState.authenticated(
        role: AppRole.admin,
        userStatus: UserStatus.active,
        savedOnly: true,
      ),
    ],
  );

  blocTest<SessionCubit, SessionState>(
    'KIT-T10: no token restores a signed-out session',
    build: () {
      when(
        () => repository.restore(),
      ).thenAnswer((_) async => const SessionSnapshot());
      return SessionCubit(repository, signOut);
    },
    act: (cubit) => cubit.restore(),
    expect: () => [const SessionState.unauthenticated()],
  );

  blocTest<SessionCubit, SessionState>(
    'KIT-T10: two expiries at once end the session once, without the API',
    setUp: () =>
        when(() => signOut.run(byUser: false)).thenAnswer((_) async {}),
    build: () => SessionCubit(repository, signOut),
    seed: () => const SessionState.authenticated(
      role: AppRole.member,
      userStatus: UserStatus.active,
    ),
    // Two 401s at once: the second is ignored while the first is running.
    act: (cubit) => Future.wait([cubit.expire(), cubit.expire()]),
    expect: () => [const SessionState.unauthenticated()],
    verify: (_) => verify(() => signOut.run(byUser: false)).called(1),
  );

  blocTest<SessionCubit, SessionState>(
    'KIT-T10: a token with no cached user is authenticated with no role',
    build: () {
      when(
        () => repository.restore(),
      ).thenAnswer((_) async => const SessionSnapshot(token: 'jwt'));
      return SessionCubit(repository, signOut);
    },
    act: (cubit) => cubit.restore(),
    expect: () => [
      const SessionState.authenticated(
        role: null,
        userStatus: null,
        savedOnly: true,
      ),
    ],
  );

  blocTest<SessionCubit, SessionState>(
    'KIT-T10: two signOut calls at once run the user wipe once',
    seed: () => const SessionState.authenticated(
      role: AppRole.member,
      userStatus: UserStatus.active,
    ),
    setUp: () => when(() => signOut.run(byUser: true)).thenAnswer((_) async {}),
    build: () => SessionCubit(repository, signOut),
    act: (cubit) => Future.wait([cubit.signOut(), cubit.signOut()]),
    expect: () => [const SessionState.unauthenticated()],
    verify: (_) => verify(() => signOut.run(byUser: true)).called(1),
  );

  test('KIT-T10: a wipe that throws still leaves the cubit signed out and '
      'the next sign-out runs', () async {
    when(() => signOut.run(byUser: false)).thenThrow(StateError('bound'));
    final cubit = SessionCubit(repository, signOut)
      ..emit(
        const SessionState.authenticated(
          role: AppRole.member,
          userStatus: UserStatus.active,
        ),
      );
    await expectLater(cubit.expire(), throwsStateError);
    expect(cubit.state, const SessionState.unauthenticated());
    await expectLater(cubit.expire(), throwsStateError);
    verify(() => signOut.run(byUser: false)).called(2);
    await cubit.close();
  });

  group('KIT-T10: a token the OS will not read yet', () {
    blocTest<SessionCubit, SessionState>(
      'KIT-T10: an unreadable token leaves the session unknown',
      setUp: () => when(
        () => repository.restore(),
      ).thenAnswer((_) async => const SessionSnapshot(tokenUnreadable: true)),
      build: () => SessionCubit(repository, signOut),
      act: (cubit) => cubit.restore(),
      expect: () => <SessionState>[],
      verify: (cubit) => expect(cubit.state, const SessionState.unknown()),
    );

    blocTest<SessionCubit, SessionState>(
      'KIT-T10: retryRestore signs in once the read works',
      setUp: () {
        final answers = [
          const SessionSnapshot(tokenUnreadable: true),
          const SessionSnapshot(
            token: 'jwt',
            role: AppRole.member,
            userStatus: UserStatus.active,
          ),
        ];
        when(
          () => repository.restore(),
        ).thenAnswer((_) async => answers.removeAt(0));
      },
      build: () => SessionCubit(repository, signOut),
      act: (cubit) async {
        await cubit.restore();
        await cubit.retryRestore();
      },
      expect: () => [
        const SessionState.authenticated(
          role: AppRole.member,
          userStatus: UserStatus.active,
          savedOnly: true,
        ),
      ],
    );

    blocTest<SessionCubit, SessionState>(
      'KIT-T10: retryRestore signs out only when the read works and holds no token',
      setUp: () {
        final answers = [
          const SessionSnapshot(tokenUnreadable: true),
          const SessionSnapshot(),
        ];
        when(
          () => repository.restore(),
        ).thenAnswer((_) async => answers.removeAt(0));
      },
      build: () => SessionCubit(repository, signOut),
      act: (cubit) async {
        await cubit.restore();
        await cubit.retryRestore();
      },
      expect: () => [const SessionState.unauthenticated()],
    );

    blocTest<SessionCubit, SessionState>(
      'KIT-T10: retryRestore does nothing once the session is known',
      setUp: () => when(
        () => repository.restore(),
      ).thenAnswer((_) async => const SessionSnapshot()),
      build: () => SessionCubit(repository, signOut),
      act: (cubit) async {
        await cubit.restore();
        await cubit.retryRestore();
      },
      expect: () => [const SessionState.unauthenticated()],
      verify: (_) => verify(() => repository.restore()).called(1),
    );
  });

  test('KIT-T10: listeners hear each change, for the router', () async {
    when(
      () => repository.restore(),
    ).thenAnswer((_) async => const SessionSnapshot());
    final cubit = SessionCubit(repository, signOut);
    var heard = 0;
    void listener() => heard++;
    cubit.addListener(listener);
    await cubit.restore();
    await cubit.restore();
    expect(heard, 1);
    cubit.removeListener(listener);
    await cubit.close();
  });

  group('KIT-T10: the cubit follows the repository', () {
    blocTest<SessionCubit, SessionState>(
      'KIT-T10: a start elsewhere signs the cubit in with the user',
      build: () => SessionCubit(repository, signOut),
      act: (_) => controller.add(
        SessionSnapshot(
          token: 'test-token',
          role: AppRole.member,
          userStatus: UserStatus.active,
          user: SessionUser.fromJson(const {'id': 1, 'role': 'MEMBER'}),
        ),
      ),
      expect: () => [
        isA<SessionState>()
            .having((s) => s.status, 'status', SessionStatus.authenticated)
            .having((s) => s.user?.id, 'user', 1)
            .having((s) => s.savedOnly, 'savedOnly', isFalse),
      ],
    );

    blocTest<SessionCubit, SessionState>(
      'restore from the cache is saved-only until the refresh answers',
      setUp: () => when(repository.restore).thenAnswer(
        (_) async => const SessionSnapshot(
          token: 'test-token',
          role: AppRole.member,
          userStatus: UserStatus.active,
        ),
      ),
      build: () => SessionCubit(repository, signOut),
      act: (cubit) => cubit.restore(),
      expect: () => [
        isA<SessionState>().having((s) => s.savedOnly, 'savedOnly', isTrue),
      ],
    );

    test('refresh while signed out does nothing', () async {
      final cubit = SessionCubit(repository, signOut);
      expect(await cubit.refresh(), isNull);
      verifyNever(repository.refresh);
      await cubit.close();
    });
  });
}
