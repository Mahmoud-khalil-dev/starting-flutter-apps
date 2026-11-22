import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';

List<bool> _all(PlatformCapabilities c) => [
  c.nativeCalls,
  c.inAppPurchase,
  c.biometrics,
  c.push,
  c.crashReporting,
  c.keychainStorage,
];

void main() {
  group('KIT-T8: PlatformCapabilities', () {
    test('iOS and Android can do everything', () {
      const ios = PlatformCapabilities(
        isWeb: false,
        platform: TargetPlatform.iOS,
      );
      const android = PlatformCapabilities(
        isWeb: false,
        platform: TargetPlatform.android,
      );
      expect(_all(ios), everyElement(isTrue));
      expect(_all(android), everyElement(isTrue));
    });

    test('the web can do none of it, whatever browser OS it runs on', () {
      for (final platform in TargetPlatform.values) {
        final web = PlatformCapabilities(isWeb: true, platform: platform);
        expect(_all(web), everyElement(isFalse), reason: '$platform');
      }
    });

    test('desktop is not a target', () {
      const mac = PlatformCapabilities(
        isWeb: false,
        platform: TargetPlatform.macOS,
      );
      expect(_all(mac), everyElement(isFalse));
    });

    test('KIT-T15: the share sheet and dialing are phone-only', () {
      const web = PlatformCapabilities(
        isWeb: true,
        platform: TargetPlatform.android,
      );
      const ios = PlatformCapabilities(
        isWeb: false,
        platform: TargetPlatform.iOS,
      );
      const mac = PlatformCapabilities(
        isWeb: false,
        platform: TargetPlatform.macOS,
      );
      expect(web.shareSheet, isFalse);
      expect(web.dial, isFalse);
      expect(ios.shareSheet, isTrue);
      expect(ios.dial, isTrue);
      expect(mac.shareSheet, isFalse);
      expect(mac.dial, isFalse);
    });
  });

  test('KIT-T17: local notifications are phone-only; photos ask on phones', () {
    const web = PlatformCapabilities(isWeb: true, platform: TargetPlatform.iOS);
    const ios = PlatformCapabilities(
      isWeb: false,
      platform: TargetPlatform.iOS,
    );
    const mac = PlatformCapabilities(
      isWeb: false,
      platform: TargetPlatform.macOS,
    );
    expect(web.localNotifications, isFalse);
    expect(web.photoLibraryPermission, isFalse);
    expect(ios.localNotifications, isTrue);
    expect(ios.photoLibraryPermission, isTrue);
    expect(mac.localNotifications, isFalse);
  });

  test('KIT-T17: only the phones have a settings page for the app', () {
    const web = PlatformCapabilities(isWeb: true, platform: TargetPlatform.iOS);
    const ios = PlatformCapabilities(
      isWeb: false,
      platform: TargetPlatform.iOS,
    );
    const android = PlatformCapabilities(
      isWeb: false,
      platform: TargetPlatform.android,
    );
    expect(web.appSettingsPage, isFalse);
    expect(ios.appSettingsPage, isTrue);
    expect(android.appSettingsPage, isTrue);
  });

  test('KIT-T18: only the phones take a photo with a camera', () {
    const web = PlatformCapabilities(isWeb: true, platform: TargetPlatform.iOS);
    const ios = PlatformCapabilities(
      isWeb: false,
      platform: TargetPlatform.iOS,
    );
    const mac = PlatformCapabilities(
      isWeb: false,
      platform: TargetPlatform.macOS,
    );
    expect(web.cameraCapture, isFalse);
    expect(mac.cameraCapture, isFalse);
    expect(ios.cameraCapture, isTrue);
  });
}
