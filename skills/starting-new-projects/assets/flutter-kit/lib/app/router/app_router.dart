import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_routes.dart';
import 'package:kit_app/app/router/app_route.dart';
import 'package:kit_app/app/router/route_guard.dart';
import 'package:kit_app/app/shell/app_shell.dart';
import 'package:kit_app/app/start/start_screen.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/features/home/presentation/view/home_screen.dart';
import 'package:kit_app/features/settings/presentation/view/settings_screen.dart';

/// The app router: the splash, the auth screens ([authRoutes]), then the
/// shell with its two tabs. A feature
/// adds its routes here (a tab inside the shell route, anything else beside
/// it) and its path to `RouteNames` and `RouteGuard.access`.
///
/// [tryAgain] is the splash's Try again; [guard] decides every redirect from
/// the session, which is also the router's refresh listenable. [kitGallery]
/// mounts the component gallery; [startInKitGallery] opens it first.
/// [authRoutes] come from `authRoutes()` in `auth_routes.dart`.
GoRouter createAppRouter({
  required SessionCubit session,
  required RouteGuard guard,
  required Future<void> Function() tryAgain,
  GlobalKey<NavigatorState>? navigatorKey,
  String initialLocation = RouteNames.start,
  bool kitGallery = false,
  bool startInKitGallery = false,
  List<RouteBase> authRoutes = const [],
}) => GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: kitGallery && startInKitGallery
      ? RouteNames.kitGallery
      : initialLocation,
  refreshListenable: session,
  redirect: (context, state) =>
      guard.redirect(session.state, state.uri.toString()),
  onException: (context, state, router) => router.go(RouteNames.start),
  routes: [
    if (kitGallery) ...kitGalleryRoutes(),
    ...authRoutes,
    appRoute(
      path: RouteNames.start,
      builder: (context, state) => StartScreen(
        session: session,
        onTryAgain: tryAgain,
        onRoute: () => context.go(RouteNames.home),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => ListenableBuilder(
        listenable: session,
        builder: (context, _) => AppShell(
          role: session.state.role,
          location: state.matchedLocation,
          onSelect: context.go,
          child: child,
        ),
      ),
      routes: [
        appRoute(
          path: RouteNames.home,
          builder: (context, state) => const HomeScreen(),
        ),
        appRoute(
          path: RouteNames.settings,
          builder: (context, state) =>
              SettingsScreen(onSignOut: session.signOut),
        ),
      ],
    ),
  ],
);
