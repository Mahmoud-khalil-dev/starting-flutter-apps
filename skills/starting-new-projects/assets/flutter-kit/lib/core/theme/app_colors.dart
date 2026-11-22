import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_palette.dart';

/// The colour roles every widget reads (`context.colors`). Two instances
/// exist, `AppPalette.light` and `AppPalette.dark`; a widget never names a
/// raw colour (rule `raw-colour`).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.hint,
    required this.outline,
    required this.divider,
    required this.primary,
    required this.onPrimary,
    required this.primaryInk,
    required this.onPrimaryInk,
    required this.brand,
    required this.gold,
    required this.goldInk,
    required this.danger,
    required this.onDanger,
    required this.success,
    required this.warning,
    required this.scrim,
    required this.glass,
    required this.glassRim,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.navIndicator,
    required this.loaderBeam,
    required this.shadow,
  });

  /// The page behind everything.
  final Color background;

  /// Cards, sheets, fields, bars.
  final Color surface;

  /// Grouped rows and raised cards.
  final Color surfaceRaised;

  /// Body and title text.
  final Color ink;

  /// Secondary text.
  final Color inkMuted;

  /// Placeholders. Still 4.5:1: a hint carries meaning here.
  final Color hint;

  /// Field and control boundaries, 3:1 (WCAG 1.4.11).
  final Color outline;

  /// Decorative hairlines only; never the only cue.
  final Color divider;

  /// A fill: filled buttons. It always carries [onPrimary] text and is never
  /// a mark on its own, because in dark it may be dim on the surface.
  final Color primary;
  final Color onPrimary;

  /// Primary as text, an icon or a mark: links, quiet buttons, the selected
  /// icon, switch tracks, focus borders, selection pills. 4.5:1 on every
  /// surface: the brand seed, lightened or darkened until it reads.
  final Color primaryInk;

  /// Text on a [primaryInk] fill (a selected segment).
  final Color onPrimaryInk;

  /// The brand identity, the same in both modes (a banner fill). Set text on
  /// it with `readableOn(brand, ...)`, never a fixed white; on the dark theme
  /// a very dark brand colour will not stand out from the surface.
  final Color brand;

  /// Accent for non-text marks (3:1 on every surface). The name is the
  /// source app's; it holds `Brand.accent`.
  final Color gold;

  /// The accent as text.
  final Color goldInk;
  final Color danger;
  final Color onDanger;
  final Color success;
  final Color warning;

  /// Modal barrier tint, translucent (45% light, 60% dark) so the page
  /// stays visible behind sheets and dialogs.
  final Color scrim;

  /// Frosted glass base of the tab pill, opaque here: the pill fills it at
  /// `AppDimensions.glassOpacity` over its blur, or the denser
  /// `AppDimensions.glassOpacityWeb` where there is no blur (web).
  final Color glass;

  /// The capsule's and the lens's 1 px rim, so the glass reads as polished.
  final Color glassRim;
  final Color shimmerBase;

  /// The lighter band of the loading sweep.
  final Color shimmerHighlight;

  /// The tint behind a selected navigation item.
  final Color navIndicator;

  /// The beam that circles the logo loader's ring.
  final Color loaderBeam;
  final Color shadow;

  /// Every colour used as text on a surface. The contrast test walks these.
  List<Color> get textColors => [
    ink,
    inkMuted,
    hint,
    primaryInk,
    goldInk,
    danger,
    success,
    warning,
  ];

  List<Color> get surfaces => [background, surface, surfaceRaised];

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? ink,
    Color? inkMuted,
    Color? hint,
    Color? outline,
    Color? divider,
    Color? primary,
    Color? onPrimary,
    Color? primaryInk,
    Color? onPrimaryInk,
    Color? brand,
    Color? gold,
    Color? goldInk,
    Color? danger,
    Color? onDanger,
    Color? success,
    Color? warning,
    Color? scrim,
    Color? glass,
    Color? glassRim,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? navIndicator,
    Color? loaderBeam,
    Color? shadow,
  }) => AppColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    hint: hint ?? this.hint,
    outline: outline ?? this.outline,
    divider: divider ?? this.divider,
    primary: primary ?? this.primary,
    primaryInk: primaryInk ?? this.primaryInk,
    onPrimaryInk: onPrimaryInk ?? this.onPrimaryInk,
    glassRim: glassRim ?? this.glassRim,
    loaderBeam: loaderBeam ?? this.loaderBeam,
    onPrimary: onPrimary ?? this.onPrimary,
    brand: brand ?? this.brand,
    gold: gold ?? this.gold,
    goldInk: goldInk ?? this.goldInk,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    scrim: scrim ?? this.scrim,
    glass: glass ?? this.glass,
    shimmerBase: shimmerBase ?? this.shimmerBase,
    shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    navIndicator: navIndicator ?? this.navIndicator,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      hint: l(hint, other.hint),
      outline: l(outline, other.outline),
      divider: l(divider, other.divider),
      primary: l(primary, other.primary),
      primaryInk: l(primaryInk, other.primaryInk),
      onPrimaryInk: l(onPrimaryInk, other.onPrimaryInk),
      glassRim: l(glassRim, other.glassRim),
      loaderBeam: l(loaderBeam, other.loaderBeam),
      onPrimary: l(onPrimary, other.onPrimary),
      brand: l(brand, other.brand),
      gold: l(gold, other.gold),
      goldInk: l(goldInk, other.goldInk),
      danger: l(danger, other.danger),
      onDanger: l(onDanger, other.onDanger),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      scrim: l(scrim, other.scrim),
      glass: l(glass, other.glass),
      shimmerBase: l(shimmerBase, other.shimmerBase),
      shimmerHighlight: l(shimmerHighlight, other.shimmerHighlight),
      navIndicator: l(navIndicator, other.navIndicator),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension AppColorsX on BuildContext {
  /// The active palette. Without the extension (a plain Material theme) it falls back
  /// to the palette of the ambient brightness, so a kit widget never throws.
  AppColors get colors {
    final theme = Theme.of(this);
    return theme.extension<AppColors>() ??
        AppPalette.forBrightness(theme.brightness);
  }
}
