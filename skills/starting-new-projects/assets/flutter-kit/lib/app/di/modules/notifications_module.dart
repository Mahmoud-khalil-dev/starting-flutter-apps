import 'package:get_it/get_it.dart';
import 'package:kit_app/core/notifications/local_notifications.dart';
import 'package:kit_app/core/notifications/notification_router.dart';
import 'package:kit_app/core/notifications/push_service.dart';
import 'package:kit_app/core/permissions/permission_platform.dart';
import 'package:kit_app/core/permissions/permissions.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/platform/plugin_local_notifications.dart';
import 'package:kit_app/core/platform/plugin_permission_platform.dart';

void registerNotificationsModule(GetIt sl) {
  final capabilities = sl<PlatformCapabilities>();
  sl
    // The vendor slot: replace with the project's PushService.
    ..registerLazySingleton<PushService>(() => const NoopPushService())
    ..registerLazySingleton<LocalNotifications>(
      () => capabilities.localNotifications
          ? PluginLocalNotifications()
          : const NoopLocalNotifications(),
    )
    ..registerLazySingleton<NotificationRouter>(() => NotificationRouter(sl()))
    ..registerLazySingleton<PlatformPermission>(
      () => const PluginPermissionPlatform(),
    )
    ..registerLazySingleton<Permissions>(
      () => Permissions(
        platform: sl(),
        preferences: sl(),
        capabilities: capabilities,
      ),
    );
}
