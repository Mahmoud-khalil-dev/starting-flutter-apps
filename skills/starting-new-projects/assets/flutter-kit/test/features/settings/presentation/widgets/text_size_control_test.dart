import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/features/settings/presentation/widgets/text_size_control.dart';

import '../../../../helpers/pump_app.dart';

/// The slider: the one semantics node a screen reader can step.
SemanticsNode _slider() {
  final nodes = find.semantics
      .byAction(SemanticsAction.increase)
      .evaluate()
      .toList();
  expect(nodes, hasLength(1));
  return nodes.single;
}

void _step(WidgetTester tester, SemanticsAction action) =>
    tester.semantics.performAction(find.semantics.byAction(action), action);

void main() {
  const cases = {
    'en': ('100%', '105%', '95%'),
    'ar': ('١٠٠٪', '١٠٥٪', '٩٥٪'),
  };

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final MapEntry(key: language, value: (value, up, down))
        in cases.entries) {
      testWidgets('KIT-T12: the slider tells a screen reader $value on '
          '${platform.name} in $language', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(
          tester,
          TextSizeControl(value: 1, onChanged: (_) async {}),
          language: language,
          platform: platform,
        );
        final data = _slider().getSemanticsData();
        expect(data.value, value);
        expect(data.increasedValue, up);
        expect(data.decreasedValue, down);
        handle.dispose();
      });
    }
  }

  testWidgets('KIT-T12: on iOS a screen reader step moves one step and '
      'saves it', (tester) async {
    final handle = tester.ensureSemantics();
    final saved = <double>[];
    var current = 1.0;
    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => TextSizeControl(
          value: current,
          onChanged: (v) async {
            saved.add(v);
            setState(() => current = v);
          },
        ),
      ),
      platform: TargetPlatform.iOS,
    );
    expect(find.byType(CupertinoSlider), findsOneWidget);
    _step(tester, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(saved.single, closeTo(1.05, 1e-9));
    expect(_slider().getSemanticsData().value, '105%');
    _step(tester, SemanticsAction.decrease);
    await tester.pumpAndSettle();
    expect(saved.last, closeTo(1, 1e-9));
    handle.dispose();
  });

  testWidgets('KIT-T12: the web never gets the Apple slider', (tester) async {
    await pumpApp(
      tester,
      TextSizeControl(value: 1, onChanged: (_) async {}),
      platform: TargetPlatform.iOS,
      web: true,
    );
    expect(find.byType(CupertinoSlider), findsNothing);
    expect(find.byType(Slider), findsOneWidget);
  });
}
