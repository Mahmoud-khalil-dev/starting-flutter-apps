import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_fonts.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/app_theme.dart';
import 'package:kit_app/core/theme/brand.dart';

void main() {
  tearDown(() {
    AppFonts.override = null;
    AppFonts.fallbackOverride = null;
  });

  test('KIT-T11: a test can name fallback families for every role', () {
    expect(AppFonts.fallbackFor('ar'), isEmpty);
    expect(AppFonts.displayFallbackFor('en'), isEmpty);
    AppFonts.fallbackOverride = ['Other Script'];
    for (final language in ['en', 'ar']) {
      expect(AppFonts.fallbackFor(language), ['Other Script']);
      expect(AppFonts.displayFallbackFor(language), ['Other Script']);
      final t = AppTheme.build(
        brightness: Brightness.light,
        language: language,
      ).extension<AppTextStyles>()!;
      expect(t.body.fontFamilyFallback, ['Other Script']);
      expect(t.display.fontFamilyFallback, ['Other Script']);
    }
  });

  test('KIT-T8: every role reads its family from Brand, in both languages', () {
    for (final language in ['en', 'ar']) {
      expect(AppFonts.primaryFor(language), Brand.bodyFamily);
      expect(AppFonts.displayFor(language), Brand.displayFamily);
    }
  });

  test('KIT-T8: named families reach every text role and the theme', () {
    AppFonts.override = (body: 'Body Face', display: 'Display Face');
    for (final language in ['en', 'ar']) {
      expect(AppFonts.primaryFor(language), 'Body Face');
      expect(AppFonts.displayFor(language), 'Display Face');
      final theme = AppTheme.build(
        brightness: Brightness.light,
        language: language,
      );
      final t = theme.extension<AppTextStyles>()!;
      for (final s in [t.title, t.body, t.label, t.caption, t.numeric]) {
        expect(s.fontFamily, 'Body Face', reason: language);
      }
      for (final s in [t.display, t.headline]) {
        expect(s.fontFamily, 'Display Face', reason: language);
      }
      expect(theme.textTheme.bodyMedium!.fontFamily, 'Body Face');
    }
  });

  test(
    'KIT-T8: a family is set on the theme, a null one is left to the OS',
    () {
      AppFonts.override = (body: null, display: null);
      final t = AppTheme.build(
        brightness: Brightness.light,
        language: 'en',
      ).extension<AppTextStyles>()!;
      expect(t.body.fontFamily, isNull);
      expect(t.display.fontFamily, isNull);
    },
  );

  test('KIT-T8: the system font needs no fallback face', () {
    for (final language in ['en', 'ar']) {
      expect(AppFonts.fallbackFor(language), isEmpty);
      expect(AppFonts.displayFallbackFor(language), isEmpty);
    }
  });
}
