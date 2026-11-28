import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kit_app/core/error/error_handler.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_remote_source.dart';
import 'package:kit_app/core/session/session_user.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/secure_storage.dart';

class SessionSnapshot extends Equatable {
  const SessionSnapshot({
    this.token,
    this.role,
    this.userStatus,
    this.user,
    this.tokenUnreadable = false,
  });

  final String? token;
  final AppRole? role;
  final UserStatus? userStatus;
  final SessionUser? user;

  /// The secure store refused the read (a locked phone). The token is
  /// unknown, not absent: it must never be taken for "signed out".
  final bool tokenUnreadable;

  bool get hasToken => token != null && token!.isNotEmpty;

  @override
  List<Object?> get props => [token, role, userStatus, user, tokenUnreadable];
}

/// The session as the device keeps it: the token in secure storage and the
/// user object in preferences. This is the only writer of both.
class SessionRepository {
  SessionRepository(
    this._secure,
    this._preferences,
    this._remote, {
    bool Function()? isForeground,
  }) : _isForeground = isForeground ?? _assumeForeground;

  /// The real predicate is wired in the injector ([appIsResumed]); without
  /// one a read is trusted.
  static bool _assumeForeground() => true;

  /// True while the app is resumed. A background launch (a wake-up on a
  /// locked phone) is not.
  static bool appIsResumed() =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  final SecureStorage _secure;
  final AppPreferences _preferences;
  final SessionRemoteSource _remote;
  final bool Function() _isForeground;
  final _changes = StreamController<SessionSnapshot>.broadcast();
  String? _token;
  SessionUser? _user;
  var _tokenUnreadable = false;
  var _generation = 0;

  /// The token for the auth header, held in memory after [restore].
  String? get token => _token;

  SessionUser? get user => _user;

  bool get hasTokenNow => _token != null && _token!.isNotEmpty;

  /// Counts sessions: it goes up when one starts and when one begins to end.
  /// A late answer that belongs to an older value is dropped, never applied
  /// to the next user or to a signed-out app.
  int get generation => _generation;

  /// Called when a sign-out begins, before any hook runs.
  void invalidate() => _generation++;

  Future<void>? _signOut;

  /// A sign-out runs until [done]. A [start] that comes meanwhile (the user
  /// signs in again while a hook is slow) waits for it, so the end of the
  /// old session never wipes the new one.
  void holdStartsUntil(Future<void> done) {
    _signOut = done;
    void release() {
      if (identical(_signOut, done)) _signOut = null;
    }

    done.then((_) => release(), onError: (Object _) => release());
  }

  /// Every sign-in and every saved user. SessionCubit follows it, so a
  /// feature never calls the Cubit.
  Stream<SessionSnapshot> get changes => _changes.stream;

  SessionSnapshot get current => SessionSnapshot(
    token: _token,
    role: _user?.role,
    userStatus: _user?.status,
    user: _user,
    tokenUnreadable: _tokenUnreadable,
  );

  Future<SessionSnapshot> restore() async {
    // A PlatformException means the store refused the read (an iPhone that
    // is locked after a restart), not that there is no token.
    // flutter_secure_storage on iOS answers null, not an error, while the
    // phone is locked. So a null read outside the foreground is just as
    // unknown as an exception: a background wake-up must not read a signed-in
    // user as signed out.
    // A sign-out that begins while the read is in flight moves the generation;
    // the late answer is dropped, so it never puts the old token back.
    final generation = _generation;
    String? token;
    var unreadable = false;
    try {
      token = await _secure.readToken();
      unreadable = (token == null || token.isEmpty) && !_isForeground();
    } on PlatformException {
      token = null;
      unreadable = true;
    }
    if (generation != _generation) return current;
    _token = token;
    _tokenUnreadable = unreadable;
    _user = SessionUser.fromJson(cachedUser(_preferences.userJson));
    return current;
  }

  Future<void> start({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    for (var running = _signOut; running != null; running = _signOut) {
      try {
        await running;
      } on Object catch (_) {
        // The sign-out has ended either way.
      }
    }
    final generation = ++_generation;
    await _inOrder(() => _secure.writeToken(token));
    if (generation != _generation) return;
    _token = token;
    _tokenUnreadable = false;
    await _writeUser(user, generation);
    if (generation != _generation) return;
    _changes.add(current);
  }

  /// Saves the user for the session that is current now. A save that belongs
  /// to an older session (pass its [generation]) is dropped.
  Future<void> saveUser(Map<String, dynamic> user, {int? generation}) async {
    final expected = generation ?? _generation;
    if (expected != _generation) return;
    await _writeUser(user, expected);
    if (expected != _generation) return;
    _changes.add(current);
  }

  Future<Either<Failure, SessionUser>> refresh() async {
    final generation = _generation;
    final result = await attempt(_remote.fetchProfile);
    return result.fold<Future<Either<Failure, SessionUser>>>(
      (failure) async => Left(failure),
      (body) async {
        final user = SessionUser.userIn(body);
        if (user == null) return const Left(UnknownFailure());
        // The session ended while the profile was in flight: write nothing.
        if (generation != _generation) return const Left(UnknownFailure());
        await saveUser(user, generation: generation);
        final saved = _user;
        if (saved == null || generation != _generation) {
          return const Left(UnknownFailure());
        }
        return Right(saved);
      },
    );
  }

  /// Deletes the token and forgets the user. SignOutService wipes the rest.
  Future<void> endSession() async {
    _generation++;
    _token = null;
    _tokenUnreadable = false;
    _user = null;
    await _inOrder(_secure.deleteToken);
  }

  Future<void> _secureWrites = Future<void>.value();

  /// Token writes and deletes run one after another, in the order they were
  /// asked for: a sign-in's write that is still on its way when a sign-out
  /// deletes must land before the delete, never after it.
  Future<void> _inOrder(Future<void> Function() write) {
    final next = _secureWrites.then((_) => write());
    _secureWrites = next.then((_) {}, onError: (Object _) {});
    return next;
  }

  /// Only the named user fields are saved (SessionUser.storedFields); the
  /// whole object stays in memory. The token stays only in secure storage.
  Future<void> _writeUser(Map<String, dynamic> user, int generation) async {
    if (generation != _generation) return;
    await _preferences.setUserJson(jsonEncode(SessionUser.stored(user)));
    if (generation != _generation) return;
    _user = SessionUser.fromJson(user);
  }

  static Map<String, dynamic>? cachedUser(String? json) {
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
