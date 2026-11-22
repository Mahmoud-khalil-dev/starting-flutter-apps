import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/features/auth/data/repositories/auth_sign_out_hook.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AuthRepository {}

void main() {
  test(
    'KIT-T16: a sign-out makes the repository forget a fresh code',
    () async {
      final repository = _Repository();
      await AuthSignOutHook(repository).onSignOut(byUser: true);
      verify(repository.forgetCodeJustSent).called(1);
    },
  );
}
