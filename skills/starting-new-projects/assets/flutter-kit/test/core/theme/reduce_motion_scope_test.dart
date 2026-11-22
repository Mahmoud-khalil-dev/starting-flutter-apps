import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/theme/reduce_motion_scope.dart';

void main() {
  testWidgets('KIT-T8: the platform reduce-motion flag reaches context.motion '
      'and follows changes', (tester) async {
    late AppMotion motion;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: ReduceMotionScope(
          child: Builder(
            builder: (context) {
              motion = context.motion;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(motion.reduced, isFalse);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(motion.reduced, isTrue);
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pump();
    expect(motion.reduced, isFalse);
  });

  testWidgets('KIT-T8: disableAnimations alone also reduces motion', (
    tester,
  ) async {
    late AppMotion motion;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: ReduceMotionScope(
          child: Builder(
            builder: (context) {
              motion = context.motion;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(motion.reduced, isTrue);
  });
}
