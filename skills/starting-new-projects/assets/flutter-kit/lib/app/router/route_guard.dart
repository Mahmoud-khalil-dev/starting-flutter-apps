import 'package:kit_app/core/router/pending_deep_link.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_state.dart';

/// Who may open which path. Deny by default: a path missing from [access]
/// sends the user home. The server enforces every rule; this is the
/// client's view of it. Change the table and its test together.
class RouteGuard {
  RouteGuard({
    required this._deepLinks,
    this._openPaths = const {},
    this._needsProfile = _never,
  });

  static bool _never(SessionState session) => false;

  /// The kit's profile rule: an active account with no name finishes its
  /// profile first. Pass it as `needsProfile`; change it to the product's.
  static bool nameMissing(SessionState session) =>
      (session.user?.name?.trim() ?? '').isEmpty;

  static const List<AppRole> _everyone = [AppRole.member, AppRole.admin];

  /// Add one row per screen a signed-in user may open.
  static const access = <String, List<AppRole>>{
    RouteNames.home: _everyone,
    RouteNames.settings: _everyone,
  };

  /// Open without a session.
  static const Set<String> public = {
    RouteNames.start,
    RouteNames.signIn,
    RouteNames.signUp,
    RouteNames.forgotPassword,
    RouteNames.resetPassword,
  };

  /// Where a signed-in user is sent once the entry steps are done.
  static const Set<String> _entry = {
    ...public,
    RouteNames.verify,
    RouteNames.blocked,
    RouteNames.noAccess,
    RouteNames.completeProfile,
  };

  final PendingDeepLink _deepLinks;

  /// Open in every session state, whoever is signed in. The kit opens only
  /// its debug gallery this way; every app screen needs a session.
  final Set<String> _openPaths;

  /// Whether a signed-in, active account must finish its profile before it
  /// reaches the app.
  final bool Function(SessionState session) _needsProfile;

  /// Where a role lands after sign-in. Change it for a role with another
  /// first screen.
  static String homeFor(AppRole role) => RouteNames.home;

  static bool allows(AppRole role, String path) {
    for (final MapEntry(key: prefix, value: roles) in access.entries) {
      if (path == prefix || path.startsWith('$prefix/')) {
        return roles.contains(role);
      }
    }
    return false;
  }

  String? redirect(SessionState session, String location) {
    final path = Uri.parse(location).path;
    if (_openPaths.contains(path)) return null;
    switch (session.status) {
      case SessionStatus.unknown:
        if (path == RouteNames.start) return null;
        _hold(path, location);
        return RouteNames.start;
      case SessionStatus.unauthenticated:
        if (public.contains(path)) return null;
        _hold(path, location);
        return RouteNames.signIn;
      case SessionStatus.authenticated:
        return _signedIn(session, path);
    }
  }

  String? _signedIn(SessionState session, String path) {
    // A token with no cached user: let it sign in again instead of trapping
    // it on no-access.
    if (session.role == null && public.contains(path)) return null;
    final step = switch (session.userStatus) {
      UserStatus.inactive => RouteNames.verify,
      UserStatus.blocked => RouteNames.blocked,
      UserStatus.active => null,
      null => RouteNames.noAccess,
    };
    final role = session.role;
    final blocking = step ?? (role == null ? RouteNames.noAccess : null);
    if (blocking != null) return path == blocking ? null : blocking;
    if (_needsProfile(session)) {
      return path == RouteNames.completeProfile
          ? null
          : RouteNames.completeProfile;
    }
    if (_entry.contains(path)) {
      final held = _deepLinks.consume();
      return held != null && allows(role!, Uri.parse(held).path)
          ? held
          : homeFor(role!);
    }
    return allows(role!, path) ? null : homeFor(role);
  }

  void _hold(String path, String location) {
    if (!_entry.contains(path)) _deepLinks.hold(location);
  }
}
