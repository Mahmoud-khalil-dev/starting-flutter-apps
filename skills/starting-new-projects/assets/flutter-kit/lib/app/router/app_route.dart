import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A MaterialPage: iOS gets the interactive swipe-back, Android its own
/// transition. Its name is the matched path and its arguments are `extra`,
/// so `ModalRoute.of(context).settings` reads the path and the arguments.
Page<void> appPage(GoRouterState state, Widget child) => MaterialPage<void>(
  key: state.pageKey,
  name: state.matchedLocation,
  arguments: state.extra,
  child: child,
);

GoRoute appRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
  GlobalKey<NavigatorState>? parentNavigatorKey,
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  parentNavigatorKey: parentNavigatorKey,
  routes: routes,
  pageBuilder: (context, state) => appPage(state, builder(context, state)),
);
