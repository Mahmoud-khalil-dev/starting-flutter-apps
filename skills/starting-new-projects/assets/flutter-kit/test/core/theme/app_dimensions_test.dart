import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/app_shadows.dart';

void main() {
  test('KIT-T8: spacing sits on the 4-pt grid and grows', () {
    expect(AppDimensions.spacing, [4, 8, 12, 16, 24, 32, 48, 64]);
    for (final s in AppDimensions.spacing) {
      expect(s % 4, 0);
    }
  });

  test('KIT-T8: radii are concentric and the touch target is 48', () {
    expect(
      AppDimensions.innerRadius(AppDimensions.radiusXl, AppDimensions.xs),
      AppDimensions.radiusLg,
    );
    expect(
      AppDimensions.innerRadius(AppDimensions.radiusSm, AppDimensions.md),
      0,
    );
    expect(AppDimensions.touchTarget, 48);
    expect(AppDimensions.buttonHeight, greaterThanOrEqualTo(48));
    expect(AppDimensions.fieldHeight, greaterThanOrEqualTo(48));
  });

  test('KIT-T8: shadows are layered, soft and darker in dark mode', () {
    final light = AppShadows.high(AppPalette.light);
    final dark = AppShadows.high(AppPalette.dark);
    expect(light, hasLength(2));
    expect(light.last.blurRadius, greaterThan(light.first.blurRadius));
    expect(light.every((s) => s.color.a < 0.2), isTrue);
    expect(dark.last.color.a, greaterThan(light.last.color.a));
    expect(
      AppShadows.pressed(AppPalette.light).single.blurRadius,
      lessThan(AppShadows.low(AppPalette.light).last.blurRadius),
    );
  });

  test('KIT-T8: radii and sizes keep the brief values', () {
    expect(
      [
        AppDimensions.radiusSm,
        AppDimensions.radiusMd,
        AppDimensions.radiusLg,
        AppDimensions.radiusXl,
        AppDimensions.radiusPill,
      ],
      [8, 12, 16, 24, 999],
    );
    expect(
      [
        AppDimensions.xxs,
        AppDimensions.xs,
        AppDimensions.sm,
        AppDimensions.md,
        AppDimensions.lg,
        AppDimensions.xl,
        AppDimensions.xxl,
        AppDimensions.xxxl,
      ],
      [4, 8, 12, 16, 24, 32, 48, 64],
    );
    expect(
      [
        AppDimensions.touchTarget,
        AppDimensions.buttonHeight,
        AppDimensions.fieldHeight,
        AppDimensions.iconSm,
        AppDimensions.iconMd,
        AppDimensions.iconLg,
        AppDimensions.iconXl,
        AppDimensions.hairline,
        AppDimensions.spinnerStroke,
        AppDimensions.focusRing,
        AppDimensions.flat,
      ],
      [48, 52, 52, 16, 20, 24, 32, 1, 2, 2, 0],
    );
    expect(
      [
        AppDimensions.contentMaxWidth,
        AppDimensions.dialogMaxWidth,
        AppDimensions.listPaneWidth,
        AppDimensions.railWidth,
        AppDimensions.sidebarWidth,
        AppDimensions.pillHeight,
        AppDimensions.pillMargin,
        AppDimensions.badgeDot,
      ],
      [640, 480, 360, 80, 264, 64, 16, 8],
    );
    expect(
      [
        AppDimensions.avatarSm,
        AppDimensions.avatarMd,
        AppDimensions.avatarLg,
        AppDimensions.glassBlur,
        AppDimensions.backdropBlur,
        AppDimensions.loadMoreExtent,
        AppDimensions.shakeOffset,
        AppDimensions.riseOffset,
      ],
      [32, 48, 72, 24, 12, 320, 8, 12],
    );
  });

  test('KIT-T8: every shadow has its exact alpha, blur and offset', () {
    void check(
      List<BoxShadow> shadows,
      Color base,
      List<(double, double, double)> want, // alpha, blur, dy
    ) {
      expect(shadows, hasLength(want.length));
      for (var i = 0; i < want.length; i++) {
        expect(shadows[i].color.a, closeTo(want[i].$1, 0.004), reason: '$i');
        expect(
          shadows[i].color.withValues(alpha: 1),
          base.withValues(alpha: 1),
        );
        expect(shadows[i].blurRadius, want[i].$2);
        expect(shadows[i].offset, Offset(0, want[i].$3));
      }
    }

    final lc = AppPalette.light.shadow;
    final dc = AppPalette.dark.shadow;
    check(AppShadows.low(AppPalette.light), lc, [(0.05, 2, 1), (0.07, 16, 6)]);
    check(AppShadows.low(AppPalette.dark), dc, [(0.20, 2, 1), (0.24, 16, 6)]);
    check(AppShadows.high(AppPalette.light), lc, [
      (0.06, 4, 2),
      (0.10, 32, 12),
    ]);
    check(AppShadows.high(AppPalette.dark), dc, [(0.22, 4, 2), (0.24, 32, 12)]);
    check(AppShadows.pressed(AppPalette.light), lc, [(0.06, 2, 1)]);
    check(AppShadows.pressed(AppPalette.dark), dc, [(0.20, 2, 1)]);
  });

  test(
    'KIT-T8: every shadow is soft: blur at least twice its drop, alpha low',
    () {
      for (final c in [AppPalette.light, AppPalette.dark]) {
        for (final (name, shadows) in [
          ('low', AppShadows.low(c)),
          ('high', AppShadows.high(c)),
          ('pressed', AppShadows.pressed(c)),
        ]) {
          for (final s in shadows) {
            final reason = '$name ${c == AppPalette.dark ? 'dark' : 'light'}';
            expect(
              s.blurRadius,
              greaterThanOrEqualTo(2 * s.offset.dy),
              reason: reason,
            );
            expect(s.color.a, lessThanOrEqualTo(0.24), reason: reason);
          }
        }
      }
    },
  );

  test('KIT-T8: capsule tokens', () {
    expect(AppDimensions.tabHugWidth, 96);
    expect(AppDimensions.tabHugMax, 3);
    expect(AppDimensions.badgeRing, 2);
    expect(
      AppDimensions.tabHugWidth,
      greaterThanOrEqualTo(AppDimensions.touchTarget),
    );
  });
}
