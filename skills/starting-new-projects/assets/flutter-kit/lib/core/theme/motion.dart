import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// The motion tokens. The only place a Duration or a
/// Curve for motion is written (rule `raw-motion`).
abstract final class Motion {
  /// Press feedback, toggles.
  static const instant = Duration(milliseconds: 100);

  /// Chips, selection, small reveals.
  static const quick = Duration(milliseconds: 200);

  /// Cards, sheets, tab changes.
  static const standard = Duration(milliseconds: 320);

  /// Page transitions, hero moments.
  static const gentle = Duration(milliseconds: 480);

  /// Success and confirmation moments.
  static const slow = Duration(milliseconds: 700);

  /// Delay between list items entering.
  static const stagger = Duration(milliseconds: 40);

  /// One sweep of the loading shimmer and its rest; slow on purpose.
  static const shimmerPeriod = Duration(milliseconds: 1600);

  /// The reduce-motion breath of a skeleton: twice the sweep period.
  static const breathe = Duration(milliseconds: 3200);

  /// The share of [shimmerPeriod] the band travels; the rest is still.
  static const double shimmerSweepShare = 0.75;

  /// The band's tilt from vertical: 20 degrees.
  static const double shimmerTilt = 20 * math.pi / 180;

  /// The lowest opacity of the breath.
  static const double shimmerDim = 0.6;

  /// The band's pace across the sweep: slow in, slow out.
  static const Curve sweep = Curves.easeInOutSine;

  /// A loading state waits this long before it shows: a fast answer never
  /// flashes a skeleton.
  static const Duration loadingDelay = quick;

  /// Once shown, a skeleton stays at least this long.
  static const Duration loadingMinShow = gentle;

  /// The logo loader holds the still mark this long before the beam shows.
  static const loaderDelay = Duration(milliseconds: 400);

  /// One lap of the beam round the ring.
  static const loaderLap = Duration(milliseconds: 1600);

  /// One turn of the logo mark about its own axis while the loader waits:
  /// once a beam lap, at an even pace.
  static const Duration leafTurn = loaderLap;

  /// Once shown, the loader stays at least this long.
  static const Duration loaderMinShow = slow;

  /// Under reduce motion the ring glows between this and full.
  static const double loaderGlow = 0.5;

  /// After this, the loader adds one quiet line.
  static const longWait = Duration(seconds: 5);

  /// How long "Back online" stays (the connection banner).
  static const bannerHold = Duration(seconds: 2);
  static const snackbarHold = Duration(seconds: 4);

  /// Countdown refresh.
  static const tick = Duration(seconds: 1);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  /// Sheets and the tab pill: settles with under 4% overshoot.
  static const Curve spring = SpringCurve();

  /// Lands at the end at once: a movement under reduce motion, where a fade
  /// on the same animation carries the change instead.
  static const Curve jump = Threshold(0);

  /// The tab lens: its leading edge travels on the spring over [standard],
  /// its trailing edge leaves a [stagger] later, so the lens stretches
  /// toward the new tab and gathers back into one slot.
  static const lensTravel = Duration(milliseconds: 360);
  static const Curve lensLead = Interval(0, 320 / 360, curve: spring);
  static const Curve lensTrail = Interval(40 / 360, 1, curve: spring);

  /// The lens under a long press: lifted off the glass.
  static const double lensLift = 1.06;

  static const double pressScale = 0.97;

  /// Opacity of a pressed element under reduce motion, where it cannot scale.
  static const double pressDim = 0.72;
  static const double dialogScale = 0.96;
  static const double maxOvershoot = 0.04;

  /// Items after this many enter together; a long list never waits.
  static const int maxStaggered = 8;
}

/// A critically under-damped spring as a curve. Damping ratio 0.8 overshoots
/// about 1.5%; the test holds it under [Motion.maxOvershoot].
class SpringCurve extends Curve {
  const SpringCurve({this.dampingRatio = 0.8, this.stiffness = 180});

  final double dampingRatio;
  final double stiffness;

  /// Seconds until the envelope falls under 0.1% of the travel.
  double get _settle =>
      -math.log(0.001) / (dampingRatio * math.sqrt(stiffness));

  @override
  double transformInternal(double t) {
    final spring = SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: stiffness,
      ratio: dampingRatio,
    );
    return SpringSimulation(spring, 0, 1, 0).x(t * _settle);
  }
}

/// The motion a widget may use here. Under reduce motion a movement becomes
/// a short fade, staggers vanish, loading spinners keep turning (they carry
/// meaning), and haptics still fire.
@immutable
class AppMotion {
  const AppMotion({required this.reduced});

  factory AppMotion.of(BuildContext context) =>
      AppMotion(reduced: MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  final bool reduced;

  /// Whether to translate, scale or rotate at all.
  bool get moves => !reduced;

  /// The time for a movement; under reduce motion, the fade that replaces
  /// it, never longer than the movement itself.
  Duration move(Duration full) => fade(full);

  /// A fade, at most [Motion.quick] under reduce motion.
  Duration fade(Duration full) =>
      reduced && full > Motion.quick ? Motion.quick : full;

  Duration stagger(int index) => reduced
      ? Duration.zero
      : Motion.stagger * math.min(index, Motion.maxStaggered);
}

extension AppMotionX on BuildContext {
  AppMotion get motion => AppMotion.of(this);
}
