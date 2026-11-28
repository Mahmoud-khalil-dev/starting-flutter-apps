import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_remote_source.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_user.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRemote extends Mock implements SessionRemoteSource {}

class _MockSecure extends Mock implements FlutterSecureStorage {}

const _member = '{"id":1,"role":"MEMBER","status":"ACTIVE"}';
const _admin = '{"id":2,"role":"ADMIN","status":"ACTIVE"}';

Future<SessionRepository> _repository({String? token, String? user}) async {
  FlutterSecureStorage.setMockInitialValues({'token': ?token});
  SharedPreferences.setMockInitialValues({'user': ?user});
  return SessionRepository(
    const SecureStorage(FlutterSecureStorage()),
    AppPreferences(await SharedPreferences.getInstance()),
    _MockRemote(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KIT-T10: only the named user fields are saved to the device', () async {
    final repository = await _repository();
    await repository.start(
      token: 'test-token',
      user: {'id': 1, 'role': 'MEMBER', 'name': 'A', 'national_id': '123'},
    );
    final prefs = await SharedPreferences.getInstance();
    final saved = SessionRepository.cachedUser(prefs.getString('user'))!;
    expect(saved, {'id': 1, 'role': 'MEMBER', 'name': 'A'});
    expect(repository.user!.raw['national_id'], '123');
  });

  group('KIT-T10: the cached user', () {
    for (final (name, json, role) in [
      ('a member', _member, AppRole.member),
      ('an admin', _admin, AppRole.admin),
    ]) {
      test('KIT-T10: $name gives $role and a known status', () {
        final user = SessionRepository.cachedUser(json);
        expect(AppRole.parse(user?['role']), role);
        expect(UserStatus.parse(user?['status']), isNotNull);
      });
    }

    test('a broken or empty value gives no user', () {
      expect(SessionRepository.cachedUser(null), isNull);
      expect(SessionRepository.cachedUser('not json'), isNull);
      expect(SessionRepository.cachedUser('[]'), isNull);
      expect(SessionRepository.cachedUser('"text"'), isNull);
    });

    test('an unknown role or status is denied, not guessed', () {
      expect(AppRole.parse('VISITOR'), isNull);
      expect(AppRole.parse(null), isNull);
      expect(UserStatus.parse('SUSPENDED'), isNull);
      expect(UserStatus.parse('INACTIVE'), UserStatus.inactive);
      expect(UserStatus.parse('BLOCKED'), UserStatus.blocked);
    });
  });

  group('KIT-T10: SessionRepository', () {
    test('restore reads the token and the cached role', () async {
      final repository = await _repository(token: 'jwt', user: _admin);
      final snapshot = await repository.restore();
      expect(snapshot.hasToken, isTrue);
      expect(snapshot.role, AppRole.admin);
      expect(snapshot.userStatus, UserStatus.active);
      expect(repository.token, 'jwt');
    });

    test('no token restores a signed-out snapshot', () async {
      final snapshot = await (await _repository()).restore();
      expect(snapshot.hasToken, isFalse);
    });

    test('ending the session deletes the token only', () async {
      final repository = await _repository(token: 'jwt', user: '{}');
      await repository.restore();
      await repository.endSession();
      expect(repository.token, isNull);
      expect(await const FlutterSecureStorage().read(key: 'token'), isNull);
      expect((await SharedPreferences.getInstance()).getString('user'), '{}');
    });
  });

  group('KIT-T10: the session repository', () {
    late _MockSecure secure;
    late _MockRemote remote;
    late AppPreferences prefs;
    late SessionRepository repository;
    const user = <String, dynamic>{
      'id': 1,
      'name': 'Test Member',
      'role': 'MEMBER',
      'status': 'ACTIVE',
    };

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = AppPreferences(await SharedPreferences.getInstance());
      secure = _MockSecure();
      remote = _MockRemote();
      when(
        () => secure.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      repository = SessionRepository(SecureStorage(secure), prefs, remote);
    });

    test(
      'KIT-T10: a profile answer after sign-out writes nothing back',
      () async {
        final answer = Completer<Object?>();
        when(() => remote.fetchProfile()).thenAnswer((_) => answer.future);
        when(
          () => secure.delete(key: any(named: 'key')),
        ).thenAnswer((_) async {});
        final refreshing = repository.refresh();
        await repository.endSession();
        answer.complete({'data': user});
        final result = await refreshing;
        expect(result.isLeft(), isTrue);
        expect(prefs.userJson, isNull);
        expect(repository.user, isNull);
      },
    );

    test(
      'KIT-T10: a restore that lands after sign-out puts nothing back',
      () async {
        SharedPreferences.setMockInitialValues({'user': jsonEncode(user)});
        prefs = AppPreferences(await SharedPreferences.getInstance());
        repository = SessionRepository(SecureStorage(secure), prefs, remote);
        final read = Completer<String?>();
        when(
          () => secure.read(key: any(named: 'key')),
        ).thenAnswer((_) => read.future);
        when(
          () => secure.delete(key: any(named: 'key')),
        ).thenAnswer((_) async {});
        final restoring = repository.restore();
        await repository.endSession();
        read.complete('old-token');
        await restoring;
        expect(repository.token, isNull);
        expect(repository.user, isNull);
      },
    );

    test(
      'KIT-T10: start writes the token key and the user object as received',
      () async {
        final changes = repository.changes.first;
        await repository.start(token: 'test-token', user: user);
        verify(() => secure.write(key: 'token', value: 'test-token')).called(1);
        expect(jsonDecode(prefs.userJson!), user);
        final snapshot = await changes;
        expect(snapshot.role, AppRole.member);
        expect(snapshot.user!.name, 'Test Member');
        expect(repository.token, 'test-token');
      },
    );

    test(
      'KIT-T10: an unreadable token is flagged, not taken for none',
      () async {
        await prefs.setUserJson(jsonEncode(user));
        when(
          () => secure.read(key: 'token'),
        ).thenThrow(PlatformException(code: '-25308'));
        final snapshot = await repository.restore();
        expect(snapshot.tokenUnreadable, isTrue);
        expect(snapshot.token, isNull);
        expect(snapshot.user?.name, 'Test Member');
      },
    );

    test(
      'KIT-T10: the generation moves when a session starts and when one ends',
      () async {
        final before = repository.generation;
        await repository.start(token: 'test-token', user: user);
        final started = repository.generation;
        expect(started, greaterThan(before));
        repository.invalidate();
        final ending = repository.generation;
        expect(ending, greaterThan(started));
        when(
          () => secure.delete(key: any(named: 'key')),
        ).thenAnswer((_) async {});
        await repository.endSession();
        expect(repository.generation, greaterThan(ending));
      },
    );

    group('KIT-T10: a null token read outside the foreground', () {
      SessionRepository build({required bool foreground}) {
        when(() => secure.read(key: 'token')).thenAnswer((_) async => null);
        return SessionRepository(
          SecureStorage(secure),
          prefs,
          remote,
          isForeground: () => foreground,
        );
      }

      test(
        'KIT-T10: null while not resumed is unreadable, not signed out',
        () async {
          final snapshot = await build(foreground: false).restore();
          expect(snapshot.tokenUnreadable, isTrue);
          expect(snapshot.hasToken, isFalse);
        },
      );

      test('KIT-T10: null while resumed is signed out', () async {
        final snapshot = await build(foreground: true).restore();
        expect(snapshot.tokenUnreadable, isFalse);
        expect(snapshot.hasToken, isFalse);
      });

      test('KIT-T10: a token read while not resumed is a token', () async {
        when(
          () => secure.read(key: 'token'),
        ).thenAnswer((_) async => 'test-token');
        final snapshot = await SessionRepository(
          SecureStorage(secure),
          prefs,
          remote,
          isForeground: () => false,
        ).restore();
        expect(snapshot.tokenUnreadable, isFalse);
        expect(snapshot.hasToken, isTrue);
      });
    });

    test('refresh saves the profile and publishes it', () async {
      await repository.start(token: 'test-token', user: user);
      when(remote.fetchProfile).thenAnswer(
        (_) async => {
          'data': {...user, 'status': 'BLOCKED'},
        },
      );
      final result = await repository.refresh();
      expect(result.isRight(), isTrue);
      expect(repository.user!.status, UserStatus.blocked);
      expect(
        SessionRepository.cachedUser(prefs.userJson)!['status'],
        'BLOCKED',
      );
    });

    test('refresh offline keeps the saved user', () async {
      await repository.start(token: 'test-token', user: user);
      when(remote.fetchProfile).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(
        await repository.refresh(),
        const Left<Failure, SessionUser>(NoConnection()),
      );
      expect(repository.user!.name, 'Test Member');
    });

    test('a profile body with no user is an unknown failure', () async {
      when(remote.fetchProfile).thenAnswer((_) async => {'data': 'x'});
      expect(
        await repository.refresh(),
        const Left<Failure, SessionUser>(UnknownFailure()),
      );
    });
  });
  group('KIT-T10: a token write that lands late', () {
    test(
      'a sign-out during a sign-in token write leaves no token stored',
      () async {
        SharedPreferences.setMockInitialValues({});
        final secure = _MockSecure();
        final writing = Completer<void>();
        String? stored;
        when(
          () => secure.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((invocation) async {
          await writing.future;
          stored = invocation.namedArguments[#value] as String?;
        });
        when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {
          stored = null;
        });
        final repository = SessionRepository(
          SecureStorage(secure),
          AppPreferences(await SharedPreferences.getInstance()),
          _MockRemote(),
        );
        final signIn = repository.start(token: 'late', user: {'id': 1});
        await pumpEventQueue();
        // The sign-out deletes while the write is still on its way.
        repository.invalidate();
        final signOut = repository.endSession();
        await pumpEventQueue();
        writing.complete();
        await signIn;
        await signOut;
        expect(stored, isNull);
        expect(repository.token, isNull);
      },
    );
  });
}
