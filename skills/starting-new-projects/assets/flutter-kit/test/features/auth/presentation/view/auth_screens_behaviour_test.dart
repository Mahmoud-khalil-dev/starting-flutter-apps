import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/media/avatar_upload_cubit.dart';
import 'package:kit_app/core/telemetry/recording_mask.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/cubit/resend_code_cubit.dart';
import 'package:kit_app/features/auth/presentation/view/complete_profile_screen.dart';
import 'package:kit_app/features/auth/presentation/view/sign_in_screen.dart';
import 'package:kit_app/features/auth/presentation/view/sign_up_screen.dart';
import 'package:kit_app/features/auth/presentation/view/verify_code_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/avatar_cubit.dart';
import '../../../../helpers/pump_app.dart';

class _Repository extends Mock implements AuthRepository {}

const ValueKey<String> _masked = ValueKey('masked');

Widget _masking(Widget child) => KeyedSubtree(key: _masked, child: child);

Future<void> _signOut() async {}

void main() {
  late _Repository repository;

  setUp(() => repository = _Repository());

  Widget scoped(Widget screen, {int cooldown = 60, bool start = false}) =>
      RecordingMaskScope(
        masker: _masking,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AuthCubit(repository)),
            BlocProvider<AvatarUploadCubit>(create: (_) => testAvatarCubit()),
            BlocProvider(
              create: (_) {
                final cubit = ResendCodeCubit(
                  repository,
                  cooldownTicks: cooldown,
                );
                if (start) cubit.startCooldown();
                return cubit;
              },
            ),
          ],
          child: screen,
        ),
      );

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    String language = 'en',
  }) => pumpApp(tester, scoped(screen), language: language);

  testWidgets('KIT-T16: an empty sign-in asks for both fields', (tester) async {
    await pump(tester, const SignInScreen());
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.text('Please fill this in.'), findsNWidgets(2));
    verifyZeroInteractions(repository);
  });

  testWidgets('KIT-T16: sign-in sends what was typed', (tester) async {
    when(
      () => repository.signIn(identifier: 'a@b.co', password: 'secret1a'),
    ).thenAnswer((_) async => const Right(unit));
    await pump(tester, const SignInScreen());
    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'secret1a');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    verify(
      () => repository.signIn(identifier: 'a@b.co', password: 'secret1a'),
    ).called(1);
  });

  testWidgets('KIT-T16: wrong details show one quiet message', (tester) async {
    when(
      () => repository.signIn(identifier: 'a@b.co', password: 'secret1a'),
    ).thenAnswer((_) async => const Left(Unauthorized()));
    await pump(tester, const SignInScreen());
    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'secret1a');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(
      find.text('That email, phone or password does not match our records.'),
      findsOneWidget,
    );
  });

  testWidgets('KIT-T16: every auth field is masked in recordings', (
    tester,
  ) async {
    await pump(tester, const SignInScreen());
    expect(find.byKey(_masked), findsNWidgets(2));
    await pump(tester, const SignUpScreen());
    expect(find.byKey(_masked), findsNWidgets(5));
    expect(
      tester
          .widgetList<AppTextField>(find.byType(AppTextField))
          .every((field) => field.sensitive),
      isTrue,
    );
    await pump(
      tester,
      const CompleteProfileScreen(onSignOut: _signOut, canUseCamera: false),
    );
    expect(find.byKey(_masked), findsOneWidget);
  });

  testWidgets('KIT-T16: the password can be shown and hidden', (tester) async {
    await pump(tester, const SignInScreen());
    TextField password() =>
        tester.widget<TextField>(find.byType(TextField).at(1));
    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(password().obscureText, isTrue);
  });

  testWidgets('KIT-T16: sign-up checks that the passwords match', (
    tester,
  ) async {
    await pump(tester, const SignUpScreen());
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Sara Ali');
    await tester.enterText(fields.at(1), 'sara@example.com');
    await tester.enterText(fields.at(2), '0501234567');
    await tester.enterText(fields.at(3), 'secret1a');
    await tester.enterText(fields.at(4), 'secret1b');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('These entries do not match.'), findsOneWidget);
    verifyZeroInteractions(repository);
  });

  testWidgets('KIT-T16: sign-up sends a valid form', (tester) async {
    when(
      () => repository.signUp(
        name: 'Sara Ali',
        email: 'sara@example.com',
        phone: '0501234567',
        password: 'secret1a',
      ),
    ).thenAnswer((_) async => const Right(unit));
    await pump(tester, const SignUpScreen());
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Sara Ali');
    await tester.enterText(fields.at(1), 'sara@example.com');
    await tester.enterText(fields.at(2), '0501234567');
    await tester.enterText(fields.at(3), 'secret1a');
    await tester.enterText(fields.at(4), 'secret1a');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    verify(
      () => repository.signUp(
        name: 'Sara Ali',
        email: 'sara@example.com',
        phone: '0501234567',
        password: 'secret1a',
      ),
    ).called(1);
  });

  testWidgets('KIT-T16: a short code is not sent', (tester) async {
    await pump(tester, const VerifyCodeScreen(onSignOut: _signOut));
    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('4'), findsWidgets);
    verifyNever(() => repository.verifyCode(any()));
  });

  testWidgets('KIT-T16: a valid code is sent', (tester) async {
    when(
      () => repository.verifyCode('1234'),
    ).thenAnswer((_) async => const Right(unit));
    await pump(tester, const VerifyCodeScreen(onSignOut: _signOut));
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    verify(() => repository.verifyCode('1234')).called(1);
  });

  testWidgets('KIT-T16: the resend button waits, then asks once', (
    tester,
  ) async {
    when(repository.resendCode).thenAnswer((_) async => const Right(unit));
    await pumpApp(
      tester,
      scoped(
        const VerifyCodeScreen(onSignOut: _signOut),
        cooldown: 2,
        start: true,
      ),
      settle: false,
    );
    await tester.pump();
    expect(find.text('Send a new code'), findsNothing);
    expect(find.textContaining('00:02'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Send a new code'), findsOneWidget);
    await tester.tap(find.text('Send a new code'));
    await tester.pump();
    await tester.pump();
    verify(repository.resendCode).called(1);
    expect(find.text('A new code is on its way.'), findsOneWidget);
    // Let the new cooldown and the snackbar run out.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('KIT-T16: a failed resend is told quietly', (tester) async {
    when(
      repository.resendCode,
    ).thenAnswer((_) async => const Left(NoConnection()));
    await pump(tester, const VerifyCodeScreen(onSignOut: _signOut));
    await tester.tap(find.text('Send a new code'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('KIT-T16: the resend countdown shows Arabic-Indic digits', (
    tester,
  ) async {
    await pumpApp(
      tester,
      scoped(
        const VerifyCodeScreen(onSignOut: _signOut),
        cooldown: 75,
        start: true,
      ),
      language: 'ar',
      settle: false,
    );
    await tester.pump();
    expect(find.textContaining('٠١:١٥'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('٠١:١٤'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('KIT-T16: a name too short is not saved', (tester) async {
    await pump(
      tester,
      const CompleteProfileScreen(onSignOut: _signOut, canUseCamera: false),
    );
    await tester.enterText(find.byType(TextField), 'S');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    verifyNever(() => repository.completeProfile(name: any(named: 'name')));
    await tester.enterText(find.byType(TextField), 'Sara');
    when(
      () => repository.completeProfile(name: 'Sara'),
    ).thenAnswer((_) async => const Right(unit));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    verify(() => repository.completeProfile(name: 'Sara')).called(1);
  });
}
