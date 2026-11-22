import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:kit_app/features/settings/presentation/view/settings_screen.dart';
import 'package:kit_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/l10n.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/settings_cubit.dart';

Future<(SettingsCubit, MockSettingsRepository)> _pump(
  WidgetTester tester, {
  String language = 'en',
  Brightness brightness = Brightness.light,
  Size size = TestSizes.phone,
  bool reduceMotion = false,
  TargetPlatform? platform,
  double textScale = 1,
  AppSettings initial = AppSettings.defaults,
  Either<Failure, Unit> saveResult = const Right(unit),
}) async {
  final (cubit, repository) = (await tester.runAsync(
    () => loadedSettings(initial: initial, saveResult: saveResult),
  ))!;
  addTearDown(cubit.close);
  await pumpApp(
    tester,
    BlocProvider.value(value: cubit, child: const SettingsScreen()),
    language: language,
    brightness: brightness,
    size: size,
    reduceMotion: reduceMotion,
    platform: platform,
    textScale: textScale,
  );
  return (cubit, repository);
}

AppLocalizations _l(String language) => l10nFor(language);

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets('KIT-T12: the phone lists the three groups ($language)', (
      tester,
    ) async {
      await _pump(tester, language: language);
      final l10n = _l(language);
      expect(find.text(l10n.navSettings), findsOneWidget);
      for (final title in [
        l10n.settingsAppearanceTitle,
        l10n.settingsLanguageTitle,
        l10n.settingsTextSizeTitle,
      ]) {
        // AppGroup upper-cases Latin titles.
        expect(
          find.text(language == 'ar' ? title : title.toUpperCase()),
          findsOneWidget,
        );
      }
      for (final label in [
        l10n.settingsThemeSystem,
        l10n.settingsThemeLight,
        l10n.settingsThemeDark,
        l10n.settingsLanguageSystem,
        l10n.settingsLanguageEnglish,
        l10n.settingsLanguageArabic,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });
  }

  testWidgets('KIT-T12: choosing Dark saves it and the control follows', (
    tester,
  ) async {
    final (cubit, repository) = await _pump(tester);
    await tester.tap(find.text(_l('en').settingsThemeDark));
    await tester.pumpAndSettle();
    verify(
      () => repository.save(
        AppSettings.defaults.copyWith(themeMode: ThemeMode.dark),
      ),
    ).called(1);
    expect(cubit.state.settings.themeMode, ThemeMode.dark);
  });

  testWidgets('KIT-T12: choosing a language saves it, and the device again', (
    tester,
  ) async {
    final (cubit, _) = await _pump(
      tester,
      initial: AppSettings.defaults.copyWith(locale: const Locale('ar')),
    );
    await tester.tap(find.text(_l('en').settingsLanguageEnglish));
    await tester.pumpAndSettle();
    expect(cubit.state.settings.locale, const Locale('en'));
    await tester.tap(find.text(_l('en').settingsLanguageSystem));
    await tester.pumpAndSettle();
    expect(cubit.state.settings.locale, isNull);
  });

  testWidgets('KIT-T12: the text size shows as a percentage', (tester) async {
    await _pump(
      tester,
      initial: AppSettings.defaults.copyWith(textScale: 1.25),
    );
    expect(find.text('125%'), findsOneWidget);
  });

  testWidgets('KIT-T12: in Arabic the text size uses Arabic-Indic digits', (
    tester,
  ) async {
    await _pump(
      tester,
      language: 'ar',
      initial: AppSettings.defaults.copyWith(textScale: 1.25),
    );
    expect(find.text('١٢٥٪'), findsOneWidget);
    expect(find.textContaining('125'), findsNothing);
  });

  testWidgets('KIT-T12: dragging the slider saves once, when it is released', (
    tester,
  ) async {
    final (cubit, repository) = await _pump(tester);
    final slider = find.byType(Slider);
    final start = tester.getCenter(slider);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    verifyNever(() => repository.save(any()));
    await gesture.up();
    await tester.pumpAndSettle();
    verify(() => repository.save(any())).called(1);
    expect(cubit.state.settings.textScale, greaterThan(1));
    expect(
      cubit.state.settings.textScale,
      lessThanOrEqualTo(AppSettings.maxTextScale),
    );
  });

  testWidgets('KIT-T12: the slider reaches both ends of the range', (
    tester,
  ) async {
    await _pump(tester);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, AppSettings.minTextScale);
    expect(slider.max, AppSettings.maxTextScale);
  });

  testWidgets('KIT-T12: the slider has the Apple look on iOS', (tester) async {
    final (cubit, _) = await _pump(tester, platform: TargetPlatform.iOS);
    expect(find.byType(CupertinoSlider), findsOneWidget);
    // Apple's slider is dragged by its thumb: 100% sits 20% along the
    // range, inside a thumb's width of each end.
    const thumbRadius = 14.0;
    final box = tester.getRect(find.byType(CupertinoSlider));
    const range = AppSettings.maxTextScale - AppSettings.minTextScale;
    const along = (1 - AppSettings.minTextScale) / range;
    final thumb = Offset(
      box.left + thumbRadius + along * (box.width - 2 * thumbRadius),
      box.center.dy,
    );
    final gesture = await tester.startGesture(thumb);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(cubit.state.settings.textScale, greaterThan(1));
  });

  testWidgets('KIT-T12: the slider is Material on Android', (tester) async {
    await _pump(tester, platform: TargetPlatform.android);
    expect(find.byType(CupertinoSlider), findsNothing);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('KIT-T12: the slider says its value in Arabic-Indic digits', (
    tester,
  ) async {
    await _pump(tester, language: 'ar', platform: TargetPlatform.android);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.semanticFormatterCallback!(1.25), '١٢٥٪');
    expect(slider.label, '١٠٠٪');
  });

  testWidgets('KIT-T12: a failed save shows a message and clears it', (
    tester,
  ) async {
    final (cubit, _) = await _pump(
      tester,
      saveResult: const Left(UnknownFailure()),
    );
    await tester.tap(find.text(_l('en').settingsThemeDark));
    await tester.pump();
    await tester.pump();
    expect(find.text(_l('en').errorUnknown), findsOneWidget);
    expect(cubit.state.failure, isNull);
    expect(cubit.state.settings.themeMode, ThemeMode.system);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  for (final size in [TestSizes.tablet, TestSizes.web]) {
    testWidgets('KIT-T12: from ${size.width.toInt()} wide it is two panes', (
      tester,
    ) async {
      await _pump(tester, size: size);
      final l10n = _l('en');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('settings-list')),
          matching: find.text(l10n.settingsLanguageTitle),
        ),
        findsOneWidget,
      );
      // The first section's controls are open; the others are not.
      expect(find.text(l10n.settingsThemeDark), findsOneWidget);
      expect(find.text(l10n.settingsLanguageEnglish), findsNothing);
      expect(find.byType(Slider), findsNothing);
    });
  }

  testWidgets('KIT-T12: choosing a section on a tablet opens its controls', (
    tester,
  ) async {
    await _pump(tester, size: TestSizes.tablet);
    final l10n = _l('en');
    await tester.tap(find.text(l10n.settingsLanguageTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsLanguageEnglish), findsOneWidget);
    expect(find.text(l10n.settingsThemeDark), findsNothing);
    await tester.tap(find.text(l10n.settingsTextSizeTitle));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('KIT-T12: a tablet saves from the open pane too', (tester) async {
    final (cubit, _) = await _pump(tester, size: TestSizes.web);
    await tester.tap(find.text(_l('en').settingsThemeLight));
    await tester.pumpAndSettle();
    expect(cubit.state.settings.themeMode, ThemeMode.light);
  });

  testWidgets('KIT-T12: the pane fades over Motion.quick, or jumps', (
    tester,
  ) async {
    await _pump(tester, size: TestSizes.tablet);
    final l10n = _l('en');
    await tester.tap(find.text(l10n.settingsLanguageTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(l10n.settingsThemeDark), findsOneWidget);
    expect(find.text(l10n.settingsLanguageEnglish), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsThemeDark), findsNothing);
  });

  testWidgets('KIT-T12: under reduce motion the pane switches at once', (
    tester,
  ) async {
    await _pump(tester, size: TestSizes.tablet, reduceMotion: true);
    final l10n = _l('en');
    await tester.tap(find.text(l10n.settingsLanguageTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text(l10n.settingsThemeDark), findsNothing);
    expect(find.text(l10n.settingsLanguageEnglish), findsOneWidget);
  });

  for (final language in ['en', 'ar']) {
    for (final brightness in Brightness.values) {
      for (final size in [TestSizes.phone, TestSizes.tablet, TestSizes.web]) {
        testWidgets('KIT-T12: no overflow at the largest text size '
            '($language, ${brightness.name}, ${size.width.toInt()})', (
          tester,
        ) async {
          await _pump(
            tester,
            language: language,
            brightness: brightness,
            size: size,
            textScale: AppSettings.maxTextScale,
            initial: AppSettings.defaults.copyWith(
              textScale: AppSettings.maxTextScale,
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
