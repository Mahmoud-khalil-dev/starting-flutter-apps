import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';

/// The pinned bottom actions of a form or flow: the primary
/// at the end edge, an optional secondary at the start, inside the safe
/// area, above the keyboard (AppScaffold resizes).
class AppActionBar extends StatelessWidget {
  const AppActionBar({required this.primary, this.secondary, super.key});

  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppDimensions.md),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.contentMaxWidth,
              ),
              child: Row(
                children: [
                  if (secondary != null) ...[
                    Expanded(child: secondary!),
                    const SizedBox(width: AppDimensions.sm),
                  ],
                  Expanded(child: primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
