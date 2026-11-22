import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/widgets/app_system_overlay.dart';

import '../../helpers/pump_app.dart';

SystemUiOverlayStyle _style(WidgetTester tester) => tester
    .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.descendant(
        of: find.byType(AppSystemOverlay),
        matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      ),
    )
    .value;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('KIT-T16: the system bars suit the ${brightness.name} theme', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppSystemOverlay(child: SizedBox()),
        brightness: brightness,
      );
      final style = _style(tester);
      final dark = brightness == Brightness.dark;
      // Dark ground: light icons. Light ground: dark icons.
      expect(
        style.statusBarIconBrightness,
        dark ? Brightness.light : Brightness.dark,
      );
      expect(
        style.systemNavigationBarIconBrightness,
        dark ? Brightness.light : Brightness.dark,
      );
      // iOS names the bar's own brightness, the opposite of the icons.
      expect(style.statusBarBrightness, brightness);
      expect(style.statusBarColor, Colors.transparent);
      expect(
        style.systemNavigationBarColor,
        Theme.of(
          tester.element(find.byType(AppSystemOverlay)),
        ).scaffoldBackgroundColor,
      );
    });
  }
}
