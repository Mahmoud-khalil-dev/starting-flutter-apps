import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The logo loader: the still [logo] inside a thin ring, with a short beam
/// of light travelling the ring. For cold start, session restore and
/// full-screen waits only; anything with a known shape gets a skeleton
/// (docs/DESIGN.md "Loading"). One live "Loading" node. Any image will do:
/// the project passes its own mark, such as `AssetImage('assets/logo.png')`.
class AppLogoLoader extends StatefulWidget {
  const AppLogoLoader({
    required this.logo,
    this.done = false,
    this.onExited,
    this.fullScreen = true,
    super.key,
  });

  static const orbitKey = Key('logo-orbit');

  /// The image drawn inside the ring, fitted to it.
  final ImageProvider logo;

  /// The long-wait line's style as Text resolves it here, bold text
  /// included, so its height can be kept before it shows.
  @visibleForTesting
  static TextStyle lineStyle(BuildContext context) {
    final style = DefaultTextStyle.of(
      context,
    ).style.merge(context.text.caption);
    if (!MediaQuery.boldTextOf(context)) return style;
    return AppTextStyles.weighted(style, FontWeight.bold);
  }

  /// The wait is over: the loader leaves once it has shown its minimum.
  final bool done;
  final VoidCallback? onExited;

  /// On the background, centred; false sizes to the mark (the gallery).
  final bool fullScreen;

  @override
  State<AppLogoLoader> createState() => _AppLogoLoaderState();
}

class _AppLogoLoaderState extends State<AppLogoLoader>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  late final _exit = AnimationController(
    vsync: this,
    duration: Motion.standard,
  );
  bool _long = false;
  bool _exited = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    // Gone once fully faded: the controller holds 1 for a frame before it
    // reports completed, and nothing is left to see by then.
    _exit.addListener(() {
      if (_exited || _exit.value < 1) return;
      _exited = true;
      _ticker.stop();
      widget.onExited?.call();
    });
  }

  void _tick(Duration elapsed) {
    _elapsed.value = elapsed;
    if (!_long && elapsed >= Motion.longWait) setState(() => _long = true);
    if (widget.done &&
        elapsed >= Motion.loaderMinShow &&
        _exit.status == AnimationStatus.dismissed) {
      _exit
        ..duration = context.motion.fade(Motion.standard)
        ..forward();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _exit.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  OrbitPainter _painter(Duration elapsed, Color color, bool moves) {
    final since = elapsed - Motion.loaderDelay;
    if (since.isNegative) {
      return OrbitPainter(
        head: 0,
        beam: 0,
        glow: null,
        color: color,
        stroke: _stroke,
      );
    }
    final us = since.inMicroseconds;
    // The light arrives over Motion.quick, beam or glow, never at once.
    final arrive = Motion.enter.transform(
      math.min(1, us / Motion.quick.inMicroseconds),
    );
    if (!moves) {
      final breath = Motion.breathe.inMicroseconds;
      final phase = (us % breath) / breath;
      final rise = (1 - math.cos(2 * math.pi * phase)) / 2;
      return OrbitPainter(
        head: 0,
        beam: 0,
        glow: (Motion.loaderGlow + (1 - Motion.loaderGlow) * rise) * arrive,
        color: color,
        stroke: _stroke,
      );
    }
    final lap = Motion.loaderLap.inMicroseconds;
    return OrbitPainter(
      head: Motion.sweep.transform((us % lap) / lap),
      beam: arrive,
      glow: null,
      color: color,
      stroke: _stroke,
    );
  }

  /// The height [copy] takes as the caption at [width], as Text lays it out.
  static double _lineHeight(BuildContext context, String copy, double width) {
    final inherited = DefaultTextStyle.of(context);
    final painter = TextPainter(
      text: TextSpan(text: copy, style: AppLogoLoader.lineStyle(context)),
      textAlign: TextAlign.center,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      textHeightBehavior: inherited.textHeightBehavior,
      locale: Localizations.maybeLocaleOf(context),
    )..layout(maxWidth: width);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// The beam's width; the ring is drawn this wide.
  static const double _stroke = 2;

  /// Space between the ring and the corners of the logo's square.
  static const double _gap = AppDimensions.xs;

  /// The inset that puts a square logo's corners inside the ring, not on it:
  /// the square's diagonal is the ring's inner diameter, so a logo with
  /// sharp or rounded corners never reaches the beam.
  static const double _inset =
      AppDimensions.logoLoaderHeight / 2 -
      (AppDimensions.logoLoaderHeight / 2 - _stroke - _gap) / math.sqrt2;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final moves = context.motion.moves;
    final mark = SizedBox.square(
      dimension: AppDimensions.logoLoaderHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Under reduce motion, the still logo exactly as drawn.
          Padding(
            padding: const EdgeInsets.all(_inset),
            child: Image(image: widget.logo, fit: BoxFit.contain),
          ),
          // The beam repaints every frame; the mark under it never does.
          RepaintBoundary(
            child: ValueListenableBuilder<Duration>(
              valueListenable: _elapsed,
              builder: (context, elapsed, _) => CustomPaint(
                key: AppLogoLoader.orbitKey,
                painter: _painter(elapsed, c.loaderBeam, moves),
              ),
            ),
          ),
        ],
      ),
    );
    final copy = AppLocalizations.of(context)!.loaderLongWait;
    final line = AnimatedOpacity(
      opacity: _long ? 1 : 0,
      duration: context.motion.fade(Motion.gentle),
      curve: Motion.enter,
      child: ExcludeSemantics(
        child: _long
            ? Text(
                copy,
                textAlign: TextAlign.center,
                style: context.text.caption,
              )
            : const SizedBox.shrink(),
      ),
    );
    Widget body = Column(
      mainAxisSize: widget.fullScreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.fullScreen) const Spacer(),
        mark,
        const SizedBox(height: AppDimensions.lg),
        // The line's own height is kept from the start, at this text
        // scale and width, so the mark never moves when it arrives.
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimensions.lg,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: _lineHeight(context, copy, constraints.maxWidth),
              child: line,
            ),
          ),
        ),
        if (widget.fullScreen) const Spacer(),
      ],
    );
    final leave = CurvedAnimation(parent: _exit, curve: Motion.exit);
    body = FadeTransition(
      opacity: ReverseAnimation(leave),
      child: moves
          ? ScaleTransition(
              scale: Tween<double>(
                begin: 1,
                end: Motion.dialogScale,
              ).animate(leave),
              child: body,
            )
          : body,
    );
    if (widget.fullScreen) {
      body = ColoredBox(
        color: c.background,
        child: SizedBox.expand(child: body),
      );
    }
    return Semantics(
      container: true,
      liveRegion: true,
      label: AppLocalizations.of(context)!.loaderLabel,
      child: ExcludeSemantics(child: body),
    );
  }
}

/// The beam: a short light along the ring's centre line, brightest at
/// [head] (0 to 1 from the top centre, clockwise) with a tail that fades
/// softly to nothing. Under reduce motion the whole ring glows instead.
class OrbitPainter extends CustomPainter {
  OrbitPainter({
    required this.head,
    required this.beam,
    required this.glow,
    required this.color,
    required this.stroke,
  });

  final double head;
  final double beam;
  final double? glow;
  final Color color;
  final double stroke;

  /// Nested layers that build the tail's ramp; enough that no band shows.
  static const int slices = 32;

  /// The tail's share of the ring.
  static const double tail = 0.18;

  /// The tail's brightness at [x], 0 at its end to 1 at the head: eased in
  /// so the light thins away rather than stopping at an edge.
  static double falloff(double x) => x * x;

  /// The ring and its metric by size: a painter is made every frame, the
  /// ring only when a size is new. Loaders of one size share it; a few
  /// sizes at most are kept.
  static final Map<(Size, double), (Path, ui.PathMetric)> _rings = {};

  /// The ring's centre line: a circle inside [size], from the top centre,
  /// clockwise.
  static Path ring(Size size, double stroke) => Path()
    ..addArc(
      (Offset.zero & size).deflate(stroke / 2),
      -math.pi / 2,
      2 * math.pi,
    );

  static (Path, ui.PathMetric) _ring(Size size, double stroke) {
    final kept = _rings[(size, stroke)];
    if (kept != null) return kept;
    if (_rings.length >= 4) _rings.clear();
    final path = ring(size, stroke);
    return _rings[(size, stroke)] = (path, path.computeMetrics().single);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final glowing = glow;
    if (glowing != null) {
      paint.color = color.withValues(alpha: color.a * glowing);
      canvas.drawPath(_ring(size, stroke).$1, paint);
      return;
    }
    if (beam <= 0) return;
    final metric = _ring(size, stroke).$2;
    final length = metric.length;
    final end = head * length;
    final span = tail * length;
    // One layer holds the whole beam's opacity, so the nested strokes and
    // the round head compose to the ramp and never to a brighter bead.
    canvas.saveLayer(
      Offset.zero & size,
      // Only the layer paint's alpha counts.
      Paint()..color = color.withValues(alpha: color.a * beam),
    );
    final opaque = color.withValues(alpha: 1);
    var below = 0.0;
    for (var i = 0; i < slices; i++) {
      // Layer i runs from its start to the head; where it adds to the
      // layers under it the sum reaches falloff of that band.
      final target = falloff((i + 1) / slices);
      final alpha = below >= 1 ? 0.0 : 1 - (1 - target) / (1 - below);
      below = target;
      if (alpha <= 0) continue;
      paint.color = opaque.withValues(alpha: alpha);
      canvas.drawPath(_arc(metric, end - span + i * span / slices, end), paint);
    }
    final nose = metric.getTangentForOffset(end % length)!.position;
    canvas
      ..drawCircle(nose, stroke / 2, Paint()..color = opaque)
      ..restore();
  }

  /// The ring from [from] to [to], one unbroken stroke across the seam.
  static Path _arc(ui.PathMetric metric, double from, double to) {
    final length = metric.length;
    if (from >= 0) return metric.extractPath(from, to);
    return metric.extractPath(from + length, length)
      ..extendWithPath(metric.extractPath(0, to), Offset.zero);
  }

  @override
  bool shouldRepaint(OrbitPainter old) =>
      old.head != head ||
      old.beam != beam ||
      old.glow != glow ||
      old.color != color ||
      old.stroke != stroke;
}
