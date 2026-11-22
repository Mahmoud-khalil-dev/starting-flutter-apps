import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The HapticFeedback types sent to the platform while the test runs, for
/// example `HapticFeedbackType.selectionClick`.
List<String> recordHaptics(WidgetTester tester) {
  final types = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        types.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return types;
}
