import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_haptics.dart';
import 'package:kit_app/core/theme/app_shadows.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';

class AppSegment<T> {
  const AppSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// A segmented control: a pill glides under the selected
/// segment on the spring; under reduce motion it jumps. Selection haptic.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  }) : assert(segments.length >= 2, 'A segmented control needs two segments');

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final found = segments.indexWhere((s) => s.value == selected);
    assert(found >= 0, 'selected must be one of the segments');
    final index = found < 0 ? 0 : found;
    final count = segments.length;
    // -1 is the start edge, 1 the end; AlignmentDirectional mirrors it.
    final x = count == 1 ? 0.0 : -1 + 2 * index / (count - 1);
    final radius = BorderRadius.circular(AppDimensions.radiusPill);
    // Each cell is the full 48-high touch target; only the painted pill is
    // inset from the track.
    return Container(
      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: AlignmentDirectional(x, 0),
              duration: context.motion.moves ? Motion.standard : Duration.zero,
              curve: Motion.spring,
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(AppDimensions.xxs),
                  child: DecoratedBox(
                    // primaryInk, so the selection reads at 3:1 or more off the
                    // raised track in both themes, not by its shadow alone.
                    decoration: BoxDecoration(
                      color: c.primaryInk,
                      borderRadius: radius,
                      boxShadow: AppShadows.low(c),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: Semantics(
                    button: true,
                    enabled: true,
                    selected: segment.value == selected,
                    child: InkWell(
                      borderRadius: radius,
                      // The selected segment stays enabled for screen
                      // readers; tapping it again does nothing.
                      onTap: () {
                        if (segment.value == selected) return;
                        AppHaptics.selection();
                        onChanged(segment.value);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppDimensions.touchTarget,
                        ),
                        child: Center(
                          child: Text(
                            segment.label,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.weighted(
                              context.text.label.copyWith(
                                color: segment.value == selected
                                    ? c.onPrimaryInk
                                    : c.inkMuted,
                              ),
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
