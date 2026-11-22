import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/shell/app_two_pane.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';

import '../../helpers/pump_app.dart';

const _list = SizedBox.expand(key: Key('list'));
const _detail = SizedBox(
  key: Key('detail'),
  width: double.infinity,
  height: 10,
);

void main() {
  testWidgets('KIT-T10: compact shows the list only', (tester) async {
    await pumpApp(tester, const AppTwoPane(list: _list, detail: _detail));
    expect(find.byKey(const Key('detail')), findsNothing);
    expect(find.byKey(const Key('list')), findsOneWidget);
  });

  testWidgets('KIT-T10: from medium, list at 360 and a capped detail', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AppTwoPane(list: _list, detail: _detail),
      size: TestSizes.web,
    );
    expect(
      tester.getSize(find.byKey(const Key('list'))).width,
      AppDimensions.listPaneWidth,
    );
    expect(
      tester.getSize(find.byKey(const Key('detail'))).width,
      AppDimensions.contentMaxWidth,
    );
  });

  testWidgets('KIT-T10: without a detail it shows the empty detail', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AppTwoPane(list: _list, emptyDetail: Text('Choose one')),
      size: TestSizes.tablet,
    );
    expect(find.text('Choose one'), findsOneWidget);
  });
}
