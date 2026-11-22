import 'dart:math' as math;

/// Spacing on a 4-pt grid, radii, sizes. The only place
/// raw sizes are written; widgets use these names (rule `raw-dimension`).
/// Spacing, radii and targets are never scaled; only type and
/// `context.scaled` design sizes are (lib/core/utils/responsive.dart).
abstract final class AppDimensions {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
  static const List<double> spacing = [xxs, xs, sm, md, lg, xl, xxl, xxxl];

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  static const double touchTarget = 48;
  static const double buttonHeight = 52;
  static const double fieldHeight = 52;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double hairline = 1;
  static const double spinnerStroke = 2;
  static const double focusRing = 2;
  static const double flat = 0;

  static const double contentMaxWidth = 640;
  static const double dialogMaxWidth = 480;
  static const double listPaneWidth = 360;
  static const double railWidth = 80;
  static const double sidebarWidth = 264;
  static const double pillHeight = 64;
  static const double pillMargin = 16;

  /// A tab's width when the capsule hugs its tabs (three or fewer).
  static const double tabHugWidth = 96;

  /// Up to this many tabs the capsule hugs; more and it spans the width.
  static const int tabHugMax = 3;

  /// The ring of capsule fill around a badge dot, so it reads on glass.
  static const double badgeRing = 2;
  static const double badgeDot = 8;

  /// A skeleton bar: the cap height of body text, not the line height.
  static const double skeletonBar = 12;

  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 72;

  static const double glassBlur = 24;

  /// Alpha of the glass fill over its refraction or blur: translucent
  /// enough that the glass shows (the apps). Without either (web) the fill
  /// is denser, so labels stay legible over busy content.
  /// Inactive labels keep 4.5:1 over any content.
  static const double glassOpacity = 0.80;
  static const double glassOpacityWeb = 0.92;
  static const double backdropBlur = 12;
  static const double loadMoreExtent = 320;
  static const double shakeOffset = 8;
  static const double riseOffset = 12;

  /// The logo loader's mark: the image is drawn at this height.
  static const double logoLoaderHeight = 160;

  /// The radius of a shape nested [padding] inside one of radius [outer],
  /// so both curves share a centre.
  static double innerRadius(double outer, double padding) =>
      math.max(0, outer - padding);
}
