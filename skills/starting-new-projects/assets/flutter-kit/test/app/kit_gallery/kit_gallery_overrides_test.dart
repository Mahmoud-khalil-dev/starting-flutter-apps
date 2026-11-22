import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_screen.dart';
import 'package:kit_app/core/theme/motion.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

final _clock = FixedClock(DateTime(2026, 11, 20, 9));

void main() {
  group('KIT-T11: the gallery switches reach what opens above the page', () {
    // A sheet, a picker and a dialog open on a navigator; the gallery's
    // switches must govern them as they govern the page.
    Future<void> setUpGallery(WidgetTester tester, {required Size size}) async {
      await pumpApp(
        tester,
        KitGalleryScreen(clock: _clock),
        size: size,
        settle: false,
      );
      await tester.pump(Motion.slow);
      await tester.tap(find.text('Dark'));
      await tester.tap(find.text('200%'));
      await tester.tap(find.text('Increase contrast'));
      await tester.tap(find.text('Reduce motion'));
      await tester.pump(Motion.slow);
    }

    Future<void> openFrom(WidgetTester tester, String label) async {
      final button = find.text(label);
      await tester.scrollUntilVisible(
        button,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(button);
      await tester.pump(Motion.slow);
      await tester.pump(Motion.slow);
    }

    void expectOverridden(WidgetTester tester, Finder inside) {
      final context = tester.element(inside);
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(MediaQuery.textScalerOf(context).scale(10), 20);
      expect(MediaQuery.highContrastOf(context), isTrue);
      expect(MediaQuery.disableAnimationsOf(context), isTrue);
    }

    testWidgets('a sheet on a phone', (tester) async {
      await setUpGallery(tester, size: TestSizes.phone);
      await openFrom(tester, 'Sheet');
      expectOverridden(tester, find.text('Weekly plan'));
    });

    testWidgets('a picker on a phone', (tester) async {
      await setUpGallery(tester, size: TestSizes.phone);
      await openFrom(tester, 'Picker');
      expectOverridden(tester, find.text('English').last);
    });

    testWidgets('a sheet on the web, which opens as a dialog', (tester) async {
      await setUpGallery(tester, size: TestSizes.web);
      await openFrom(tester, 'Sheet');
      expectOverridden(tester, find.text('Weekly plan'));
    });

    testWidgets('a confirmation dialog', (tester) async {
      await setUpGallery(tester, size: TestSizes.phone);
      await openFrom(tester, 'Dialog');
      expectOverridden(tester, find.text('Delete this draft?'));
    });

    testWidgets('the language reaches a sheet', (tester) async {
      await setUpGallery(tester, size: TestSizes.phone);
      await tester.tap(find.text('العربية'));
      await tester.pump(Motion.slow);
      await openFrom(tester, 'لوحة');
      final context = tester.element(find.text('خطة الأسبوع'));
      expect(Localizations.localeOf(context).languageCode, 'ar');
    });
  });
}
