import 'package:flutter/widgets.dart';

/// Width classes of the window, not the device (docs/ARCHITECTURE.md).
enum WindowClass {
  compact,
  medium,
  expanded;

  static const mediumMin = 600.0;
  static const expandedMin = 1024.0;

  static WindowClass forWidth(double width) {
    if (width >= expandedMin) return WindowClass.expanded;
    if (width >= mediumMin) return WindowClass.medium;
    return WindowClass.compact;
  }
}

extension WindowClassX on BuildContext {
  WindowClass get windowClass =>
      WindowClass.forWidth(MediaQuery.sizeOf(this).width);
}

/// One layout per window class. A missing one falls back to the next
/// smaller class. It rebuilds when the window changes, rotation included.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    required this.compact,
    this.medium,
    this.expanded,
    super.key,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    final builder = switch (context.windowClass) {
      WindowClass.compact => compact,
      WindowClass.medium => medium ?? compact,
      WindowClass.expanded => expanded ?? medium ?? compact,
    };
    return builder(context);
  }
}

/// Phones scale type and design sizes from a 375-wide frame, clamped to
/// 0.85 to 1.4. From 600 px wide the scale is 1.0: a rail or a dialog
/// should not grow with the window. Touch targets,
/// spacing and radii are never scaled.
abstract final class ResponsiveScale {
  static const double designWidth = 375;
  static const double min = 0.85;
  static const double max = 1.4;

  static double forWidth(double width) {
    if (width >= WindowClass.mediumMin) return 1;
    return (width / designWidth).clamp(min, max);
  }
}

extension ResponsiveScaleX on BuildContext {
  /// Read from MediaQuery.sizeOf, so rotation and split screen rebuild.
  double get uiScale => ResponsiveScale.forWidth(MediaQuery.sizeOf(this).width);

  /// A size from the design frame, such as an illustration height.
  /// Never use it for a touch target.
  double scaled(double designValue) => designValue * uiScale;
}
