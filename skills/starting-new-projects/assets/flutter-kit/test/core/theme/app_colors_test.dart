import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_palette.dart';

void main() {
  test('KIT-T8: AppColors lerps every role and copies one', () {
    final mid = AppPalette.light.lerp(AppPalette.dark, 0.5);
    expect(
      mid.background,
      Color.lerp(AppPalette.light.background, AppPalette.dark.background, 0.5),
    );
    expect(AppPalette.light.lerp(null, 0.5), same(AppPalette.light));
    final copy = AppPalette.light.copyWith(primary: Colors.black);
    expect(copy.primary, Colors.black);
    expect(copy.surface, AppPalette.light.surface);
  });

  testWidgets('KIT-T8: context.colors reads the extension, else the ambient '
      'brightness', (tester) async {
    late AppColors withExtension;
    late AppColors withoutExtension;
    await tester.pumpWidget(
      Column(
        textDirection: TextDirection.ltr,
        children: [
          Theme(
            data: ThemeData(extensions: [AppPalette.dark]),
            child: Builder(
              builder: (context) {
                withExtension = context.colors;
                return const SizedBox();
              },
            ),
          ),
          Theme(
            data: ThemeData(brightness: Brightness.dark),
            child: Builder(
              builder: (context) {
                withoutExtension = context.colors;
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
    expect(withExtension, same(AppPalette.dark));
    expect(withoutExtension, same(AppPalette.dark));
  });

  test('KIT-T8: AppColors lerps and copies the new roles', () {
    final mid = AppPalette.light.lerp(AppPalette.dark, 0.5);
    expect(
      mid.primaryInk,
      Color.lerp(AppPalette.light.primaryInk, AppPalette.dark.primaryInk, 0.5),
    );
    expect(
      mid.loaderBeam,
      Color.lerp(AppPalette.light.loaderBeam, AppPalette.dark.loaderBeam, 0.5),
    );
    final copy = AppPalette.dark.copyWith(glassRim: Colors.black);
    expect(copy.glassRim, Colors.black);
    expect(copy.onPrimaryInk, AppPalette.dark.onPrimaryInk);
    // primary is a fill, not text: it is not a text role, though a seed that
    // already reads as ink may share its value. The roles, exactly:
    for (final c in [AppPalette.light, AppPalette.dark]) {
      expect(c.textColors, [
        c.ink,
        c.inkMuted,
        c.hint,
        c.primaryInk,
        c.goldInk,
        c.danger,
        c.success,
        c.warning,
      ]);
    }
  });
}
