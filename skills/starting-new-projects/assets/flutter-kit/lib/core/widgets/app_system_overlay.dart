import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sets the status bar and the navigation bar from the theme's brightness, so
/// the clock and icons are light on a dark ground and dark on a light one,
/// on every screen. The bars stay see-through over the page.
class AppSystemOverlay extends StatelessWidget {
  const AppSystemOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final icons = brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: icons,
        // iOS asks for the bar's own brightness, the opposite of its icons.
        statusBarBrightness: brightness,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: icons,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: child,
    );
  }
}
