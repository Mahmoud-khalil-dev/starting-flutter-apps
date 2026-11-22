import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/widgets/app_row.dart';

import '../../helpers/pump_app.dart';

const _key = Key('switch-page');

/// The colour at [point] of the page, read from its pixels.
Future<Color> _pixel(WidgetTester tester, Offset point) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_key));
  final bytes = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    return image.toByteData();
  }))!;
  final width = boundary.size.width.toInt();
  final i = (point.dy.toInt() * width + point.dx.toInt()) * 4;
  return Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required bool on,
  required String language,
  required Brightness brightness,
}) => pumpApp(
  tester,
  RepaintBoundary(
    key: _key,
    child: ColoredBox(
      color: brightness == Brightness.dark
          ? AppPalette.dark.background
          : AppPalette.light.background,
      child: AppRow.toggle(title: 'Reminders', value: on, onChanged: (_) {}),
    ),
  ),
  language: language,
  brightness: brightness,
  platform: TargetPlatform.iOS,
  web: false,
);

bool _whiteish(Color c) => c.r > 0.95 && c.g > 0.95 && c.b > 0.95;

void main() {
  for (final brightness in Brightness.values) {
    final palette = brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    for (final language in ['en', 'ar']) {
      final name = '${brightness.name} $language';

      testWidgets('KIT-T11: the iOS switch names both track colours ($name)', (
        tester,
      ) async {
        await _pump(
          tester,
          on: true,
          language: language,
          brightness: brightness,
        );
        final s = tester.widget<Switch>(find.byType(Switch));
        expect(s.activeTrackColor, palette.primaryInk);
        expect(s.inactiveTrackColor, palette.outline);
      });

      testWidgets(
        'KIT-T11: the knob sits at the end when on and the start when off, '
        'flipped in Arabic ($name)',
        (tester) async {
          final rtl = language == 'ar';
          Rect rect() => tester.getRect(find.byType(Switch));
          for (final on in [true, false]) {
            await _pump(
              tester,
              on: on,
              language: language,
              brightness: brightness,
            );
            final r = rect();
            final left = Offset(r.left + 0.2 * r.width, r.center.dy);
            final right = Offset(r.left + 0.8 * r.width, r.center.dy);
            final knobOnRight = on != rtl;
            expect(
              _whiteish(await _pixel(tester, knobOnRight ? right : left)),
              isTrue,
              reason:
                  'on=$on rtl=$rtl: knob should be '
                  '${knobOnRight ? 'right' : 'left'}',
            );
            final trackSide = await _pixel(tester, knobOnRight ? left : right);
            expect(
              trackSide,
              on ? palette.primaryInk : palette.outline,
              reason: 'on=$on rtl=$rtl: the track shows its state colour',
            );
          }
        },
      );
    }
  }
}
