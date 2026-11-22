import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/press_scale.dart';

import '../../helpers/pump_app.dart';

Widget _subject({bool enabled = true}) => PressScale(
  enabled: enabled,
  builder: (_, {required pressed}) => Text(pressed ? 'down' : 'up'),
);

void main() {
  testWidgets('KIT-T10: a press scales to 0.97 and back', (tester) async {
    await pumpApp(tester, Center(child: _subject()));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('up')),
    );
    await tester.pump(Motion.instant);
    expect(find.text('down'), findsOneWidget);
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      Motion.pressScale,
    );
    await gesture.up();
    await tester.pump(Motion.instant);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('KIT-T10: under reduce motion a press dims instead', (
    tester,
  ) async {
    await pumpApp(tester, Center(child: _subject()), reduceMotion: true);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('up')),
    );
    await tester.pump(Motion.instant);
    expect(find.byType(AnimatedScale), findsNothing);
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      lessThan(1),
    );
    await gesture.up();
  });

  testWidgets('KIT-T10: a disabled press does nothing', (tester) async {
    await pumpApp(tester, Center(child: _subject(enabled: false)));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('up')),
    );
    await tester.pump(Motion.instant);
    expect(find.text('up'), findsOneWidget);
    await gesture.up();
  });

  testWidgets('KIT-T10: a cancelled press resets', (tester) async {
    await pumpApp(tester, Center(child: _subject()));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('up')),
    );
    await tester.pump(Motion.instant);
    expect(find.text('down'), findsOneWidget);
    await gesture.cancel();
    await tester.pump(Motion.instant);
    expect(find.text('up'), findsOneWidget);
  });

  testWidgets('KIT-T10: disabling mid-press resets and stays reset', (
    tester,
  ) async {
    final enabled = ValueNotifier<bool>(true);
    await pumpApp(
      tester,
      ValueListenableBuilder<bool>(
        valueListenable: enabled,
        builder: (_, on, _) => Center(child: _subject(enabled: on)),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('up')),
    );
    await tester.pump(Motion.instant);
    expect(find.text('down'), findsOneWidget);
    enabled.value = false;
    await tester.pump();
    enabled.value = true;
    await tester.pump(Motion.instant);
    expect(find.text('up'), findsOneWidget);
    await gesture.up();
  });
}
