import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/widgets/auto_direction_text.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('KIT-T11: the first strong character decides the direction', () {
    expect(firstStrongDirection('مرحبا hello'), TextDirection.rtl);
    expect(firstStrongDirection('12 hello مرحبا'), TextDirection.ltr);
    expect(firstStrongDirection('+20 100 (5)'), isNull);
    expect(firstStrongDirection('٣٤٥'), isNull);
  });

  testWidgets('KIT-T11: AutoDirectionText follows its text, else inherits', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AutoDirectionText('Alex Morgan'),
      language: 'ar',
    );
    expect(
      tester.widget<Text>(find.text('Alex Morgan')).textDirection,
      TextDirection.ltr,
    );
    await pumpApp(tester, const AutoDirectionText('٣٤٥'), language: 'ar');
    expect(tester.widget<Text>(find.text('٣٤٥')).textDirection, isNull);
  });

  test('KIT-T11: neutral and mixed strings', () {
    expect(firstStrongDirection('٣ ساعات'), TextDirection.rtl);
    expect(firstStrongDirection('Room 12'), TextDirection.ltr);
    expect(firstStrongDirection('שלום'), TextDirection.rtl);
    expect(firstStrongDirection(''), isNull);
    expect(firstStrongDirection('٣٫٥٪ ،'), isNull);
  });
}
