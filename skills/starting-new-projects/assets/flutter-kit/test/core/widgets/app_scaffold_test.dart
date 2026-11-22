import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:kit_app/core/widgets/app_action_bar.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_scaffold.dart';
import 'package:kit_app/core/widgets/connection_banner.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('KIT-T11: AppScaffold shows the banner from ConnectionScope', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const ConnectionScope(
        statuses: Stream.empty(),
        initial: ConnectionStatus.offline,
        child: AppScaffold(title: 'Home', body: Text('body')),
      ),
    );
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('KIT-T11: content is capped at 640 unless wide', (tester) async {
    for (final (wide, max) in [(false, 640.0), (true, 1440.0)]) {
      await pumpApp(
        tester,
        AppScaffold(
          wide: wide,
          body: const SizedBox(key: Key('body'), width: double.infinity),
        ),
        size: TestSizes.web,
      );
      expect(tester.getSize(find.byKey(const Key('body'))).width, max);
    }
  });

  testWidgets('KIT-T11: the body moves above the keyboard', (tester) async {
    await pumpApp(tester, const AppScaffold(body: SizedBox()));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).resizeToAvoidBottomInset,
      isTrue,
    );
  });

  testWidgets('KIT-T11: AppActionBar keeps the safe area, secondary at start', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    for (final (language, secondaryLeft) in [('en', true), ('ar', false)]) {
      await pumpApp(
        tester,
        AppScaffold(
          body: const SizedBox(),
          bottomBar: AppActionBar(
            secondary: AppButton(
              label: 'Back',
              onPressed: () {},
              variant: AppButtonVariant.secondary,
            ),
            primary: AppButton(label: 'Pay', onPressed: () {}),
          ),
        ),
        language: language,
      );
      final pay = tester.getRect(find.text('Pay'));
      final back = tester.getRect(find.text('Back'));
      expect(pay.bottom, lessThanOrEqualTo(TestSizes.phone.height - 34));
      expect(back.left < pay.left, secondaryLeft, reason: language);
    }
  });

  testWidgets('KIT-T11: without a bottom bar the body keeps the inset', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    await pumpApp(
      tester,
      const AppScaffold(body: SizedBox.expand(key: Key('body'))),
    );
    expect(
      tester.getRect(find.byKey(const Key('body'))).bottom,
      lessThanOrEqualTo(TestSizes.phone.height - 34),
    );
  });
}
