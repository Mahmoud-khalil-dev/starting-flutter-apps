import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/app.dart';
import 'package:kit_app/app/router/app_router.dart';
import 'package:kit_app/app/router/route_guard.dart';
import 'package:kit_app/core/notifications/notification_router.dart';
import 'package:kit_app/core/router/pending_deep_link.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/settings_cubit.dart';

class _Session extends Mock implements SessionRepository {}

class _SignOut extends Mock implements SignOutService {}

void main() {
  testWidgets('KIT-T17: a tap during startup opens once the session settles', (
    tester,
  ) async {
    final restored = Completer<SessionSnapshot>();
    final session = _Session();
    when(session.restore).thenAnswer((_) => restored.future);
    when(
      () => session.changes,
    ).thenAnswer((_) => const Stream<SessionSnapshot>.empty());
    when(() => session.token).thenReturn(null);
    final cubit = SessionCubit(session, _SignOut());
    addTearDown(cubit.close);
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    final links = PendingDeepLink();
    final router = createAppRouter(
      session: cubit,
      guard: RouteGuard(deepLinks: links),
      tryAgain: () async {},
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(App(router: router, settings: settings));
    unawaited(cubit.restore());
    await tester.pump();

    NotificationRouter(router).open(RouteNames.settings);
    await tester.pump();
    expect(links.held, RouteNames.settings);

    restored.complete(
      const SessionSnapshot(
        token: 't',
        role: AppRole.member,
        userStatus: UserStatus.active,
      ),
    );
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, RouteNames.settings);
    expect(links.held, isNull);
  });

  testWidgets('KIT-T17: a tap with no session opens after sign-in', (
    tester,
  ) async {
    final session = _Session();
    final changes = StreamController<SessionSnapshot>.broadcast();
    addTearDown(changes.close);
    when(session.restore).thenAnswer((_) async => const SessionSnapshot());
    when(() => session.changes).thenAnswer((_) => changes.stream);
    when(() => session.token).thenReturn(null);
    final cubit = SessionCubit(session, _SignOut());
    addTearDown(cubit.close);
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    final links = PendingDeepLink();
    final router = createAppRouter(
      session: cubit,
      guard: RouteGuard(deepLinks: links),
      tryAgain: () async {},
    );
    addTearDown(router.dispose);
    await tester.runAsync(cubit.restore);
    await tester.pumpWidget(App(router: router, settings: settings));
    await tester.pumpAndSettle();
    expect(cubit.state.status, SessionStatus.unauthenticated);

    NotificationRouter(router).open(RouteNames.settings);
    await tester.pumpAndSettle();
    expect(links.held, RouteNames.settings);
  });

  testWidgets('KIT-T17: an outside address in a tap changes nothing', (
    tester,
  ) async {
    final session = _Session();
    when(session.restore).thenAnswer(
      (_) async => const SessionSnapshot(
        token: 't',
        role: AppRole.member,
        userStatus: UserStatus.active,
      ),
    );
    when(
      () => session.changes,
    ).thenAnswer((_) => const Stream<SessionSnapshot>.empty());
    when(() => session.token).thenReturn('t');
    final cubit = SessionCubit(session, _SignOut());
    addTearDown(cubit.close);
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    final links = PendingDeepLink();
    final router = createAppRouter(
      session: cubit,
      guard: RouteGuard(deepLinks: links),
      tryAgain: () async {},
    );
    addTearDown(router.dispose);
    await tester.runAsync(cubit.restore);
    await tester.pumpWidget(App(router: router, settings: settings));
    await tester.pumpAndSettle();
    final before = router.state.matchedLocation;
    NotificationRouter(router)
      ..open('https://evil.example/x')
      ..open('//evil.example/x');
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, before);
  });
}
