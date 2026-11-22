import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/shell/app_shell.dart';
import 'package:kit_app/app/shell/app_sidebar.dart';
import 'package:kit_app/app/shell/shell_destinations.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';

import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

/// Counts how often its State is created, to prove the page keeps it.
class _Page extends StatefulWidget {
  const _Page(this.inits);

  final List<int> inits;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  void initState() {
    super.initState();
    widget.inits.add(1);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Size size = TestSizes.phone,
    TargetPlatform? platform,
    Set<ShellTab> badges = const {},
    String location = RouteNames.home,
    Widget child = const SizedBox.expand(),
  }) => pumpApp(
    tester,
    AppShell(
      role: AppRole.member,
      location: location,
      onSelect: (_) {},
      badges: badges,
      child: child,
    ),
    size: size,
    platform: platform,
  );

  testWidgets('KIT-T10: a badged selected tab says it is selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final l10n = l10nFor('en');
    await pump(tester, badges: {ShellTab.home});
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(RegExp(l10n.navActionRequired(l10n.navHome))),
      ),
      isSemantics(isSelected: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('KIT-T10: the rail announces a badge', (tester) async {
    final semantics = tester.ensureSemantics();
    final l10n = l10nFor('en');
    await pump(tester, size: TestSizes.tablet, badges: {ShellTab.settings});
    expect(find.byKey(const Key('badge-settings')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(l10n.navActionRequired(l10n.navSettings))),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('KIT-T10: the page keeps its state across width classes', (
    tester,
  ) async {
    final inits = <int>[];
    final page = _Page(inits);
    await pump(tester, child: page);
    await pump(tester, size: TestSizes.tablet, child: page);
    expect(find.byType(NavigationRail), findsOneWidget);
    await pump(tester, size: TestSizes.web, child: page);
    expect(find.byType(AppSidebar), findsOneWidget);
    await pump(tester, child: page);
    expect(inits, hasLength(1));
  });

  testWidgets('KIT-T10: the sidebar snaps its width and fades its labels', (
    tester,
  ) async {
    await pump(tester, size: TestSizes.web);
    final l10n = l10nFor('en');
    await tester.tap(find.byTooltip(l10n.navCollapse));
    await tester.pump();
    expect(
      tester.getSize(find.byType(AppSidebar)).width,
      AppDimensions.railWidth,
    );
    await tester.tap(find.byTooltip(l10n.navExpand));
    await tester.pump();
    expect(
      tester.getSize(find.byType(AppSidebar)).width,
      AppDimensions.sidebarWidth,
    );
    final fade = find.ancestor(
      of: find.text(l10n.navHome),
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<FadeTransition>(fade.first).opacity.value, 0);
    await tester.pumpAndSettle();
    expect(tester.widget<FadeTransition>(fade.first).opacity.value, 1);
  });

  testWidgets('KIT-T10: bar items and sidebar rows say "Tab n of m"', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final size in [TestSizes.phone, TestSizes.web]) {
      await pump(tester, size: size);
      expect(
        find.bySemanticsLabel(RegExp(r'Settings\nTab 2 of 2')),
        findsOneWidget,
        reason: '$size',
      );
    }
    semantics.dispose();
  });

  testWidgets('KIT-T10: an unknown location asserts in debug', (tester) async {
    await pump(tester, location: '/nowhere');
    expect(tester.takeException(), isA<AssertionError>());
  });
}
