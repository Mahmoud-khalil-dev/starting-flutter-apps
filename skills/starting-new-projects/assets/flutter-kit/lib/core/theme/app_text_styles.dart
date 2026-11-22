import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_fonts.dart';
import 'package:kit_app/core/theme/app_palette.dart';

/// The type roles. Built per language, palette and window
/// scale by AppTheme; widgets read `context.text` and never write a
/// TextStyle (rule `inline-text-style`).
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.label,
    required this.caption,
    required this.smallCaps,
    required this.tab,
    required this.numeric,
  });

  /// Arabic letter spacing is always 0: spacing breaks the joined script.
  /// Arabic lines are taller: its ascenders and dots need the room.
  factory AppTextStyles.build({
    required String language,
    required AppColors colors,
    double scale = 1,

    /// The system Bold Text setting. Flutter's own bold merge sets only
    /// [FontWeight], which a variable font with an explicit wght variation
    /// ignores, so every role's weight axis is raised here.
    bool boldText = false,
  }) {
    final arabic = language == 'ar';
    TextStyle style(
      double size,
      FontWeight weight, {
      required double height,
      required double arabicHeight,
      double tracking = 0,
      Color? color,
      List<FontFeature>? features,
      bool scales = true,
      bool display = false,
    }) {
      final w = boldText && weight.value < 700 ? FontWeight.w700 : weight;
      // Arabic is balanced to the Latin's visual size.
      final balanced = arabic
          ? size * (display ? arabicDisplayScale : arabicScale)
          : size;
      // The width scale never takes a role under the 11pt floor.
      final sized = scales ? balanced * scale : balanced;
      return TextStyle(
        fontFamily: display
            ? AppFonts.displayFor(language)
            : AppFonts.primaryFor(language),
        fontFamilyFallback: display
            ? AppFonts.displayFallbackFor(language)
            : AppFonts.fallbackFor(language),
        fontSize: math.max(sized, display ? displayMinSize : minSize),
        fontWeight: w,
        // A variable font reads the weight axis, so it is set as well,
        // so every engine draws the weight asked for.
        fontVariations: [FontVariation('wght', w.value.toDouble())],
        height: arabic ? arabicHeight : height,
        letterSpacing: arabic ? 0 : tracking,
        color: color ?? colors.ink,
        fontFeatures: features,
      );
    }

    return AppTextStyles(
      display: style(
        32,
        arabic ? FontWeight.w400 : FontWeight.w600,
        height: 1.2,
        arabicHeight: 1.4,
        tracking: -0.4,
        display: true,
      ),
      headline: style(
        24,
        arabic ? FontWeight.w400 : FontWeight.w600,
        height: 1.3,
        arabicHeight: 1.5,
        tracking: -0.2,
        display: true,
      ),
      title: style(18, FontWeight.w600, height: 1.4, arabicHeight: 1.55),
      body: style(16, FontWeight.w400, height: 1.5, arabicHeight: 1.7),
      label: style(14, FontWeight.w500, height: 1.4, arabicHeight: 1.55),
      caption: style(
        12,
        FontWeight.w400,
        height: 1.35,
        arabicHeight: 1.5,
        color: colors.inkMuted,
      ),
      // Platform tab bars keep one label size on every phone width.
      tab: style(
        11,
        FontWeight.w500,
        height: 1.3,
        arabicHeight: 1.45,
        scales: false,
      ),
      smallCaps: style(
        11,
        FontWeight.w600,
        height: 1.4,
        arabicHeight: 1.5,
        tracking: 1.2,
        color: colors.inkMuted,
      ),
      numeric: style(
        16,
        FontWeight.w500,
        height: 1.3,
        arabicHeight: 1.4,
        features: const [FontFeature.tabularFigures()],
      ),
    );
  }

  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle label;
  final TextStyle caption;

  /// Group headers. Wider tracking in Latin; never upper-cased in Arabic.
  final TextStyle smallCaps;

  /// Tab bar labels: one line under an icon, sized like the platform's.
  /// The width scale leaves it alone; the user's text scale still applies.
  final TextStyle tab;

  /// No role draws smaller than this, on any phone width.
  static const double minSize = 11;

  /// Arabic text draws at this share of the Latin size. 1 suits the system
  /// font; tune it when `Brand` names fonts whose Arabic and Latin x-heights
  /// differ.
  static const double arabicScale = 1;

  /// The same for display and headline text.
  static const double arabicDisplayScale = 1;

  /// A display face with fine hairlines thins out below this.
  static const double displayMinSize = 20;

  /// Times, counts, countdowns: tabular figures so digits do not jump.
  final TextStyle numeric;

  /// [style] at weight [weight], on the wght axis as well. With a variable
  /// font `copyWith(fontWeight:)` alone keeps the role's axis value and draws
  /// the old weight. A style already heavier (it came
  /// from a Bold Text theme) keeps its weight.
  static TextStyle weighted(TextStyle style, FontWeight weight) {
    final current = style.fontWeight;
    final w = current != null && current.value > weight.value
        ? current
        : weight;
    return style.copyWith(
      fontWeight: w,
      fontVariations: [FontVariation('wght', w.value.toDouble())],
    );
  }

  TextTheme asTextTheme() => TextTheme(
    displaySmall: display,
    headlineSmall: headline,
    titleLarge: headline,
    titleMedium: title,
    titleSmall: label,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: label,
    labelMedium: label,
    labelSmall: smallCaps,
  );

  @override
  AppTextStyles copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? smallCaps,
    TextStyle? tab,
    TextStyle? numeric,
  }) => AppTextStyles(
    display: display ?? this.display,
    headline: headline ?? this.headline,
    title: title ?? this.title,
    body: body ?? this.body,
    label: label ?? this.label,
    caption: caption ?? this.caption,
    smallCaps: smallCaps ?? this.smallCaps,
    tab: tab ?? this.tab,
    numeric: numeric ?? this.numeric,
  );

  @override
  AppTextStyles lerp(covariant AppTextStyles? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTextStyles(
      display: l(display, other.display),
      headline: l(headline, other.headline),
      title: l(title, other.title),
      body: l(body, other.body),
      label: l(label, other.label),
      caption: l(caption, other.caption),
      smallCaps: l(smallCaps, other.smallCaps),
      tab: l(tab, other.tab),
      numeric: l(numeric, other.numeric),
    );
  }
}

extension AppTextStylesX on BuildContext {
  /// The active type roles; without the extension, the English light set.
  AppTextStyles get text =>
      Theme.of(this).extension<AppTextStyles>() ??
      AppTextStyles.build(language: 'en', colors: AppPalette.light);
}
