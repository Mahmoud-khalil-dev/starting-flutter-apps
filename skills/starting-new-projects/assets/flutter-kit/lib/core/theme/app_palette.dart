import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/brand.dart';
import 'package:kit_app/core/theme/contrast.dart';

/// The two palettes. The neutrals (surfaces, text, status) are fixed slate;
/// everything that carries the brand is derived from [Brand], then moved in
/// lightness only as far as it takes to read on the surfaces it sits on, so
/// a new brand colour cannot fail contrast quietly. test/core/theme/
/// app_palette_test.dart re-checks every pair.
abstract final class AppPalette {
  static const _lightSurfaces = [
    Color(0xFFF8FAFC), // background
    Color(0xFFFFFFFF), // surface
    Color(0xFFF1F5F9), // surfaceRaised
  ];
  static const _darkSurfaces = [
    Color(0xFF0F172A), // background
    Color(0xFF1E293B), // surface
    Color(0xFF334155), // surfaceRaised
  ];

  static const _white = Color(0xFFFFFFFF);
  static const _darkInk = Color(0xFF0F172A);

  static final AppColors light = _buildLight();
  static final AppColors dark = _buildDark();

  static AppColors _buildLight() {
    final primaryInk = ensureContrast(
      Brand.lightSeed,
      _lightSurfaces,
      lighten: false,
    );
    final accentInk = ensureContrast(
      Brand.accent,
      _lightSurfaces,
      lighten: false,
    );
    return AppColors(
      background: _lightSurfaces[0],
      surface: _lightSurfaces[1],
      surfaceRaised: _lightSurfaces[2],
      ink: const Color(0xFF0F172A),
      inkMuted: const Color(0xFF475569),
      hint: const Color(0xFF5B677A),
      outline: const Color(0xFF7A8699),
      divider: const Color(0xFFE2E8F0),
      primary: Brand.lightSeed,
      onPrimary: readableOn(Brand.lightSeed, light: _white, dark: _darkInk),
      primaryInk: primaryInk,
      onPrimaryInk: readableOn(primaryInk, light: _white, dark: _darkInk),
      brand: Brand.lightSeed,
      gold: ensureContrast(
        Brand.accent,
        _lightSurfaces,
        lighten: false,
        min: 3,
      ),
      goldInk: accentInk,
      danger: const Color(0xFFB3261E),
      onDanger: _white,
      success: const Color(0xFF166534),
      warning: const Color(0xFF92400E),
      scrim: const Color(0x73020617),
      glass: _white,
      glassRim: const Color(0x99FFFFFF), // white 60%
      shimmerBase: const Color(0xFFE2E8F0),
      shimmerHighlight: const Color(0xFFF8FAFC),
      navIndicator: Brand.lightSeed.withValues(alpha: 0.12),
      loaderBeam: const Color(0xFFE2E8F0), // on the primaryInk ring
      shadow: const Color(0xFF020617),
    );
  }

  static AppColors _buildDark() {
    // The fill is the dark seed lightened, the least it takes, until it
    // reaches 3:1 on every dark surface (WCAG 1.4.11), so a filled button
    // stands out by its shape and not only by its label.
    final primary = ensureContrast(
      Brand.darkSeed,
      _darkSurfaces,
      lighten: true,
      min: 3,
    );
    final primaryInk = ensureContrast(
      Brand.darkSeed,
      _darkSurfaces,
      lighten: true,
    );
    final accentInk = ensureContrast(
      Brand.accent,
      _darkSurfaces,
      lighten: true,
    );
    return AppColors(
      background: _darkSurfaces[0],
      surface: _darkSurfaces[1],
      surfaceRaised: _darkSurfaces[2],
      ink: const Color(0xFFF8FAFC),
      inkMuted: const Color(0xFFCBD5E1),
      hint: const Color(0xFFA9B6CB),
      outline: const Color(0xFF8795AC),
      divider: const Color(0xFF334155), // decorative only
      primary: primary,
      onPrimary: readableOn(
        primary,
        light: const Color(0xFFF8FAFC),
        dark: _darkInk,
      ),
      primaryInk: primaryInk,
      onPrimaryInk: readableOn(primaryInk, light: _white, dark: _darkInk),
      // The light seed lightened until it reads as text on every dark
      // surface: the sidebar draws the app name in it.
      brand: ensureContrast(Brand.lightSeed, _darkSurfaces, lighten: true),
      gold: accentInk,
      goldInk: accentInk,
      danger: const Color(0xFFFFB4AB),
      onDanger: const Color(0xFF690005),
      success: const Color(0xFF86EFAC),
      warning: const Color(0xFFFCD34D),
      scrim: const Color(0x99020617), // 60%
      glass: _darkSurfaces[0],
      glassRim: const Color(0x24FFFFFF), // white 14%
      shimmerBase: const Color(0xFF2A384E),
      shimmerHighlight: const Color(0xFF475569),
      navIndicator: primary.withValues(alpha: 0.24),
      loaderBeam: const Color(0x99F8FAFC), // ink 60% over the primaryInk ring
      shadow: const Color(0xFF000000),
    );
  }

  static AppColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
