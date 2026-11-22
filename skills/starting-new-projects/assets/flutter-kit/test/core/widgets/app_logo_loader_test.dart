import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_logo_loader.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_logo.dart';

OrbitPainter _orbit(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(AppLogoLoader.orbitKey)).painter!
        as OrbitPainter;

/// The exit fade: the one FadeTransition above the mark inside the loader
/// (the long-wait line's AnimatedOpacity holds another).
double _exitOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(AppLogoLoader),
        matching: find.ancestor(
          of: find.byKey(AppLogoLoader.orbitKey),
          matching: find.byType(FadeTransition),
        ),
      ),
    )
    .opacity
    .value;

const _long = 'Still preparing this. Thank you for waiting.';

void main() {
  group('KIT-T11: AppLogoLoader', () {
    testWidgets('holds still 400 ms, then the beam fades in and laps', (
      tester,
    ) async {
      await pumpApp(tester, const AppLogoLoader(logo: testLogo), settle: false);
      await tester.pump(Motion.loaderDelay - Motion.stagger);
      expect(_orbit(tester).beam, 0);
      await tester.pump(Motion.stagger + Motion.quick);
      expect(_orbit(tester).beam, closeTo(1, 0.01));
      final head = _orbit(tester).head;
      await tester.pump(Motion.loaderLap ~/ 4);
      expect(_orbit(tester).head, isNot(closeTo(head, 0.01)));
      await tester.pump(Motion.loaderLap - Motion.loaderLap ~/ 4);
      expect(_orbit(tester).head, closeTo(head, 0.01), reason: 'one lap');
      expect(_orbit(tester).glow, isNull);
    });

    testWidgets('the head glides through the lap seam, never jumping back', (
      tester,
    ) async {
      await pumpApp(tester, const AppLogoLoader(logo: testLogo), settle: false);
      await tester.pump(Motion.loaderDelay);
      const frame = Duration(microseconds: 16667);
      var last = _orbit(tester).head;
      final steps = <double>[];
      for (var i = 0; i < 2 * 96; i++) {
        await tester.pump(frame);
        final head = _orbit(tester).head;
        steps.add((head - last) % 1);
        last = head;
      }
      // Forward only, and never faster than the sweep curve's own peak
      // pace, so the wrap at the top of the ring is not a jump.
      final dt = frame.inMicroseconds / Motion.loaderLap.inMicroseconds;
      var peak = 0.0;
      for (var t = 0.0; t + dt <= 1; t += dt / 4) {
        peak = math.max(
          peak,
          Motion.sweep.transform(t + dt) - Motion.sweep.transform(t),
        );
      }
      peak += 1e-3;
      for (final step in steps) {
        expect(step, inInclusiveRange(0, peak));
      }
    });

    testWidgets('stays its minimum, then fades and settles away', (
      tester,
    ) async {
      var exited = 0;
      final done = ValueNotifier(false);
      addTearDown(done.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder(
          valueListenable: done,
          builder: (context, d, _) =>
              AppLogoLoader(logo: testLogo, done: d, onExited: () => exited++),
        ),
        settle: false,
      );
      done.value = true;
      await tester.pump(Motion.instant);
      await tester.pump(Motion.loaderMinShow ~/ 2);
      expect(exited, 0);
      expect(_exitOpacity(tester), 1);
      await tester.pump(Motion.loaderMinShow);
      await tester.pump(Motion.standard);
      await tester.pump();
      expect(exited, 1);
    });

    testWidgets('reduce motion: a glow breathes on the ring, the exit fades', (
      tester,
    ) async {
      var exited = 0;
      final done = ValueNotifier(false);
      addTearDown(done.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder(
          valueListenable: done,
          builder: (context, d, _) =>
              AppLogoLoader(logo: testLogo, done: d, onExited: () => exited++),
        ),
        reduceMotion: true,
        settle: false,
      );
      await tester.pump(Motion.loaderDelay + Motion.quick);
      expect(_orbit(tester).beam, 0);
      final glows = <double>[];
      for (var i = 0; i < 8; i++) {
        await tester.pump(Motion.breathe ~/ 8);
        glows.add(_orbit(tester).glow!);
      }
      expect(
        glows.reduce((a, b) => a < b ? a : b),
        closeTo(Motion.loaderGlow, 0.05),
      );
      expect(glows.reduce((a, b) => a > b ? a : b), closeTo(1, 0.05));
      expect(
        find.descendant(
          of: find.byType(AppLogoLoader),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
      );
      done.value = true;
      await tester.pump();
      await tester.pump();
      await tester.pump(Motion.quick);
      await tester.pump();
      expect(_exitOpacity(tester), 0);
      expect(exited, 1);
    });

    testWidgets('reduce motion: the glow fades in, it never pops on', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppLogoLoader(logo: testLogo),
        reduceMotion: true,
        settle: false,
      );
      await tester.pump(Motion.loaderDelay);
      expect(_orbit(tester).glow, closeTo(0, 0.01));
      await tester.pump(Motion.quick ~/ 8);
      final early = _orbit(tester).glow!;
      expect(early, greaterThan(0));
      expect(early, lessThan(Motion.loaderGlow * 0.8));
      await tester.pump(Motion.quick);
      expect(_orbit(tester).glow, greaterThanOrEqualTo(Motion.loaderGlow));
    });

    for (final language in ['en', 'ar']) {
      testWidgets('at 2x text the mark stays put when the line arrives, '
          '$language', (tester) async {
        await pumpApp(
          tester,
          const AppLogoLoader(logo: testLogo),
          language: language,
          textScale: 2,
          settle: false,
        );
        await tester.pump(Motion.longWait - Motion.tick);
        final before = tester.getRect(find.byKey(AppLogoLoader.orbitKey));
        await tester.pump(Motion.tick);
        await tester.pump(Motion.gentle);
        expect(find.byType(Text), findsOneWidget);
        expect(tester.getRect(find.byKey(AppLogoLoader.orbitKey)), before);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('after a long wait, one quiet line that is not announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const AppLogoLoader(logo: testLogo), settle: false);
      await tester.pump(Motion.longWait - Motion.tick);
      expect(find.text(_long), findsNothing);
      await tester.pump(Motion.tick);
      await tester.pump(Motion.gentle);
      expect(find.text(_long), findsOneWidget);
      expect(find.bySemanticsLabel(_long), findsNothing);
      expect(
        tester.getSemantics(find.byType(AppLogoLoader)),
        matchesSemantics(label: 'Loading', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('full screen: centred on the background, both themes', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await pumpApp(
          tester,
          const AppLogoLoader(logo: testLogo),
          brightness: brightness,
          settle: false,
        );
        final palette = brightness == Brightness.light
            ? AppPalette.light
            : AppPalette.dark;
        final fill = tester.widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(AppLogoLoader),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(fill.color, palette.background);
        expect(_orbit(tester).color, palette.loaderBeam);
        expect(
          tester.getCenter(find.byKey(AppLogoLoader.orbitKey)).dx,
          closeTo(TestSizes.phone.width / 2, 0.5),
        );
      }
    });

    testWidgets('the beam never leaves the ring on a phone, tablet or web', (
      tester,
    ) async {
      for (final size in [TestSizes.phone, TestSizes.tablet, TestSizes.web]) {
        await pumpApp(
          tester,
          const AppLogoLoader(logo: testLogo),
          size: size,
          settle: false,
        );
        await tester.pump(Motion.loaderDelay + Motion.quick);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(AppLogoLoader.orbitKey)).height,
          AppDimensions.logoLoaderHeight,
        );
        // The beam repaints alone; the mark under it is not redrawn.
        expect(
          find.descendant(
            of: find.byType(AppLogoLoader),
            matching: find.ancestor(
              of: find.byKey(AppLogoLoader.orbitKey),
              matching: find.byType(RepaintBoundary),
            ),
          ),
          findsOneWidget,
        );
      }
    });
  });

  testWidgets('KIT-T11: the line is measured bold when bold text is on', (
    tester,
  ) async {
    final weights = <bool, FontWeight?>{};
    for (final bold in [false, true]) {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(boldText: bold),
            child: Builder(
              builder: (context) {
                weights[bold] = AppLogoLoader.lineStyle(context).fontWeight;
                return const SizedBox();
              },
            ),
          ),
        ),
        settle: false,
      );
    }
    // As Text itself does under MediaQuery.boldTextOf.
    expect(weights[true], FontWeight.bold);
    expect(weights[false], isNot(FontWeight.bold));
  });
}
