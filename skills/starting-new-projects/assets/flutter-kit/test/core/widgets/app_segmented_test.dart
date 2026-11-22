import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/contrast.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_segmented.dart';

import '../../helpers/haptics.dart';
import '../../helpers/pump_app.dart';

Widget _subject(ValueNotifier<int> selected) => ValueListenableBuilder<int>(
  valueListenable: selected,
  builder: (_, value, _) => AppSegmented<int>(
    segments: const [
      AppSegment(value: 0, label: 'Upcoming'),
      AppSegment(value: 1, label: 'Past'),
    ],
    selected: value,
    onChanged: (v) => selected.value = v,
  ),
);

void main() {
  testWidgets('KIT-T11: tapping selects with a selection haptic', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    final selected = ValueNotifier(0);
    await pumpApp(tester, _subject(selected));
    await tester.tap(find.text('Past'));
    expect(selected.value, 1);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  testWidgets('KIT-T11: the pill glides with the spring', (tester) async {
    final selected = ValueNotifier(0);
    await pumpApp(tester, _subject(selected));
    final align = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
    expect(align.curve, Motion.spring);
    expect(align.duration, Motion.standard);
  });

  testWidgets('KIT-T11: under reduce motion the pill jumps', (tester) async {
    final selected = ValueNotifier(0);
    await pumpApp(tester, _subject(selected), reduceMotion: true);
    expect(
      tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).duration,
      Duration.zero,
    );
  });

  testWidgets('KIT-T11: a selected value outside the segments asserts', (
    tester,
  ) async {
    await pumpApp(tester, _subject(ValueNotifier(7)), settle: false);
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('KIT-T11: the selected pill stands 3:1 off the track', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await pumpApp(tester, _subject(ValueNotifier(0)), brightness: brightness);
      final track =
          (tester.widget<Container>(find.byType(Container).first).decoration!
                  as BoxDecoration)
              .color!;
      final pill =
          (tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byType(AnimatedAlign),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color!;
      Color ink(String label) =>
          tester.widget<Text>(find.text(label)).style!.color!;
      final why = brightness.name;
      expect(contrastRatio(pill, track), greaterThanOrEqualTo(3), reason: why);
      expect(
        contrastRatio(ink('Upcoming'), pill),
        greaterThanOrEqualTo(4.5),
        reason: why,
      );
      expect(
        contrastRatio(ink('Past'), track),
        greaterThanOrEqualTo(4.5),
        reason: why,
      );
    }
  });

  testWidgets('KIT-T11: the whole 48-high cell takes the tap, edge to edge', (
    tester,
  ) async {
    final selected = ValueNotifier(0);
    await pumpApp(tester, Column(children: [_subject(selected)]));
    final track = tester.getRect(find.byType(AppSegmented<int>));
    expect(track.height, greaterThanOrEqualTo(AppDimensions.touchTarget));
    final past = tester.getCenter(find.text('Past'));
    await tester.tapAt(Offset(past.dx, track.top + 1));
    await tester.pump();
    expect(selected.value, 1);
    final upcoming = tester.getCenter(find.text('Upcoming'));
    await tester.tapAt(Offset(upcoming.dx, track.bottom - 1));
    await tester.pump();
    expect(selected.value, 0);
    await tester.tapAt(Offset(track.right - 1, track.center.dy));
    await tester.pump();
    expect(selected.value, 1);
  });

  testWidgets('KIT-T11: the selected segment is not announced as disabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, Column(children: [_subject(ValueNotifier(0))]));
    expect(
      tester.getSemantics(find.text('Upcoming')),
      isSemantics(
        label: 'Upcoming',
        isButton: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });
}
