import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_theme.dart';
import 'package:kit_app/core/utils/responsive.dart';

/// Puts the app theme for the ambient language and window width above
/// [child]. [brightness] null follows the system. the app places it
/// builder with the user's choice; until then only the kit gallery uses it.
class AppThemeScope extends StatelessWidget {
  const AppThemeScope({
    required this.child,
    this.brightness,
    this.platform,
    super.key,
  });

  final Widget child;
  final Brightness? brightness;
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.cached(
      brightness: brightness ?? MediaQuery.platformBrightnessOf(context),
      language: Localizations.localeOf(context).languageCode,
      // Two decimals: a resize does not mint a theme per pixel.
      scale: (context.uiScale * 100).roundToDouble() / 100,
      platform: platform,
      boldText: MediaQuery.boldTextOf(context),
    ),
    child: child,
  );
}
