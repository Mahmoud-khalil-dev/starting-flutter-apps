import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/app/app.dart';
import 'package:kit_app/app/router/app_router.dart';
import 'package:kit_app/app/router/auth_routes.dart';
import 'package:kit_app/app/router/route_guard.dart';
import 'package:kit_app/core/router/pending_deep_link.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/session_user.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/cubit/resend_code_cubit.dart';
import 'package:kit_app/features/auth/presentation/view/complete_profile_screen.dart';
import 'package:kit_app/features/auth/presentation/view/forgot_password_screen.dart';
import 'package:kit_app/features/auth/presentation/view/reset_password_screen.dart';
import 'package:kit_app/features/auth/presentation/view/sign_in_screen.dart';
import 'package:kit_app/features/auth/presentation/view/sign_up_screen.dart';
import 'package:kit_app/features/auth/presentation/view/verify_code_screen.dart';
import 'package:kit_app/features/home/presentation/view/home_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/avatar_cubit.dart';
import '../../helpers/settings_cubit.dart';

class _Session extends Mock implements SessionRepository {}

class _SignOut extends Mock implements SignOutService {}

class _Auth extends Mock implements AuthRepository {}

class _CountingGuard extends RouteGuard {
  _CountingGuard({super.openPaths})
    : super(deepLinks: PendingDeepLink(), needsProfile: RouteGuard.nameMissing);

  int calls = 0;

  @override
  String? redirect(SessionState session, String location) {
    calls++;
    return super.redirect(session, location);
  }
}

const Map<String, Object> _named = {'id': 1, 'name': 'Sara'};

class _Harness {
  _Harness({SessionSnapshot? snapshot, Set<String> openPaths = const {}}) {
    when(
      session.restore,
    ).thenAnswer((_) async => snapshot ?? const SessionSnapshot());
    when(() => session.changes).thenAnswer((_) => changes.stream);
    when(() => session.token).thenReturn(null);
    when(auth.takeCodeJustSent).thenReturn(false);
    cubit = SessionCubit(session, signOut);
    guard = _CountingGuard(openPaths: openPaths);
    router = createAppRouter(
      session: cubit,
      guard: guard,
      tryAgain: () async {},
      authRoutes: authRoutes(
        authCubit: () => AuthCubit(auth),
        resendCubit: () => ResendCodeCubit(auth),
        avatarCubit: testAvatarCubit,
        canUseCamera: false,
        canOpenSettings: true,
        signOut: cubit.signOut,
      ),
    );
  }

  final session = _Session();
  final signOut = _SignOut();
  final auth = _Auth();
  final changes = StreamController<SessionSnapshot>.broadcast();
  late final _CountingGuard guard;
  late final SessionCubit cubit;
  late final GoRouter router;

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(cubit.restore);
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    addTearDown(cubit.close);
    addTearDown(changes.close);
    await tester.pumpWidget(App(router: router, settings: settings));
    await tester.pumpAndSettle();
  }

  String get location => router.state.matchedLocation;
}

void main() {
  testWidgets('KIT-T16: signed out lands on sign-in without a loop', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    final settled = h.guard.calls;
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(h.guard.calls, settled);
    expect(settled, lessThan(6));
  });

  testWidgets('KIT-T16: signing in moves to home', (tester) async {
    final h = _Harness();
    when(
      () => h.auth.signIn(identifier: 'a@b.co', password: 'secret1a'),
    ).thenAnswer((_) async {
      h.changes.add(
        SessionSnapshot(
          token: 't',
          role: AppRole.member,
          userStatus: UserStatus.active,
          user: SessionUser.fromJson(_named),
        ),
      );
      return const Right(unit);
    });
    await h.pump(tester);
    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'secret1a');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('KIT-T16: sign-in and sign-up link to each other', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Already have an account? Sign in'));
    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('KIT-T16: an inactive account lands on verify', (tester) async {
    final h = _Harness(
      snapshot: const SessionSnapshot(
        token: 't',
        role: AppRole.member,
        userStatus: UserStatus.inactive,
      ),
    );
    await h.pump(tester);
    expect(h.location, RouteNames.verify);
    expect(find.byType(VerifyCodeScreen), findsOneWidget);
  });

  testWidgets('KIT-T16: an active account with no name completes its profile', (
    tester,
  ) async {
    final h = _Harness(
      snapshot: SessionSnapshot(
        token: 't',
        role: AppRole.member,
        userStatus: UserStatus.active,
        user: SessionUser.fromJson(const {'id': 1}),
      ),
    );
    await h.pump(tester);
    expect(h.location, RouteNames.completeProfile);
    expect(find.byType(CompleteProfileScreen), findsOneWidget);
  });

  testWidgets('KIT-T18: completing the profile offers a photo', (tester) async {
    final h = _Harness(
      snapshot: SessionSnapshot(
        token: 't',
        role: AppRole.member,
        userStatus: UserStatus.active,
        user: SessionUser.fromJson(const {'id': 1}),
      ),
    );
    await h.pump(tester);
    expect(find.bySemanticsLabel('Change your photo'), findsOneWidget);
  });

  testWidgets('KIT-T16: asking for a reset code opens the reset screen', (
    tester,
  ) async {
    final h = _Harness();
    when(
      () => h.auth.requestPasswordReset('a@b.co'),
    ).thenAnswer((_) async => const Right(unit));
    await h.pump(tester);
    await tester.tap(find.text('Forgot your password?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a@b.co');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(h.location, RouteNames.resetPassword);
  });

  testWidgets('KIT-T16: a saved password returns to sign-in with a note', (
    tester,
  ) async {
    final h = _Harness();
    when(
      () => h.auth.resetPassword(
        identifier: 'a@b.co',
        code: '1234',
        password: 'secret1a',
      ),
    ).thenAnswer((_) async => const Right(unit));
    await h.pump(tester);
    h.router.go(RouteNames.resetPassword, extra: 'a@b.co');
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1234');
    await tester.enterText(fields.at(1), 'secret1a');
    await tester.enterText(fields.at(2), 'secret1a');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(
      find.text('Your password is saved. Please sign in.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('KIT-T16: a reset without its identifier asks again', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    h.router.go(RouteNames.resetPassword);
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    h.router.go(RouteNames.resetPassword, extra: 'a@b.co');
    await tester.pumpAndSettle();
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
  });

  testWidgets('KIT-T16: a blocked account sees the status screen', (
    tester,
  ) async {
    final h = _Harness(
      snapshot: const SessionSnapshot(
        token: 't',
        role: AppRole.member,
        userStatus: UserStatus.blocked,
      ),
    );
    await h.pump(tester);
    expect(find.text('Your account is paused'), findsOneWidget);
  });

  testWidgets('KIT-T16: an account with no role sees the no-access screen', (
    tester,
  ) async {
    final h = _Harness(
      snapshot: const SessionSnapshot(
        token: 't',
        userStatus: UserStatus.active,
      ),
    );
    await h.pump(tester);
    expect(find.text('This account has no access here'), findsOneWidget);
  });

  testWidgets('KIT-T16: the status screen signs the user out', (tester) async {
    final h = _Harness(
      snapshot: const SessionSnapshot(
        token: 't',
        role: AppRole.member,
        userStatus: UserStatus.blocked,
      ),
    );
    when(() => h.signOut.run(byUser: true)).thenAnswer((_) async {});
    await h.pump(tester);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    verify(() => h.signOut.run(byUser: true)).called(1);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('KIT-T16: open paths still bypass the guard', (tester) async {
    final h = _Harness(openPaths: const {RouteNames.home});
    await h.pump(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('KIT-T16: a cold open of verify allows a new code at once', (
    tester,
  ) async {
    final h = _Harness(
      snapshot: const SessionSnapshot(
        token: 't',
        role: AppRole.member,
        userStatus: UserStatus.inactive,
      ),
    );
    await h.pump(tester);
    expect(find.text('Send a new code'), findsOneWidget);
    expect(find.textContaining('You can ask for a new code'), findsNothing);
  });

  testWidgets('KIT-T16: verify right after a code was sent waits first', (
    tester,
  ) async {
    final h = _Harness(
      snapshot: const SessionSnapshot(
        token: 't',
        role: AppRole.member,
        userStatus: UserStatus.inactive,
      ),
    );
    await h.pump(tester);
    unawaited(h.router.push(RouteNames.verify, extra: true));
    await tester.pumpAndSettle();
    expect(find.text('Send a new code'), findsNothing);
    expect(find.textContaining('01:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('KIT-T16: sign-up then a guard redirect waits before a resend', (
    tester,
  ) async {
    final h = _Harness(
      snapshot: const SessionSnapshot(
        token: 't',
        role: AppRole.member,
        userStatus: UserStatus.inactive,
      ),
    );
    when(h.auth.takeCodeJustSent).thenReturn(true);
    await h.pump(tester);
    expect(find.text('Send a new code'), findsNothing);
    expect(find.textContaining('01:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('KIT-T16: the reset screen leads back to sign-in', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    h.router.go(RouteNames.resetPassword, extra: 'a@b.co');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Remembered it? Back to sign in'));
    await tester.tap(find.text('Remembered it? Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
