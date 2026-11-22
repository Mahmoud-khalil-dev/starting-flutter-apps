import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/motion.dart';

import '../../helpers/pump_app.dart';

/// A kit sheet is a phone-width page as tall as its section.
const double goldenSheetWidth = 390;

/// The key of the sheet [pumpGoldenSheet] measures.
const goldenSheetKey = Key('sheet');

/// A golden test that paints shadows as the app does. flutter_test draws
/// every shadow as a hard, unblurred slab by default (`debugDisableShadows`);
/// the flag is restored inside the test, before the binding checks it.
void goldenTestWidgets(String description, WidgetTesterCallback body) =>
    testWidgets(description, (tester) async {
      debugDisableShadows = false;
      try {
        await body(tester);
      } finally {
        debugDisableShadows = true;
      }
    });

/// Pumps [child] like the app (theme, fonts, language) and lets every
/// entrance finish. Never settles: shimmer and countdowns run forever.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  required String language,
  required Brightness brightness,
  required Size size,
  TargetPlatform? platform,
  bool? web,
  bool highContrast = false,
}) async {
  await pumpApp(
    tester,
    child,
    language: language,
    brightness: brightness,
    size: size,
    platform: platform,
    web: web,
    highContrast: highContrast,
    settle: false,
  );
  await _finish(tester);
}

/// Lets every entrance finish, then decodes the asset images.
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(Motion.slow);
  await tester.pump(Motion.slow);
  // 1400 ms is just past the spinner's 1333 ms cycle, where its arc is a
  // speck. 2000 ms freezes it mid-sweep, so the loading state is visible.
  await tester.pump(const Duration(milliseconds: 600));
  await _decodeAssetImages(tester);
}

/// Asset images load on real I/O, which fake time never waits for, so a
/// capture could show an empty plate. Decodes each one, then repaints.
Future<void> _decodeAssetImages(WidgetTester tester) async {
  final images = [
    for (final element in find.byType(Image).evaluate())
      if ((element.widget as Image).image case final AssetImage asset)
        (asset, element),
  ];
  if (images.isEmpty) return;
  await tester.runAsync(() async {
    for (final (asset, element) in images) {
      await precacheImage(asset, element);
    }
  });
  await tester.pump();
}

/// Pumps a kit section as a sheet: laid out at phone width, then the
/// window is fitted to the section's height, so nothing clips at the bottom
/// and no empty page trails under it.
Future<void> pumpGoldenSheet(
  WidgetTester tester,
  Widget section, {
  required String language,
  required Brightness brightness,
}) async {
  await pumpApp(
    tester,
    SingleChildScrollView(
      child: RepaintBoundary(key: goldenSheetKey, child: section),
    ),
    language: language,
    brightness: brightness,
    size: const Size(goldenSheetWidth, _measureHeight),
    settle: false,
  );
  final height = tester.getSize(find.byKey(goldenSheetKey)).height;
  tester.view.physicalSize = Size(goldenSheetWidth, height.ceilToDouble());
  await _finish(tester);
}

/// Tall enough for any section, so the first pass measures it unclipped.
const double _measureHeight = 4000;

String themeName(Brightness b) => b == Brightness.light ? 'light' : 'dark';
