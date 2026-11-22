import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_update_banner.dart';

import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('KIT-T11: the update banner offers Restart and Later', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var restarts = 0;
    var laters = 0;
    await pumpApp(
      tester,
      AppUpdateBanner(onRestart: () => restarts++, onLater: () => laters++),
    );
    final l10n = l10nFor('en');
    expect(find.text(l10n.kitUpdateTitle), findsOneWidget);
    expect(find.text(l10n.kitUpdateBody), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.liveRegion ?? false),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.kitUpdateRestart));
    await tester.tap(find.text(l10n.kitUpdateLater));
    expect((restarts, laters), (1, 1));
    semantics.dispose();
  });

  testWidgets('KIT-T11: it slides in, and fades under reduce motion', (
    tester,
  ) async {
    for (final (reduce, moves) in [(false, true), (true, false)]) {
      await pumpApp(
        tester,
        AppUpdateBanner(onRestart: () {}, onLater: () {}),
        reduceMotion: reduce,
        settle: false,
      );
      await tester.pump(Motion.quick ~/ 3);
      final slide = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slide.position.value.dy < 0, moves, reason: 'reduce: $reduce');
      final fade = tester.widget<FadeTransition>(
        find
            .descendant(
              of: find.byType(AppUpdateBanner),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, lessThan(1), reason: 'reduce: $reduce');
      await tester.pumpAndSettle();
    }
  });
}
