import 'package:dartz/dartz.dart' show Either, Unit;
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/state/view_cubit.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';

/// One auth action at a time. Success needs no navigation here: the session
/// changes and the route guard moves the screen on.
class AuthCubit extends ViewCubit<Unit> {
  AuthCubit(this._repository);

  final AuthRepository _repository;

  /// A second submit while one is in flight sends nothing: Enter, a double
  /// tap or a slow answer must not send a request twice.
  @override
  Future<void> run(
    Future<Either<Failure, Unit>> Function() fetch, {
    bool Function(Unit data)? isEmpty,
  }) async {
    if (state.isLoading) return;
    await super.run(fetch, isEmpty: isEmpty);
  }

  Future<void> signIn({required String identifier, required String password}) =>
      run(() => _repository.signIn(identifier: identifier, password: password));

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => run(
    () => _repository.signUp(
      name: name,
      email: email,
      phone: phone,
      password: password,
    ),
  );

  Future<void> verifyCode(String code) =>
      run(() => _repository.verifyCode(code));

  Future<void> requestPasswordReset(String identifier) =>
      run(() => _repository.requestPasswordReset(identifier));

  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String password,
  }) => run(
    () => _repository.resetPassword(
      identifier: identifier,
      code: code,
      password: password,
    ),
  );

  Future<void> completeProfile({required String name}) =>
      run(() => _repository.completeProfile(name: name));
}
