import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_fonts.dart';
import 'package:kit_app/core/theme/app_page_transitions.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/app_theme.dart';

void main() {
  test('KIT-T8: light and dark carry their palette and type extensions', () {
    for (final b in Brightness.values) {
      final theme = AppTheme.build(brightness: b, language: 'en');
      final colors = theme.extension<AppColors>()!;
      expect(colors, same(AppPalette.forBrightness(b)));
      expect(theme.brightness, b);
      expect(theme.colorScheme.primary, colors.primaryInk);
      expect(theme.colorScheme.onPrimary, colors.onPrimaryInk);
      expect(theme.colorScheme.error, colors.danger);
      expect(theme.scaffoldBackgroundColor, colors.background);
      expect(theme.extension<AppTextStyles>()!.body.color, colors.ink);
      expect(theme.useMaterial3, isTrue);
    }
  });

  test('KIT-T8: stock marks read primaryInk in both themes', () {
    for (final brightness in Brightness.values) {
      final theme = AppTheme.build(brightness: brightness, language: 'en');
      final c = theme.extension<AppColors>()!;
      const on = {WidgetState.selected};
      expect(theme.switchTheme.trackColor!.resolve(on), c.primaryInk);
      expect(theme.switchTheme.thumbColor!.resolve(on), c.onPrimaryInk);
      expect(theme.progressIndicatorTheme.color, c.primaryInk);
      expect(theme.textSelectionTheme.cursorColor, c.primaryInk);
      expect(theme.textSelectionTheme.selectionHandleColor, c.primaryInk);
      expect(
        (theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder)
            .borderSide
            .color,
        c.primaryInk,
      );
      expect(
        theme.inputDecorationTheme.floatingLabelStyle!.color,
        c.primaryInk,
      );
      expect(theme.navigationRailTheme.selectedIconTheme!.color, c.primaryInk);
      expect(theme.cupertinoOverrideTheme!.primaryColor, c.primaryInk);
    }
  });

  test('KIT-T8: the family follows the language', () {
    expect(
      AppTheme.build(
        brightness: Brightness.light,
        language: 'ar',
      ).extension<AppTextStyles>()!.body.fontFamily,
      AppFonts.primaryFor('ar'),
    );
    expect(
      AppTheme.build(
        brightness: Brightness.light,
        language: 'en',
      ).extension<AppTextStyles>()!.body.fontFamily,
      AppFonts.primaryFor('en'),
    );
  });

  test('KIT-T8: component themes read the palette', () {
    final theme = AppTheme.build(brightness: Brightness.dark, language: 'en');
    final c = AppPalette.dark;
    expect(theme.navigationBarTheme.indicatorColor, c.navIndicator);
    expect(
      theme.navigationBarTheme.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );
    expect(theme.dialogTheme.backgroundColor, c.surface);
    expect(theme.bottomSheetTheme.backgroundColor, Colors.transparent);
    expect(theme.dividerTheme.color, c.divider);
    expect(theme.pageTransitionsTheme, AppPageTransitions.theme);
  });

  test('KIT-T8: iOS gets no ink splash, Android keeps the ripple', () {
    expect(
      AppTheme.build(
        brightness: Brightness.light,
        language: 'en',
        platform: TargetPlatform.iOS,
      ).splashFactory,
      NoSplash.splashFactory,
    );
    expect(
      AppTheme.build(
        brightness: Brightness.light,
        language: 'en',
        platform: TargetPlatform.android,
      ).splashFactory,
      isNot(NoSplash.splashFactory),
    );
  });

  test('KIT-T8: cached returns one ThemeData per key', () {
    final a = AppTheme.cached(brightness: Brightness.light, language: 'en');
    final b = AppTheme.cached(brightness: Brightness.light, language: 'en');
    final c = AppTheme.cached(brightness: Brightness.dark, language: 'en');
    expect(a, same(b));
    expect(a, isNot(same(c)));
  });
}
