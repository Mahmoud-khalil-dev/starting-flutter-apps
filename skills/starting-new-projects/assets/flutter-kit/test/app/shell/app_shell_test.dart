import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/shell/app_shell.dart';
import 'package:kit_app/app/shell/app_sidebar.dart';
import 'package:kit_app/app/shell/frosted_nav_bar.dart';
import 'package:kit_app/app/shell/shell_destinations.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';

import '../../helpers/haptics.dart';
import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

void main() {
  final selected = <String>[];
  final reselected = <String>[];

  setUp(() {
    selected.clear();
    reselected.clear();
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = TestSizes.phone,
    TargetPlatform? platform,
    String language = 'en',
    bool reduceMotion = false,
    bool? web,
    bool highContrast = false,
    String location = RouteNames.home,
    Set<ShellTab> badges = const {},
    Widget? aboveBar,
  }) => pumpApp(
    tester,
    AppShell(
      role: AppRole.member,
      location: location,
      onSelect: selected.add,
      onReselect: reselected.add,
      badges: badges,
      aboveBar: aboveBar,
      child: const SizedBox.expand(),
    ),
    size: size,
    platform: platform,
    language: language,
    reduceMotion: reduceMotion,
    web: web,
    highContrast: highContrast,
  );

  group('KIT-T10: the shell by width class', () {
    testWidgets('KIT-T10: phone width shows a bottom bar of two destinations', (
      tester,
    ) async {
      await pump(tester);
      final l10n = l10nFor('en');
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(2));
      expect(find.text(l10n.navHome), findsOneWidget);
      expect(find.text(l10n.navSettings), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(AppSidebar), findsNothing);
    });

    testWidgets('KIT-T10: tablet width shows the rail, not the bar', (
      tester,
    ) async {
      await pump(tester, size: TestSizes.tablet);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations, hasLength(2));
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('KIT-T10: web width shows the sidebar with the app name', (
      tester,
    ) async {
      await pump(tester, size: TestSizes.web);
      expect(find.byType(AppSidebar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text(l10nFor('en').appName), findsOneWidget);
    });

    testWidgets('KIT-T10: the sidebar collapses to the rail width', (
      tester,
    ) async {
      await pump(tester, size: TestSizes.web);
      final l10n = l10nFor('en');
      expect(
        tester.getSize(find.byType(AppSidebar)).width,
        AppDimensions.sidebarWidth,
      );
      await tester.tap(find.byTooltip(l10n.navCollapse));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(AppSidebar)).width,
        AppDimensions.railWidth,
      );
      expect(find.byTooltip(l10n.navExpand), findsOneWidget);
    });

    testWidgets('KIT-T10: the bar selects the tab of the location', (
      tester,
    ) async {
      await pump(tester, location: RouteNames.settings);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
    });
  });

  group('KIT-T10: Arabic mirrors the shell', () {
    testWidgets('KIT-T10: the bar lists Home at the right in Arabic', (
      tester,
    ) async {
      final l10n = l10nFor('ar');
      await pump(tester, language: 'ar');
      expect(
        tester.getCenter(find.text(l10n.navHome)).dx,
        greaterThan(tester.getCenter(find.text(l10n.navSettings)).dx),
      );
      await pump(tester);
      final en = l10nFor('en');
      expect(
        tester.getCenter(find.text(en.navHome)).dx,
        lessThan(tester.getCenter(find.text(en.navSettings)).dx),
      );
    });

    testWidgets('KIT-T10: the rail sits at the right in Arabic', (
      tester,
    ) async {
      await pump(tester, size: TestSizes.tablet, language: 'ar');
      expect(
        tester.getCenter(find.byType(NavigationRail)).dx,
        greaterThan(TestSizes.tablet.width / 2),
      );
      await pump(tester, size: TestSizes.tablet);
      expect(
        tester.getCenter(find.byType(NavigationRail)).dx,
        lessThan(TestSizes.tablet.width / 2),
      );
    });

    testWidgets('KIT-T10: the sidebar sits at the right in Arabic', (
      tester,
    ) async {
      await pump(tester, size: TestSizes.web, language: 'ar');
      expect(
        tester.getCenter(find.byType(AppSidebar)).dx,
        greaterThan(TestSizes.web.width / 2),
      );
    });
  });

  group('KIT-T10: the frosted bar', () {
    testWidgets('KIT-T10: on a phone app the bar frosts what is behind it', (
      tester,
    ) async {
      await pump(tester);
      expect(
        find.descendant(
          of: find.byKey(FrostedNavBar.barKey),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
    });

    testWidgets('KIT-T10: on the web the bar is a dense fill, no blur', (
      tester,
    ) async {
      await pump(tester, web: true);
      expect(find.byKey(FrostedNavBar.barKey), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('KIT-T10: increased contrast makes the bar opaque', (
      tester,
    ) async {
      await pump(tester, highContrast: true);
      expect(find.byType(BackdropFilter), findsNothing);
      final fill = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byKey(FrostedNavBar.barKey),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(fill.color.a, 1);
    });

    testWidgets('KIT-T10: the bar slot sits right above the bar', (
      tester,
    ) async {
      await pump(
        tester,
        aboveBar: const SizedBox(key: Key('slot'), height: 40),
      );
      expect(
        tester.getRect(find.byKey(const Key('slot'))).bottom,
        tester.getRect(find.byKey(FrostedNavBar.barKey)).top,
      );
    });
  });

  group('KIT-T10: selecting', () {
    testWidgets('KIT-T10: select with a haptic, reselect the current', (
      tester,
    ) async {
      final haptics = recordHaptics(tester);
      await pump(tester);
      final l10n = l10nFor('en');
      await tester.tap(find.text(l10n.navSettings));
      await tester.tap(find.text(l10n.navHome));
      expect(selected, [RouteNames.settings]);
      expect(reselected, [RouteNames.home]);
      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('KIT-T10: the rail selects and reselects the same way', (
      tester,
    ) async {
      await pump(tester, size: TestSizes.tablet);
      final l10n = l10nFor('en');
      await tester.tap(find.text(l10n.navSettings));
      await tester.tap(find.text(l10n.navHome));
      expect(selected, [RouteNames.settings]);
      expect(reselected, [RouteNames.home]);
    });

    testWidgets('KIT-T10: a badge is a dot and is announced', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, badges: {ShellTab.settings});
      final l10n = l10nFor('en');
      expect(find.byKey(const Key('badge-settings')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(l10n.navActionRequired(l10n.navSettings))),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('KIT-T10: tab icons cross-fade, swap at once under reduce', (
      tester,
    ) async {
      for (final (reduce, duration) in [
        (false, Motion.quick),
        (true, Duration.zero),
      ]) {
        await pump(tester, reduceMotion: reduce);
        final switchers = tester.widgetList<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        );
        expect(switchers, hasLength(2));
        for (final s in switchers) {
          expect(s.duration, duration, reason: 'reduce: $reduce');
        }
        expect(find.byIcon(Icons.home_rounded), findsOneWidget);
        expect(find.byIcon(Icons.home_outlined), findsNothing);
      }
    });
  });

  group('KIT-T10: the page inset', () {
    for (final language in ['en', 'ar']) {
      testWidgets(
        'KIT-T10: the page is inset by the bar footprint at phone width '
        '($language)',
        (tester) async {
          EdgeInsets? padding;
          // A home indicator, so the footprint counts the safe area too.
          tester.view.padding = const FakeViewPadding(bottom: 34);
          await pumpApp(
            tester,
            AppShell(
              role: AppRole.member,
              location: RouteNames.home,
              onSelect: (_) {},
              child: Builder(
                builder: (context) {
                  padding = MediaQuery.paddingOf(context);
                  return const SizedBox.expand(key: Key('page'));
                },
              ),
            ),
            language: language,
          );
          final bar = tester.getRect(find.byKey(FrostedNavBar.barKey));
          expect(padding!.bottom, TestSizes.phone.height - bar.top);
          // The page still fills the screen, so it scrolls under the bar.
          expect(
            tester.getRect(find.byKey(const Key('page'))).bottom,
            TestSizes.phone.height,
          );
        },
      );
    }

    testWidgets('KIT-T10: the rail and sidebar leave the page inset alone', (
      tester,
    ) async {
      EdgeInsets? padding;
      for (final size in [TestSizes.tablet, TestSizes.web]) {
        await pumpApp(
          tester,
          AppShell(
            role: AppRole.member,
            location: RouteNames.home,
            onSelect: (_) {},
            child: Builder(
              builder: (context) {
                padding = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
          size: size,
        );
        expect(padding!.bottom, 0, reason: '$size');
      }
    });
  });

  for (final language in ['en', 'ar']) {
    testWidgets(
      'KIT-T10: rail labels keep the padding from the rail edges ($language)',
      (tester) async {
        await pump(tester, size: TestSizes.tablet, language: language);
        final rail = tester.getRect(find.byType(NavigationRail));
        final l10n = l10nFor(language);
        for (final d in destinationsFor(AppRole.member)) {
          final text = tester.getRect(find.text(d.label(l10n)));
          const pad = AppDimensions.sm - 0.5;
          expect(text.left, greaterThanOrEqualTo(rail.left + pad));
          expect(text.right, lessThanOrEqualTo(rail.right - pad));
        }
      },
    );
  }
}
