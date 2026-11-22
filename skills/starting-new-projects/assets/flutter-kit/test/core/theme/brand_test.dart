import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/app_theme.dart';
import 'package:kit_app/core/theme/brand.dart';
import 'package:kit_app/core/theme/contrast.dart';

void main() {
  test('KIT-T8: the light theme derives its colours from the Brand seeds', () {
    final theme = AppTheme.build(brightness: Brightness.light, language: 'en');
    final c = AppPalette.light;
    expect(c.primary, Brand.lightSeed);
    expect(c.brand, Brand.lightSeed);
    expect(
      c.primaryInk,
      ensureContrast(Brand.lightSeed, c.surfaces, lighten: false),
    );
    expect(theme.colorScheme.primary, c.primaryInk);
  });

  test('KIT-T8: the dark theme derives its colours from the Brand seeds', () {
    final c = AppPalette.dark;
    expect(
      c.primary,
      ensureContrast(Brand.darkSeed, c.surfaces, lighten: true, min: 3),
    );
    expect(c.brand, ensureContrast(Brand.lightSeed, c.surfaces, lighten: true));
    expect(
      c.primaryInk,
      ensureContrast(Brand.darkSeed, c.surfaces, lighten: true),
    );
  });

  test('KIT-T8: the accent marks follow Brand.accent in both themes', () {
    final l = AppPalette.light;
    final d = AppPalette.dark;
    expect(
      l.gold,
      ensureContrast(Brand.accent, l.surfaces, lighten: false, min: 3),
    );
    expect(l.goldInk, ensureContrast(Brand.accent, l.surfaces, lighten: false));
    expect(d.gold, ensureContrast(Brand.accent, d.surfaces, lighten: true));
    expect(d.goldInk, d.gold);
  });

  test('KIT-T8: every role takes its family from whatever Brand says', () {
    for (final language in ['en', 'ar']) {
      final t = AppTheme.build(
        brightness: Brightness.light,
        language: language,
      ).extension<AppTextStyles>()!;
      expect(t.body.fontFamily, Brand.bodyFamily);
      expect(t.display.fontFamily, Brand.displayFamily);
    }
  });

  test('KIT-T8: the brand colour is the light seed, read for dark in dark', () {
    expect(AppPalette.light.brand, Brand.lightSeed);
    expect(
      AppPalette.dark.brand,
      ensureContrast(Brand.lightSeed, AppPalette.dark.surfaces, lighten: true),
    );
  });

  test(
    'KIT-T8: text on the light seed is picked to read, whatever the seed',
    () {
      final c = AppPalette.light;
      expect(
        contrastRatio(c.onPrimary, Brand.lightSeed),
        greaterThanOrEqualTo(4.5),
      );
    },
  );
}
