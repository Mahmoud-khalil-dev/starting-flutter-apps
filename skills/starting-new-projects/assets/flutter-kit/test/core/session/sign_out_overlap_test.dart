import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/session/session_bound.dart';
import 'package:kit_app/core/session/session_remote_source.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRemote extends Mock implements SessionRemoteSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KIT-T10: a sign-out and a sign-in that overlap', () {
    late SessionRepository real;
    late AppPreferences preferences;
    late _MockRemote api;

    SignOutService realService(
      List<SignOutHook> hooks, {
      Duration? hookWait,
      List<SignOutHook> Function()? buildHooks,
    }) => SignOutService(
      session: real,
      remote: api,
      preferences: preferences,
      bound: SessionBoundRegistry(),
      hooks: buildHooks ?? () => hooks,
      hookWait: hookWait ?? const Duration(seconds: 3),
    );

    Future<String?> storedToken() =>
        const FlutterSecureStorage().read(key: 'token');

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      preferences = AppPreferences(await SharedPreferences.getInstance());
      api = _MockRemote();
      real = SessionRepository(
        const SecureStorage(FlutterSecureStorage()),
        preferences,
        api,
      );
      await real.start(token: 'old', user: {'id': 1});
    });

    test('a sign-in while a hook is slow keeps the new session', () async {
      final gate = Completer<void>();
      final running = realService([_GateHook(gate.future)]).run(byUser: false);
      await pumpEventQueue();
      final signIn = real.start(token: 'new', user: {'id': 2});
      await pumpEventQueue();
      gate.complete();
      await running;
      await signIn;
      expect(real.token, 'new');
      expect(await storedToken(), 'new');
      expect(preferences.userJson, '{"id":2}');
    });

    test(
      'the token and the user are gone before the first hook runs',
      () async {
        String? tokenSeenByHook = 'not read';
        String? userSeenByHook = 'not read';
        final hook = _GateHook(
          Future<void>.value(),
          onRun: () async {
            tokenSeenByHook = await storedToken();
            userSeenByHook = preferences.userJson;
          },
        );
        await realService([hook]).run(byUser: false);
        expect(tokenSeenByHook, isNull);
        expect(userSeenByHook, isNull);
      },
    );

    test('a hook list that fails to build still wipes and lets a sign-in '
        'through', () async {
      final service = realService(
        const [],
        buildHooks: () => throw StateError('no hooks'),
      );
      await expectLater(service.run(byUser: false), throwsStateError);
      expect(real.token, isNull);
      expect(await storedToken(), isNull);
      expect(preferences.userJson, isNull);
      await real
          .start(token: 'new', user: {'id': 2})
          .timeout(const Duration(seconds: 2));
      expect(await storedToken(), 'new');
    });

    test('a hook that never completes still ends the sign-out', () async {
      final never = _GateHook(Completer<void>().future);
      final second = _GateHook(Future<void>.value());
      await realService(
        [never, second],
        hookWait: const Duration(milliseconds: 20),
      ).run(byUser: false).timeout(const Duration(seconds: 2));
      expect(second.ran, isTrue);
      expect(real.token, isNull);
      expect(await storedToken(), isNull);
    });
  });
}

class _GateHook implements SignOutHook {
  _GateHook(this._gate, {this.onRun});

  final Future<void> _gate;
  final Future<void> Function()? onRun;
  bool ran = false;

  @override
  Future<void> onSignOut({required bool byUser}) async {
    ran = true;
    await onRun?.call();
    await _gate;
  }
}
