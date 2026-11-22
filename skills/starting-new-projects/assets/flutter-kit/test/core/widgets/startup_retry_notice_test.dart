import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/widgets/app_entrance.dart';
import 'package:kit_app/core/widgets/startup_retry_notice.dart';

import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets('KIT-T10: the retry notice speaks $language and retries', (
      tester,
    ) async {
      var retries = 0;
      await pumpApp(
        tester,
        StartupRetryNotice(onRetry: () => retries++),
        language: language,
      );
      final l10n = l10nFor(language);
      expect(find.text(l10n.startupRetryBody), findsOneWidget);
      await tester.tap(find.text(l10n.startupRetryAction));
      expect(retries, 1);
    });
  }

  /// How far the notice sits below its resting place in the first frame.
  Future<double> riseOffset(WidgetTester tester, {required bool reduce}) async {
    await pumpApp(
      tester,
      StartupRetryNotice(onRetry: () {}),
      reduceMotion: reduce,
      settle: false,
    );
    await tester.pump();
    final rise = find
        .descendant(
          of: find.byType(AppEntrance),
          matching: find.byType(Transform),
        )
        .first;
    return tester.widget<Transform>(rise).transform.getTranslation().y;
  }

  testWidgets('KIT-T10: the notice rises into place with motion on', (
    tester,
  ) async {
    expect(await riseOffset(tester, reduce: false), greaterThan(0));
  });

  testWidgets('KIT-T10: the notice does not rise under reduce motion', (
    tester,
  ) async {
    expect(await riseOffset(tester, reduce: true), 0);
    expect(find.text(l10nFor('en').startupRetryBody), findsOneWidget);
  });

  testWidgets('KIT-T10: the retry notice texts are the agreed copy', (
    tester,
  ) async {
    expect(
      l10nFor('en').startupRetryBody,
      'We are still opening your saved session.',
    );
    expect(l10nFor('en').startupRetryAction, 'Try again');
    expect(l10nFor('ar').startupRetryBody, 'ما زلنا نفتح جلستك المحفوظة.');
    expect(l10nFor('ar').startupRetryAction, 'حاول مرة أخرى');
  });
}
