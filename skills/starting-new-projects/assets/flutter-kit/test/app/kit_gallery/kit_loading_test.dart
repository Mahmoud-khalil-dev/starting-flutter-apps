import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/kit_gallery/kit_foundations_section.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_screen.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_sections.dart';
import 'package:kit_app/app/kit_gallery/kit_loading_section.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_logo_loader.dart';
import 'package:kit_app/core/widgets/app_skeletons.dart';
import 'package:kit_app/core/widgets/app_state_view.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

final _clock = FixedClock(DateTime(2026, 11, 20, 9));

Future<void> _pumpSection(
  WidgetTester tester,
  KitSection section, {
  Brightness brightness = Brightness.light,
}) => pumpApp(
  tester,
  SingleChildScrollView(child: section.build(clock: _clock)),
  brightness: brightness,
  settle: false,
);

void main() {
  testWidgets('KIT-T11: the loading section shows skeletons and the loader', (
    tester,
  ) async {
    await pumpApp(tester, KitGalleryScreen(clock: _clock), settle: false);
    final section = find.byType(KitLoadingSection);
    await tester.scrollUntilVisible(
      section,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    Finder inSection(Type type) =>
        find.descendant(of: section, matching: find.byType(type));
    expect(inSection(AppSkeletonHeader), findsOneWidget);
    expect(inSection(AppSkeletonCard), findsOneWidget);
    expect(inSection(AppSkeletonList), findsOneWidget);
    expect(inSection(AppLogoLoader), findsOneWidget);
    final finish = find.text('Finish waiting');
    await tester.ensureVisible(finish);
    await tester.pump();
    await tester.tap(finish);
    await tester.pump(Motion.loaderMinShow);
    await tester.pump(Motion.standard);
    await tester.pump(Motion.standard);
    await tester.pump();
    expect(inSection(AppLogoLoader), findsNothing);
    // The loader's height left the page: Replay may be off screen, in
    // the cache or beyond it, so walk the gallery until it is built.
    final replay = find.text('Replay');
    final gallery = find.byType(Scrollable).first;
    for (var i = 0; i < 8 && replay.evaluate().isEmpty; i++) {
      await tester.drag(gallery, const Offset(0, 200));
      await tester.pump();
    }
    await tester.ensureVisible(replay);
    expect(replay, findsOneWidget);
    await tester.pump();
    await tester.tap(replay);
    await tester.pump();
    expect(inSection(AppLogoLoader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('KIT-T11: the skeleton screen says "Loading" once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpSection(tester, KitSection.loading);
    await tester.pump(Motion.slow);
    final label = l10nFor('en').loaderLabel;
    final live = find.semantics.byPredicate((node) {
      final data = node.getSemanticsData();
      return data.label == label && data.flagsCollection.isLiveRegion;
    });
    // The header, card and list are one region; the logo loader below them
    // is its own sample, and says it for itself.
    expect(live, findsExactly(2));
    semantics.dispose();
  });

  testWidgets('KIT-T11: the loader logo sits in a square ring', (tester) async {
    for (final brightness in Brightness.values) {
      await _pumpSection(tester, KitSection.loading, brightness: brightness);
      await tester.pump(Motion.slow);
      final ring = find.descendant(
        of: find.byType(AppLogoLoader),
        matching: find.byKey(AppLogoLoader.orbitKey),
      );
      expect(ring, findsOneWidget, reason: '$brightness');
      final size = tester.getSize(ring);
      expect(size.height, greaterThan(0), reason: '$brightness');
      expect(size.width, closeTo(size.height, 0.5), reason: '$brightness');
    }
  });

  testWidgets('KIT-T11: the contrast switch reaches the components', (
    tester,
  ) async {
    await pumpApp(tester, KitGalleryScreen(clock: _clock), settle: false);
    final foundations = find.byType(KitFoundationsSection);
    expect(MediaQuery.highContrastOf(tester.element(foundations)), isFalse);
    await tester.tap(find.text('Increase contrast'));
    await tester.pump();
    expect(MediaQuery.highContrastOf(tester.element(foundations)), isTrue);
  });

  testWidgets('KIT-T11: at 2x text the state frames hold their copy', (
    tester,
  ) async {
    await pumpApp(
      tester,
      SingleChildScrollView(child: KitSection.states.build(clock: _clock)),
      textScale: 2,
      settle: false,
    );
    await tester.pump(Motion.slow);
    expect(tester.takeException(), isNull);
    final frames = find.descendant(
      of: find.byType(KitSection.states.type),
      matching: find.byType(AppStateView),
    );
    expect(frames, findsNWidgets(ScreenStatus.values.length));
    final one = tester.getSize(frames.first).height;
    expect(one, greaterThan(AppDimensions.xxxl * 4 * 1.9));
  });
}
