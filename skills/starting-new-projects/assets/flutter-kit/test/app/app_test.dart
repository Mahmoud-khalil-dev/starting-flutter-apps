import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/app/app.dart';
import 'package:kit_app/core/l10n/arabic_digit_localizations.dart';
import 'package:kit_app/core/theme/reduce_motion_scope.dart';
import 'package:kit_app/core/widgets/app_sensitive.dart';
import 'package:kit_app/core/widgets/app_system_overlay.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/l10n/app_localizations.dart';

import '../helpers/settings_cubit.dart';

const _arabic = AppSettings(
  themeMode: ThemeMode.system,
  locale: Locale('ar'),
  textScale: 1,
);

GoRouter _router(void Function(BuildContext) capture) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        capture(context);
        return const SizedBox();
      },
    ),
  ],
);

void main() {
  testWidgets(
    'KIT-T10: App applies locale, direction, delegates and the builder',
    (tester) async {
      late BuildContext captured;
      final (settings, _) = (await tester.runAsync(
        () => loadedSettings(initial: _arabic),
      ))!;
      addTearDown(settings.close);
      await tester.pumpWidget(
        App(
          router: _router((c) => captured = c),
          settings: settings,
          builder: (context, child) =>
              KeyedSubtree(key: const ValueKey('wrap'), child: child!),
        ),
      );
      await tester.pumpAndSettle();
      expect(Directionality.of(captured), TextDirection.rtl);
      expect(AppLocalizations.of(captured)!.localeName, 'ar');
      expect(find.byKey(const ValueKey('wrap')), findsOneWidget);
    },
  );

  testWidgets('KIT-T10: the Arabic-Indic picker strings come first', (
    tester,
  ) async {
    final (settings, _) = (await tester.runAsync(
      () => loadedSettings(initial: _arabic),
    ))!;
    addTearDown(settings.close);
    await tester.pumpWidget(App(router: _router((_) {}), settings: settings));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final delegates = app.localizationsDelegates!.toList();
    expect(delegates.first, ArabicDigitMaterialLocalizations.delegate);
    expect(delegates, contains(ArabicDigitCupertinoLocalizations.delegate));
  });

  testWidgets('KIT-T10: the theme follows the system brightness and language', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    late BuildContext captured;
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    await tester.pumpWidget(
      App(router: _router((c) => captured = c), settings: settings),
    );
    await tester.pumpAndSettle();
    expect(Theme.of(captured).brightness, Brightness.dark);
  });

  testWidgets('KIT-T10: a chosen brightness wins over the system', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    late BuildContext captured;
    final (settings, _) = (await tester.runAsync(
      () => loadedSettings(
        initial: AppSettings.defaults.copyWith(themeMode: ThemeMode.light),
      ),
    ))!;
    addTearDown(settings.close);
    await tester.pumpWidget(
      App(router: _router((c) => captured = c), settings: settings),
    );
    await tester.pumpAndSettle();
    expect(Theme.of(captured).brightness, Brightness.light);
  });

  testWidgets('KIT-T10: the reduce-motion scope sits above the pages', (
    tester,
  ) async {
    late BuildContext captured;
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    await tester.pumpWidget(
      App(router: _router((c) => captured = c), settings: settings),
    );
    await tester.pumpAndSettle();
    expect(
      find.ancestor(
        of: find.byWidgetPredicate((w) => w is SizedBox),
        matching: find.byType(ReduceMotionScope),
      ),
      findsWidgets,
    );
    expect(captured, isNotNull);
  });

  testWidgets('KIT-T11: App gives its masker to AppSensitive below it', (
    tester,
  ) async {
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    var masked = 0;
    Widget masker(Widget child) {
      masked++;
      return child;
    }

    await tester.pumpWidget(
      App(
        settings: settings,
        router: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const AppSensitive(child: SizedBox()),
            ),
          ],
        ),
        masker: masker,
      ),
    );
    await tester.pumpAndSettle();
    expect(masked, greaterThan(0));
  });

  testWidgets('KIT-T12: switching to dark changes the theme brightness', (
    tester,
  ) async {
    late BuildContext captured;
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    await tester.pumpWidget(
      App(router: _router((c) => captured = c), settings: settings),
    );
    await tester.pumpAndSettle();
    expect(Theme.of(captured).brightness, Brightness.light);
    await tester.runAsync(() => settings.setThemeMode(ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(Theme.of(captured).brightness, Brightness.dark);
    await tester.runAsync(() => settings.setThemeMode(ThemeMode.system));
    await tester.pumpAndSettle();
    expect(Theme.of(captured).brightness, Brightness.light);
  });

  testWidgets('KIT-T12: switching the language flips locale and direction', (
    tester,
  ) async {
    late BuildContext captured;
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    await tester.pumpWidget(
      App(router: _router((c) => captured = c), settings: settings),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => settings.setLocale(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(AppLocalizations.of(captured)!.localeName, 'ar');
    expect(Directionality.of(captured), TextDirection.rtl);
  });

  testWidgets('KIT-T12: the chosen text size scales the whole app', (
    tester,
  ) async {
    late BuildContext captured;
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    await tester.pumpWidget(
      App(router: _router((c) => captured = c), settings: settings),
    );
    await tester.pumpAndSettle();
    expect(MediaQuery.textScalerOf(captured).scale(10), 10);
    await tester.runAsync(() => settings.setTextScale(1.3));
    await tester.pumpAndSettle();
    expect(MediaQuery.textScalerOf(captured).scale(10), closeTo(13, 0.001));
  });

  testWidgets('KIT-T12: the chosen text size multiplies the system one', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    late BuildContext captured;
    final (settings, _) = (await tester.runAsync(
      () => loadedSettings(
        initial: AppSettings.defaults.copyWith(textScale: 1.2),
      ),
    ))!;
    addTearDown(settings.close);
    await tester.pumpWidget(
      App(router: _router((c) => captured = c), settings: settings),
    );
    await tester.pumpAndSettle();
    expect(MediaQuery.textScalerOf(captured).scale(10), closeTo(18, 0.001));
  });

  testWidgets('KIT-T12: the text scale is capped at 2.0 whatever the system', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    late BuildContext captured;
    final (settings, _) = (await tester.runAsync(loadedSettings))!;
    addTearDown(settings.close);
    await tester.pumpWidget(
      App(router: _router((c) => captured = c), settings: settings),
    );
    await tester.pumpAndSettle();
    expect(MediaQuery.textScalerOf(captured).scale(10), closeTo(20, 0.001));
    await tester.runAsync(() => settings.setTextScale(1.3));
    await tester.pumpAndSettle();
    expect(MediaQuery.textScalerOf(captured).scale(10), closeTo(20, 0.001));
    await tester.runAsync(() => settings.setTextScale(0.85));
    await tester.pumpAndSettle();
    expect(MediaQuery.textScalerOf(captured).scale(10), closeTo(20, 0.001));
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'KIT-T16: the whole app sets its system bars for ${mode.name}',
      (tester) async {
        final (settings, _) = (await tester.runAsync(
          () => loadedSettings(
            initial: AppSettings.defaults.copyWith(themeMode: mode),
          ),
        ))!;
        addTearDown(settings.close);
        await tester.pumpWidget(
          App(router: _router((_) {}), settings: settings),
        );
        await tester.pumpAndSettle();
        final style = tester
            .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find
                  .descendant(
                    of: find.byType(AppSystemOverlay),
                    matching: find.byType(
                      AnnotatedRegion<SystemUiOverlayStyle>,
                    ),
                  )
                  .first,
            )
            .value;
        expect(
          style.statusBarIconBrightness,
          mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
        );
      },
    );
  }
}
