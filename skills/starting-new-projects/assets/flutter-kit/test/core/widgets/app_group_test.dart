import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/widgets/app_directional_icon.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/app_row.dart';

import '../../helpers/haptics.dart';
import '../../helpers/pump_app.dart';

double _netFlip(WidgetTester tester) => tester
    .widgetList<Transform>(
      find.descendant(
        of: find.byType(AppDirectionalIcon),
        matching: find.byType(Transform),
      ),
    )
    .fold<double>(1, (product, t) => product * t.transform.entry(0, 0));

void main() {
  testWidgets('KIT-T11: an icon that does not mirror itself is flipped once', (
    tester,
  ) async {
    const plain = IconData(0xe000, fontFamily: 'MaterialIcons');
    for (final (language, flipped) in [('en', false), ('ar', true)]) {
      await pumpApp(
        tester,
        const AppDirectionalIcon(plain),
        language: language,
      );
      expect(_netFlip(tester), flipped ? -1 : 1, reason: language);
    }
  });

  testWidgets('KIT-T11: a long title and subtitle wrap without overflow', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AppRow.navigation(
        title:
            'A very long row title that must wrap onto several lines at large text',
        subtitle:
            'A long supporting line that also has to wrap instead of clipping',
        onTap: _noop,
      ),
      size: const Size(320, 800),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('KIT-T11: the group title is small caps, dividers are inset', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AppGroup(
        title: 'Account',
        children: [
          AppRow.info(title: 'One'),
          AppRow.info(title: 'Two'),
          AppRow.info(title: 'Three'),
        ],
      ),
    );
    expect(find.text('ACCOUNT'), findsOneWidget);
    final dividers = tester.widgetList<Divider>(find.byType(Divider));
    expect(dividers, hasLength(2));
    expect(dividers.first.indent, greaterThan(0));
  });

  testWidgets('KIT-T11: navigation rows mirror the chevron and call back', (
    tester,
  ) async {
    for (final (language, flipped) in [('en', false), ('ar', true)]) {
      var taps = 0;
      await pumpApp(
        tester,
        AppRow.navigation(title: 'Language', onTap: () => taps++),
        language: language,
      );
      expect(_netFlip(tester), flipped ? -1 : 1, reason: language);
      await tester.tap(find.text('Language'));
      expect(taps, 1);
    }
  });

  testWidgets('KIT-T11: a value that does not fit moves under the title', (
    tester,
  ) async {
    const value = 'alex.morgan@example.com';
    await pumpApp(
      tester,
      const AppRow.value(title: 'Email', value: value),
      size: const Size(320, 800),
      textScale: 2,
    );
    final title = tester.getRect(find.text('Email'));
    final shown = tester.getRect(find.text(value));
    expect(shown.top, greaterThanOrEqualTo(title.bottom));
    await pumpApp(tester, const AppRow.value(title: 'Email', value: 'a@b.c'));
    expect(
      tester.getCenter(find.text('a@b.c')).dy,
      closeTo(tester.getCenter(find.text('Email')).dy, 1),
    );
  });

  testWidgets('KIT-T11: a toggle flips with a selection haptic', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    bool? changed;
    await pumpApp(
      tester,
      AppRow.toggle(
        title: 'Reminders',
        value: false,
        onChanged: (v) => changed = v,
      ),
    );
    await tester.tap(find.text('Reminders'));
    expect(changed, isTrue);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  testWidgets('KIT-T11: an on toggle wears primaryInk on iOS too', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await pumpApp(
        tester,
        AppRow.toggle(title: 'Reminders', value: true, onChanged: (_) {}),
        platform: TargetPlatform.iOS,
        brightness: brightness,
      );
      // Switch.adaptive ignores the theme's trackColor on iOS and falls
      // back to the system green, so the row passes primaryInk itself.
      final track = tester.widget<Switch>(find.byType(Switch)).activeTrackColor;
      expect(
        track,
        AppPalette.forBrightness(brightness).primaryInk,
        reason: brightness.name,
      );
    }
  });

  testWidgets('KIT-T11: a destructive action is in the danger colour', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AppRow.action(
        title: 'Sign out',
        tone: AppRowTone.destructive,
        onTap: () {},
      ),
    );
    expect(
      tester.widget<Text>(find.text('Sign out')).style?.color,
      AppPalette.light.danger,
    );
  });
}

void _noop() {}
