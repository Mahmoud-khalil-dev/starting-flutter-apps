import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/router/route_guard.dart';
import 'package:kit_app/core/router/pending_deep_link.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/session_user.dart';

SessionState _signedIn(
  AppRole? role, [
  UserStatus? status = UserStatus.active,
]) => SessionState.authenticated(role: role, userStatus: status);

/// The access table the kit ships. Changing a role's access means changing
/// this and RouteGuard.access in one pull request.
const _expected = <String, Set<AppRole>>{
  RouteNames.home: {AppRole.member, AppRole.admin},
  RouteNames.settings: {AppRole.member, AppRole.admin},
};

void main() {
  late PendingDeepLink links;
  late RouteGuard guard;

  setUp(() {
    links = PendingDeepLink();
    guard = RouteGuard(deepLinks: links);
  });

  test('KIT-T10: an open path is allowed in every session state', () {
    final open = RouteGuard(
      deepLinks: PendingDeepLink(),
      openPaths: {RouteNames.home},
    );
    for (final state in [
      const SessionState.unknown(),
      const SessionState.unauthenticated(),
      _signedIn(AppRole.admin),
      _signedIn(null, null),
    ]) {
      expect(open.redirect(state, RouteNames.home), isNull);
    }
  });

  test('KIT-T10: without open paths a signed-out user goes to sign-in', () {
    expect(
      guard.redirect(const SessionState.unauthenticated(), RouteNames.home),
      RouteNames.signIn,
    );
  });

  group('KIT-T10: the role table', () {
    for (final MapEntry(key: path, value: allowed) in _expected.entries) {
      for (final role in AppRole.values) {
        test('KIT-T10: $role on $path', () {
          expect(
            guard.redirect(_signedIn(role), path),
            allowed.contains(role) ? isNull : RouteGuard.homeFor(role),
          );
        });
      }
    }

    test('the table names every shell destination', () {
      for (final tab in RouteNames.tabs) {
        expect(RouteGuard.access.keys, contains(tab));
      }
    });

    test('sub-paths follow their parent', () {
      expect(guard.redirect(_signedIn(AppRole.member), '/settings/x'), isNull);
      expect(
        guard.redirect(_signedIn(AppRole.member), '/settingsx'),
        isNotNull,
      );
    });

    test('an unknown path is denied for every role', () {
      for (final role in AppRole.values) {
        expect(
          guard.redirect(_signedIn(role), '/nowhere'),
          RouteGuard.homeFor(role),
        );
      }
    });
  });

  group('KIT-T10: session states', () {
    test('an unknown session holds the link and waits at start', () {
      const unknown = SessionState.unknown();
      expect(guard.redirect(unknown, '/settings/42?tab=x'), RouteNames.start);
      expect(links.held, '/settings/42?tab=x');
      expect(guard.redirect(unknown, RouteNames.start), isNull);
    });

    test('KIT-T10: the guard redirects a signed-out user', () {
      const out = SessionState.unauthenticated();
      for (final path in RouteGuard.public) {
        expect(guard.redirect(out, path), isNull, reason: path);
      }
      expect(guard.redirect(out, RouteNames.settings), RouteNames.signIn);
      expect(links.held, RouteNames.settings);
    });

    test('an entry point consumes an allowed held link', () {
      links.hold('/settings/42');
      expect(
        guard.redirect(_signedIn(AppRole.member), RouteNames.signIn),
        '/settings/42',
      );
      expect(links.held, isNull);
    });

    test('a held link the table does not allow goes home', () {
      links.hold('/nowhere');
      expect(
        guard.redirect(_signedIn(AppRole.admin), RouteNames.start),
        RouteNames.home,
      );
    });

    test(
      'inactive, blocked, unknown status and unknown role go to their step',
      () {
        expect(
          guard.redirect(
            _signedIn(AppRole.member, UserStatus.inactive),
            RouteNames.home,
          ),
          RouteNames.verify,
        );
        expect(
          guard.redirect(
            _signedIn(AppRole.member, UserStatus.inactive),
            RouteNames.verify,
          ),
          isNull,
        );
        expect(
          guard.redirect(
            _signedIn(AppRole.member, UserStatus.blocked),
            RouteNames.home,
          ),
          RouteNames.blocked,
        );
        expect(
          guard.redirect(_signedIn(AppRole.member, null), RouteNames.home),
          RouteNames.noAccess,
        );
        expect(
          guard.redirect(_signedIn(null), RouteNames.home),
          RouteNames.noAccess,
        );
        expect(guard.redirect(_signedIn(null), RouteNames.noAccess), isNull);
      },
    );

    test('a session with no role may reach sign-in and start', () {
      expect(guard.redirect(_signedIn(null, null), RouteNames.signIn), isNull);
      expect(guard.redirect(_signedIn(null, null), RouteNames.start), isNull);
    });

    test('a session with no role goes to no-access from a protected path', () {
      for (final path in [RouteNames.home, RouteNames.settings]) {
        expect(
          guard.redirect(_signedIn(null, null), path),
          RouteNames.noAccess,
          reason: path,
        );
      }
    });

    test('open paths hold no link', () {
      final open = RouteGuard(
        deepLinks: links,
        openPaths: {RouteNames.settings},
      );
      expect(
        open.redirect(
          const SessionState.unauthenticated(),
          RouteNames.settings,
        ),
        isNull,
      );
      expect(links.held, isNull);
    });
  });

  group('KIT-T16', () {
    final noName = SessionState.authenticated(
      role: AppRole.member,
      userStatus: UserStatus.active,
      user: SessionUser.fromJson(const {'id': 1, 'name': ' '}),
    );
    final named = SessionState.authenticated(
      role: AppRole.member,
      userStatus: UserStatus.active,
      user: SessionUser.fromJson(const {'id': 1, 'name': 'Sara'}),
    );

    test('KIT-T16: signed out, home goes to sign-in', () {
      final guard = RouteGuard(deepLinks: PendingDeepLink());
      expect(
        guard.redirect(const SessionState.unauthenticated(), RouteNames.home),
        RouteNames.signIn,
      );
    });

    test('KIT-T16: signed out, every auth screen stays open', () {
      final guard = RouteGuard(deepLinks: PendingDeepLink());
      for (final path in [
        RouteNames.signIn,
        RouteNames.signUp,
        RouteNames.forgotPassword,
        RouteNames.resetPassword,
      ]) {
        expect(
          guard.redirect(const SessionState.unauthenticated(), path),
          isNull,
          reason: path,
        );
      }
    });

    test('KIT-T16: a signed-in user is moved off the auth screens', () {
      final guard = RouteGuard(deepLinks: PendingDeepLink());
      for (final path in [
        RouteNames.signUp,
        RouteNames.forgotPassword,
        RouteNames.resetPassword,
      ]) {
        expect(guard.redirect(named, path), RouteNames.home, reason: path);
      }
    });

    test('KIT-T16: a missing name goes to complete the profile', () {
      final guard = RouteGuard(
        deepLinks: PendingDeepLink(),
        needsProfile: RouteGuard.nameMissing,
      );
      expect(
        guard.redirect(noName, RouteNames.home),
        RouteNames.completeProfile,
      );
      expect(guard.redirect(noName, RouteNames.completeProfile), isNull);
      expect(
        guard.redirect(named, RouteNames.completeProfile),
        RouteNames.home,
      );
    });

    test('KIT-T16: a blocked account is not asked for a name', () {
      final guard = RouteGuard(
        deepLinks: PendingDeepLink(),
        needsProfile: RouteGuard.nameMissing,
      );
      final blocked = SessionState.authenticated(
        role: AppRole.member,
        userStatus: UserStatus.blocked,
        user: SessionUser.fromJson(const {'id': 1}),
      );
      expect(guard.redirect(blocked, RouteNames.home), RouteNames.blocked);
    });

    test('KIT-T16: without needsProfile no one is asked for a name', () {
      final guard = RouteGuard(deepLinks: PendingDeepLink());
      expect(guard.redirect(noName, RouteNames.home), isNull);
    });
  });
}
