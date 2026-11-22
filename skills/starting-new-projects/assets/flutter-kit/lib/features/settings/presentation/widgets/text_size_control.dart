import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_app/core/l10n/app_formats.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/platform_style.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The text size as a percentage above a slider. Dragging only moves the
/// thumb; the choice is saved once, when the finger lifts, so a drag is one
/// write and the app does not rescale under the finger. It has the platform's
/// look: Apple's slider on iOS and macOS, Material's elsewhere (the web
/// included). A screen reader hears the same percentage in the same digits
/// on both, and a screen-reader step moves one step and saves it. Apple's
/// slider keeps its system track colour.
class TextSizeControl extends StatefulWidget {
  const TextSizeControl({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final double value;
  final Future<void> Function(double scale) onChanged;

  @override
  State<TextSizeControl> createState() => _TextSizeControlState();
}

class _TextSizeControlState extends State<TextSizeControl> {
  /// Steps of 5%, from the smallest size to the largest.
  static const _steps = 15;
  static const double _step =
      (AppSettings.maxTextScale - AppSettings.minTextScale) / _steps;

  /// Where the thumb is while it is held or its save is in flight.
  double? _held;

  String _percent(BuildContext context, double scale) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.settingsTextSizeValue(
      AppFormats.of(context).formatNumber((scale * 100).round()),
    );
  }

  Future<void> _commit(double scale) async {
    await widget.onChanged(scale);
    if (mounted) setState(() => _held = null);
  }

  /// [scale] moved [by] steps, on a step, inside the range.
  static double _stepped(double scale, int by) {
    final index = ((scale - AppSettings.minTextScale) / _step).round() + by;
    return (AppSettings.minTextScale + index.clamp(0, _steps) * _step).clamp(
      AppSettings.minTextScale,
      AppSettings.maxTextScale,
    );
  }

  /// Apple's slider reports its track position (20% at a size of 100%) in
  /// Western digits, so its own semantics are replaced by the percentage.
  Widget _apple(BuildContext context, double value) {
    final up = _stepped(value, 1);
    final down = _stepped(value, -1);
    return Semantics(
      slider: true,
      value: _percent(context, value),
      increasedValue: _percent(context, up),
      decreasedValue: _percent(context, down),
      onIncrease: up > value ? () => _jump(up) : null,
      onDecrease: down < value ? () => _jump(down) : null,
      child: ExcludeSemantics(
        child: CupertinoSlider(
          value: value,
          min: AppSettings.minTextScale,
          max: AppSettings.maxTextScale,
          divisions: _steps,
          activeColor: context.colors.primaryInk,
          onChanged: (v) => setState(() => _held = v),
          onChangeEnd: _commit,
        ),
      ),
    );
  }

  void _jump(double scale) {
    setState(() => _held = scale);
    _commit(scale);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shown = _held ?? widget.value;
    final value = shown.clamp(
      AppSettings.minTextScale,
      AppSettings.maxTextScale,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_percent(context, shown), style: context.text.label),
        if (context.isCupertino)
          _apple(context, value)
        else
          Slider(
            value: value,
            min: AppSettings.minTextScale,
            max: AppSettings.maxTextScale,
            divisions: _steps,
            label: _percent(context, shown),
            activeColor: c.primaryInk,
            inactiveColor: c.outline,
            semanticFormatterCallback: (v) => _percent(context, v),
            onChanged: (v) => setState(() => _held = v),
            onChangeEnd: _commit,
          ),
      ],
    );
  }
}
