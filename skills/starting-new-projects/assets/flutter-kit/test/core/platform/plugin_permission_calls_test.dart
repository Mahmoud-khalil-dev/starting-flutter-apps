import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/platform/plugin_permission_platform.dart';

/// The plugin's method channel, answered in the test: what the app sends the
/// operating system, and what it makes of the answer. Status codes are the
/// plugin's own: 0 denied, 1 granted, 2 restricted, 3 limited,
/// 4 permanently denied, 5 provisional.
const _channel = MethodChannel('flutter.baseflow.com/permissions/methods');

// permission_handler's own permission codes.
const _camera = 1;
const _photos = 9;
const _notification = 17;

void main() {
  final messenger =
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;
  final calls = <MethodCall>[];
  var status = 0;

  setUp(() {
    calls.clear();
    status = 0;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'checkPermissionStatus':
          return status;
        case 'requestPermissions':
          final asked = (call.arguments as List).cast<int>();
          return {for (final p in asked) p: status};
        case 'openAppSettings':
          return true;
      }
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  const platform = PluginPermissionPlatform();

  test('KIT-T17: each app permission asks the plugin for its own', () async {
    await platform.status(AppPermission.camera);
    await platform.status(AppPermission.photos);
    await platform.status(AppPermission.notifications);
    expect(calls.map((c) => c.arguments), [_camera, _photos, _notification]);
  });

  test('KIT-T17: the answers become app states', () async {
    status = 1;
    expect(
      await platform.status(AppPermission.camera),
      PermissionState.granted,
    );
    status = 4;
    expect(
      await platform.status(AppPermission.camera),
      PermissionState.permanentlyDenied,
    );
    status = 3;
    expect(
      await platform.status(AppPermission.photos),
      PermissionState.limited,
    );
  });

  test('KIT-T17: request sends one permission and maps the answer', () async {
    status = 1;
    expect(
      await platform.request(AppPermission.notifications),
      PermissionState.granted,
    );
    final request = calls.singleWhere((c) => c.method == 'requestPermissions');
    expect(request.arguments, [_notification]);
  });

  test('KIT-T17: Settings opens through the plugin', () async {
    expect(await platform.openSettings(), isTrue);
    expect(calls.map((c) => c.method), contains('openAppSettings'));
  });
}
