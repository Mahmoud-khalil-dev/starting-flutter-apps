import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// What the user chose on the Settings screen: the theme, the language
/// (null follows the device) and the text size.
class AppSettings extends Equatable {
  const AppSettings({
    required this.themeMode,
    required this.locale,
    required this.textScale,
  });

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    locale: null,
    textScale: 1,
  );

  static const minTextScale = 0.85;
  static const maxTextScale = 1.6;

  /// What the app's text scale never exceeds: the chosen size times the
  /// system's. Beyond it the layouts stop being usable.
  static const maxEffectiveTextScale = 2.0;

  /// [scale] held between [minTextScale] and [maxTextScale].
  static double clampScale(double scale) =>
      scale.clamp(minTextScale, maxTextScale);

  final ThemeMode themeMode;
  final Locale? locale;
  final double textScale;

  /// [clearLocale] returns to the device language, which a null [locale]
  /// cannot say.
  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    double? textScale,
    bool clearLocale = false,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    locale: clearLocale ? null : locale ?? this.locale,
    textScale: textScale ?? this.textScale,
  );

  @override
  List<Object?> get props => [themeMode, locale, textScale];
}
