import 'package:dartz/dartz.dart';
import 'package:kit_app/core/error/error_handler.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_user.dart';
import 'package:kit_app/features/auth/data/models/auth_result.dart';
import 'package:kit_app/features/auth/data/sources/auth_remote_source.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';

/// If the sign-up API returns no token (it asks to verify first), a project
/// changes `signUp` to `_plain` and routes to the verify screen itself; the
/// kit assumes a token so the guard can move an inactive user to `/verify`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._session, {this._now = DateTime.now});

  final AuthRemoteSource _remote;
  final SessionRepository _session;
  final DateTime Function() _now;

  /// How long a sent code counts as fresh: the resend cooldown.
  static const Duration _freshFor = Duration(minutes: 1);
  DateTime? _codeSentAt;

  /// A call whose answer carries a token and a user: start the session.
  Future<Either<Failure, Unit>> _start(Future<Object?> Function() call) async {
    final result = await attempt(call);
    return result.fold<Future<Either<Failure, Unit>>>(
      (failure) async => Left(failure),
      (body) async {
        final auth = AuthResult.fromBody(body);
        if (auth == null) return const Left(UnknownFailure());
        await _session.start(token: auth.token, user: auth.user);
        return const Right(unit);
      },
    );
  }

  /// A call that changes the user: save the user it returns, or read the
  /// profile again when it returns none. An answer that lands after the
  /// session ended (a sign-out while it was in flight) is not this session's
  /// to save: it writes nothing and reads nothing.
  Future<Either<Failure, Unit>> _update(Future<Object?> Function() call) async {
    final generation = _session.generation;
    final result = await attempt(call);
    return result.fold<Future<Either<Failure, Unit>>>(
      (failure) async => Left(failure),
      (body) async {
        if (generation != _session.generation) return const Left(Cancelled());
        final user = SessionUser.userIn(body);
        if (user != null) {
          await _session.saveUser(user, generation: generation);
          return const Right(unit);
        }
        return (await _session.refresh()).map((_) => unit);
      },
    );
  }

  Future<Either<Failure, Unit>> _plain(Future<Object?> Function() call) async =>
      (await attempt(call)).map((_) => unit);

  @override
  Future<Either<Failure, Unit>> signIn({
    required String identifier,
    required String password,
  }) =>
      _start(() => _remote.signIn(identifier: identifier, password: password));

  @override
  Future<Either<Failure, Unit>> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final result = await _start(
      () => _remote.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
      ),
    );
    if (result.isRight()) _codeSentAt = _now();
    return result;
  }

  @override
  Future<Either<Failure, Unit>> verifyCode(String code) =>
      _update(() => _remote.verifyCode(code));

  @override
  void forgetCodeJustSent() => _codeSentAt = null;

  @override
  bool takeCodeJustSent() {
    final sentAt = _codeSentAt;
    _codeSentAt = null;
    return sentAt != null && _now().difference(sentAt) < _freshFor;
  }

  @override
  Future<Either<Failure, Unit>> resendCode() => _plain(_remote.resendCode);

  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String identifier) =>
      _plain(() => _remote.requestPasswordReset(identifier));

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String identifier,
    required String code,
    required String password,
  }) => _plain(
    () => _remote.resetPassword(
      identifier: identifier,
      code: code,
      password: password,
    ),
  );

  @override
  Future<Either<Failure, Unit>> completeProfile({required String name}) =>
      _update(() => _remote.completeProfile(name: name));
}
