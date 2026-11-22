import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';

/// Keeps a tab label on one line inside its item. The user's text scale is
/// capped at [maxScale]; a label wider than its item minus the label
/// padding shrinks to fit, but never below [floorScale] of the base size
/// (or the user's own scale when that is smaller). If it still does not
/// fit at the floor, it ends in an ellipsis. It never wraps, so a word
/// never breaks. The tab's semantics label is untouched.
///
/// [style] is the base label style; null reads the navigation bar theme's.
class FitLabel extends StatelessWidget {
  const FitLabel({
    required this.label,
    required this.child,
    this.style,
    super.key,
  });

  final String label;
  final Widget child;
  final TextStyle? style;

  /// The tab label's text scale never goes above this.
  static const double maxScale = 1.3;

  /// The tab label never shrinks below this multiple of its base size.
  static const double floorScale = 1;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final base =
          style ??
          NavigationBarTheme.of(
            context,
          ).labelTextStyle?.resolve(const {WidgetState.selected});
      final size = base?.fontSize;
      final room = constraints.maxWidth - 2 * AppDimensions.xxs;
      final user = MediaQuery.textScalerOf(
        context,
      ).clamp(maxScaleFactor: maxScale);
      var scaler = user;
      if (size != null && room > 0) {
        final floor = user.scale(size) / size < floorScale
            ? user
            : TextScaler.noScaling;
        final painter = TextPainter(
          text: TextSpan(text: label, style: base),
          textDirection: Directionality.of(context),
          maxLines: 1,
        );
        // Text width is not exactly linear in size; a few passes settle it.
        for (var pass = 0; pass < 3; pass++) {
          painter
            ..textScaler = scaler
            ..layout();
          if (painter.width <= room) break;
          final next = scaler.scale(size) / size * room / painter.width;
          scaler = next * size <= floor.scale(size)
              ? floor
              : TextScaler.linear(next);
          if (identical(scaler, floor)) break;
        }
        painter.dispose();
      }
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: DefaultTextStyle.merge(
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          child: child,
        ),
      );
    },
  );
}
