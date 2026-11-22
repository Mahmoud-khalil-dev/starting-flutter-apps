import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/di/retry_prompt.dart';
import 'package:kit_app/core/theme/motion.dart';

import '../../helpers/pump_app.dart';

void main() {
  late GlobalKey<NavigatorState> key;

  Future<void> pumpHost(WidgetTester tester, {String language = 'en'}) async {
    key = GlobalKey<NavigatorState>();
    // The app's own navigator key goes on the MaterialApp's navigator, as
    // the router does; pumpApp builds the same app under it.
    await pumpApp(
      tester,
      Navigator(
        key: key,
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const SizedBox()),
      ),
      language: language,
    );
  }

  testWidgets('KIT-T11: the timeout prompt asks calmly and answers yes', (
    tester,
  ) async {
    await pumpHost(tester);
    final answer = askRetryWithDialog(key);
    await tester.pump();
    await tester.pump(Motion.slow);
    expect(find.text('The connection is slow'), findsOneWidget);
    expect(
      find.text(
        'The connection is taking longer than usual. Please try again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    await tester.pump(Motion.slow);
    expect(await answer, isTrue);
  });

  testWidgets('KIT-T11: the timeout prompt answers no to Not now', (
    tester,
  ) async {
    await pumpHost(tester);
    final answer = askRetryWithDialog(key);
    await tester.pump(Motion.slow);
    await tester.tap(find.text('Not now'));
    await tester.pump(Motion.slow);
    expect(await answer, isFalse);
  });

  testWidgets('KIT-T11: dismissing the timeout prompt means no', (
    tester,
  ) async {
    await pumpHost(tester);
    final answer = askRetryWithDialog(key);
    await tester.pump(Motion.slow);
    await tester.tapAt(const Offset(4, 4));
    await tester.pump(Motion.slow);
    expect(await answer, isFalse);
  });

  testWidgets('KIT-T11: the timeout prompt speaks Arabic in Arabic', (
    tester,
  ) async {
    await pumpHost(tester, language: 'ar');
    final answer = askRetryWithDialog(key);
    await tester.pump(Motion.slow);
    expect(find.text('الاتصال بطيء'), findsOneWidget);
    await tester.tap(find.text('ليس الآن'));
    await tester.pump(Motion.slow);
    expect(await answer, isFalse);
  });

  test('KIT-T11: with no screen to ask on, the prompt answers no', () async {
    expect(await askRetryWithDialog(GlobalKey<NavigatorState>()), isFalse);
  });
}
