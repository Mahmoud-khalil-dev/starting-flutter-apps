import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/l10n/arabic_digit_localizations.dart';
import 'package:kit_app/core/theme/app_theme.dart';
import 'package:kit_app/core/utils/responsive.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// Phone, tablet and desktop-web window sizes (docs/ARCHITECTURE.md).
abstract final class TestSizes {
  static const phone = Size(390, 844);
  static const tablet = Size(820, 1180);
  static const web = Size(1440, 900);
}

/// Pumps [child] under a Material inside a MaterialApp with the app's
/// localizations and the app theme. [settle] false pumps one frame, for
/// tests that step through an animation or show a looping spinner. [web]
/// true renders as the web build does (null: the platform the test runs on).
///
/// A second call in the same test applies its theme, platform, language,
/// text scale, reduce motion and increased contrast in its first frame:
/// the theme does not animate, and the app is keyed by those values so it
/// is built afresh. A change of [size] alone keeps the tree, as a window
/// resize does.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  String language = 'en',
  Brightness brightness = Brightness.light,
  Size size = TestSizes.phone,
  double textScale = 1,
  TargetPlatform? platform,
  bool? web,
  bool reduceMotion = false,
  bool highContrast = false,
  bool boldText = false,
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      key: ValueKey((
        language,
        brightness,
        textScale,
        platform,
        web,
        reduceMotion,
        highContrast,
        boldText,
      )),
      themeAnimationDuration: Duration.zero,
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        // First, so the Arabic-Indic digit strings win over the stock ones.
        ArabicDigitMaterialLocalizations.delegate,
        ArabicDigitCupertinoLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      theme: AppTheme.build(
        brightness: brightness,
        language: language,
        scale: ResponsiveScale.forWidth(size.width),
        platform: platform,
        web: web,
        boldText: boldText,
      ),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
          highContrast: highContrast,
          boldText: boldText,
        ),
        child: page ?? const SizedBox(),
      ),
      home: Material(child: child),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
