import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/view/reset_password_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class _Repository extends Mock implements AuthRepository {}

/// A one-time code keeps the digits the user typed on screen; the API gets
/// Western digits.
void main() {
  late _Repository repository;

  setUp(() => repository = _Repository());

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    String language = 'en',
  }) => pumpApp(
    tester,
    BlocProvider(create: (_) => AuthCubit(repository), child: screen),
    language: language,
  );

  testWidgets(
    'KIT-T16: an Arabic-Indic reset code is shown as typed and sent as '
    'Western digits',
    (tester) async {
      when(
        () => repository.resetPassword(
          identifier: 'a@b.co',
          code: '1234',
          password: 'secret1a',
        ),
      ).thenAnswer((_) async => const Left(NoConnection()));
      await pump(
        tester,
        const ResetPasswordScreen(identifier: 'a@b.co'),
        language: 'ar',
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '١٢٣٤');
      await tester.pump();
      expect(find.text('١٢٣٤'), findsOneWidget);
      await tester.enterText(fields.at(1), 'secret1a');
      await tester.enterText(fields.at(2), 'secret1a');
      await tester.tap(find.text('حفظ كلمة المرور'));
      await tester.pumpAndSettle();
      verify(
        () => repository.resetPassword(
          identifier: 'a@b.co',
          code: '1234',
          password: 'secret1a',
        ),
      ).called(1);
    },
  );
}
