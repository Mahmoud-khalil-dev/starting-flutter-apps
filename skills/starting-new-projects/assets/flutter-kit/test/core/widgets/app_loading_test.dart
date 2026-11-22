import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/contrast.dart';
import 'package:kit_app/core/widgets/app_loading.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('KIT-T10: AppLoading is the platform spinner and announced', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, const AppLoading(), settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await pumpApp(
      tester,
      const AppLoading(),
      platform: TargetPlatform.iOS,
      settle: false,
    );
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'KIT-T10: the iOS spinner reads on raised surfaces in both themes',
    (tester) async {
      for (final brightness in Brightness.values) {
        await pumpApp(
          tester,
          const AppLoading(),
          platform: TargetPlatform.iOS,
          brightness: brightness,
          settle: false,
        );
        final c = AppPalette.forBrightness(brightness);
        final color = tester
            .widget<CupertinoActivityIndicator>(
              find.byType(CupertinoActivityIndicator),
            )
            .color;
        expect(color, c.inkMuted, reason: brightness.name);
        expect(
          contrastRatio(color!, c.surfaceRaised),
          greaterThanOrEqualTo(3),
          reason: brightness.name,
        );
      }
    },
  );
}
