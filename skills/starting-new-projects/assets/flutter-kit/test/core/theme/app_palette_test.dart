import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/contrast.dart';

const _aaText = 4.5;
const _nonText = 3.0;

void _expectAtLeast(Color fg, Color bg, double min, String what) {
  final ratio = contrastRatio(fg, bg);
  expect(
    ratio,
    greaterThanOrEqualTo(min),
    reason: '$what is ${ratio.toStringAsFixed(2)}:1',
  );
}

void main() {
  for (final (name, c) in [
    ('light', AppPalette.light),
    ('dark', AppPalette.dark),
  ]) {
    group('KIT-T8: $name palette', () {
      test('every text colour reaches 4.5:1 on every surface', () {
        for (final fg in c.textColors) {
          for (final bg in c.surfaces) {
            _expectAtLeast(fg, bg, _aaText, '$fg on $bg');
          }
        }
      });

      test('text on filled colours reaches 4.5:1', () {
        _expectAtLeast(c.onPrimary, c.primary, _aaText, 'onPrimary');
        _expectAtLeast(c.onPrimaryInk, c.primaryInk, _aaText, 'onPrimaryInk');
        _expectAtLeast(c.onDanger, c.danger, _aaText, 'onDanger');
        _expectAtLeast(
          readableOn(
            c.brand,
            light: AppPalette.light.surface,
            dark: AppPalette.dark.background,
          ),
          c.brand,
          _aaText,
          'text on brand',
        );
      });

      test('outlines, gold and the selected indicator reach 3:1', () {
        for (final bg in c.surfaces) {
          _expectAtLeast(c.outline, bg, _nonText, 'outline on $bg');
          _expectAtLeast(c.gold, bg, _nonText, 'gold on $bg');
          // The selected tab icon, links and selection marks use primaryInk
          // (the primaryInk role); primary is a fill that always carries onPrimary.
          _expectAtLeast(c.primaryInk, bg, _nonText, 'primaryInk on $bg');
        }
      });

      test('the brand fill stands out by itself: 3:1 on every surface', () {
        // A filled button, the selected-tab fill and the indicator read as
        // shapes without their labels (WCAG 1.4.11).
        for (final bg in c.surfaces) {
          _expectAtLeast(c.primary, bg, _nonText, 'primary on $bg');
        }
      });

      test('the brand colour reads as text on every surface', () {
        // The sidebar draws the app name in it, on the surface.
        for (final bg in c.surfaces) {
          _expectAtLeast(c.brand, bg, _aaText, 'brand on $bg');
        }
      });

      test('the modal scrim lets the page show through', () {
        // An opaque barrier hides the page behind every sheet and dialog.
        expect(c.scrim.a, inInclusiveRange(0.3, 0.7));
      });
    });
  }

  test('KIT-T8: contrastRatio matches the WCAG examples', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.01));
    // A mid grey on white is 2.9:1 and fails AA.
    expect(
      contrastRatio(const Color(0xFF979797), Colors.white),
      lessThan(_aaText),
    );
  });

  test('KIT-T8: forBrightness returns the matching palette', () {
    expect(AppPalette.forBrightness(Brightness.dark), same(AppPalette.dark));
    expect(AppPalette.forBrightness(Brightness.light), same(AppPalette.light));
  });

  group('KIT-T8: the dark palette', () {
    final d = AppPalette.dark;

    test('the ink reads on every dark surface, whatever the seed', () {
      for (final bg in d.surfaces) {
        expect(contrastRatio(d.primaryInk, bg), greaterThanOrEqualTo(4.5));
        expect(contrastRatio(d.goldInk, bg), greaterThanOrEqualTo(4.5));
      }
    });

    test('the layers separate on a phone and the skeleton shows on both', () {
      expect(contrastRatio(d.surface, d.background), greaterThan(1.15));
      expect(contrastRatio(d.surfaceRaised, d.surface), greaterThan(1.1));
      expect(contrastRatio(d.shimmerBase, d.surface), greaterThan(1.2));
      expect(contrastRatio(d.shimmerBase, d.surfaceRaised), greaterThan(1.08));
      expect(
        contrastRatio(d.shimmerHighlight, d.shimmerBase),
        greaterThan(1.5),
      );
    });
  });

  test('KIT-T8: the light ink and accent read on every light surface', () {
    final l = AppPalette.light;
    for (final bg in l.surfaces) {
      expect(contrastRatio(l.primaryInk, bg), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(l.goldInk, bg), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(l.gold, bg), greaterThanOrEqualTo(3));
    }
  });
}
