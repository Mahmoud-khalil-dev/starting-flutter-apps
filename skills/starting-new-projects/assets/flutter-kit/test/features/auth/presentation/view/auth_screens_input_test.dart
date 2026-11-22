import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/media/avatar_upload_cubit.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/cubit/resend_code_cubit.dart';
import 'package:kit_app/features/auth/presentation/view/complete_profile_screen.dart';
import 'package:kit_app/features/auth/presentation/view/forgot_password_screen.dart';
import 'package:kit_app/features/auth/presentation/view/reset_password_screen.dart';
import 'package:kit_app/features/auth/presentation/view/sign_in_screen.dart';
import 'package:kit_app/features/auth/presentation/view/sign_up_screen.dart';
import 'package:kit_app/features/auth/presentation/view/verify_code_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/avatar_cubit.dart';
import '../../../../helpers/pump_app.dart';

class _Repository extends Mock implements AuthRepository {}

Future<void> _signOut() async {}

void main() {
  late _Repository repository;

  setUp(() => repository = _Repository());

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    String language = 'en',
  }) => pumpApp(
    tester,
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(repository)),
        BlocProvider(create: (_) => ResendCodeCubit(repository)),
        BlocProvider<AvatarUploadCubit>(create: (_) => testAvatarCubit()),
      ],
      child: screen,
    ),
    language: language,
  );

  group('KIT-T16: the keyboard', () {
    bool focused(WidgetTester tester, int index) => tester
        .state<EditableTextState>(find.byType(EditableText).at(index))
        .widget
        .focusNode
        .hasFocus;

    testWidgets('KIT-T16: next moves to the next field on sign-in', (
      tester,
    ) async {
      await pump(tester, const SignInScreen());
      await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(focused(tester, 1), isTrue);
    });

    testWidgets('KIT-T16: next walks every sign-up field in order', (
      tester,
    ) async {
      await pump(tester, const SignUpScreen());
      for (var i = 0; i < 4; i++) {
        await tester.enterText(find.byType(TextField).at(i), 'x');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();
        expect(focused(tester, i + 1), isTrue, reason: 'after field $i');
      }
    });

    testWidgets('KIT-T16: enter on the last sign-in field signs in', (
      tester,
    ) async {
      when(
        () => repository.signIn(identifier: 'a@b.co', password: 'secret1a'),
      ).thenAnswer((_) async => const Right(unit));
      await pump(tester, const SignInScreen());
      await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
      await tester.enterText(find.byType(TextField).at(1), 'secret1a');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      verify(
        () => repository.signIn(identifier: 'a@b.co', password: 'secret1a'),
      ).called(1);
    });

    testWidgets('KIT-T16: enter on an empty sign-in only shows the errors', (
      tester,
    ) async {
      await pump(tester, const SignInScreen());
      await tester.tap(find.byType(TextField).at(1));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Please fill this in.'), findsNWidgets(2));
      verifyZeroInteractions(repository);
    });

    testWidgets(
      'KIT-T16: enter on the last sign-up field creates the account',
      (tester) async {
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
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        verify(
          () => repository.signUp(
            name: 'Sara Ali',
            email: 'sara@example.com',
            phone: '0501234567',
            password: 'secret1a',
          ),
        ).called(1);
      },
    );

    testWidgets('KIT-T16: enter confirms the code on verify', (tester) async {
      when(
        () => repository.verifyCode('1234'),
      ).thenAnswer((_) async => const Right(unit));
      await pump(tester, const VerifyCodeScreen(onSignOut: _signOut));
      await tester.enterText(find.byType(TextField), '1234');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      verify(() => repository.verifyCode('1234')).called(1);
    });

    testWidgets('KIT-T16: enter on the last reset field saves the password', (
      tester,
    ) async {
      when(
        () => repository.resetPassword(
          identifier: 'a@b.co',
          code: '1234',
          password: 'secret1a',
        ),
      ).thenAnswer((_) async => const Left(NoConnection()));
      await pump(tester, const ResetPasswordScreen(identifier: 'a@b.co'));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1234');
      await tester.enterText(fields.at(1), 'secret1a');
      await tester.enterText(fields.at(2), 'secret1a');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      verify(
        () => repository.resetPassword(
          identifier: 'a@b.co',
          code: '1234',
          password: 'secret1a',
        ),
      ).called(1);
    });

    testWidgets('KIT-T16: enter sends the reset code request', (tester) async {
      when(
        () => repository.requestPasswordReset('a@b.co'),
      ).thenAnswer((_) async => const Left(NoConnection()));
      await pump(tester, const ForgotPasswordScreen());
      await tester.enterText(find.byType(TextField), 'a@b.co');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      verify(() => repository.requestPasswordReset('a@b.co')).called(1);
    });

    testWidgets('KIT-T16: enter saves the name on complete profile', (
      tester,
    ) async {
      when(
        () => repository.completeProfile(name: 'Sara'),
      ).thenAnswer((_) async => const Left(NoConnection()));
      await pump(
        tester,
        const CompleteProfileScreen(onSignOut: _signOut, canUseCamera: false),
      );
      await tester.enterText(find.byType(TextField), 'Sara');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      verify(() => repository.completeProfile(name: 'Sara')).called(1);
    });

    testWidgets(
      'KIT-T16: the identifier field types both an email and a phone',
      (tester) async {
        for (final screen in const <Widget>[
          SignInScreen(),
          ForgotPasswordScreen(),
        ]) {
          await pump(tester, screen);
          final field = tester.widget<TextField>(find.byType(TextField).first);
          expect(field.keyboardType, TextInputType.text);
          expect(field.autocorrect, isFalse);
          expect(field.autofillHints, contains(AutofillHints.username));
        }
      },
    );
  });

  group('KIT-T16: codes', () {
    testWidgets('KIT-T16: a pasted code with a space is sent as digits', (
      tester,
    ) async {
      when(
        () => repository.verifyCode('123456'),
      ).thenAnswer((_) async => const Right(unit));
      await pump(tester, const VerifyCodeScreen(onSignOut: _signOut));
      await tester.enterText(find.byType(TextField), '123 456');
      await tester.pump();
      expect(find.text('123456'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      verify(() => repository.verifyCode('123456')).called(1);
    });

    testWidgets(
      'KIT-T16: a pasted Arabic-Indic code with a dash is sent as digits',
      (tester) async {
        when(
          () => repository.verifyCode('123456'),
        ).thenAnswer((_) async => const Right(unit));
        await pump(
          tester,
          const VerifyCodeScreen(onSignOut: _signOut),
          language: 'ar',
        );
        await tester.enterText(find.byType(TextField), '١٢٣-٤٥٦');
        await tester.pump();
        expect(find.text('١٢٣٤٥٦'), findsOneWidget);
        await tester.tap(find.text('تأكيد'));
        await tester.pumpAndSettle();
        verify(() => repository.verifyCode('123456')).called(1);
      },
    );

    testWidgets('KIT-T16: the code field keeps at most eight digits', (
      tester,
    ) async {
      await pump(tester, const VerifyCodeScreen(onSignOut: _signOut));
      await tester.enterText(find.byType(TextField), '1234567890');
      expect(find.text('12345678'), findsOneWidget);
    });

    testWidgets('KIT-T16: the reset code is cleaned the same way', (
      tester,
    ) async {
      when(
        () => repository.resetPassword(
          identifier: 'a@b.co',
          code: '123456',
          password: 'secret1a',
        ),
      ).thenAnswer((_) async => const Left(NoConnection()));
      await pump(tester, const ResetPasswordScreen(identifier: 'a@b.co'));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '123 456');
      await tester.enterText(fields.at(1), 'secret1a');
      await tester.enterText(fields.at(2), 'secret1a');
      await tester.tap(find.text('Save password'));
      await tester.pumpAndSettle();
      verify(
        () => repository.resetPassword(
          identifier: 'a@b.co',
          code: '123456',
          password: 'secret1a',
        ),
      ).called(1);
    });

    for (final (name, screen, action) in <(String, Widget, String)>[
      ('verify', const VerifyCodeScreen(onSignOut: _signOut), 'Confirm'),
      (
        'reset',
        const ResetPasswordScreen(identifier: 'a@b.co'),
        'Save password',
      ),
    ]) {
      testWidgets(
        'KIT-T16: too many tries on $name is said quietly with the wait',
        (tester) async {
          when(() => repository.verifyCode(any())).thenAnswer(
            (_) async =>
                const Left(TooManyRequests(retryAfter: Duration(seconds: 75))),
          );
          when(
            () => repository.resetPassword(
              identifier: any(named: 'identifier'),
              code: any(named: 'code'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async =>
                const Left(TooManyRequests(retryAfter: Duration(seconds: 75))),
          );
          await pump(tester, screen);
          final fields = find.byType(TextField);
          await tester.enterText(fields.first, '1234');
          if (name == 'reset') {
            await tester.enterText(fields.at(1), 'secret1a');
            await tester.enterText(fields.at(2), 'secret1a');
          }
          await tester.tap(find.text(action));
          await tester.pumpAndSettle();
          expect(find.textContaining('01:15'), findsOneWidget);
          expect(find.textContaining('went wrong'), findsNothing);
        },
      );

      testWidgets('KIT-T16: an expired code on $name asks for a new one', (
        tester,
      ) async {
        when(
          () => repository.verifyCode(any()),
        ).thenAnswer((_) async => const Left(CodeExpired()));
        when(
          () => repository.resetPassword(
            identifier: any(named: 'identifier'),
            code: any(named: 'code'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(CodeExpired()));
        await pump(tester, screen, language: 'ar');
        final fields = find.byType(TextField);
        await tester.enterText(fields.first, '1234');
        if (name == 'reset') {
          await tester.enterText(fields.at(1), 'secret1a');
          await tester.enterText(fields.at(2), 'secret1a');
        }
        await tester.tap(
          find.text(name == 'reset' ? 'حفظ كلمة المرور' : 'تأكيد'),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('انتهت صلاحية هذا الرمز. يُرجى طلب رمز جديد.'),
          findsOneWidget,
        );
      });
    }
  });

  group('KIT-T16: the way back', () {
    testWidgets('KIT-T16: forgot password has its own courteous link', (
      tester,
    ) async {
      await pump(tester, const ForgotPasswordScreen());
      expect(find.text('Remembered it? Back to sign in'), findsOneWidget);
      expect(find.text('Already have an account? Sign in'), findsNothing);
    });

    testWidgets('KIT-T16: reset password offers a way back to sign-in', (
      tester,
    ) async {
      await pump(tester, const ResetPasswordScreen(identifier: 'a@b.co'));
      expect(find.text('Remembered it? Back to sign in'), findsOneWidget);
    });

    testWidgets('KIT-T16: the way back reads well in Arabic', (tester) async {
      await pump(
        tester,
        const ResetPasswordScreen(identifier: 'a@b.co'),
        language: 'ar',
      );
      expect(find.text('تذكّرتها؟ العودة إلى تسجيل الدخول'), findsOneWidget);
    });
  });
}
