import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_app/app/di/injector.dart';
import 'package:kit_app/app/router/route_guard.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/cubit/resend_code_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/stub_adapter.dart';

Future<GetIt> _graph() async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  final locator = GetIt.asNewInstance();
  addTearDown(locator.reset);
  await initDependencies(locator: locator);
  return locator;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KIT-T16: each screen gets its own auth Cubits', () async {
    final locator = await _graph();
    expect(locator<AuthRepository>(), same(locator<AuthRepository>()));
    final first = locator<AuthCubit>();
    final second = locator<AuthCubit>();
    final resend = locator<ResendCodeCubit>();
    addTearDown(() async {
      await first.close();
      await second.close();
      await resend.close();
    });
    expect(first, isNot(same(second)));
    expect(resend.state.canSend, isTrue);
  });

  test(
    'KIT-T16: a sign-in through the real graph starts the session',
    () async {
      final locator = await _graph();
      locator<Dio>().httpClientAdapter = StubAdapter(
        (_) async => jsonBody({
          'data': {
            'token': 'session-token',
            'user': {
              'id': 1,
              'name': 'Sara',
              'status': 'active',
              'role': 'member',
            },
          },
        }),
      );
      // The session Cubit listens from its first use, as it does at boot.
      final session = locator<SessionCubit>();
      final cubit = locator<AuthCubit>();
      addTearDown(cubit.close);
      await cubit.signIn(identifier: 'a@b.co', password: 'secret1a');
      expect(cubit.state.failure, isNull);
      await pumpEventQueue();
      expect(session.state.status, SessionStatus.authenticated);
    },
  );

  test('KIT-T16: a code just sent does not outlive a sign-out', () async {
    final locator = await _graph();
    locator<Dio>().httpClientAdapter = StubAdapter(
      (_) async => jsonBody({
        'data': {
          'token': 'session-token',
          'user': {
            'id': 1,
            'name': 'Sara',
            'status': 'active',
            'role': 'member',
          },
        },
      }),
    );
    locator<SessionCubit>();
    await locator<AuthRepository>().signUp(
      name: 'Sara',
      email: 'a@b.co',
      phone: '+100',
      password: 'secret1a',
    );
    await locator<SignOutService>().run(byUser: true);
    // Another account signs in within the minute and lands on verify cold.
    final resend = locator<ResendCodeCubit>()..begin();
    addTearDown(resend.close);
    expect(resend.state.canSend, isTrue);
  });

  test('KIT-T16: the real guard keeps home behind a session', () async {
    final locator = await _graph();
    expect(
      locator<RouteGuard>().redirect(
        const SessionState.unauthenticated(),
        RouteNames.home,
      ),
      RouteNames.signIn,
    );
    expect(
      locator<RouteGuard>().redirect(
        const SessionState.unauthenticated(),
        RouteNames.settings,
      ),
      RouteNames.signIn,
    );
  });
}
