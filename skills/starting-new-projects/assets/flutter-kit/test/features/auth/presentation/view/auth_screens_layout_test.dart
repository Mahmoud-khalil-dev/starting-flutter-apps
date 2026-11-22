import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/media/avatar_upload_cubit.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/cubit/resend_code_cubit.dart';
import 'package:kit_app/features/auth/presentation/view/account_status_screen.dart';
import 'package:kit_app/features/auth/presentation/view/complete_profile_screen.dart';
import 'package:kit_app/features/auth/presentation/view/forgot_password_screen.dart';
import 'package:kit_app/features/auth/presentation/view/reset_password_screen.dart';
import 'package:kit_app/features/auth/presentation/view/sign_in_screen.dart';
import 'package:kit_app/features/auth/presentation/view/sign_up_screen.dart';
import 'package:kit_app/features/auth/presentation/view/verify_code_screen.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_layout.dart';
import 'package:kit_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/avatar_cubit.dart';
import '../../../../helpers/l10n.dart';
import '../../../../helpers/pump_app.dart';

class _Repository extends Mock implements AuthRepository {}

Future<void> _signOut() async {}

final _screens = <String, (Widget, String Function(AppLocalizations))>{
  'sign in': (const SignInScreen(), (l) => l.authSignInTitle),
  'sign up': (const SignUpScreen(), (l) => l.authSignUpTitle),
  'verify': (
    const VerifyCodeScreen(onSignOut: _signOut),
    (l) => l.authVerifyTitle,
  ),
  'forgot': (const ForgotPasswordScreen(), (l) => l.authForgotTitle),
  'reset': (
    const ResetPasswordScreen(identifier: 'a@b.co'),
    (l) => l.authResetTitle,
  ),
  'complete': (
    const CompleteProfileScreen(onSignOut: _signOut, canUseCamera: false),
    (l) => l.authCompleteTitle,
  ),
  'blocked': (
    const AccountStatusScreen(
      kind: AccountStatusKind.blocked,
      onSignOut: _signOut,
    ),
    (l) => l.authBlockedTitle,
  ),
  'no access': (
    const AccountStatusScreen(
      kind: AccountStatusKind.noAccess,
      onSignOut: _signOut,
    ),
    (l) => l.authNoAccessTitle,
  ),
};

Widget _provided(Widget screen, _Repository repository) => MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => AuthCubit(repository)),
    BlocProvider(create: (_) => ResendCodeCubit(repository)),
    BlocProvider<AvatarUploadCubit>(create: (_) => testAvatarCubit()),
  ],
  child: screen,
);

void main() {
  for (final MapEntry(key: name, value: (screen, title)) in _screens.entries) {
    for (final size in [TestSizes.phone, TestSizes.tablet, TestSizes.web]) {
      for (final language in ['en', 'ar']) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'KIT-T16: $name lays out at ${size.width.toInt()} in $language '
            '${brightness.name}',
            (tester) async {
              await pumpApp(
                tester,
                _provided(screen, _Repository()),
                size: size,
                language: language,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
              expect(find.text(title(l10nFor(language))), findsOneWidget);
              expect(
                find.byKey(AuthLayout.brandPanelKey),
                size == TestSizes.web ? findsOneWidget : findsNothing,
              );
            },
          );
        }
      }
    }

    for (final language in ['en', 'ar']) {
      testWidgets(
        'KIT-T16: $name holds at the largest text size in $language',
        (tester) async {
          await pumpApp(
            tester,
            _provided(screen, _Repository()),
            language: language,
            textScale: 2,
          );
          expect(tester.takeException(), isNull);
          expect(find.text(title(l10nFor(language))), findsOneWidget);
        },
      );
    }

    testWidgets('KIT-T16: $name settles at once under reduce motion', (
      tester,
    ) async {
      await pumpApp(
        tester,
        _provided(screen, _Repository()),
        reduceMotion: true,
        settle: false,
      );
      await tester.pump();
      expect(find.text(title(l10nFor('en'))), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
