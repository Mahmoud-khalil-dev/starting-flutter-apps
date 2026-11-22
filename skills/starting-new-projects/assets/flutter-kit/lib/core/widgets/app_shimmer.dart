import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// One tilted band of light across skeletons: it
/// travels from the start edge for 75% of [Motion.shimmerPeriod], then
/// rests. Every synced shimmer reads the same clock, the frame time, so
/// all skeletons on a screen sweep together. Under reduce motion the
/// blocks breathe in opacity instead; nothing moves sideways.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    required this.child,
    this.synced = true,
    this.announce = true,
    this.semanticsLabel,
    super.key,
  });

  final Widget child;

  /// False runs on its own clock from the moment it appears: a one-off
  /// highlight, such as the success check's.
  final bool synced;

  /// One live "Loading" node for the whole skeleton; false when the
  /// shimmer decorates something that already speaks. A screen region
  /// says "Loading" once: when several shimmers sit side by side (a
  /// header, a card, a list), the first announces and the rest pass false.
  final bool announce;
  final String? semanticsLabel;

  @override
  State<AppShimmer> createState() => AppShimmerState();
}

@visibleForTesting
class AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _phase = ValueNotifier<double>(0);

  /// Where the shared period stands, 0 to 1.
  double get phase => _phase.value;

  bool get sweepsForward => Directionality.of(context) == TextDirection.ltr;

  // Read once per dependency change, not on every frame.
  int _period = Motion.shimmerPeriod.inMicroseconds;

  void _tick(Duration elapsed) {
    final now = widget.synced
        ? SchedulerBinding.instance.currentFrameTimeStamp
        : elapsed;
    _phase.value = (now.inMicroseconds % _period) / _period;
  }

  /// The band's position across the sweep, 0 to 1, eased; 1 at rest.
  @visibleForTesting
  static double sweepAt(double phase) => phase >= Motion.shimmerSweepShare
      ? 1
      : Motion.sweep.transform(phase / Motion.shimmerSweepShare);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _period = (context.motion.moves ? Motion.shimmerPeriod : Motion.breathe)
        .inMicroseconds;
    if (!_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (base, highlight) = (c.shimmerBase, c.shimmerHighlight);
    final rtl = !sweepsForward;
    final moves = context.motion.moves;
    final blocks = widget.child;
    final Widget painted = RepaintBoundary(
      child: ValueListenableBuilder<double>(
        valueListenable: _phase,
        child: blocks,
        builder: (context, phase, child) {
          if (!moves) {
            // A breath: 1.0 down to shimmerDim and back, once per period.
            final dip = (1 - math.cos(2 * math.pi * phase)) / 2;
            return Opacity(
              opacity: 1 - (1 - Motion.shimmerDim) * dip,
              child: child,
            );
          }
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              // Physical ends (the default); ShimmerSweep mirrors the
              // travel and tilt.
              colors: [base, base, highlight, base, base],
              stops: const [0, 0.35, 0.5, 0.65, 1],
              transform: ShimmerSweep(sweepAt(phase), rtl: rtl),
            ).createShader(bounds),
            child: child,
          );
        },
      ),
    );
    if (!widget.announce) return ExcludeSemantics(child: painted);
    return Semantics(
      liveRegion: true,
      label: widget.semanticsLabel ?? AppLocalizations.of(context)!.loaderLabel,
      child: ExcludeSemantics(child: painted),
    );
  }
}

/// Moves the shimmer's gradient across its bounds and tilts it. At 0 the
/// band is wholly off the start edge, at 1 wholly off the end edge.
class ShimmerSweep extends GradientTransform {
  const ShimmerSweep(this.progress, {required this.rtl});

  final double progress;
  final bool rtl;

  /// Half the band (0.15 of the width) plus half the gradient (0.5).
  static const double _band = 0.65;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final tilt = rtl ? -Motion.shimmerTilt : Motion.shimmerTilt;
    final reach =
        bounds.width * _band + bounds.height * math.tan(Motion.shimmerTilt) / 2;
    final t = rtl ? 1 - progress : progress;
    final dx = -reach + 2 * reach * t;
    final centre = bounds.center;
    return Matrix4.identity()
      ..translateByDouble(centre.dx + dx, centre.dy, 0, 1)
      ..rotateZ(tilt)
      ..translateByDouble(-centre.dx, -centre.dy, 0, 1);
  }
}

enum _Shape { block, circle, bar }

/// A placeholder block in the shimmer base colour. Put bones under one
/// [AppShimmer] per group, never one shimmer per bone, so a group sweeps
/// and announces "Loading" once.
class AppSkeleton extends StatelessWidget {
  /// A block of [height]; with no [width] it takes the width it is given,
  /// so in a Row it needs Expanded (or a width), as a Row gives none.
  const AppSkeleton({
    required this.height,
    this.width,
    this.radius = AppDimensions.radiusSm,
    super.key,
  }) : widthFactor = null,
       _shape = _Shape.block;

  /// One line of body text.
  const AppSkeleton.line({super.key, this.width})
    : height = AppDimensions.md,
      radius = AppDimensions.radiusSm,
      widthFactor = null,
      _shape = _Shape.block;

  /// An avatar or icon disc.
  const AppSkeleton.circle({super.key, double size = AppDimensions.avatarMd})
    : width = size,
      height = size,
      radius = AppDimensions.radiusPill,
      widthFactor = null,
      _shape = _Shape.circle;

  /// A bar of text, a share of the width it is given.
  const AppSkeleton.bar({super.key, double this.widthFactor = 1})
    : width = null,
      height = AppDimensions.skeletonBar,
      radius = AppDimensions.radiusSm,
      _shape = _Shape.bar;

  /// Null: the width it is given.
  final double? width;
  final double height;
  final double radius;

  /// Null: [width] or the full width.
  final double? widthFactor;
  final _Shape _shape;

  @override
  Widget build(BuildContext context) {
    final block = SizedBox(
      key: switch (_shape) {
        _Shape.circle => const ValueKey('skeleton-circle'),
        _Shape.bar => const ValueKey('skeleton-bar'),
        _Shape.block => null,
      },
      // No width: the width it is given; a loose column would otherwise
      // shrink an unsized box to nothing.
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.shimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
    final factor = widthFactor;
    final Widget sized = factor == null
        ? block
        : FractionallySizedBox(
            widthFactor: factor,
            alignment: AlignmentDirectional.centerStart,
            child: block,
          );
    return width == null ? _NeedsWidth(child: sized) : sized;
  }
}

/// Asserts that a width-less skeleton is given a width, with a message
/// that says what to do, in place of the framework's infinite-size error.
/// A proxy, not a LayoutBuilder, so intrinsic sizing still passes through.
class _NeedsWidth extends SingleChildRenderObjectWidget {
  const _NeedsWidth({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNeedsWidth();
}

class _RenderNeedsWidth extends RenderProxyBox {
  @override
  void performLayout() {
    assert(
      constraints.hasBoundedWidth,
      'An AppSkeleton without a width was laid out with unbounded width, '
      'as a Row child is: wrap it in Expanded or give it a width.',
    );
    super.performLayout();
  }
}
