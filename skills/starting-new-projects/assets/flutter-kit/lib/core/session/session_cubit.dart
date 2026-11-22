import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/sign_out_service.dart';

/// The app-wide session. It is the router's refreshListenable: listeners are
/// told after the new state is set, so a redirect reads the new state.
class SessionCubit extends Cubit<SessionState> implements Listenable {
  SessionCubit(this._repository, this._signOut)
    : super(const SessionState.unknown()) {
    _subscription = _repository.changes.listen(_follow);
  }

  final SessionRepository _repository;
  final SignOutService _signOut;
  final _listeners = <VoidCallback>[];
  late final StreamSubscription<SessionSnapshot> _subscription;

  /// The last read was refused by the OS: the state stays `unknown` until a
  /// read works. A locked phone must never mean "signed out".
  var _unreadable = false;

  Future<void> restore() async {
    final snapshot = await _repository.restore();
    if (isClosed) return;
    _unreadable = snapshot.tokenUnreadable;
    if (_unreadable) return;
    emit(
      snapshot.hasToken
          ? _signedIn(snapshot, savedOnly: true)
          : const SessionState.unauthenticated(),
    );
  }

  /// Reads the stored session again after a read the OS refused.
  /// Returns true when it read again.
  Future<bool> retryRestore() async {
    if (state.status != SessionStatus.unknown || !_unreadable) return false;
    await restore();
    return true;
  }

  /// Revalidates the saved user. A 401 already ended the session through
  /// AuthInterceptor; offline keeps the saved user and says so.
  Future<Failure?> refresh() async {
    if (state.status != SessionStatus.authenticated) return null;
    final result = await _repository.refresh();
    return result.fold((failure) => failure, (_) => null);
  }

  void _follow(SessionSnapshot snapshot) {
    if (isClosed || !snapshot.hasToken) return;
    emit(_signedIn(snapshot));
  }

  static SessionState _signedIn(
    SessionSnapshot snapshot, {
    bool savedOnly = false,
  }) => SessionState.authenticated(
    role: snapshot.role,
    userStatus: snapshot.userStatus,
    user: snapshot.user,
    savedOnly: savedOnly,
  );

  /// A 401 outside the sign-in paths (the API has no refresh token). The state goes
  /// first; the service wipes without the API. It never returns early on an
  /// unauthenticated state: a token saved by a writer this Cubit never saw
  /// must still go.
  Future<void> expire() => _end(byUser: false);

  /// The user signs out (Settings).
  Future<void> signOut() => _end(byUser: true);

  /// True while a wipe runs, so a second call at the same time (two 401s, a
  /// double tap) is ignored. Every call that starts a wipe wipes.
  bool _ending = false;

  Future<void> _end({required bool byUser}) async {
    if (_ending) return;
    _ending = true;
    try {
      emit(const SessionState.unauthenticated());
      if (byUser && (_repository.token ?? '').isEmpty) {
        // A token the session never saw: read it from storage so the logout
        // request still carries it.
        try {
          await _repository.restore();
        } on Object catch (_) {
          // No token to send; the wipe goes on.
        }
      }
      await _signOut.run(byUser: byUser);
    } finally {
      _ending = false;
    }
  }

  @override
  void emit(SessionState state) {
    final changed = state != this.state;
    super.emit(state);
    if (!changed) return;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
