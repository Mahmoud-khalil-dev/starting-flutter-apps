import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/boot/boot_failure_screen.dart';
import 'package:kit_app/l10n/app_localizations_ar.dart';
import 'package:kit_app/l10n/app_localizations_en.dart';

void main() {
  for (final (code, l10n) in [
    ('en', AppLocalizationsEn()),
    ('ar', AppLocalizationsAr()),
  ]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets('KIT-T10: the boot failure screen shows its copy and retries '
          '($code, ${brightness.name})', (tester) async {
        tester.platformDispatcher.localeTestValue = Locale(code);
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        var retried = 0;

        await tester.pumpWidget(
          BootFailureScreen(
            onRetry: () async {
              retried++;
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.bootFailureTitle), findsOneWidget);
        expect(find.text(l10n.bootFailureBody), findsOneWidget);
        expect(find.text(l10n.bootFailureRetry), findsOneWidget);
        final theme = Theme.of(tester.element(find.byType(Scaffold)));
        expect(theme.brightness, brightness);
        expect(
          Directionality.of(tester.element(find.byType(Scaffold))),
          code == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );

        await tester.tap(find.text(l10n.bootFailureRetry));
        expect(retried, 1);
      });
    }
  }

  testWidgets('KIT-T10: an unsupported system language shows English', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('fr');
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(BootFailureScreen(onRetry: () async {}));
    await tester.pumpAndSettle();

    expect(find.text(AppLocalizationsEn().bootFailureTitle), findsOneWidget);
  });

  for (final reduce in [false, true]) {
    testWidgets(
      'KIT-T10: the retry button shows a calm loading state while a retry runs '
      '(reduce motion: $reduce)',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: reduce);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final gate = Completer<void>();
        var retried = 0;
        await tester.pumpWidget(
          BootFailureScreen(
            onRetry: () {
              retried++;
              return gate.future;
            },
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        final l10n = AppLocalizationsEn();

        await tester.tap(find.text(l10n.bootFailureRetry));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text(l10n.bootFailureRetry), findsNothing);

        await tester.tap(find.byType(CircularProgressIndicator));
        expect(retried, 1);

        gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text(l10n.bootFailureRetry), findsOneWidget);
      },
    );
  }
}
