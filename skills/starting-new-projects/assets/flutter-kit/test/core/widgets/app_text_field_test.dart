import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';

import '../../helpers/pump_app.dart';

double _shift(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byType(AppTextField),
        matching: find.byKey(const ValueKey('shake')),
      ),
    )
    .transform
    .getTranslation()
    .x;

void main() {
  testWidgets('KIT-T11: typed Arabic-Indic digits go on as Western digits', (
    tester,
  ) async {
    String? value;
    await pumpApp(
      tester,
      AppTextField(label: 'Age', digits: true, onChanged: (v) => value = v),
      language: 'ar',
    );
    await tester.enterText(find.byType(TextField), '٣٤');
    expect(value, '34');
    expect(find.text('٣٤'), findsOneWidget);
  });

  testWidgets('KIT-T11: an error shakes the field once and shows', (
    tester,
  ) async {
    final error = ValueNotifier<String?>(null);
    await pumpApp(
      tester,
      ValueListenableBuilder<String?>(
        valueListenable: error,
        builder: (_, e, _) => AppTextField(label: 'Email', errorText: e),
      ),
    );
    expect(_shift(tester), 0);
    error.value = 'Please check the email address.';
    await tester.pump();
    await tester.pump(Motion.standard * 0.15);
    expect(_shift(tester), isNot(0));
    await tester.pumpAndSettle();
    expect(_shift(tester), 0);
    expect(find.text('Please check the email address.'), findsOneWidget);
  });

  testWidgets('KIT-T11: under reduce motion the error shows without a shake', (
    tester,
  ) async {
    final error = ValueNotifier<String?>(null);
    await pumpApp(
      tester,
      ValueListenableBuilder<String?>(
        valueListenable: error,
        builder: (_, e, _) => AppTextField(label: 'Email', errorText: e),
      ),
      reduceMotion: true,
    );
    error.value = 'Please check the email address.';
    await tester.pump();
    await tester.pump(Motion.standard * 0.15);
    expect(_shift(tester), 0);
  });

  testWidgets('KIT-T11: left-to-right fields stay LTR in Arabic', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AppTextField(label: 'Phone', leftToRight: true),
      language: 'ar',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets('KIT-T11: a read-only field reports taps', (tester) async {
    var taps = 0;
    await pumpApp(
      tester,
      AppTextField(label: 'Time', readOnly: true, onTap: () => taps++),
    );
    await tester.tap(find.byType(TextField));
    expect(taps, 1);
  });

  testWidgets('KIT-T16: the keyboard action submits the typed text', (
    tester,
  ) async {
    String? submitted;
    await pumpApp(
      tester,
      AppTextField(
        label: 'Code',
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => submitted = v,
      ),
    );
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 'abc');
  });

  testWidgets('KIT-T16: input formatters shape what is typed or pasted', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AppTextField(
        label: 'Code',
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
    await tester.enterText(find.byType(TextField), 'a1b2');
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('KIT-T16: autocorrect can be turned off', (tester) async {
    await pumpApp(tester, const AppTextField(label: 'Who', autocorrect: false));
    expect(tester.widget<TextField>(find.byType(TextField)).autocorrect, false);
  });
}
