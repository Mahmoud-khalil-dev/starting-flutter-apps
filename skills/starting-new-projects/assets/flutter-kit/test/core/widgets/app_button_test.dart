import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/contrast.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_button.dart';

import '../../helpers/haptics.dart';
import '../../helpers/pump_app.dart';

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration!
        as BoxDecoration;

void main() {
  testWidgets('KIT-T10: variants paint from the palette', (tester) async {
    for (final (variant, fill) in [
      (AppButtonVariant.primary, AppPalette.light.primary),
      (AppButtonVariant.destructive, AppPalette.light.danger),
      (AppButtonVariant.secondary, AppPalette.light.surface),
    ]) {
      await pumpApp(
        tester,
        AppButton(label: 'Confirm', onPressed: () {}, variant: variant),
      );
      expect(_decoration(tester).color, fill, reason: '$variant');
    }
  });

  testWidgets(
    'KIT-T10: loading shows a spinner, ignores taps and is announced',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await pumpApp(
        tester,
        AppButton(
          label: 'Confirm',
          onPressed: () => taps++,
          state: AppButtonState.loading,
        ),
        settle: false,
      );
      await tester.pump(Motion.quick);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      expect(taps, 0);
      semantics.dispose();
    },
  );

  testWidgets('KIT-T10: success shows a check', (tester) async {
    await pumpApp(
      tester,
      AppButton(
        label: 'Confirm',
        onPressed: () {},
        state: AppButtonState.success,
      ),
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
  });

  testWidgets('KIT-T10: no callback means disabled', (tester) async {
    await pumpApp(tester, const AppButton(label: 'Confirm', onPressed: null));
    expect(_decoration(tester).color, AppPalette.light.surfaceRaised);
    expect(_decoration(tester).boxShadow, isEmpty);
  });

  testWidgets('KIT-T10: a tap calls back with a light haptic', (tester) async {
    final haptics = recordHaptics(tester);
    var taps = 0;
    await pumpApp(tester, AppButton(label: 'Confirm', onPressed: () => taps++));
    await tester.tap(find.text('Confirm'));
    expect(taps, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('KIT-T10: only primary presses buzz', (tester) async {
    for (final variant in AppButtonVariant.values) {
      final haptics = recordHaptics(tester);
      var taps = 0;
      await pumpApp(
        tester,
        AppButton(label: 'Go', variant: variant, onPressed: () => taps++),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 1, reason: '$variant');
      final buzzes = variant == AppButtonVariant.primary;
      expect(
        haptics,
        buzzes ? ['HapticFeedbackType.lightImpact'] : isEmpty,
        reason: '$variant',
      );
    }
  });

  testWidgets('KIT-T10: the target stays at least 48 at every scale', (
    tester,
  ) async {
    for (final (width, scale) in [(320.0, 1.0), (320.0, 2.0), (1440.0, 1.0)]) {
      await pumpApp(
        tester,
        Center(
          child: AppButton(label: 'OK', onPressed: () {}),
        ),
        size: Size(width, 800),
        textScale: scale,
      );
      final size = tester.getSize(find.byType(AnimatedContainer));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('KIT-T10: the icon sits at the start in both directions', (
    tester,
  ) async {
    for (final (language, iconFirst) in [('en', true), ('ar', false)]) {
      await pumpApp(
        tester,
        Center(
          child: AppButton(label: 'Call', icon: Icons.call, onPressed: () {}),
        ),
        language: language,
      );
      final icon = tester.getCenter(find.byIcon(Icons.call)).dx;
      final label = tester.getCenter(find.text('Call')).dx;
      expect(icon < label, iconFirst, reason: language);
    }
  });

  testWidgets('KIT-T10: a disabled button is announced as disabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, const AppButton(label: 'Confirm', onPressed: null));
    expect(
      tester.getSemantics(find.byType(AppButton)),
      isSemantics(label: 'Confirm', isButton: true, hasEnabledState: true),
    );
    semantics.dispose();
  });

  testWidgets('KIT-T10: a long label wraps at 320 wide, never truncates', (
    tester,
  ) async {
    const label = 'Confirm the plan and continue to the summary now';
    await pumpApp(
      tester,
      Center(
        child: AppButton(label: label, onPressed: () {}),
      ),
      size: const Size(320, 800),
    );
    final text = tester.widget<Text>(find.text(label));
    expect(text.overflow, isNull);
    expect(tester.getSize(find.text(label)).height, greaterThan(24));
    expect(
      tester.getSize(find.byType(AnimatedContainer)).width,
      lessThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('KIT-T10: dark destructive is quiet: danger outline on surface', (
    tester,
  ) async {
    final c = AppPalette.dark;
    await pumpApp(
      tester,
      AppButton(
        label: 'Cancel',
        onPressed: () {},
        variant: AppButtonVariant.destructive,
      ),
      brightness: Brightness.dark,
    );
    final d = _decoration(tester);
    final ink = tester.widget<Text>(find.text('Cancel')).style!.color!;
    expect(d.color, c.surface, reason: 'no pastel slab on a dark ground');
    expect((d.border! as Border).top.color, c.danger);
    expect(ink, c.danger);
    expect(contrastRatio(ink, d.color!), greaterThanOrEqualTo(4.5));
  });
}
