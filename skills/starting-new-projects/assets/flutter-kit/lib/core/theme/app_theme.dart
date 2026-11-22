import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_fonts.dart';
import 'package:kit_app/core/theme/app_page_transitions.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/platform_style.dart';

/// The full Material 3 theme for one brightness, language, window scale and
/// platform. Every component reads AppColors and AppTextStyles from here.
abstract final class AppTheme {
  static final Map<
    (Brightness, String, double, TargetPlatform?, bool?, bool),
    ThemeData
  >
  _cache = {};

  /// One ThemeData per key; AppThemeScope rebuilds often (rotation).
  static ThemeData cached({
    required Brightness brightness,
    required String language,
    double scale = 1,
    TargetPlatform? platform,
    bool? web,
    bool boldText = false,
  }) => _cache.putIfAbsent(
    (brightness, language, scale, platform, web, boldText),
    () => build(
      brightness: brightness,
      language: language,
      scale: scale,
      platform: platform,
      web: web,
      boldText: boldText,
    ),
  );

  static ThemeData build({
    required Brightness brightness,
    required String language,
    double scale = 1,
    TargetPlatform? platform,

    /// The web build; null asks [PlatformCapabilities]. Tests set it.
    bool? web,

    /// The system Bold Text setting, as [AppTextStyles.build] takes it.
    bool boldText = false,
  }) {
    final isWeb = web ?? PlatformCapabilities.current().isWeb;
    final c = AppPalette.forBrightness(brightness);
    final t = AppTextStyles.build(
      language: language,
      colors: c,
      scale: scale,
      boldText: boldText,
    );
    final target = platform ?? defaultTargetPlatform;
    final cupertino = PlatformCapabilities(
      isWeb: isWeb,
      platform: target,
    ).cupertinoLook;
    final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      borderSide: BorderSide(color: c.outline),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      platform: platform,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primaryInk,
        onPrimary: c.onPrimaryInk,
        secondary: c.gold,
        onSecondary: c.onPrimaryInk,
        error: c.danger,
        onError: c.onDanger,
        surface: c.surface,
        onSurface: c.ink,
        onSurfaceVariant: c.inkMuted,
        surfaceContainerHighest: c.surfaceRaised,
        outline: c.outline,
        outlineVariant: c.divider,
        shadow: c.shadow,
        scrim: c.scrim,
      ),
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: AppFonts.primaryFor(language),
      fontFamilyFallback: AppFonts.fallbackFor(language),
      textTheme: t.asTextTheme(),
      extensions: [
        c,
        t,
        AppPlatformStyle(web: isWeb),
      ],
      pageTransitionsTheme: isWeb
          ? AppPageTransitions.web
          : AppPageTransitions.theme,
      splashFactory: cupertino
          ? NoSplash.splashFactory
          : InkRipple.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: cupertino,
        titleTextStyle: t.title,
      ),
      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: AppDimensions.hairline,
        space: AppDimensions.hairline,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: t.body.copyWith(color: c.hint),
        labelStyle: t.label.copyWith(color: c.inkMuted),
        floatingLabelStyle: t.label.copyWith(color: c.primaryInk),
        errorStyle: t.caption.copyWith(color: c.danger),
        errorMaxLines: 3,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.md,
        ),
        border: field,
        enabledBorder: field,
        focusedBorder: field.copyWith(
          borderSide: BorderSide(
            color: c.primaryInk,
            width: AppDimensions.focusRing,
          ),
        ),
        errorBorder: field.copyWith(borderSide: BorderSide(color: c.danger)),
        focusedErrorBorder: field.copyWith(
          borderSide: BorderSide(
            color: c.danger,
            width: AppDimensions.focusRing,
          ),
        ),
      ),
      // No NavigationBar ships (the capsule replaced it), but FitLabel reads
      // this label style when it is given none, so it stays.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.navIndicator,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.primaryInk : c.inkMuted,
            size: AppDimensions.iconLg,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? t.tab.copyWith(
                  color: c.ink,
                  fontWeight: t.title.fontWeight,
                  fontVariations: t.title.fontVariations,
                )
              : t.tab.copyWith(color: c.inkMuted),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.navIndicator,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(color: c.primaryInk),
        unselectedIconTheme: IconThemeData(color: c.inkMuted),
        selectedLabelTextStyle: t.label.copyWith(color: c.ink),
        unselectedLabelTextStyle: t.label.copyWith(color: c.inkMuted),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        titleTextStyle: t.title,
        contentTextStyle: t.body.copyWith(color: c.inkMuted),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: t.body.copyWith(color: c.surface),
        actionTextColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPrimaryInk : c.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? c.primaryInk : c.surfaceRaised,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primaryInk,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primaryInk,
        selectionColor: c.navIndicator,
        selectionHandleColor: c.primaryInk,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: c.primaryInk,
        scaffoldBackgroundColor: c.background,
      ),
    );
  }
}
