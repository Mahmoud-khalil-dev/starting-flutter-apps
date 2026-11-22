import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/permissions/permission_platform.dart';
import 'package:kit_app/core/permissions/permissions.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Platform extends Mock implements PlatformPermission {}

const _phone = PlatformCapabilities(isWeb: false, platform: TargetPlatform.iOS);
const _web = PlatformCapabilities(isWeb: true, platform: TargetPlatform.iOS);
const AppPermission _camera = AppPermission.camera;

void main() {
  late _Platform platform;
  late AppPreferences preferences;

  setUpAll(() => registerFallbackValue(AppPermission.camera));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = AppPreferences(await SharedPreferences.getInstance());
    platform = _Platform();
  });

  Permissions permissions([PlatformCapabilities capabilities = _phone]) =>
      Permissions(
        platform: platform,
        preferences: preferences,
        capabilities: capabilities,
      );

  void platformSays(PermissionState state) =>
      when(() => platform.status(any())).thenAnswer((_) async => state);

  test('KIT-T17: denied and never asked is not asked', () async {
    platformSays(PermissionState.denied);
    expect(await permissions().check(_camera), PermissionState.notAsked);
  });

  test('KIT-T17: asking records it; a refusal is then denied', () async {
    platformSays(PermissionState.denied);
    when(
      () => platform.request(_camera),
    ).thenAnswer((_) async => PermissionState.denied);
    final p = permissions();
    expect(await p.request(_camera), PermissionState.denied);
    expect(await p.check(_camera), PermissionState.denied);
  });

  test('KIT-T17: a refusal is remembered across a restart', () async {
    platformSays(PermissionState.denied);
    when(
      () => platform.request(_camera),
    ).thenAnswer((_) async => PermissionState.denied);
    await permissions().request(_camera);
    // A new Permissions over the same stored preferences.
    expect(await permissions().check(_camera), PermissionState.denied);
  });

  test('KIT-T17: limited and permanently denied pass through', () async {
    platformSays(PermissionState.limited);
    expect(
      await permissions().check(AppPermission.photos),
      PermissionState.limited,
    );
    platformSays(PermissionState.permanentlyDenied);
    expect(
      await permissions().check(_camera),
      PermissionState.permanentlyDenied,
    );
  });

  test(
    'KIT-T17: limited access is usable and is remembered as granted',
    () async {
      platformSays(PermissionState.limited);
      final p = permissions();
      expect(PermissionState.limited.usable, isTrue);
      await p.check(AppPermission.photos);
      platformSays(PermissionState.denied);
      expect(await p.check(AppPermission.photos), PermissionState.revoked);
    },
  );

  test('KIT-T17: granted once, then off in Settings, is revoked', () async {
    platformSays(PermissionState.granted);
    final p = permissions();
    expect(await p.check(_camera), PermissionState.granted);
    platformSays(PermissionState.denied);
    expect(await p.check(_camera), PermissionState.revoked);
    platformSays(PermissionState.permanentlyDenied);
    expect(await p.check(_camera), PermissionState.revoked);
  });

  test('KIT-T17: a permission turned back on leaves revoked', () async {
    platformSays(PermissionState.granted);
    final p = permissions();
    await p.check(_camera);
    platformSays(PermissionState.denied);
    expect(await p.check(_camera), PermissionState.revoked);
    platformSays(PermissionState.granted);
    expect(await p.check(_camera), PermissionState.granted);
  });

  test(
    'KIT-T17: a permission that needs Settings is not asked again',
    () async {
      platformSays(PermissionState.permanentlyDenied);
      expect(
        await permissions().request(_camera),
        PermissionState.permanentlyDenied,
      );
      verifyNever(() => platform.request(any()));
    },
  );

  test('KIT-T17: a revoked permission is not asked again either', () async {
    platformSays(PermissionState.granted);
    final p = permissions();
    await p.check(_camera);
    platformSays(PermissionState.denied);
    expect(await p.request(_camera), PermissionState.revoked);
    verifyNever(() => platform.request(any()));
  });

  test('KIT-T17: a granted permission is not asked again', () async {
    platformSays(PermissionState.granted);
    expect(await permissions().request(_camera), PermissionState.granted);
    verifyNever(() => platform.request(any()));
  });

  test('KIT-T17: the web has no notification permission to ask', () async {
    expect(
      await permissions(_web).check(AppPermission.notifications),
      PermissionState.unavailable,
    );
    expect(
      await permissions(_web).request(AppPermission.notifications),
      PermissionState.unavailable,
    );
    verifyZeroInteractions(platform);
  });

  test('KIT-T17: the web picks photos in the browser and never asks', () async {
    expect(
      await permissions(_web).check(AppPermission.photos),
      PermissionState.granted,
    );
    verifyZeroInteractions(platform);
  });

  test(
    'KIT-T17: the web camera is not asked until the browser was asked',
    () async {
      platformSays(PermissionState.denied);
      final p = permissions(_web);
      expect(await p.check(_camera), PermissionState.notAsked);
      when(
        () => platform.request(_camera),
      ).thenAnswer((_) async => PermissionState.granted);
      expect(await p.request(_camera), PermissionState.granted);
      verify(() => platform.request(_camera)).called(1);
    },
  );

  test('KIT-T17: nothing is asked while only checking', () async {
    platformSays(PermissionState.denied);
    await permissions().check(AppPermission.notifications);
    verifyNever(() => platform.request(any()));
  });

  test('KIT-T17: Settings opens through the platform', () async {
    when(platform.openSettings).thenAnswer((_) async => true);
    expect(await permissions().openSettings(), isTrue);
  });
}
