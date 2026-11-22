import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// WCAG 2.2 contrast ratio of two opaque colours, from 1 to 21.
/// https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// [color] moved in lightness, the least it takes, until it reaches [min]:1
/// on every one of [backgrounds]. [lighten] picks the direction (dark
/// surfaces lighten the colour, light surfaces darken it). A colour that
/// already reads comes back unchanged, so a good brand colour is never
/// touched. Where no lightness reaches [min] (a hue that cannot), the
/// closest reach is returned and the palette test names it.
Color ensureContrast(
  Color color,
  Iterable<Color> backgrounds, {
  required bool lighten,
  double min = 4.5,
}) {
  bool reads(Color c) => backgrounds.every((b) => contrastRatio(c, b) >= min);
  if (reads(color)) return color;
  final hsl = HSLColor.fromColor(color);
  final step = lighten ? 0.01 : -0.01;
  var lightness = hsl.lightness;
  var out = color;
  while (!reads(out) && lightness + step >= 0 && lightness + step <= 1) {
    lightness += step;
    out = hsl.withLightness(lightness).toColor();
  }
  if (reads(out)) return out;
  // The steps may stop a hair short of white or black.
  final extreme = lighten ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  return reads(extreme) ? extreme : out;
}

/// The text colour to set on [fill]: the better of [light] and [dark] when it
/// reaches [min]:1. On a mid-luminance fill neither may (the worst case is
/// 4.23:1), so each ink is then pushed toward white or black, the least it
/// takes, and the one that reaches [min] is returned. White or black always
/// does, so text on a brand fill is never unreadable.
Color readableOn(
  Color fill, {
  required Color light,
  required Color dark,
  double min = 4.5,
}) {
  final best = contrastRatio(light, fill) >= contrastRatio(dark, fill)
      ? light
      : dark;
  if (contrastRatio(best, fill) >= min) return best;
  final lighter = ensureContrast(light, [fill], lighten: true, min: min);
  final darker = ensureContrast(dark, [fill], lighten: false, min: min);
  return contrastRatio(lighter, fill) >= contrastRatio(darker, fill)
      ? lighter
      : darker;
}
