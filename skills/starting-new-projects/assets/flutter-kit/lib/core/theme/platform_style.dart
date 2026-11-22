import 'package:flutter/material.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';

/// Whether the theme renders the web build. AppTheme sets it from
/// [PlatformCapabilities], so a test can ask for the web on any platform.
/// The kit's platform look and its backdrop blur both follow it.
@immutable
class AppPlatformStyle extends ThemeExtension<AppPlatformStyle> {
  const AppPlatformStyle({required this.web});

  final bool web;

  @override
  AppPlatformStyle copyWith({bool? web}) =>
      AppPlatformStyle(web: web ?? this.web);

  @override
  AppPlatformStyle lerp(AppPlatformStyle? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension PlatformStyleX on BuildContext {
  /// What the theme's platform can show: its platform, and whether this is
  /// the web build (from the theme, else [PlatformCapabilities.current]).
  PlatformCapabilities get _shown {
    final theme = Theme.of(this);
    return PlatformCapabilities(
      isWeb:
          theme.extension<AppPlatformStyle>()?.web ??
          PlatformCapabilities.current().isWeb,
      platform: theme.platform,
    );
  }

  /// The Apple look, read from the theme so tests can pick a platform and the
  /// web never touches dart:io. Never on the web, whatever OS the browser
  /// reports. What a platform can *do* is asked of PlatformCapabilities.
  bool get isCupertino => _shown.cupertinoLook;

  /// Whether a sheet, dialog or the glass bar frosts what lies behind it.
  bool get blursBackdrop => _shown.backdropBlur;
}
