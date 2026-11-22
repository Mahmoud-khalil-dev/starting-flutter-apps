import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/utils/responsive.dart';

import '../../helpers/pump_app.dart';

Widget _layout({bool withMedium = true, bool withExpanded = true}) =>
    AdaptiveLayout(
      compact: (_) => const Text('compact'),
      medium: withMedium ? (_) => const Text('medium') : null,
      expanded: withExpanded ? (_) => const Text('expanded') : null,
    );

void main() {
  test('KIT-T8: window classes break at 600 and 1024', () {
    expect(WindowClass.forWidth(599.9), WindowClass.compact);
    expect(WindowClass.forWidth(600), WindowClass.medium);
    expect(WindowClass.forWidth(1023.9), WindowClass.medium);
    expect(WindowClass.forWidth(1024), WindowClass.expanded);
  });

  testWidgets('KIT-T8: AdaptiveLayout picks the layout for the window', (
    tester,
  ) async {
    await pumpApp(tester, _layout());
    expect(find.text('compact'), findsOneWidget);
    await pumpApp(tester, _layout(), size: TestSizes.tablet);
    expect(find.text('medium'), findsOneWidget);
    await pumpApp(tester, _layout(), size: TestSizes.web);
    expect(find.text('expanded'), findsOneWidget);
  });

  testWidgets('KIT-T8: a missing layout falls back to the next smaller one', (
    tester,
  ) async {
    await pumpApp(tester, _layout(withExpanded: false), size: TestSizes.web);
    expect(find.text('medium'), findsOneWidget);
    await pumpApp(
      tester,
      _layout(withMedium: false, withExpanded: false),
      size: TestSizes.web,
    );
    expect(find.text('compact'), findsOneWidget);
  });

  testWidgets('KIT-T8: rotating the window rebuilds the layout', (
    tester,
  ) async {
    await pumpApp(tester, _layout(), size: const Size(844, 390));
    expect(find.text('medium'), findsOneWidget);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.text('compact'), findsOneWidget);
  });

  test('KIT-T8: the scale is clamped by width and 1.0 from 600 wide', () {
    expect(ResponsiveScale.forWidth(300), 0.85);
    expect(ResponsiveScale.forWidth(375), 1);
    expect(ResponsiveScale.forWidth(450), closeTo(1.2, 0.001));
    expect(ResponsiveScale.forWidth(599), 1.4);
    expect(ResponsiveScale.forWidth(600), 1);
    expect(ResponsiveScale.forWidth(1440), 1);
  });

  testWidgets('KIT-T8: rotation rescales and targets never scale', (
    tester,
  ) async {
    late double scale;
    late double illustration;
    final probe = Builder(
      builder: (context) {
        scale = context.uiScale;
        illustration = context.scaled(100);
        return const Align(
          child: SizedBox(
            width: AppDimensions.touchTarget,
            height: AppDimensions.touchTarget,
            key: Key('target'),
          ),
        );
      },
    );
    await pumpApp(tester, probe, size: const Size(450, 900));
    expect(scale, closeTo(1.2, 0.001));
    expect(illustration, closeTo(120, 0.001));
    expect(tester.getSize(find.byKey(const Key('target'))).height, 48);
    tester.view.physicalSize = const Size(900, 450);
    await tester.pumpAndSettle();
    expect(scale, 1);
  });

  testWidgets('KIT-T8: touch targets stay 48 while the scale is not 1', (
    tester,
  ) async {
    late double scale;
    late double target;
    final probe = Builder(
      builder: (context) {
        scale = context.uiScale;
        target = AppDimensions.touchTarget;
        return const SizedBox();
      },
    );
    for (final size in const [Size(300, 600), Size(599, 900)]) {
      await pumpApp(tester, probe, size: size);
      expect(scale, isNot(1));
      expect(target, 48);
    }
    tester.view.physicalSize = const Size(450, 900);
    await tester.pumpAndSettle();
    expect(scale, closeTo(1.2, 0.001));
    expect(target, 48);
    tester.view.physicalSize = const Size(900, 450);
    await tester.pumpAndSettle();
    expect(scale, 1);
    expect(target, 48);
  });
}
