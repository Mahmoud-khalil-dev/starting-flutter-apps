import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/permissions/permission_platform.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/storage_keys.dart';

/// The one way the app asks for a permission. It remembers what it asked
/// and what was granted, so it can tell "never asked" from "refused" and
/// notice a permission turned off later in Settings. It never asks by
/// itself: a screen that explains why calls [request].
class Permissions {
  Permissions({
    required this._platform,
    required this._preferences,
    required this._capabilities,
  });

  final PlatformPermission _platform;
  final AppPreferences _preferences;
  final PlatformCapabilities _capabilities;

  Set<String> _read(String key) => switch (_preferences.readString(key)) {
    final String names when names.isNotEmpty => names.split(',').toSet(),
    _ => {},
  };

  Future<void> _add(String key, AppPermission permission) async {
    final names = _read(key);
    if (!names.add(permission.name)) return;
    await _preferences.writeString(key, names.join(','));
  }

  /// What this platform answers without asking the operating system. The
  /// web camera is not here: the browser asks the user itself, so it goes
  /// through the platform like a phone's and reads "not asked" until then.
  PermissionState? _fixed(AppPermission permission) => switch (permission) {
    AppPermission.notifications when !_capabilities.localNotifications =>
      PermissionState.unavailable,
    AppPermission.photos when !_capabilities.photoLibraryPermission =>
      PermissionState.granted,
    _ => null,
  };

  Future<PermissionState> check(AppPermission permission) async {
    final fixed = _fixed(permission);
    if (fixed != null) return fixed;
    final raw = await _platform.status(permission);
    if (raw.usable) {
      await _add(StorageKeys.permissionsGranted, permission);
      return raw;
    }
    if (_read(StorageKeys.permissionsGranted).contains(permission.name)) {
      return PermissionState.revoked;
    }
    if (raw == PermissionState.denied &&
        !_read(StorageKeys.permissionsAsked).contains(permission.name)) {
      return PermissionState.notAsked;
    }
    return raw;
  }

  Future<PermissionState> request(AppPermission permission) async {
    final now = await check(permission);
    if (now.usable || now.needsSettings || now == PermissionState.unavailable) {
      return now;
    }
    await _add(StorageKeys.permissionsAsked, permission);
    final answer = await _platform.request(permission);
    if (answer.usable) await _add(StorageKeys.permissionsGranted, permission);
    return answer;
  }

  Future<bool> openSettings() => _platform.openSettings();
}
