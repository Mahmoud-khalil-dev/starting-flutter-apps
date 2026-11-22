import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/motion.dart';

/// Text whose changed characters roll vertically: a
/// countdown, a balance as it updates. Unchanged characters stay still. Under
/// reduce motion changes fade in place. Pass text already localized.
class AppRollingDigits extends StatelessWidget {
  const AppRollingDigits(this.text, {this.style, super.key});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // A font that loads after the first frame (the web) changes the digit
    // widths, so the cells are measured again.
    listenable: PaintingBinding.instance.systemFonts,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final motion = context.motion;
    final chars = text.characters.toList();
    final base = style ?? DefaultTextStyle.of(context).style;
    final tabular = base.copyWith(
      fontFeatures: [...?base.fontFeatures, const FontFeature.tabularFigures()],
    );
    final scaler = MediaQuery.textScalerOf(context);
    final cells = cellsOf(tabular, scaler);
    // Alexandria's Arabic-Indic digits are proportional even with tnum
    //, so each digit gets a cell as wide as its widest sibling
    // and a countdown never shifts as it counts.
    Widget cell(String char, Widget text) {
      final width = _eastern.contains(char)
          ? cells.eastern
          : _western.contains(char)
          ? cells.western
          : null;
      if (width == null) return text;
      return SizedBox(
        key: const ValueKey('digit-cell'),
        width: width,
        child: Center(child: text),
      );
    }

    // Slots count from the end, so a change of length keeps the trailing
    // characters in place and only the end that differs rolls.
    ValueKey<String> keyOf(int slot, String char) => ValueKey('$slot$char');
    // Digits read left to right in every language (a number is never
    // mirrored); the caller localizes the characters.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Semantics(
        label: text,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < chars.length; i++)
              ClipRect(
                key: ValueKey('slot${chars.length - 1 - i}'),
                child: AnimatedSwitcher(
                  duration: motion.move(Motion.quick),
                  switchInCurve: Motion.enter,
                  switchOutCurve: Motion.exit,
                  transitionBuilder: (child, animation) {
                    final incoming =
                        child.key == keyOf(chars.length - 1 - i, chars[i]);
                    final from = Offset(0, incoming ? 1 : -1);
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: motion.moves ? from : Offset.zero,
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: keyOf(chars.length - 1 - i, chars[i]),
                    child: cell(chars[i], Text(chars[i], style: tabular)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const _western = '0123456789';
  static const _eastern = '٠١٢٣٤٥٦٧٨٩';

  static final Map<(TextStyle, TextScaler), DigitCells> _cells = {};
  static bool _watching = false;

  /// The digit cell widths for [style] at [scaler], measured once: a
  /// countdown rebuilds every second with the same style.
  static DigitCells cellsOf(TextStyle style, TextScaler scaler) {
    if (!_watching) {
      _watching = true;
      PaintingBinding.instance.systemFonts.addListener(_cells.clear);
    }
    final key = (style, scaler);
    final kept = _cells[key];
    if (kept != null) return kept;
    // A screen uses a few digit styles; past that, start afresh.
    if (_cells.length >= 8) _cells.clear();
    return _cells[key] = DigitCells._(
      western: _widest(style, scaler, arabic: false),
      eastern: _widest(style, scaler, arabic: true),
    );
  }

  /// The widest digit of one script in [style].
  static double _widest(
    TextStyle style,
    TextScaler scaler, {
    required bool arabic,
  }) {
    var widest = 0.0;
    for (final digit in (arabic ? _eastern : _western).characters) {
      final painter = TextPainter(
        text: TextSpan(text: digit, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    return widest;
  }
}

/// The cell width of a Western and of an Arabic-Indic digit in one style.
final class DigitCells {
  const DigitCells._({required this.western, required this.eastern});

  final double western;
  final double eastern;
}
