import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_haptics.dart';

import '../../helpers/haptics.dart';

void main() {
  testWidgets('KIT-T8: haptics send selection, light and medium impacts', (
    tester,
  ) async {
    final sent = recordHaptics(tester);
    await AppHaptics.selection();
    await AppHaptics.light();
    await AppHaptics.success();
    expect(sent, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });
}
