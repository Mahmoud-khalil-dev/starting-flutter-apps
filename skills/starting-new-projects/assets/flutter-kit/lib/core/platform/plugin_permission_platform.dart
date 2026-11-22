import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/permissions/permission_platform.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

class PluginPermissionPlatform implements PlatformPermission {
  const PluginPermissionPlatform();

  static handler.Permission _of(AppPermission permission) =>
      switch (permission) {
        AppPermission.notifications => handler.Permission.notification,
        AppPermission.camera => handler.Permission.camera,
        AppPermission.photos => handler.Permission.photos,
      };

  /// Restricted (parental controls, device policy) is treated as
  /// permanently denied: the user cannot grant it from the app.
  static PermissionState mapStatus(handler.PermissionStatus status) =>
      switch (status) {
        handler.PermissionStatus.granted ||
        handler.PermissionStatus.provisional => PermissionState.granted,
        handler.PermissionStatus.limited => PermissionState.limited,
        handler.PermissionStatus.denied => PermissionState.denied,
        handler.PermissionStatus.permanentlyDenied ||
        handler.PermissionStatus.restricted =>
          PermissionState.permanentlyDenied,
      };

  @override
  Future<PermissionState> status(AppPermission permission) async =>
      mapStatus(await _of(permission).status);

  @override
  Future<PermissionState> request(AppPermission permission) async =>
      mapStatus(await _of(permission).request());

  @override
  Future<bool> openSettings() => handler.openAppSettings();
}
