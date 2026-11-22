import 'package:get_it/get_it.dart';
import 'package:kit_app/app/di/modules/auth_module.dart';
import 'package:kit_app/app/di/modules/core_module.dart';
import 'package:kit_app/app/di/modules/data_module.dart';
import 'package:kit_app/app/di/modules/media_module.dart';
import 'package:kit_app/app/di/modules/network_module.dart';
import 'package:kit_app/app/di/modules/notifications_module.dart';
import 'package:kit_app/app/di/modules/routing_module.dart';
import 'package:kit_app/app/di/modules/session_module.dart';
import 'package:kit_app/app/di/modules/settings_module.dart';
import 'package:kit_app/core/cache/cache_layer.dart';
import 'package:kit_app/core/cache/cache_sign_out_hook.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/di/service_locator.dart';
import 'package:kit_app/core/logging/app_log.dart';
import 'package:kit_app/core/media/media_sign_out_hook.dart';
import 'package:kit_app/core/notifications/local_notifications.dart';
import 'package:kit_app/core/notifications/notifications_sign_out_hook.dart';
import 'package:kit_app/core/notifications/push_service.dart';
import 'package:kit_app/core/router/pending_deep_link.dart';
import 'package:kit_app/core/router/pending_deep_link_hook.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/core/telemetry/analytics_sink.dart';
import 'package:kit_app/features/auth/data/repositories/auth_sign_out_hook.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';

/// Registers the app graph. One module per area; each feature adds its own
/// module here. Always register against the abstract type. A project's own
/// crash reporter and analytics sink register before boot; `resetLocator`
/// keeps them across the first boot's reset and every retry, and the no-op
/// defaults fill in what is missing.
Future<void> initDependencies({
  GetIt? locator,
  Future<bool> Function()? askRetry,
}) async {
  final target = locator ?? sl;
  registerTelemetryDefaults(locator: target);
  // AppLog.error reaches the project's reporter, on every boot and retry.
  AppLog.reporter = target<CrashReporter>();
  await registerCoreModule(target);
  registerNetworkModule(target, askRetry: askRetry);
  registerSessionModule(target);
  registerDataModule(target);
  registerSettingsModule(target);
  registerAuthModule(target);
  registerRoutingModule(target);
  // After the routing module: the notification router needs the (lazy) router.
  registerNotificationsModule(target);
  registerMediaModule(target);
  target.registerLazySingleton<List<SignOutHook>>(
    () => [
      AnalyticsSignOutHook(target<AnalyticsSink>()),
      // Before the pending link is cleared: a tap that lands while the
      // notifications are being cleared must not leave a link behind.
      NotificationsSignOutHook(
        target<LocalNotifications>(),
        target<PushService>(),
      ),
      PendingDeepLinkHook(target<PendingDeepLink>()),
      CacheSignOutHook(target<CacheLayer>()),
      target<MediaSignOutHook>(),
      AuthSignOutHook(target<AuthRepository>()),
    ],
  );
}
