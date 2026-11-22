import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_shimmer.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('KIT-T11: AppShimmer sweeps from the start edge', (tester) async {
    for (final (language, forward) in [('en', true), ('ar', false)]) {
      await pumpApp(
        tester,
        const AppShimmer(child: AppSkeleton(height: 20)),
        language: language,
        settle: false,
      );
      final state = tester.state<AppShimmerState>(find.byType(AppShimmer));
      expect(state.sweepsForward, forward, reason: language);
    }
  });

  group('KIT-T11: AppShimmer', () {
    test('KIT-T11: sweeps for 75% of the period, then rests', () {
      expect(AppShimmerState.sweepAt(0), 0);
      expect(AppShimmerState.sweepAt(0.375), closeTo(0.5, 0.01));
      expect(AppShimmerState.sweepAt(0.75), closeTo(1, 0.001));
      expect(AppShimmerState.sweepAt(0.9), 1);
      // Eased, not linear: slower at the ends.
      expect(AppShimmerState.sweepAt(0.075), lessThan(0.1));
    });

    testWidgets('every shimmer on screen shares one phase', (tester) async {
      final second = ValueNotifier(false);
      await pumpApp(
        tester,
        ValueListenableBuilder(
          valueListenable: second,
          builder: (context, on, _) => Column(
            children: [
              const AppShimmer(child: AppSkeleton(height: 20)),
              if (on)
                const AppShimmer(
                  key: Key('late'),
                  child: AppSkeleton(height: 20),
                ),
            ],
          ),
        ),
        settle: false,
      );
      await tester.pump(Motion.shimmerPeriod * 0.3);
      second.value = true;
      await tester.pump();
      await tester.pump(Motion.stagger);
      final states = tester
          .stateList<AppShimmerState>(find.byType(AppShimmer))
          .toList();
      expect(states, hasLength(2));
      expect(states.first.phase, closeTo(states.last.phase, 0.001));
      expect(states.first.phase, greaterThan(0));
    });

    testWidgets('is one repaint boundary and one "Loading" node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const AppShimmer(
          child: Column(
            children: [AppSkeleton(height: 20), AppSkeleton(height: 20)],
          ),
        ),
        settle: false,
      );
      expect(
        find.descendant(
          of: find.byType(AppShimmer),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
      expect(
        tester.getSemantics(find.byType(AppShimmer)),
        matchesSemantics(label: 'Loading', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('a decorative shimmer says nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const AppShimmer(
          announce: false,
          synced: false,
          child: AppSkeleton(height: 20),
        ),
        settle: false,
      );
      expect(find.bySemanticsLabel('Loading'), findsNothing);
      handle.dispose();
    });

    test('the band is tilted, mirrors in Arabic and crosses the width', () {
      const bounds = Rect.fromLTWH(0, 0, 300, 60);
      final ltr = const ShimmerSweep(0.5, rtl: false).transform(bounds)!;
      final rtl = const ShimmerSweep(0.5, rtl: true).transform(bounds)!;
      // A rotation: the x axis picks up a y component, opposite in RTL.
      expect(ltr.entry(1, 0), closeTo(math.sin(Motion.shimmerTilt), 0.001));
      expect(rtl.entry(1, 0), closeTo(-math.sin(Motion.shimmerTilt), 0.001));
      // The gradient's centre line, mapped through the matrix, is the band.
      double centreX(ShimmerSweep sweep) => MatrixUtils.transformPoint(
        sweep.transform(bounds)!,
        bounds.center,
      ).dx;
      // Off the start edge at 0, off the end edge at 1; the band is 0.15 of
      // the width wide, so its centre must clear the edge by half of that.
      expect(centreX(const ShimmerSweep(0, rtl: false)), lessThan(0));
      expect(centreX(const ShimmerSweep(1, rtl: false)), greaterThan(300));
      expect(centreX(const ShimmerSweep(0, rtl: true)), greaterThan(300));
      expect(centreX(const ShimmerSweep(1, rtl: true)), lessThan(0));
      expect(
        centreX(const ShimmerSweep(0.5, rtl: false)),
        closeTo(bounds.center.dx, 0.001),
      );
    });

    testWidgets('reduce motion breathes 1.0 to 0.6 and never sweeps', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppShimmer(child: AppSkeleton(height: 20)),
        reduceMotion: true,
        settle: false,
      );
      expect(find.byType(ShaderMask), findsNothing);
      final seen = <double>[];
      for (var i = 0; i < 16; i++) {
        await tester.pump(Motion.breathe ~/ 16);
        seen.add(
          tester
              .widget<Opacity>(
                find.descendant(
                  of: find.byType(AppShimmer),
                  matching: find.byType(Opacity),
                ),
              )
              .opacity,
        );
      }
      expect(seen.reduce(math.min), closeTo(Motion.shimmerDim, 0.05));
      expect(seen.reduce(math.max), closeTo(1, 0.05));
      expect(tester.hasRunningAnimations, isTrue, reason: 'still alive');
    });
  });

  testWidgets('KIT-T11: AppSkeleton takes its size and radius', (tester) async {
    await pumpApp(
      tester,
      const Center(child: AppSkeleton(width: 120, height: 16, radius: 4)),
    );
    expect(tester.getSize(find.byType(AppSkeleton)), const Size(120, 16));
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(AppSkeleton),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (box.decoration as BoxDecoration).borderRadius,
      BorderRadius.circular(4),
    );
  });
}
