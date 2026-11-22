import 'package:dartz/dartz.dart';
import 'package:kit_app/core/error/failures.dart';

/// What the auth screens need from the API. Sign-in and sign-up start the
/// session; verifying a code and completing the profile update its user.
/// The guard moves the screens on when the session changes.
abstract interface class AuthRepository {
  Future<Either<Failure, Unit>> signIn({
    required String identifier,
    required String password,
  });

  Future<Either<Failure, Unit>> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<Either<Failure, Unit>> verifyCode(String code);

  Future<Either<Failure, Unit>> resendCode();

  /// True once after a code was just sent (sign-up), so the verify screen
  /// waits before offering a new one even when a guard redirect opened it.
  bool takeCodeJustSent();

  /// Forgets a fresh code: called when the session ends, so it never reaches
  /// the next account.
  void forgetCodeJustSent();

  Future<Either<Failure, Unit>> requestPasswordReset(String identifier);

  Future<Either<Failure, Unit>> resetPassword({
    required String identifier,
    required String code,
    required String password,
  });

  Future<Either<Failure, Unit>> completeProfile({required String name});
}
