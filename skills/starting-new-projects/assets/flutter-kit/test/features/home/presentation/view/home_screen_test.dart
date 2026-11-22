import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/features/home/presentation/view/home_screen.dart';

import '../../../../helpers/l10n.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets('KIT-T10: home says where the app starts ($language)', (
      tester,
    ) async {
      await pumpApp(tester, const HomeScreen(), language: language);
      final l10n = l10nFor(language);
      expect(find.text(l10n.homeEmptyTitle), findsOneWidget);
      expect(find.text(l10n.homeEmptyBody), findsOneWidget);
    });
  }

  testWidgets('KIT-T10: the English title is the calm starting line', (
    tester,
  ) async {
    await pumpApp(tester, const HomeScreen());
    expect(find.text('Your app starts here'), findsOneWidget);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
    ('web', TestSizes.web),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'KIT-T10: home fits at $name width in ${brightness.name} at 2x text',
        (tester) async {
          await pumpApp(
            tester,
            const HomeScreen(),
            size: size,
            brightness: brightness,
            textScale: 2,
            language: 'ar',
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(HomeScreen), findsOneWidget);
          expect(
            tester.getCenter(find.text(l10nFor('ar').homeEmptyTitle)).dx,
            closeTo(size.width / 2, 1),
          );
        },
      );
    }
  }
}
