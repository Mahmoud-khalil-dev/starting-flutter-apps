import 'package:flutter/widgets.dart';

/// An icon that points along the reading direction: a chevron or arrow that
/// faces left in Arabic. Icons that already mirror themselves
/// (matchTextDirection) are left alone.
class AppDirectionalIcon extends StatelessWidget {
  const AppDirectionalIcon(this.icon, {this.size, this.color, super.key});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(
      flipX: rtl && !icon.matchTextDirection,
      child: Icon(icon, size: size, color: color),
    );
  }
}
