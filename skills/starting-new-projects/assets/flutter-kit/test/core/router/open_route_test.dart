import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/app/router/app_route.dart';
import 'package:kit_app/core/router/open_route.dart';
import 'package:kit_app/core/router/route_names.dart';

Future<GoRouter> _pump(WidgetTester tester) async {
  Widget screen(BuildContext context, GoRouterState state) =>
      Text('at ${state.matchedLocation}');
  final router = GoRouter(
    initialLocation: RouteNames.home,
    routes: [
      appRoute(path: RouteNames.home, builder: screen),
      appRoute(path: RouteNames.settings, builder: screen),
      appRoute(path: '/details', builder: screen),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  return router;
}

void main() {
  testWidgets(
    'KIT-T10: pages are MaterialPages named by path, with extra as arguments',
    (tester) async {
      final router = await _pump(tester);
      unawaited(router.push<void>('/details', extra: {'id': 7}));
      await tester.pumpAndSettle();
      final route = ModalRoute.of(tester.element(find.text('at /details')))!;
      expect(route, isA<MaterialRouteTransitionMixin<dynamic>>());
      expect(route.settings.name, '/details');
      expect(route.settings.arguments, {'id': 7});
    },
  );

  testWidgets('KIT-T10: openRoute goes to a tab and pushes anything else', (
    tester,
  ) async {
    final router = await _pump(tester);
    final context = tester.element(find.text('at /home'));
    openRoute(context, '/details');
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    openRoute(tester.element(find.text('at /details')), RouteNames.settings);
    await tester.pumpAndSettle();
    expect(find.text('at /settings'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
