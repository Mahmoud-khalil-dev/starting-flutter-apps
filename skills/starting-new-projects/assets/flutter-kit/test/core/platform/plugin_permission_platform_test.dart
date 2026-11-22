import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/platform/plugin_permission_platform.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  test('KIT-T17: every plugin status maps to one app state', () {
    const expected = {
      PermissionStatus.granted: PermissionState.granted,
      PermissionStatus.provisional: PermissionState.granted,
      PermissionStatus.limited: PermissionState.limited,
      PermissionStatus.denied: PermissionState.denied,
      PermissionStatus.permanentlyDenied: PermissionState.permanentlyDenied,
      PermissionStatus.restricted: PermissionState.permanentlyDenied,
    };
    for (final status in PermissionStatus.values) {
      expect(
        PluginPermissionPlatform.mapStatus(status),
        expected[status],
        reason: status.name,
      );
    }
  });
}
