import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_sections.dart';

import '../helpers/fixed_clock.dart';
import 'helpers/golden_fonts.dart';
import 'helpers/golden_frame.dart';

double _width(String family, String text) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: family, fontSize: 20),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

void main() {
  test('KIT-T11: the golden harness loads the SDK fonts', () async {
    // Does not lean on flutter_test_config: loads the fonts itself, and
    // proves the probe can tell a real face from the fallback.
    // Ahem, the test fallback, draws every glyph exactly fontSize wide.
    expect(_width('NoSuchFamily', 'Sample!'), closeTo(140, 0.5));
    await loadGoldenFonts();
    expect(_width('Roboto', 'Sample!'), isNot(closeTo(140, 0.5)));
  });

  test(
    'KIT-T11: the icon font path throws loudly when the font is missing',
    () {
      final empty = Directory.systemTemp.createTempSync('no_sdk');
      addTearDown(() => empty.deleteSync(recursive: true));
      expect(
        () => materialIconsPath(
          flutterRoot: empty.path,
          executable: '${empty.path}/bin/dart',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('MaterialIcons-Regular.otf not found'),
          ),
        ),
      );
    },
  );

  test('KIT-T11: the icon font path resolves in the real SDK', () {
    expect(File(materialIconsPath()).existsSync(), isTrue);
  });

  goldenTestWidgets('KIT-T11: goldens paint real, blurred shadows', (
    tester,
  ) async {
    expect(debugDisableShadows, isFalse);
  });

  testWidgets('KIT-T11: pumpGolden decodes asset images before the capture', (
    tester,
  ) async {
    await pumpGolden(
      tester,
      Image.asset('assets/images/logo.png', height: 32),
      language: 'en',
      brightness: Brightness.dark,
      size: const Size(390, 200),
    );
    final image = tester.renderObject<RenderImage>(find.byType(RawImage));
    expect(image.image, isNotNull, reason: 'the logo is drawn, not blank');
  });

  for (final section in KitSection.values.where((s) => s != KitSection.shell)) {
    for (final language in ['en', 'ar']) {
      testWidgets(
        'KIT-T11: the ${section.name} sheet in $language fits its frame',
        (tester) async {
          await pumpGoldenSheet(
            tester,
            section.build(clock: FixedClock(DateTime(2026, 11, 20, 9))),
            language: language,
            brightness: Brightness.light,
          );
          final sheet = tester.getRect(find.byKey(goldenSheetKey));
          final frame = tester.view.physicalSize / tester.view.devicePixelRatio;
          expect(
            sheet.bottom,
            lessThanOrEqualTo(frame.height),
            reason: 'clips',
          );
          expect(frame.height - sheet.bottom, lessThan(1), reason: 'tail');
        },
      );
    }
  }
}
