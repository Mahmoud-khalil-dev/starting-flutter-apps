import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_haptics.dart';
import 'package:kit_app/core/theme/app_shadows.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/press_scale.dart';
import 'package:kit_app/l10n/app_localizations.dart';

enum AppButtonVariant { primary, secondary, quiet, destructive }

enum AppButtonState { idle, loading, success }

/// The one button: press scales to 0.97 with the shadow dropping,
/// loading morphs the label into a thin spinner, success into a check.
/// One primary per screen. Labels wrap, never shrink or truncate.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.state = AppButtonState.idle,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonState state;

  /// Drawn at the start edge, before the label.
  final IconData? icon;

  /// Fill the available width.
  final bool expand;

  bool get _enabled => onPressed != null && state == AppButtonState.idle;

  /// A light haptic on a primary press only.
  void _tap() {
    if (variant == AppButtonVariant.primary) AppHaptics.light();
    onPressed!();
  }

  (Color, Color, BoxBorder?) _paint(AppColors c, {required bool dark}) {
    if (onPressed == null) {
      return variant == AppButtonVariant.quiet
          ? (Colors.transparent, c.hint, null)
          : (c.surfaceRaised, c.hint, null);
    }
    return switch (variant) {
      AppButtonVariant.primary => (c.primary, c.onPrimary, null),
      AppButtonVariant.secondary => (
        c.surface,
        c.ink,
        Border.all(color: c.outline),
      ),
      AppButtonVariant.quiet => (Colors.transparent, c.primaryInk, null),
      // On a dark ground a filled pastel red is loud; dark mode draws the
      // destructive action as a danger outline on the surface instead.
      AppButtonVariant.destructive when dark => (
        c.surface,
        c.danger,
        Border.all(color: c.danger),
      ),
      AppButtonVariant.destructive => (c.danger, c.onDanger, null),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final (fill, ink, border) = _paint(
      c,
      dark: Theme.of(context).brightness == Brightness.dark,
    );
    final radius = BorderRadius.circular(AppDimensions.radiusMd);
    final content = AnimatedSwitcher(
      duration: motion.fade(Motion.quick),
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      child: switch (state) {
        AppButtonState.idle => _Label(
          key: const ValueKey('label'),
          label: label,
          icon: icon,
          color: ink,
        ),
        AppButtonState.loading => SizedBox.square(
          key: const ValueKey('loading'),
          dimension: AppDimensions.iconMd,
          child: CircularProgressIndicator(
            strokeWidth: AppDimensions.spinnerStroke,
            color: ink,
          ),
        ),
        AppButtonState.success => Icon(
          Icons.check_rounded,
          key: const ValueKey('success'),
          color: ink,
          size: AppDimensions.iconLg,
        ),
      },
    );
    final button = Semantics(
      button: true,
      enabled: _enabled,
      label: state == AppButtonState.loading
          ? AppLocalizations.of(context)!.loaderLabel
          : label,
      excludeSemantics: true,
      onTap: _enabled ? _tap : null,
      child: PressScale(
        enabled: _enabled,
        builder: (context, {required pressed}) => AnimatedContainer(
          duration: motion.fade(Motion.quick),
          curve: Motion.enter,
          constraints: const BoxConstraints(
            minHeight: AppDimensions.buttonHeight,
            minWidth: AppDimensions.touchTarget,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: border,
            boxShadow: variant == AppButtonVariant.primary && _enabled
                ? (pressed ? AppShadows.pressed(c) : AppShadows.low(c))
                : const [],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _enabled ? _tap : null,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: AppDimensions.sm,
                ),
                child: Center(widthFactor: expand ? null : 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: AppDimensions.iconMd, color: color),
        const SizedBox(width: AppDimensions.xs),
      ],
      Flexible(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.weighted(
            context.text.label.copyWith(color: color),
            FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
