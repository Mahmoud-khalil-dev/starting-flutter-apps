import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/motion.dart';

void main() {
  test('KIT-T8: motion tokens hold the spec values', () {
    expect(Motion.instant, const Duration(milliseconds: 100));
    expect(Motion.quick, const Duration(milliseconds: 200));
    expect(Motion.standard, const Duration(milliseconds: 320));
    expect(Motion.gentle, const Duration(milliseconds: 480));
    expect(Motion.slow, const Duration(milliseconds: 700));
    expect(Motion.stagger, const Duration(milliseconds: 40));
    expect(Motion.enter, Curves.easeOutCubic);
    expect(Motion.exit, Curves.easeInCubic);
    expect(Motion.pressScale, 0.97);
    expect(Motion.dialogScale, 0.96);
  });

  test('KIT-T8: the spring overshoots at most 4% and ends at 1', () {
    var peak = 0.0;
    for (var i = 1; i < 1000; i++) {
      final v = Motion.spring.transform(i / 1000);
      if (v > peak) peak = v;
    }
    expect(peak, greaterThan(1));
    expect(peak, lessThanOrEqualTo(1 + Motion.maxOvershoot));
    expect(Motion.spring.transform(0), 0);
    expect(Motion.spring.transform(1), 1);
    expect(Motion.spring.transform(0.999), closeTo(1, 0.01));
  });

  test('KIT-T8: movement becomes a short fade under reduce motion', () {
    const full = AppMotion(reduced: false);
    const reduced = AppMotion(reduced: true);
    expect(full.moves, isTrue);
    expect(full.move(Motion.gentle), Motion.gentle);
    expect(reduced.moves, isFalse);
    expect(reduced.move(Motion.gentle), Motion.quick);
    expect(reduced.fade(Motion.instant), Motion.instant);
    expect(reduced.fade(Motion.slow), Motion.quick);
    expect(full.stagger(3), const Duration(milliseconds: 120));
    expect(full.stagger(20), Motion.stagger * Motion.maxStaggered);
    expect(reduced.stagger(3), Duration.zero);
  });

  testWidgets('KIT-T8: context.motion reads disableAnimations', (tester) async {
    late AppMotion motion;
    Widget probe({required bool disable}) => MediaQuery(
      data: MediaQueryData(disableAnimations: disable),
      child: Builder(
        builder: (context) {
          motion = context.motion;
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(probe(disable: false));
    expect(motion.reduced, isFalse);
    await tester.pumpWidget(probe(disable: true));
    expect(motion.reduced, isTrue);
  });

  test('KIT-T8: under reduce motion a move never outlasts the full one', () {
    const reduced = AppMotion(reduced: true);
    expect(reduced.move(Motion.instant), Motion.instant);
    expect(reduced.move(Duration.zero), Duration.zero);
    expect(reduced.move(Motion.quick), Motion.quick);
    expect(reduced.move(Motion.gentle), Motion.quick);
  });

  test('KIT-T8: shimmer tokens', () {
    expect(Motion.shimmerPeriod, const Duration(milliseconds: 1600));
    expect(Motion.breathe, Motion.shimmerPeriod * 2);
    expect(Motion.shimmerSweepShare, 0.75);
    expect(Motion.shimmerTilt, closeTo(20 * math.pi / 180, 1e-9));
    expect(Motion.shimmerDim, 0.6);
    expect(Motion.sweep.transform(0.5), closeTo(0.5, 0.01));
  });

  test('KIT-T8: loader tokens', () {
    expect(Motion.loaderDelay, const Duration(milliseconds: 400));
    expect(Motion.loaderLap, const Duration(milliseconds: 1600));
    expect(Motion.loaderMinShow, Motion.slow);
    expect(Motion.loaderGlow, 0.5);
    expect(Motion.longWait, const Duration(seconds: 5));
  });

  test('KIT-T8: the lens edges share one travel time a stagger apart', () {
    expect(Motion.lensTravel, Motion.standard + Motion.stagger);
    expect(Motion.lensLead.transform(0), 0);
    expect(Motion.lensTrail.transform(0.05), 0);
    expect(Motion.lensLead.transform(1), closeTo(1, 0.001));
    expect(Motion.lensTrail.transform(1), closeTo(1, 0.001));
    // The leading edge is ahead until it first arrives; the spring then
    // overshoots a little, so the trailing edge may pass it after that.
    var arrived = false;
    for (var t = 0.05; t < 1; t += 0.05) {
      final lead = Motion.lensLead.transform(t);
      if (lead >= 1) arrived = true;
      if (arrived) break;
      expect(lead, greaterThanOrEqualTo(Motion.lensTrail.transform(t)));
    }
    expect(arrived, isTrue);
  });

  test('KIT-T8: loading waits a quick beat and shows a gentle one', () {
    expect(Motion.loadingDelay, const Duration(milliseconds: 200));
    expect(Motion.loadingMinShow, const Duration(milliseconds: 480));
  });

  test('KIT-T8: the lens lifts by 6%', () => expect(Motion.lensLift, 1.06));

  test('KIT-T8: the logo mark turns once a beam lap, slowly', () {
    expect(Motion.leafTurn, Motion.loaderLap);
    expect(
      Motion.leafTurn.inMilliseconds,
      inInclusiveRange(1200, 2400),
      reason: 'one turn a lap only while the lap is 1.2 to 2.4 s',
    );
  });
}
