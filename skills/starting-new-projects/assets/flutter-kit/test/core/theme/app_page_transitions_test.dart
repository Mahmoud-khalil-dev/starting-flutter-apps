import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/core/theme/app_page_transitions.dart';
import 'package:kit_app/core/theme/app_theme.dart';
import 'package:kit_app/core/theme/motion.dart';

import 'package:kit_app/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';

double _opacityAbove(WidgetTester tester, String text) => tester
    .widget<FadeTransition>(
      find
          .ancestor(of: find.text(text), matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

/// A MaterialPage, as an app's routes build them: iOS gets the interactive
/// swipe-back, Android its own transition.
Page<void> _page(GoRouterState state, String label) => MaterialPage<void>(
  key: state.pageKey,
  child: Scaffold(body: Center(child: Text(label))),
);

/// Two GoRoute pages under a GoRouter on iOS, with the second pushed.
Future<void> _pumpIosStack(WidgetTester tester, String language) async {
  tester.view
    ..physicalSize = TestSizes.phone
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, state) => _page(state, 'home'),
        routes: [
          GoRoute(
            path: 'next',
            pageBuilder: (_, state) => _page(state, 'next'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.build(
        brightness: Brightness.light,
        language: language,
        platform: TargetPlatform.iOS,
      ),
    ),
  );
  unawaited(router.push('/next'));
  await tester.pumpAndSettle();
  expect(find.text('next'), findsOneWidget);
  expect(find.text('home'), findsNothing);
}

Future<void> _swipe(WidgetTester tester, Offset from, double dx) async {
  final gesture = await tester.startGesture(from);
  await gesture.moveBy(Offset(dx / 4, 0));
  await tester.pump();
  await gesture.moveBy(Offset(dx * 3 / 4, 0));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Widget _pusher() => Builder(
  builder: (context) => TextButton(
    onPressed: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const Text('next'))),
    child: const Text('go'),
  ),
);

void main() {
  test('KIT-T8: the web fades through on every platform, iOS Safari too', () {
    for (final platform in TargetPlatform.values) {
      final b = AppTheme.build(
        brightness: Brightness.light,
        language: 'en',
        platform: platform,
        web: true,
      ).pageTransitionsTheme.builders;
      for (final key in TargetPlatform.values) {
        expect(
          b[key],
          isA<FadeThroughPageTransitionsBuilder>(),
          reason: '${platform.name} theme, ${key.name} key',
        );
      }
    }
    expect(
      AppTheme.build(
        brightness: Brightness.light,
        language: 'en',
        platform: TargetPlatform.iOS,
        web: false,
      ).pageTransitionsTheme.builders[TargetPlatform.iOS],
      isA<CupertinoPageTransitionsBuilder>(),
    );
  });

  test('KIT-T8: iOS gets Cupertino swipe-back, the rest fade-through', () {
    final b = AppPageTransitions.theme.builders;
    expect(b[TargetPlatform.iOS], isA<CupertinoPageTransitionsBuilder>());
    expect(b[TargetPlatform.macOS], isA<CupertinoPageTransitionsBuilder>());
    for (final p in [
      TargetPlatform.android,
      TargetPlatform.linux,
      TargetPlatform.windows,
      TargetPlatform.fuchsia,
    ]) {
      expect(b[p], isA<FadeThroughPageTransitionsBuilder>());
    }
    expect(
      const FadeThroughPageTransitionsBuilder().transitionDuration,
      Motion.gentle,
    );
  });

  testWidgets('KIT-T8: a pushed page fades through over Motion.gentle', (
    tester,
  ) async {
    await pumpApp(tester, _pusher(), platform: TargetPlatform.android);
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(Motion.gentle * 0.2);
    final early = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('next'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(early.opacity.value, 0); // the old page is still fading out
    final scale = tester.widget<ScaleTransition>(
      find
          .ancestor(
            of: find.text('next'),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    expect(scale.scale.value, lessThan(1));
    await tester.pump(Motion.gentle * 0.79);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(Motion.gentle * 0.02);
    await tester.pump();
    final route = ModalRoute.of(tester.element(find.text('next')))!;
    expect(route.animation!.status, AnimationStatus.completed);
  });

  testWidgets('KIT-T8: under reduce motion the page only fades', (
    tester,
  ) async {
    await pumpApp(
      tester,
      _pusher(),
      platform: TargetPlatform.android,
      reduceMotion: true,
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(Motion.gentle * 0.2);
    expect(
      find.ancestor(
        of: find.text('next'),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
    await tester.pump(Motion.gentle * 0.21);
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('next'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('KIT-T8: under reduce motion a pop fades out at once', (
    tester,
  ) async {
    await pumpApp(
      tester,
      _pusher(),
      platform: TargetPlatform.android,
      reduceMotion: true,
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    // The pop mirrors the push: the fade fills the first 40% of the reverse.
    await tester.pump(Motion.standard * 0.2);
    expect(_opacityAbove(tester, 'next'), lessThan(0.5));
    await tester.pump(Motion.standard * 0.21);
    expect(_opacityAbove(tester, 'next'), 0);
    await tester.pumpAndSettle();
    expect(find.text('next'), findsNothing);
  });

  testWidgets(
    'KIT-T8: on iOS a swipe from the leading edge pops a routed page',
    (tester) async {
      await _pumpIosStack(tester, 'en');
      await _swipe(tester, const Offset(10, 400), TestSizes.phone.width * 0.6);
      expect(find.text('home'), findsOneWidget);
      expect(find.text('next'), findsNothing);
    },
  );

  testWidgets('KIT-T8: in Arabic on iOS the swipe starts at the right edge', (
    tester,
  ) async {
    await _pumpIosStack(tester, 'ar');
    // From the left edge it does nothing in right-to-left.
    await _swipe(tester, const Offset(10, 400), TestSizes.phone.width * 0.6);
    expect(find.text('next'), findsOneWidget);
    await _swipe(
      tester,
      Offset(TestSizes.phone.width - 10, 400),
      -TestSizes.phone.width * 0.6,
    );
    expect(find.text('home'), findsOneWidget);
    expect(find.text('next'), findsNothing);
  });
}
