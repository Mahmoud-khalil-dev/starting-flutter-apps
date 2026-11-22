import 'dart:async';

import 'package:kit_app/core/session/session_bound.dart';
import 'package:kit_app/core/session/session_remote_source.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/storage_keys.dart';

/// Something outside the session that holds user state: a local cache, a
/// notification inbox, analytics, a biometric item. A project registers its
/// own hooks in the injector.
abstract interface class SignOutHook {
  Future<void> onSignOut({required bool byUser});
}

/// The one sign-out. `run` captures the token, starts the logout request
/// with it, deletes the token and the user's data, then runs the hooks, each
/// for at most `hookWait`, and waits for the request at most `logoutWait`.
///
/// The token and the user's data go first: a hook that hangs, or an app that
/// is killed while the hooks run, must not leave them on the device. A hook
/// that needs the token on a request cannot have it; such a call belongs in
/// the logout request. A sign-in that comes while a run is going waits for it
/// to end, so the wipe never takes the new session.
class SignOutService {
  SignOutService({
    required this._session,
    required this._remote,
    required this._preferences,
    required this._bound,
    required this._hooks,
    this._logoutWait = const Duration(seconds: 5),
    this._hookWait = const Duration(seconds: 3),
  });

  final SessionRepository _session;
  final SessionRemoteSource _remote;
  final AppPreferences _preferences;
  final SessionBoundRegistry _bound;
  final List<SignOutHook> Function() _hooks;
  final Duration _logoutWait;
  final Duration _hookWait;
  final _wiped = StreamController<void>.broadcast();

  /// Emits once at the end of every [run], after the token and the user's
  /// preferences are gone.
  Stream<void> get wiped => _wiped.stream;

  /// Rethrows the first failure (a bound Cubit's reset, a storage error)
  /// after every step has run.
  Future<void> run({required bool byUser}) async {
    // The token is read before the first await, and the request carries it
    // in its own header: the wipe below clears the session before the
    // request leaves.
    final token = _session.token;
    // Answers still on their way belong to this session: from here on they
    // are dropped.
    _session.invalidate();
    final done = Completer<void>();
    _session.holdStartsUntil(done.future);
    final logout = byUser && token != null && token.isNotEmpty
        ? _remote.logout(token).then<void>((_) {}, onError: (Object _) {})
        : Future<void>.value();
    Object? firstError;
    StackTrace? firstStack;
    Future<void> step(FutureOr<void> Function() action) async {
      try {
        await action();
      } on Object catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }

    try {
      await step(() => _preferences.remove(StorageKeys.userData));
      await step(_session.endSession);
      // Building the list can throw (a registration that fails): that is
      // one more step error, and the rest still runs.
      await step(() async {
        for (final hook in _hooks()) {
          try {
            await hook.onSignOut(byUser: byUser).timeout(_hookWait);
          } on Object catch (_) {
            // A hook that fails or hangs must not keep the rest from running.
          }
        }
      });
      await step(_bound.resetAll);
      _wiped.add(null);
    } finally {
      // A sign-in waits on this; it is released whatever happened above.
      done.complete();
    }
    await logout.timeout(_logoutWait, onTimeout: () {});
    if (firstError case final error?) {
      Error.throwWithStackTrace(error, firstStack!);
    }
  }
}
