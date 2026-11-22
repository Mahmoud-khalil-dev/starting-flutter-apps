import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/widgets/app_date_picker.dart';

import '../../helpers/pump_app.dart';

void main() {
  final initial = DateTime(2026, 11, 20);

  Future<Future<DateTime?>> open(WidgetTester tester) async {
    final context = tester.element(find.byKey(const Key('anchor')));
    final result = showAppDatePicker(
      context,
      initial: initial,
      first: DateTime(2026),
      last: DateTime(2027),
    );
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('KIT-T11: iOS gets a date wheel with Done', (tester) async {
    await pumpApp(
      tester,
      const SizedBox(key: Key('anchor')),
      platform: TargetPlatform.iOS,
    );
    final result = await open(tester);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, initial);
  });

  testWidgets('KIT-T11: Android gets the Material date picker', (tester) async {
    await pumpApp(tester, const SizedBox(key: Key('anchor')));
    await open(tester);
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('KIT-T11: an initial before the first opens clamped', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SizedBox(key: Key('anchor')),
      platform: TargetPlatform.iOS,
    );
    final context = tester.element(find.byKey(const Key('anchor')));
    final result = showAppDatePicker(
      context,
      initial: DateTime(2025, 6, 1, 14, 20),
      first: DateTime(2026, 3, 5),
      last: DateTime(2027),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, DateTime(2026, 3, 5));
  });

  testWidgets('KIT-T11: an initial after the last opens clamped', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SizedBox(key: Key('anchor')),
      platform: TargetPlatform.iOS,
    );
    final context = tester.element(find.byKey(const Key('anchor')));
    final result = showAppDatePicker(
      context,
      initial: DateTime(2030, 6),
      first: DateTime(2026),
      last: DateTime(2027, 2, 3, 9),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, DateTime(2027, 2, 3));
  });

  testWidgets('KIT-T11: a non-midnight initial returns midnight', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SizedBox(key: Key('anchor')),
      platform: TargetPlatform.iOS,
    );
    final context = tester.element(find.byKey(const Key('anchor')));
    final result = showAppDatePicker(
      context,
      initial: DateTime(2026, 11, 20, 15, 45),
      first: DateTime(2026),
      last: DateTime(2027),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, DateTime(2026, 11, 20));
  });

  testWidgets('KIT-T11: Material clamps too and returns the date only', (
    tester,
  ) async {
    await pumpApp(tester, const SizedBox(key: Key('anchor')));
    final context = tester.element(find.byKey(const Key('anchor')));
    final result = showAppDatePicker(
      context,
      initial: DateTime(2030, 6, 1, 8),
      first: DateTime(2026),
      last: DateTime(2027, 2, 3),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await result, DateTime(2027, 2, 3));
  });

  testWidgets('KIT-T11: dismissing the date picker returns null', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SizedBox(key: Key('anchor')),
      platform: TargetPlatform.iOS,
    );
    final result = await open(tester);
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });

  testWidgets('KIT-T11: a second date picker while one is open is ignored', (
    tester,
  ) async {
    await pumpApp(tester, const SizedBox(key: Key('anchor')));
    final context = tester.element(find.byKey(const Key('anchor')));
    unawaited(
      showAppDatePicker(
        context,
        initial: initial,
        first: DateTime(2026),
        last: DateTime(2027),
      ),
    );
    final second = showAppDatePicker(
      context,
      initial: initial,
      first: DateTime(2026),
      last: DateTime(2027),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(await second, isNull);
  });

  final western = find.textContaining(RegExp('[0-9]'));

  testWidgets('KIT-T11: the Material date picker shows Arabic-Indic in ar', (
    tester,
  ) async {
    await pumpApp(tester, const SizedBox(key: Key('anchor')), language: 'ar');
    await open(tester);
    expect(find.textContaining('٢٠'), findsWidgets);
    expect(western, findsNothing);
  });

  testWidgets('KIT-T11: the Cupertino date wheel shows Arabic-Indic in ar', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SizedBox(key: Key('anchor')),
      language: 'ar',
      platform: TargetPlatform.iOS,
    );
    await open(tester);
    expect(find.text('٢٠٢٦'), findsWidgets);
    expect(find.text('٢٠'), findsWidgets);
    expect(
      find.descendant(of: find.byType(CupertinoDatePicker), matching: western),
      findsNothing,
    );
  });

  testWidgets('KIT-T11: the date pickers keep Western digits in en', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SizedBox(key: Key('anchor')),
      platform: TargetPlatform.iOS,
    );
    await open(tester);
    expect(find.text('2026'), findsWidgets);
    expect(find.textContaining('٢'), findsNothing);
  });

  testWidgets('KIT-T11: the Material date picker has no text entry toggle', (
    tester,
  ) async {
    await pumpApp(tester, const SizedBox(key: Key('anchor')));
    await open(tester);
    expect(
      tester
          .widget<DatePickerDialog>(find.byType(DatePickerDialog))
          .initialEntryMode,
      DatePickerEntryMode.calendarOnly,
    );
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });
}
