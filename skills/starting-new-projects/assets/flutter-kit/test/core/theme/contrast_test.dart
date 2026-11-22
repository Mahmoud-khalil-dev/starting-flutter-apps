import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/contrast.dart';

void main() {
  test('KIT-T8: ensureContrast keeps a colour that already reads', () {
    const ink = Color(0xFF111111);
    expect(ensureContrast(ink, const [Colors.white], lighten: false), ink);
  });

  test(
    'KIT-T8: ensureContrast darkens a colour until it reaches the ratio',
    () {
      const pale = Color(0xFF9AA5F5);
      final fixed = ensureContrast(pale, const [Colors.white], lighten: false);
      expect(contrastRatio(fixed, Colors.white), greaterThanOrEqualTo(4.5));
      expect(fixed.computeLuminance(), lessThan(pale.computeLuminance()));
    },
  );

  test('KIT-T8: ensureContrast lightens on every dark surface at once', () {
    const surfaces = [Color(0xFF0F172A), Color(0xFF334155)];
    final fixed = ensureContrast(
      const Color(0xFF3B3F9E),
      surfaces,
      lighten: true,
    );
    for (final s in surfaces) {
      expect(contrastRatio(fixed, s), greaterThanOrEqualTo(4.5));
    }
  });

  test('KIT-T8: ensureContrast honours a lower minimum for non-text marks', () {
    const mid = Color(0xFF8A94A8);
    final fixed = ensureContrast(
      mid,
      const [Colors.white],
      lighten: false,
      min: 3,
    );
    expect(contrastRatio(fixed, Colors.white), greaterThanOrEqualTo(3));
    expect(fixed, mid, reason: 'already 3:1, so it is left alone');
  });

  test('KIT-T8: readableOn picks the lighter or darker text colour', () {
    const light = Color(0xFFFFFFFF);
    const dark = Color(0xFF0F172A);
    expect(
      readableOn(const Color(0xFF3730A3), light: light, dark: dark),
      light,
    );
    expect(readableOn(const Color(0xFFA5B4FC), light: light, dark: dark), dark);
  });

  test('KIT-T8: readableOn always reaches 4.5:1, mid-luminance fills too', () {
    const light = Color(0xFFF8FAFC);
    const dark = Color(0xFF0F172A);
    final fills = <Color>[
      const Color(0xFF458B23), // the worst case: 4.23:1 with either ink
      const Color(0xFFFFFDE7),
      const Color(0xFF050510),
      const Color(0xFF000000),
      const Color(0xFFFFFFFF),
      for (var h = 0; h < 360; h += 6)
        for (final sat in [0.3, 0.6, 1.0])
          for (var l = 0.05; l < 0.96; l += 0.05)
            HSLColor.fromAHSL(1, h.toDouble(), sat, l).toColor(),
    ];
    for (final fill in fills) {
      final ink = readableOn(fill, light: light, dark: dark);
      expect(
        contrastRatio(ink, fill),
        greaterThanOrEqualTo(4.5),
        reason: '$fill gets $ink',
      );
    }
  });

  test('KIT-T8: readableOn keeps the given ink when it already reads', () {
    const light = Color(0xFFF8FAFC);
    const dark = Color(0xFF0F172A);
    expect(
      readableOn(const Color(0xFF3730A3), light: light, dark: dark),
      light,
    );
    expect(readableOn(const Color(0xFFFFFDE7), light: light, dark: dark), dark);
  });

  test('KIT-T8: ensureContrast ends on pure white or black when the last '
      'step falls short of it', () {
    const grey = Color(0xFF767676);
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    // Only pure white (or black) reaches these ratios: a lightness step stops
    // a hair short of the extreme.
    final whiteOnly = contrastRatio(white, grey);
    final blackOnly = contrastRatio(black, grey);
    expect(
      ensureContrast(
        const Color(0xFF808080),
        const [grey],
        lighten: true,
        min: whiteOnly,
      ),
      white,
    );
    expect(
      ensureContrast(
        const Color(0xFF6E6E6E),
        const [grey],
        lighten: false,
        min: blackOnly,
      ),
      black,
    );
  });
}
