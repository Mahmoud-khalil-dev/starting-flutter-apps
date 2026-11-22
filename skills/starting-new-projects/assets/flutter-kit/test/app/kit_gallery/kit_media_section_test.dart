import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_sections.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/widgets/app_avatar.dart';
import 'package:kit_app/core/widgets/app_avatar_upload.dart';
import 'package:kit_app/core/widgets/app_network_image.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

Future<void> _pump(
  WidgetTester tester, {
  String language = 'en',
  Brightness brightness = Brightness.light,
}) => pumpApp(
  tester,
  SingleChildScrollView(
    child: KitSection.media.build(clock: FixedClock(DateTime(2026, 11, 20, 9))),
  ),
  language: language,
  brightness: brightness,
  settle: false,
);

void main() {
  testWidgets(
    'KIT-T18: the media section shows each upload state and the camera prompt',
    (
      tester,
    ) async {
      for (final language in ['en', 'ar']) {
        await _pump(tester, language: language);
        expect(find.byType(AppAvatarUpload), findsNWidgets(4));
        expect(find.byType(AppNetworkImage), findsOneWidget);
        expect(tester.takeException(), isNull, reason: language);
      }
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'KIT-T18: the avatar stands out from its card in ${brightness.name}',
      (tester) async {
        await _pump(tester, brightness: brightness);
        final colors = tester
            .element(find.byType(AppAvatarUpload).first)
            .colors;
        final avatar = tester.widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(AppAvatar).first,
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        final backdrop = tester.widget<ColoredBox>(
          find
              .ancestor(
                of: find.byType(AppAvatarUpload).first,
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(backdrop.color, colors.surface);
        expect(avatar.color, isNot(backdrop.color));
      },
    );
  }
}
