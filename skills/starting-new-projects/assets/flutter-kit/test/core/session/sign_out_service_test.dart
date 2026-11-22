import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/auth_interceptor.dart';
import 'package:kit_app/core/session/session_bound.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_remote_source.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/secure_storage.dart';
import 'package:kit_app/core/storage/storage_keys.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/stub_adapter.dart';

class _MockSession extends Mock implements SessionRepository {}

class _MockRemote extends Mock implements SessionRemoteSource {}

class _MockBound extends Mock implements SessionBound {}

class _MockHook extends Mock implements SignOutHook {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSession session;
  late _MockRemote remote;
  late _MockBound bound;
  late _MockHook hook;
  late AppPreferences prefs;
  final order = <String>[];

  Future<SignOutService> service({Map<String, Object>? seed}) async {
    SharedPreferences.setMockInitialValues({
      for (final key in StorageKeys.userData) key: 'x',
      for (final key in StorageKeys.device) key: 'kept',
      ...?seed,
    });
    prefs = AppPreferences(await SharedPreferences.getInstance());
    final registry = SessionBoundRegistry()..add(() => bound);
    return SignOutService(
      session: session,
      remote: remote,
      preferences: prefs,
      bound: registry,
      hooks: () => [hook],
      logoutWait: const Duration(milliseconds: 50),
    );
  }

  setUp(() {
    order.clear();
    session = _MockSession();
    remote = _MockRemote();
    bound = _MockBound();
    hook = _MockHook();
    when(() => session.token).thenReturn('test-token');
    when(session.endSession).thenAnswer((_) async {
      order.add('token');
    });
    when(() => remote.logout(any())).thenAnswer((_) async {
      order.add('api');
    });
    when(bound.reset).thenAnswer((_) {
      order.add('bound');
    });
    when(() => hook.onSignOut(byUser: any(named: 'byUser'))).thenAnswer((
      _,
    ) async {
      order.add('hook');
    });
  });

  group('KIT-T10: sign-out', () {
    test(
      'KIT-T10: logout carries the token captured before the wipe',
      () async {
        await (await service()).run(byUser: true);
        verify(() => remote.logout('test-token')).called(1);
        expect(order.first, 'api');
        expect(order, containsAll(['hook', 'bound', 'token']));
      },
    );

    test(
      'KIT-T10: the session generation moves before the first hook runs',
      () async {
        when(session.invalidate).thenAnswer((_) => order.add('invalidate'));
        await (await service()).run(byUser: true);
        expect(order.indexOf('invalidate'), isNonNegative);
        expect(order.indexOf('invalidate'), lessThan(order.indexOf('hook')));
      },
    );

    test('user data goes and device choices stay', () async {
      await (await service()).run(byUser: true);
      for (final key in StorageKeys.userData) {
        expect(prefs.read(key), isNull, reason: key);
      }
      for (final key in StorageKeys.device) {
        expect(prefs.read(key), 'kept', reason: key);
      }
    });

    test('a failing or slow API never blocks the wipe', () async {
      when(
        () => remote.logout(any()),
      ).thenAnswer((_) => Completer<void>().future);
      await (await service()).run(byUser: true);
      verify(session.endSession).called(1);
    });

    test('a failing hook still wipes', () async {
      when(
        () => hook.onSignOut(byUser: any(named: 'byUser')),
      ).thenThrow(StateError('hook'));
      await (await service()).run(byUser: true);
      verify(session.endSession).called(1);
    });

    test('a failing bound cubit still deletes the token', () async {
      when(bound.reset).thenThrow(StateError('bound'));
      await expectLater((await service()).run(byUser: false), throwsStateError);
      verify(session.endSession).called(1);
    });

    test('an expiry does not call the API', () async {
      await (await service()).run(byUser: false);
      verifyNever(() => remote.logout(any()));
      verify(() => hook.onSignOut(byUser: false)).called(1);
    });

    test('wiped fires last, so a reload reads empty storage', () async {
      final signOut = await service();
      String? userSeenByReload = 'not read';
      final seen = signOut.wiped.first.then((_) {
        order.add('wiped');
        userSeenByReload = prefs.userJson;
      });
      await signOut.run(byUser: true);
      await seen;
      expect(order.last, 'wiped');
      expect(order, containsAllInOrder(['token', 'hook', 'bound']));
      expect(userSeenByReload, isNull);
    });
  });

  group('KIT-T10: what a sign-out keeps and wipes, key by key', () {
    const wiped = ['user'];
    const kept = [
      'endOnboarding',
      'settings.themeMode',
      'settings.locale',
      'settings.textScale',
      'storage_schema',
      'permissions_asked',
      'permissions_granted',
    ];

    test('the two lists cover every key the app persists, once', () {
      final all = {...StorageKeys.preferences};
      expect({...wiped, ...kept}, all);
      expect(wiped.length + kept.length, all.length);
    });

    for (final key in wiped) {
      test('$key is wiped', () async {
        final signOut = await service(seed: {for (final k in wiped) k: 'x'});
        await signOut.run(byUser: true);
        expect(prefs.read(key), isNull);
      });
    }

    for (final key in kept) {
      test('$key is kept', () async {
        final signOut = await service(seed: {key: 'device-choice'});
        await signOut.run(byUser: true);
        expect(prefs.read(key), 'device-choice');
      });
    }

    test('a user sign-out and an expiry wipe the same keys', () async {
      for (final byUser in [true, false]) {
        final signOut = await service();
        await signOut.run(byUser: byUser);
        for (final key in wiped) {
          expect(prefs.read(key), isNull, reason: '$key byUser=$byUser');
        }
      }
    });
  });

  group('KIT-T10: the logout request carries the token', () {
    test('the request has its bearer header although the session is already '
        'wiped when it leaves', () async {
      FlutterSecureStorage.setMockInitialValues({'token': 'test-token'});
      SharedPreferences.setMockInitialValues({
        'user': '{"id":1,"role":"MEMBER"}',
      });
      final preferences = AppPreferences(await SharedPreferences.getInstance());
      late SessionRepository real;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      final adapter = StubAdapter((_) async => jsonBody({'ok': true}));
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(
          readToken: () => real.token,
          readLanguage: () => 'en',
          onSessionExpired: () {},
          signInPaths: const {'/sign-in'},
        ),
      );
      real = SessionRepository(
        const SecureStorage(FlutterSecureStorage()),
        preferences,
        SessionRemoteSource(dio),
      );
      await real.restore();
      expect(real.token, 'test-token');
      final signOut = SignOutService(
        session: real,
        remote: SessionRemoteSource(dio),
        preferences: preferences,
        bound: SessionBoundRegistry(),
        hooks: () => const [],
      );
      await signOut.run(byUser: true);
      final sent = adapter.requests.single;
      expect(sent.path, ApiEndpoints.logout);
      expect(sent.headers['Authorization'], 'Bearer test-token');
      expect(real.token, isNull);
      expect(preferences.userJson, isNull);
      expect(await const FlutterSecureStorage().read(key: 'token'), isNull);
    });

    test('a signed-out user with no token sends no request', () async {
      when(() => session.token).thenReturn(null);
      await (await service()).run(byUser: true);
      verifyNever(() => remote.logout(any()));
      verify(session.endSession).called(1);
    });

    test('an empty token sends no request', () async {
      when(() => session.token).thenReturn('');
      await (await service()).run(byUser: true);
      verifyNever(() => remote.logout(any()));
    });

    test('a logout request that throws is ignored', () async {
      when(() => remote.logout(any())).thenAnswer(
        (_) => Future<void>.error(
          DioException(
            requestOptions: RequestOptions(path: ApiEndpoints.logout),
          ),
        ),
      );
      await (await service()).run(byUser: true);
      verify(session.endSession).called(1);
    });
  });

  group('KIT-T10: every bound Cubit resets, even after one fails', () {
    test('a failing first bound does not skip the second', () async {
      final second = _MockBound();
      when(second.reset).thenReturn(null);
      when(bound.reset).thenThrow(StateError('first'));
      final registry = SessionBoundRegistry()
        ..add(() => bound)
        ..add(() => second);
      SharedPreferences.setMockInitialValues({});
      final signOut = SignOutService(
        session: session,
        remote: remote,
        preferences: AppPreferences(await SharedPreferences.getInstance()),
        bound: registry,
        hooks: () => const [],
      );
      await expectLater(signOut.run(byUser: false), throwsStateError);
      verify(second.reset).called(1);
      verify(session.endSession).called(1);
    });
  });

  group('KIT-T10: a token the session never saw', () {
    for (final byUser in [true, false]) {
      test('signOut and expire wipe when the session never saw the token '
          '(${byUser ? 'signOut' : 'expire'})', () async {
        // Boot with no token: the cubit is unauthenticated. Then another
        // writer saves a token outside SessionRepository.
        FlutterSecureStorage.setMockInitialValues({});
        SharedPreferences.setMockInitialValues({});
        final sp = await SharedPreferences.getInstance();
        final preferences = AppPreferences(sp);
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
        final adapter = StubAdapter((_) async => jsonBody({'ok': true}));
        dio.httpClientAdapter = adapter;
        late SessionRepository real;
        dio.interceptors.add(
          AuthInterceptor(
            readToken: () => real.token,
            readLanguage: () => 'en',
            onSessionExpired: () {},
            signInPaths: const {'/sign-in'},
          ),
        );
        final remote = SessionRemoteSource(dio);
        real = SessionRepository(
          const SecureStorage(FlutterSecureStorage()),
          preferences,
          remote,
        );
        final cubit = SessionCubit(
          real,
          SignOutService(
            session: real,
            remote: remote,
            preferences: preferences,
            bound: SessionBoundRegistry(),
            hooks: () => const [],
          ),
        );
        await cubit.restore();
        expect(cubit.state.status, SessionStatus.unauthenticated);

        await const FlutterSecureStorage().write(
          key: 'token',
          value: 'saved-token',
        );
        await sp.setString('user', '{"id":1,"role":"MEMBER"}');

        if (byUser) {
          await cubit.signOut();
        } else {
          await cubit.expire();
        }

        expect(await const FlutterSecureStorage().read(key: 'token'), isNull);
        expect(preferences.userJson, isNull);
        if (byUser) {
          expect(adapter.requests.single.path, ApiEndpoints.logout);
          expect(
            adapter.requests.single.headers['Authorization'],
            'Bearer saved-token',
          );
        } else {
          expect(adapter.requests, isEmpty);
        }
        await cubit.close();
      });
    }
  });
}
