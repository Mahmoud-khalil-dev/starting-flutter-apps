import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/session/session_bound.dart';
import 'package:kit_app/core/session/session_remote_source.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/secure_storage.dart';
import 'package:kit_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kit_app/features/auth/data/sources/auth_remote_source.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Secure extends Mock implements SecureStorage {}

class _SessionRemote extends Mock implements SessionRemoteSource {}

class _AuthRemote extends Mock implements AuthRemoteSource {}

/// A real session and a real sign-out, so the race runs through the same
/// generation checks the app uses.
void main() {
  late _Secure secure;
  late _SessionRemote sessionRemote;
  late _AuthRemote remote;
  late AppPreferences prefs;
  late SessionRepository session;
  late AuthRepositoryImpl auth;
  late SignOutService signOut;
  late Completer<Object?> answer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = AppPreferences(await SharedPreferences.getInstance());
    secure = _Secure();
    String? stored;
    when(() => secure.writeToken(any())).thenAnswer((i) async {
      stored = i.positionalArguments.first as String;
    });
    when(secure.deleteToken).thenAnswer((_) async => stored = null);
    when(secure.readToken).thenAnswer((_) async => stored);
    sessionRemote = _SessionRemote();
    session = SessionRepository(secure, prefs, sessionRemote);
    remote = _AuthRemote();
    auth = AuthRepositoryImpl(remote, session);
    signOut = SignOutService(
      session: session,
      remote: sessionRemote,
      preferences: prefs,
      bound: SessionBoundRegistry(),
      hooks: () => const [],
    );
    answer = Completer<Object?>();
    when(() => remote.verifyCode(any())).thenAnswer((_) => answer.future);
    when(
      () => remote.completeProfile(name: any(named: 'name')),
    ).thenAnswer((_) => answer.future);
    await session.start(token: 'first', user: {'id': 1, 'name': 'First'});
  });

  final calls = <String, Future<Either<Failure, Unit>> Function()>{
    'verifyCode': () => auth.verifyCode('1234'),
    'completeProfile': () => auth.completeProfile(name: 'First Person'),
  };

  for (final MapEntry(key: name, value: call) in calls.entries) {
    test('KIT-T16: a $name answer that lands after a sign-out writes no '
        'user back', () async {
      final pending = call();
      await signOut.run(byUser: false);
      expect(prefs.userJson, isNull);
      answer.complete({
        'data': {
          'user': {'id': 1, 'name': 'First Person'},
        },
      });
      final result = await pending;
      expect(prefs.userJson, isNull);
      expect(session.user, isNull);
      expect(result, const Left<Failure, Unit>(Cancelled()));
    });

    test('KIT-T16: a $name answer with no user that lands after a sign-out '
        'reads no profile', () async {
      final pending = call();
      await signOut.run(byUser: false);
      answer.complete({'data': <String, Object?>{}});
      final result = await pending;
      verifyNever(sessionRemote.fetchProfile);
      expect(prefs.userJson, isNull);
      expect(result, const Left<Failure, Unit>(Cancelled()));
    });
  }

  test('KIT-T16: a completeProfile answer in the same session saves the '
      'user', () async {
    final pending = auth.completeProfile(name: 'First Person');
    answer.complete({
      'data': {
        'user': {'id': 1, 'name': 'First Person'},
      },
    });
    expect(await pending, const Right<Failure, Unit>(unit));
    expect(prefs.userJson, contains('First Person'));
  });
}
