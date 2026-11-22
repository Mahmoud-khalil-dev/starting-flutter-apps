import 'package:kit_app/core/permissions/app_permission.dart';

/// The operating system's permission calls. The plugin implementation is
/// `PluginPermissionPlatform` in `core/platform`.
abstract interface class PlatformPermission {
  Future<PermissionState> status(AppPermission permission);
  Future<PermissionState> request(AppPermission permission);
  Future<bool> openSettings();
}
