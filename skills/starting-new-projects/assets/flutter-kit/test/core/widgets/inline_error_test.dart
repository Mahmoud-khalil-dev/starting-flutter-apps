import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/inline_error.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('KIT-T11: InlineError is a live region that fades in', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, const InlineError('Wrong code'), settle: false);
    final start = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Wrong code'),
        matching: find.byType(Opacity),
      ),
    );
    expect(start.opacity, 0);
    await tester.pump(Motion.quick);
    expect(
      tester.getSemantics(find.text('Wrong code')),
      isSemantics(isLiveRegion: true),
    );
    semantics.dispose();
  });
}
