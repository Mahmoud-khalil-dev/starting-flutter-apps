import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/app/app.dart';
import 'package:kit_app/app/router/app_router.dart';
import 'package:kit_app/app/router/route_guard.dart';
import 'package:kit_app/app/start/start_screen.dart';
import 'package:kit_app/core/router/pending_deep_link.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/features/home/presentation/view/home_screen.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/presentation/view/settings_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/settings_cubit.dart';

class _Repository extends Mock implements SessionRepository {}

class _SignOut extends Mock implements SignOutService {}

class _Harness {
  _Harness({SessionSnapshot? snapshot, this.tryAgain}) {
    final repository = _Repository();
    when(repository.restore).thenAnswer(
      (_) async =>
          snapshot ??
          const SessionSnapshot(
            token: 't',
            role: AppRole.member,
            userStatus: UserStatus.active,
          ),
    );
    when(
      () => repository.changes,
    ).thenAnswer((_) => const Stream<SessionSnapshot>.empty());
    when(() => repository.token).thenReturn('t');
    when(
      () => signOut.run(byUser: any(named: 'byUser')),
    ).thenAnswer((_) async {});
    session = SessionCubit(repository, signOut);
    router = createAppRouter(
      session: session,
      guard: RouteGuard(
        deepLinks: PendingDeepLink(),
        openPaths: const {RouteNames.home, RouteNames.settings},
      ),
      tryAgain: () async => tryAgain?.call(),
    );
  }

  final void Function()? tryAgain;
  final signOut = _SignOut();
  late final SessionCubit session;
  late final GoRouter router;

  Future<void> pump(
    WidgetTester tester, {
    Size size = TestSizes.phone,
    String language = 'en',
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (settings, _) = (await tester.runAsync(
      () => loadedSettings(
        initial: AppSettings.defaults.copyWith(locale: Locale(language)),
      ),
    ))!;
    addTearDown(settings.close);
    await tester.pumpWidget(App(router: router, settings: settings));
    await tester.pumpAndSettle();
  }

  String get location =>
      router.routerDelegate.currentConfiguration.uri.toString();
}

void main() {
  group('KIT-T10: the router', () {
    testWidgets('KIT-T10: a settled session leaves the splash for Home', (
      tester,
    ) async {
      final harness = _Harness();
      await harness.session.restore();
      await harness.pump(tester);
      expect(harness.location, RouteNames.home);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);
    });

    testWidgets('KIT-T10: a signed-out visitor reaches Home on open paths', (
      tester,
    ) async {
      final harness = _Harness(snapshot: const SessionSnapshot());
      await harness.session.restore();
      await harness.pump(tester);
      expect(harness.location, RouteNames.home);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('KIT-T10: the splash holds while the session is unsettled', (
      tester,
    ) async {
      final harness = _Harness();
      await harness.pump(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(harness.location, RouteNames.start);
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      // The session settles: the splash goes on to Home.
      await harness.session.restore();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('KIT-T10: an unread session offers Try again on the splash', (
      tester,
    ) async {
      var tries = 0;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final harness = _Harness(tryAgain: () => tries++);
      await harness.pump(tester);
      for (var i = 0; i < 7; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text(l10nFor('en').startupRetryBody), findsOneWidget);
      await tester.tap(find.text(l10nFor('en').startupRetryAction));
      await tester.pump();
      expect(tries, 1);
      expect(harness.location, RouteNames.start);
    });

    testWidgets('KIT-T10: the shell tabs go between Home and Settings', (
      tester,
    ) async {
      final harness = _Harness();
      await harness.session.restore();
      await harness.pump(tester);
      await tester.tap(find.text(l10nFor('en').navSettings));
      await tester.pumpAndSettle();
      expect(harness.location, RouteNames.settings);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text(l10nFor('en').settingsThemeDark), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      await tester.tap(find.text(l10nFor('en').navHome));
      await tester.pumpAndSettle();
      expect(harness.location, RouteNames.home);
    });

    testWidgets('KIT-T12: Sign out in Settings ends the session', (
      tester,
    ) async {
      final harness = _Harness();
      await harness.session.restore();
      await harness.pump(tester);
      await tester.tap(find.text(l10nFor('en').navSettings));
      await tester.pumpAndSettle();
      final action = find.text(l10nFor('en').authSignOutAction);
      await tester.scrollUntilVisible(
        action,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(action);
      await tester.pumpAndSettle();
      verify(() => harness.signOut.run(byUser: true)).called(1);
      expect(harness.session.state, const SessionState.unauthenticated());
    });

    testWidgets('KIT-T10: a tablet gets the rail, a phone the bar', (
      tester,
    ) async {
      final harness = _Harness();
      await harness.session.restore();
      await harness.pump(tester, size: TestSizes.tablet);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('KIT-T10: an unknown location goes back to the splash', (
      tester,
    ) async {
      final harness = _Harness();
      await harness.session.restore();
      await harness.pump(tester);
      harness.router.go('/nowhere');
      await tester.pumpAndSettle();
      // The splash routes on at once, so the visitor lands on Home.
      expect(harness.location, RouteNames.home);
    });

    testWidgets('KIT-T10: Arabic mirrors the router shell', (tester) async {
      final harness = _Harness();
      await harness.session.restore();
      await harness.pump(tester, language: 'ar');
      final l10n = l10nFor('ar');
      expect(
        tester.getCenter(find.text(l10n.navHome)).dx,
        greaterThan(tester.getCenter(find.text(l10n.navSettings)).dx),
      );
      expect(find.text(l10n.homeEmptyTitle), findsOneWidget);
    });
  });
}
