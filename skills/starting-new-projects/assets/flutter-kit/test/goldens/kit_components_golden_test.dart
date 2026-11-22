@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_sections.dart';
import 'package:kit_app/core/theme/motion.dart';

import '../helpers/fixed_clock.dart';
import 'helpers/golden_frame.dart';

final _clock = FixedClock(DateTime(2026, 11, 20, 9));

const List<KitSection> _sheets = [
  KitSection.foundations,
  KitSection.actions,
  KitSection.lists,
  KitSection.feedback,
  KitSection.states,
  KitSection.loading,
];

void main() {
  for (final section in _sheets) {
    for (final language in ['en', 'ar']) {
      for (final brightness in Brightness.values) {
        final name = 'kit_${section.name}_${language}_${themeName(brightness)}';
        goldenTestWidgets('KIT-T11: $name', (tester) async {
          await pumpGoldenSheet(
            tester,
            section.build(clock: _clock),
            language: language,
            brightness: brightness,
          );
          if (section == KitSection.loading) {
            // The band and the beam move: freeze them a quarter lap in, on
            // the fake clock, so every run draws the same frame.
            await tester.pump(Motion.loaderDelay + Motion.loaderLap ~/ 4);
          }
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      }
    }
  }
}
