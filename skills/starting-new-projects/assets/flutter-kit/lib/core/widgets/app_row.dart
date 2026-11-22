import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_haptics.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/widgets/app_directional_icon.dart';

enum AppRowTone { neutral, destructive }

enum _Kind { navigation, value, toggle, info, action }

/// One row of an AppGroup. Five kinds, one height rule: at least the touch
/// target, growing with the text. A value that does not fit beside the
/// title moves under it instead of truncating.
class AppRow extends StatelessWidget {
  const AppRow.navigation({
    required this.title,
    required VoidCallback this.onTap,
    this.subtitle,
    this.leading,
    this.value,
    super.key,
  }) : _kind = _Kind.navigation,
       toggled = false,
       onToggle = null,
       tone = AppRowTone.neutral;

  const AppRow.value({
    required this.title,
    required String this.value,
    this.leading,
    super.key,
  }) : _kind = _Kind.value,
       subtitle = null,
       onTap = null,
       toggled = false,
       onToggle = null,
       tone = AppRowTone.neutral;

  const AppRow.toggle({
    required this.title,
    required bool value,
    required ValueChanged<bool> onChanged,
    this.subtitle,
    this.leading,
    super.key,
  }) : _kind = _Kind.toggle,
       toggled = value,
       onToggle = onChanged,
       value = null,
       onTap = null,
       tone = AppRowTone.neutral;

  const AppRow.info({
    required this.title,
    this.subtitle,
    this.leading,
    super.key,
  }) : _kind = _Kind.info,
       value = null,
       onTap = null,
       toggled = false,
       onToggle = null,
       tone = AppRowTone.neutral;

  const AppRow.action({
    required this.title,
    required VoidCallback this.onTap,
    this.leading,
    this.tone = AppRowTone.neutral,
    super.key,
  }) : _kind = _Kind.action,
       subtitle = null,
       value = null,
       toggled = false,
       onToggle = null;

  final _Kind _kind;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final String? value;
  final VoidCallback? onTap;
  final bool toggled;
  final ValueChanged<bool>? onToggle;
  final AppRowTone tone;

  void _toggle() {
    AppHaptics.selection();
    onToggle!(!toggled);
  }

  VoidCallback? get _onTap => switch (_kind) {
    _Kind.toggle => _toggle,
    _Kind.navigation || _Kind.action => onTap,
    _Kind.value || _Kind.info => null,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final titleStyle = context.text.body.copyWith(
      color: tone == AppRowTone.destructive
          ? c.danger
          : _kind == _Kind.action
          ? c.primaryInk
          : c.ink,
    );
    final valueStyle = context.text.body.copyWith(color: c.inkMuted);
    final trailing = switch (_kind) {
      _Kind.navigation => AppDirectionalIcon(
        Icons.chevron_right_rounded,
        color: c.hint,
      ),
      _Kind.toggle => ExcludeSemantics(
        // On iOS the adaptive switch ignores the theme's trackColor and
        // draws the system colours, so both tracks are named here: on is
        // primaryInk, off is the 3:1 outline, readable on the row's surface
        // in light and dark.
        child: Switch.adaptive(
          value: toggled,
          activeTrackColor: c.primaryInk,
          inactiveTrackColor: c.outline,
          onChanged: (_) => _toggle(),
        ),
      ),
      _ => null,
    };
    return Semantics(
      toggled: _kind == _Kind.toggle ? toggled : null,
      button: _kind == _Kind.navigation || _kind == _Kind.action,
      child: InkWell(
        onTap: _onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.touchTarget,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppDimensions.sm),
                ],
                Expanded(
                  child: _TitleAndValue(
                    title: title,
                    subtitle: subtitle,
                    value: value,
                    titleStyle: titleStyle,
                    valueStyle: valueStyle,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppDimensions.xs),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleAndValue extends StatelessWidget {
  const _TitleAndValue({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.titleStyle,
    required this.valueStyle,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final TextStyle titleStyle;
  final TextStyle valueStyle;

  double _width(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null) Text(subtitle!, style: context.text.caption),
      ],
    );
    final value = this.value;
    if (value == null) return head;
    return LayoutBuilder(
      builder: (context, constraints) {
        final needed =
            _width(context, title, titleStyle) +
            AppDimensions.md +
            _width(context, value, valueStyle);
        final shownValue = Text(value, style: valueStyle);
        if (needed <= constraints.maxWidth) {
          return Row(
            children: [
              Expanded(child: head),
              const SizedBox(width: AppDimensions.md),
              shownValue,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            head,
            const SizedBox(height: AppDimensions.xxs),
            shownValue,
          ],
        );
      },
    );
  }
}
