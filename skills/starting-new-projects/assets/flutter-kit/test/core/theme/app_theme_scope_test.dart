import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_fonts.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/app_theme_scope.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('KIT-T8: AppThemeScope follows brightness, language and width', (
    tester,
  ) async {
    late BuildContext captured;
    final probe = AppThemeScope(
      brightness: Brightness.dark,
      child: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    );
    await pumpApp(tester, probe, language: 'ar', size: const Size(450, 900));
    expect(captured.colors, same(AppPalette.dark));
    expect(captured.text.body.fontFamily, AppFonts.primaryFor('ar'));
    expect(
      captured.text.body.fontSize,
      closeTo(16 * 1.2 * AppTextStyles.arabicScale, 0.01),
    );
    tester.view.physicalSize = const Size(900, 450);
    await tester.pumpAndSettle();
    expect(captured.text.body.fontSize, 16 * AppTextStyles.arabicScale);
  });
}
