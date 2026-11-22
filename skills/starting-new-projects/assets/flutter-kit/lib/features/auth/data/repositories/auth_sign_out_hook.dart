import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';

/// Forgets a code that was just sent when a session ends: the next account
/// never inherits the last one's wait.
class AuthSignOutHook implements SignOutHook {
  const AuthSignOutHook(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> onSignOut({required bool byUser}) async =>
      _repository.forgetCodeJustSent();
}
