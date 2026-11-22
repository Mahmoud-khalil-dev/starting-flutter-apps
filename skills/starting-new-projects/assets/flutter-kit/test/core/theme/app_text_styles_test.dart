import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_fonts.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';

List<TextStyle> _all(AppTextStyles t) => [
  t.display,
  t.headline,
  t.title,
  t.body,
  t.label,
  t.caption,
  t.smallCaps,
  t.tab,
  t.numeric,
];

void main() {
  final en = AppTextStyles.build(language: 'en', colors: AppPalette.light);
  final ar = AppTextStyles.build(language: 'ar', colors: AppPalette.light);

  test('KIT-T8: roles keep a clear display-to-body contrast', () {
    expect(en.display.fontSize, 32);
    expect(en.headline.fontSize, 24);
    expect(en.title.fontSize, 18);
    expect(en.body.fontSize, 16);
    expect(en.label.fontSize, 14);
    expect(en.caption.fontSize, 12);
    expect(en.smallCaps.fontSize, 11);
    expect(en.title.fontWeight, FontWeight.w600);
    expect(en.body.fontWeight, FontWeight.w400);
  });

  test('KIT-T8: tab labels keep the platform size at any width scale', () {
    for (final language in ['en', 'ar']) {
      final wide = AppTextStyles.build(
        language: language,
        colors: AppPalette.light,
        scale: 1.2,
      );
      expect(wide.tab.fontSize, 11, reason: language);
      expect(
        wide.body.fontSize,
        16 * 1.2 * (language == 'ar' ? AppTextStyles.arabicScale : 1),
        reason: language,
      );
    }
  });

  test('KIT-T8: nothing is smaller than 11 pt', () {
    for (final s in [..._all(en), ..._all(ar)]) {
      expect(s.fontSize, greaterThanOrEqualTo(11));
    }
  });

  test('KIT-T8: nothing is smaller than 11 pt on the narrowest phone', () {
    for (final language in ['en', 'ar']) {
      final narrow = AppTextStyles.build(
        language: language,
        colors: AppPalette.light,
        scale: 0.85,
      );
      for (final s in _all(narrow)) {
        expect(s.fontSize, greaterThanOrEqualTo(11), reason: language);
      }
      expect(
        narrow.body.fontSize,
        closeTo(
          16 * 0.85 * (language == 'ar' ? AppTextStyles.arabicScale : 1),
          0.001,
        ),
      );
    }
  });

  test('KIT-T8: each language gets its family and Arabic is never spaced', () {
    expect(en.smallCaps.letterSpacing, greaterThan(0));
    for (final s in _all(ar)) {
      expect(s.letterSpacing ?? 0, 0);
      expect(s.height, greaterThan(en.body.height! - 0.2));
    }
    expect(ar.body.height, greaterThan(en.body.height!));
  });

  test('KIT-T8: colours come from the palette and numbers are tabular', () {
    expect(en.body.color, AppPalette.light.ink);
    expect(en.caption.color, AppPalette.light.inkMuted);
    expect(
      en.numeric.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('KIT-T8: the scale multiplies sizes only', () {
    final big = AppTextStyles.build(
      language: 'en',
      colors: AppPalette.light,
      scale: 1.4,
    );
    expect(big.body.fontSize, closeTo(16 * 1.4, 0.001));
    expect(big.body.height, en.body.height);
  });

  test('KIT-T8: the text styles lerp and map onto a TextTheme', () {
    final theme = en.asTextTheme();
    expect(theme.bodyMedium, en.body);
    expect(theme.titleMedium, en.title);
    expect(theme.labelLarge, en.label);
    expect(en.lerp(ar, 0).body.fontFamily, AppFonts.primaryFor('en'));
  });

  test(
    'KIT-T8: every role has its face, size, weight, height and tracking',
    () {
      // role: en size, en weight, ar weight, en height, ar height, tracking,
      // display face
      final want =
          <
            String,
            (double, FontWeight, FontWeight, double, double, double, bool)
          >{
            'display': (
              32,
              FontWeight.w600,
              FontWeight.w400,
              1.2,
              1.4,
              -0.4,
              true,
            ),
            'headline': (
              24,
              FontWeight.w600,
              FontWeight.w400,
              1.3,
              1.5,
              -0.2,
              true,
            ),
            'title': (
              18,
              FontWeight.w600,
              FontWeight.w600,
              1.4,
              1.55,
              0,
              false,
            ),
            'body': (16, FontWeight.w400, FontWeight.w400, 1.5, 1.7, 0, false),
            'label': (
              14,
              FontWeight.w500,
              FontWeight.w500,
              1.4,
              1.55,
              0,
              false,
            ),
            'caption': (
              12,
              FontWeight.w400,
              FontWeight.w400,
              1.35,
              1.5,
              0,
              false,
            ),
            'smallCaps': (
              11,
              FontWeight.w600,
              FontWeight.w600,
              1.4,
              1.5,
              1.2,
              false,
            ),
            'tab': (11, FontWeight.w500, FontWeight.w500, 1.3, 1.45, 0, false),
            'numeric': (
              16,
              FontWeight.w500,
              FontWeight.w500,
              1.3,
              1.4,
              0,
              false,
            ),
          };
      Map<String, TextStyle> byName(AppTextStyles t) => {
        'display': t.display,
        'headline': t.headline,
        'title': t.title,
        'body': t.body,
        'label': t.label,
        'caption': t.caption,
        'smallCaps': t.smallCaps,
        'tab': t.tab,
        'numeric': t.numeric,
      };
      for (final MapEntry(key: role, value: w) in want.entries) {
        final a = byName(en)[role]!;
        expect(a.fontSize, w.$1, reason: 'en $role size');
        expect(a.fontWeight, w.$2, reason: 'en $role weight');
        expect(a.fontVariations, [
          FontVariation('wght', w.$2.value.toDouble()),
        ]);
        expect(a.height, w.$4, reason: 'en $role height');
        expect(a.letterSpacing, w.$6, reason: 'en $role tracking');
        expect(
          a.fontFamilyFallback,
          w.$7 ? AppFonts.displayFallbackFor('en') : AppFonts.fallbackFor('en'),
          reason: 'en $role fallback',
        );
        expect(
          a.fontFamily,
          w.$7 ? AppFonts.displayFor('en') : AppFonts.primaryFor('en'),
        );
        final b = byName(ar)[role]!;
        final factor = w.$7
            ? AppTextStyles.arabicDisplayScale
            : AppTextStyles.arabicScale;
        expect(
          b.fontSize,
          closeTo(math.max(w.$1 * factor, AppTextStyles.minSize), 0.001),
          reason: 'ar $role size',
        );
        expect(b.fontWeight, w.$3, reason: 'ar $role weight');
        expect(b.height, w.$5, reason: 'ar $role height');
        expect(b.letterSpacing, 0, reason: 'ar $role tracking');
        expect(
          b.fontFamily,
          w.$7 ? AppFonts.displayFor('ar') : AppFonts.primaryFor('ar'),
        );
        expect(
          b.fontFamilyFallback,
          w.$7 ? AppFonts.displayFallbackFor('ar') : AppFonts.fallbackFor('ar'),
        );
      }
    },
  );

  test(
    'KIT-T8: display text is never set under its minimum size, on any phone',
    () {
      for (final language in ['en', 'ar']) {
        final narrow = AppTextStyles.build(
          language: language,
          colors: AppPalette.light,
          scale: 0.85,
        );
        for (final s in [narrow.display, narrow.headline]) {
          expect(
            s.fontSize,
            greaterThanOrEqualTo(AppTextStyles.displayMinSize),
          );
        }
      }
    },
  );

  test('KIT-T8: with bold text every role carries wght 700 or its own', () {
    for (final language in ['en', 'ar']) {
      final bold = AppTextStyles.build(
        language: language,
        colors: AppPalette.light,
        boldText: true,
      );
      final regular = AppTextStyles.build(
        language: language,
        colors: AppPalette.light,
      );
      for (final (b, r) in [
        for (var i = 0; i < _all(bold).length; i++)
          (_all(bold)[i], _all(regular)[i]),
      ]) {
        final want = math.max(r.fontWeight!.value, 700);
        expect(b.fontWeight!.value, want, reason: language);
        expect(b.fontVariations, [FontVariation('wght', want.toDouble())]);
        expect(b.fontSize, r.fontSize);
      }
    }
  });

  test('KIT-T8: weighted sets the weight and the wght axis together', () {
    final s = AppTextStyles.weighted(en.label, FontWeight.w600);
    expect(s.fontWeight, FontWeight.w600);
    expect(s.fontVariations, [const FontVariation('wght', 600)]);
    expect(s.fontSize, en.label.fontSize);
    // A style that came from a bold theme stays at its heavier weight.
    final bold = AppTextStyles.build(
      language: 'en',
      colors: AppPalette.light,
      boldText: true,
    );
    final kept = AppTextStyles.weighted(bold.label, FontWeight.w600);
    expect(kept.fontVariations, [const FontVariation('wght', 700)]);
    expect(kept.fontWeight, FontWeight.w700);
  });

  test('KIT-T8: smallCaps and numeric colours and tabular figures', () {
    for (final t in [en, ar]) {
      expect(t.smallCaps.color, AppPalette.light.inkMuted);
      expect(t.numeric.color, AppPalette.light.ink);
      expect(t.numeric.fontFeatures, [const FontFeature.tabularFigures()]);
      for (final s in [t.display, t.headline, t.title, t.body, t.label]) {
        expect(s.color, AppPalette.light.ink);
      }
    }
  });
}
