import 'package:flutter/painting.dart';
import 'package:kit_app/core/theme/app_colors.dart';

/// Soft layered shadows instead of hard borders : a close
/// contact shadow and a wide ambient one. Every blur is at least twice its
/// drop and no alpha passes 0.24, so elevation reads as a glow under the
/// surface, never as an offset slab. Dark mode uses a little more alpha of
/// black, which is all that reads on a dark surface.
abstract final class AppShadows {
  static bool _dark(AppColors c) => c.background.computeLuminance() < 0.1;

  static List<BoxShadow> low(AppColors c) => [
    BoxShadow(
      color: c.shadow.withValues(alpha: _dark(c) ? 0.20 : 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: c.shadow.withValues(alpha: _dark(c) ? 0.24 : 0.07),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> high(AppColors c) => [
    BoxShadow(
      color: c.shadow.withValues(alpha: _dark(c) ? 0.22 : 0.06),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: c.shadow.withValues(alpha: _dark(c) ? 0.24 : 0.10),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  /// The shadow drops when a card or button is pressed .
  static List<BoxShadow> pressed(AppColors c) => [
    BoxShadow(
      color: c.shadow.withValues(alpha: _dark(c) ? 0.20 : 0.06),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
}
