import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/presentation/view/settings_screen.dart';

import '../../../../helpers/l10n.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/settings_cubit.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String language,
  required Size size,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  VoidCallback? onSignOut,
}) async {
  final (cubit, _) = (await tester.runAsync(loadedSettings))!;
  addTearDown(cubit.close);
  await pumpApp(
    tester,
    BlocProvider.value(
      value: cubit,
      child: SettingsScreen(onSignOut: onSignOut),
    ),
    language: language,
    brightness: brightness,
    size: size,
    textScale: textScale,
  );
}

void main() {
  for (final language in ['en', 'ar']) {
    for (final size in [TestSizes.phone, TestSizes.tablet, TestSizes.web]) {
      final width = size.width.toInt();
      testWidgets('KIT-T12: a signed-in user can sign out from Settings '
          '($language, $width)', (tester) async {
        var calls = 0;
        await _pump(
          tester,
          language: language,
          size: size,
          onSignOut: () => calls++,
        );
        final action = find.text(l10nFor(language).authSignOutAction);
        await tester.scrollUntilVisible(
          action,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(action);
        await tester.pump();
        expect(calls, 1);
      });

      for (final brightness in Brightness.values) {
        testWidgets('KIT-T12: the sign-out row fits at the largest text size '
            '($language, ${brightness.name}, $width)', (tester) async {
          await _pump(
            tester,
            language: language,
            size: size,
            brightness: brightness,
            textScale: AppSettings.maxTextScale,
            onSignOut: () {},
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('KIT-T12: with no sign-out to call, Settings shows none', (
    tester,
  ) async {
    await _pump(tester, language: 'en', size: TestSizes.phone);
    expect(find.text(l10nFor('en').authSignOutAction), findsNothing);
  });
}
