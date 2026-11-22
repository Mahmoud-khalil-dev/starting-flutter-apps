import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/platform_style.dart';

/// What the phone bar is made of where it runs.
enum BarMaterial {
  /// A backdrop blur under a translucent fill: the iOS and Android apps.
  frost,

  /// A dense fill, no blur: the web, where a blur is costly and uneven.
  dense,

  /// Increased contrast: an opaque surface with an outline rim.
  opaque,
}

/// The bar's material here.
BarMaterial barMaterialOf(BuildContext context) {
  if (MediaQuery.highContrastOf(context)) return BarMaterial.opaque;
  return context.blursBackdrop ? BarMaterial.frost : BarMaterial.dense;
}

/// The phone width tab bar: a Material [NavigationBar] on a frosted fill, so
/// the page scrolls under it and shows through. Its destinations and
/// selection come from the shell.
class FrostedNavBar extends StatelessWidget {
  const FrostedNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// Found by tests and by the shell to place the bar's slot.
  static const barKey = Key('frostedNavBar');

  final List<Widget> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final material = barMaterialOf(context);
    final bar = NavigationBar(
      backgroundColor: Colors.transparent,
      elevation: AppDimensions.flat,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: destinations,
    );
    final filled = switch (material) {
      BarMaterial.frost => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppDimensions.glassBlur,
            sigmaY: AppDimensions.glassBlur,
          ),
          child: ColoredBox(
            color: c.glass.withValues(alpha: AppDimensions.glassOpacity),
            child: bar,
          ),
        ),
      ),
      BarMaterial.dense => ColoredBox(
        color: c.glass.withValues(alpha: AppDimensions.glassOpacityWeb),
        child: bar,
      ),
      BarMaterial.opaque => ColoredBox(color: c.surface, child: bar),
    };
    return DecoratedBox(
      key: barKey,
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: BorderDirectional(
          top: BorderSide(
            color: material == BarMaterial.opaque ? c.outline : c.glassRim,
          ),
        ),
      ),
      child: filled,
    );
  }
}
