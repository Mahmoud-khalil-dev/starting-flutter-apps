import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/app/router/app_router.dart';
import 'package:kit_app/app/router/auth_routes.dart';
import 'package:kit_app/app/router/route_guard.dart';
import 'package:kit_app/app/session_recovery.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/router/pending_deep_link.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/session_cubit.dart';

/// `flutter run --dart-define=KIT_GALLERY=true` opens the gallery first.
// A function: a const would be folded to its default and the analyzer
// would flag the argument as redundant.
bool _startInKitGallery() => const bool.fromEnvironment('KIT_GALLERY');

/// The router and its guard. Only the debug gallery is an open path; every
/// app screen needs a session, and the auth screens are the guard's public
/// paths.
void registerRoutingModule(GetIt sl) {
  sl
    // The navigator the router runs on, which the retry dialog asks on.
    ..registerLazySingleton<GlobalKey<NavigatorState>>(GlobalKey.new)
    ..registerLazySingleton<PendingDeepLink>(PendingDeepLink.new)
    ..registerLazySingleton<RouteGuard>(
      () => RouteGuard(
        deepLinks: sl(),
        openPaths: {if (kDebugMode) RouteNames.kitGallery},
        needsProfile: RouteGuard.nameMissing,
      ),
    )
    ..registerLazySingleton<GoRouter>(
      () => createAppRouter(
        session: sl(),
        guard: sl(),
        navigatorKey: sl(),
        kitGallery: kDebugMode,
        startInKitGallery: kDebugMode && _startInKitGallery(),
        authRoutes: authRoutes(
          authCubit: sl.call,
          resendCubit: sl.call,
          avatarCubit: sl.call,
          canUseCamera: sl<PlatformCapabilities>().cameraCapture,
          canOpenSettings: sl<PlatformCapabilities>().appSettingsPage,
          signOut: () => sl<SessionCubit>().signOut(),
        ),
        // The recovery registers after the first frame, so look it up when
        // the button is pressed.
        tryAgain: () => sl<SessionRecovery>().tryAgain(),
      ),
    );
}
