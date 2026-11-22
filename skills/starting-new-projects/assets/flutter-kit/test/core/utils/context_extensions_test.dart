import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/utils/context_extensions.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('KIT-T15: the context gives l10n, formats and direction', (
    tester,
  ) async {
    late BuildContext captured;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
      language: 'ar',
    );
    expect(captured.l10n.localeName, 'ar');
    expect(captured.formats.language, 'ar');
    expect(captured.isRtl, isTrue);
  });

  testWidgets('KIT-T15: english is left to right', (tester) async {
    late BuildContext captured;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(captured.l10n.localeName, 'en');
    expect(captured.isRtl, isFalse);
  });

  testWidgets('KIT-T15: hideKeyboard drops the focus', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    late BuildContext captured;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          captured = context;
          return TextField(focusNode: focus);
        },
      ),
    );
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    captured.hideKeyboard();
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });
}
