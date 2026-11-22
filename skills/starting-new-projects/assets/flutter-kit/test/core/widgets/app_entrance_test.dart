import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_entrance.dart';

import '../../helpers/pump_app.dart';

Offset _offset(WidgetTester tester, String text) {
  final t = tester
      .widget<Transform>(
        find
            .ancestor(of: find.text(text), matching: find.byType(Transform))
            .first,
      )
      .transform
      .getTranslation();
  return Offset(t.x, t.y);
}

double _opacity(WidgetTester tester, String text) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first,
    )
    .opacity;

Widget _list(int count) => Column(
  children: [
    for (var i = 0; i < count; i++)
      AppEntrance(index: i, child: Text('item $i')),
  ],
);

void main() {
  testWidgets('KIT-T10: entrance rises and fades, staggered 40 ms', (
    tester,
  ) async {
    await pumpApp(tester, _list(3), settle: false);
    expect(_opacity(tester, 'item 0'), 0);
    expect(_offset(tester, 'item 0').dy, AppDimensions.riseOffset);
    await tester.pump(Motion.stagger);
    await tester.pump(Motion.standard ~/ 2);
    expect(_opacity(tester, 'item 1'), greaterThan(0));
    expect(_opacity(tester, 'item 2'), lessThan(_opacity(tester, 'item 1')));
    await tester.pumpAndSettle();
    expect(_opacity(tester, 'item 2'), 1);
    expect(_offset(tester, 'item 2').dy, 0);
  });

  testWidgets('KIT-T10: the stagger caps at index 8', (tester) async {
    await pumpApp(tester, _list(12), settle: false);
    await tester.pump(Motion.stagger * Motion.maxStaggered);
    await tester.pump(Motion.standard ~/ 2);
    expect(_opacity(tester, 'item 11'), _opacity(tester, 'item 8'));
  });

  testWidgets('KIT-T10: under reduce motion entrance fades only, at once', (
    tester,
  ) async {
    await pumpApp(tester, _list(3), reduceMotion: true, settle: false);
    expect(_offset(tester, 'item 2').dy, 0);
    await tester.pump(Motion.quick ~/ 2);
    expect(_opacity(tester, 'item 2'), greaterThan(0));
    await tester.pumpAndSettle();
    expect(_opacity(tester, 'item 2'), 1);
  });
}
