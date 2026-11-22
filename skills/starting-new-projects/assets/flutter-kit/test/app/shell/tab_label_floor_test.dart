import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/shell/app_shell.dart';
import 'package:kit_app/app/shell/shell_destinations.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';

import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

void main() {
  {
    for (final language in ['en', 'ar']) {
      for (final scale in [1.3, 2.0]) {
        testWidgets(
          'KIT-T10: tab labels never shrink below 1x at text scale $scale '
          '($language)',
          (tester) async {
            final semantics = tester.ensureSemantics();
            await pumpApp(
              tester,
              AppShell(
                role: AppRole.member,
                location: RouteNames.home,
                onSelect: (_) {},
                child: const SizedBox.expand(),
              ),
              language: language,
              textScale: scale,
            );
            final l10n = l10nFor(language);
            for (final d in destinationsFor(AppRole.member)) {
              final text = d.label(l10n);
              final label = find.text(text);
              final p = tester.renderObject<RenderParagraph>(label);
              final fontSize = p.text.style!.fontSize!;
              // FitLabel shrinks the text scale. Any paint-only scale an
              // ancestor adds would show as drawn height over laid-out
              // height, so the effective scale counts both.
              final drawn = tester.getSize(label).height / p.size.height;
              final effective = p.textScaler.scale(fontSize) * drawn / fontSize;
              expect(
                effective,
                greaterThanOrEqualTo(1.0 - 0.01),
                reason: '${d.path} effective scale',
              );
              final line = TextPainter(
                text: p.text,
                textDirection: p.textDirection,
                textScaler: p.textScaler,
                maxLines: 1,
              )..layout();
              addTearDown(line.dispose);
              expect(p.size.height, closeTo(line.height, 0.5), reason: d.path);
              final item = find
                  .ancestor(
                    of: label,
                    matching: find.byType(NavigationDestination),
                  )
                  .first;
              expect(
                tester.getRect(label).left,
                greaterThanOrEqualTo(tester.getRect(item).left - 0.5),
                reason: '${d.path} stays inside its item (start edge)',
              );
              expect(
                tester.getRect(label).right,
                lessThanOrEqualTo(tester.getRect(item).right + 0.5),
                reason: '${d.path} stays inside its item (end edge)',
              );
              expect(
                tester.getSemantics(item).label,
                contains(text),
                reason: '${d.path} semantics keep the full text',
              );
            }
            semantics.dispose();
          },
        );
      }
    }
  }
}
