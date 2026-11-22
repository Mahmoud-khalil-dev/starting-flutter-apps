import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/widgets/app_avatar.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_segmented.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<void> expectW600(
    WidgetTester tester,
    Widget child,
    Finder text,
  ) async {
    await pumpApp(tester, child);
    final style = tester.widget<Text>(text).style!;
    expect(style.fontWeight, FontWeight.w600);
    expect(style.fontVariations, [const FontVariation('wght', 600)]);
  }

  testWidgets('KIT-T11: AppSegmented emphasis draws at wght 600', (
    tester,
  ) async {
    await expectW600(
      tester,
      AppSegmented<int>(
        segments: const [
          AppSegment(value: 1, label: 'One'),
          AppSegment(value: 2, label: 'Two'),
        ],
        selected: 1,
        onChanged: (_) {},
      ),
      find.text('One'),
    );
  });

  testWidgets('KIT-T11: AppButton label draws at wght 600', (tester) async {
    await expectW600(
      tester,
      AppButton(label: 'Save', onPressed: () {}),
      find.text('Save'),
    );
  });

  testWidgets('KIT-T11: AppAvatar initials draw at wght 600', (tester) async {
    await expectW600(
      tester,
      const AppAvatar(name: 'Alex Morgan'),
      find.text('AM'),
    );
  });
}
