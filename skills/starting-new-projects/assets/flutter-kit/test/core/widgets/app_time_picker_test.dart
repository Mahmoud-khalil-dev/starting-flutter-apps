import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';
import 'package:kit_app/core/widgets/app_time_picker.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 11, 20, 10, 30));

  test('KIT-T11: a time at or before now is past', () {
    final now = clock.now();
    expect(isPastToday(const TimeOfDay(hour: 10, minute: 30), now), isTrue);
    expect(isPastToday(const TimeOfDay(hour: 9, minute: 0), now), isTrue);
    expect(isPastToday(const TimeOfDay(hour: 10, minute: 31), now), isFalse);
  });

  Widget subject({
    required TimeOfDay picked,
    required bool isToday,
    required void Function(TimeOfDay?) onChanged,
  }) {
    TimeOfDay? value;
    return StatefulBuilder(
      builder: (context, setState) => AppTimePicker(
        label: 'Time',
        value: value,
        isToday: isToday,
        clock: clock,
        pick: (_, _) async => picked,
        onChanged: (v) {
          onChanged(v);
          setState(() => value = v);
        },
      ),
    );
  }

  testWidgets('KIT-T11: the default pick opens the platform picker', (
    tester,
  ) async {
    for (final (platform, type) in [
      (TargetPlatform.android, TimePickerDialog),
      (TargetPlatform.iOS, CupertinoDatePicker),
    ]) {
      await pumpApp(
        tester,
        AppTimePicker(label: 'Time', value: null, onChanged: (_) {}),
        platform: platform,
      );
      await tester.tap(find.byType(AppTextField));
      await tester.pumpAndSettle();
      expect(find.byType(type), findsOneWidget, reason: '$platform');
    }
  });

  testWidgets('KIT-T11: a future time is shown in Arabic-Indic and passed on', (
    tester,
  ) async {
    TimeOfDay? changed;
    await pumpApp(
      tester,
      subject(
        picked: const TimeOfDay(hour: 11, minute: 15),
        isToday: true,
        onChanged: (v) => changed = v,
      ),
      language: 'ar',
    );
    await tester.tap(find.byType(AppTextField));
    await tester.pumpAndSettle();
    expect(changed, const TimeOfDay(hour: 11, minute: 15));
    expect(find.textContaining('١١:١٥'), findsOneWidget);
  });

  testWidgets('KIT-T11: a past time today is rejected with the error', (
    tester,
  ) async {
    final changes = <TimeOfDay?>[];
    await pumpApp(
      tester,
      subject(
        picked: const TimeOfDay(hour: 9, minute: 0),
        isToday: true,
        onChanged: changes.add,
      ),
    );
    await tester.tap(find.byType(AppTextField));
    await tester.pump();
    expect(changes, [null]);
    expect(find.text('Please choose a time later than now.'), findsOneWidget);
    final field = tester.widget<AppTextField>(find.byType(AppTextField));
    expect(field.errorText, isNotNull, reason: 'the field shakes on it');
  });

  testWidgets('KIT-T11: a valid pick clears the error', (tester) async {
    var picked = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay? value;
    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => AppTimePicker(
          label: 'Time',
          value: value,
          isToday: true,
          clock: clock,
          pick: (_, _) async => picked,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    await tester.tap(find.byType(AppTextField));
    await tester.pumpAndSettle();
    picked = const TimeOfDay(hour: 12, minute: 0);
    await tester.tap(find.byType(AppTextField));
    await tester.pumpAndSettle();
    expect(find.text('Please choose a time later than now.'), findsNothing);
    expect(value, const TimeOfDay(hour: 12, minute: 0));
  });

  testWidgets('KIT-T11: on another day a past time is accepted', (
    tester,
  ) async {
    TimeOfDay? changed;
    await pumpApp(
      tester,
      subject(
        picked: const TimeOfDay(hour: 9, minute: 0),
        isToday: false,
        onChanged: (v) => changed = v,
      ),
    );
    await tester.tap(find.byType(AppTextField));
    await tester.pumpAndSettle();
    expect(changed, const TimeOfDay(hour: 9, minute: 0));
  });

  testWidgets('KIT-T11: the iOS wheel follows the 12 or 24 hour setting', (
    tester,
  ) async {
    for (final use24 in [true, false]) {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = use24;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await pumpApp(
        tester,
        AppTimePicker(label: 'Time', value: null, onChanged: (_) {}),
        platform: TargetPlatform.iOS,
      );
      await tester.tap(find.byType(AppTextField));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
            .use24hFormat,
        use24,
      );
      await tester.tapAt(const Offset(195, 20));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('KIT-T11: cancelling the time pick changes nothing', (
    tester,
  ) async {
    var calls = 0;
    await pumpApp(
      tester,
      AppTimePicker(
        label: 'Time',
        value: null,
        clock: clock,
        pick: (_, _) async => null,
        onChanged: (_) => calls++,
      ),
    );
    await tester.tap(find.byType(AppTextField));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets('KIT-T11: two quick taps open one time picker', (tester) async {
    var opened = 0;
    final gate = Completer<TimeOfDay?>();
    await pumpApp(
      tester,
      AppTimePicker(
        label: 'Time',
        value: null,
        clock: clock,
        pick: (_, _) {
          opened++;
          return gate.future;
        },
        onChanged: (_) {},
      ),
    );
    await tester.tap(find.byType(AppTextField));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(AppTextField));
    await tester.pump(const Duration(seconds: 1));
    expect(opened, 1);
    gate.complete(const TimeOfDay(hour: 12, minute: 0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(AppTextField));
    await tester.pump();
    expect(opened, 2);
  });

  testWidgets('KIT-T11: the iOS time wheel shows Arabic-Indic hours in ar', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AppTimePicker(label: 'Time', value: null, onChanged: (_) {}),
      language: 'ar',
      platform: TargetPlatform.iOS,
    );
    await tester.tap(find.byType(AppTextField));
    await tester.pumpAndSettle();
    final wheel = find.byType(CupertinoDatePicker);
    expect(
      find.descendant(of: wheel, matching: find.textContaining('٠')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: wheel,
        matching: find.textContaining(RegExp('[0-9]')),
      ),
      findsNothing,
    );
  });

  testWidgets('KIT-T11: the Material time picker is dial only', (tester) async {
    await pumpApp(
      tester,
      AppTimePicker(label: 'Time', value: null, onChanged: (_) {}),
    );
    await tester.tap(find.byType(AppTextField));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TimePickerDialog>(find.byType(TimePickerDialog))
          .initialEntryMode,
      TimePickerEntryMode.dialOnly,
    );
    expect(find.byIcon(Icons.keyboard_outlined), findsNothing);
  });
}
