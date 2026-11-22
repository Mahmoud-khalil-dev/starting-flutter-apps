import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_haptics.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_shimmer.dart';

/// The mark of a confirmation: a check whose stroke draws
/// itself over [Motion.slow], a champagne-gold shimmer that crosses it for one
/// [Motion.shimmerPeriod], and a success haptic as it appears. Under reduce
/// motion the check is simply there, drawn, with no shimmer; the haptic still
/// fires.
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({super.key});

  @override
  State<SuccessCheck> createState() => SuccessCheckState();
}

@visibleForTesting
class SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  static final Duration _total = Motion.slow + Motion.shimmerPeriod;
  static final double _drawEnd =
      Motion.slow.inMilliseconds / _total.inMilliseconds;

  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: _total,
  );
  late final CurvedAnimation _draw = CurvedAnimation(
    parent: _run,
    curve: Interval(0, _drawEnd, curve: Motion.enter),
  );
  bool _started = false;

  /// How much of the stroke is drawn, 0 to 1.
  double get progress => _draw.value;

  @override
  void initState() {
    super.initState();
    unawaited(AppHaptics.success());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.motion.moves) {
      unawaited(_run.forward());
    } else {
      _run.value = 1;
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final check = ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppDimensions.iconMd,
        child: CustomPaint(
          painter: _CheckPainter(_draw, context.colors.success),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _run,
      child: check,
      builder: (context, child) =>
          context.motion.moves && _run.value > _drawEnd && !_run.isCompleted
          ? AppShimmer(synced: false, announce: false, child: child!)
          : child!,
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress, this.color) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.54)
      ..lineTo(size.width * 0.42, size.height * 0.74)
      ..lineTo(size.width * 0.8, size.height * 0.3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppDimensions.spinnerStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress.value),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
