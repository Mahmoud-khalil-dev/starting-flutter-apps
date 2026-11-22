import 'package:flutter/foundation.dart';

/// What the running platform can do. Features ask this, never kIsWeb or
/// Platform, so a test can pick any platform. The web never claims a
/// capability it cannot deliver: no system call UI, no in-app purchase, no
/// biometrics.
class PlatformCapabilities {
  const PlatformCapabilities({required this.isWeb, required this.platform});

  factory PlatformCapabilities.current() =>
      PlatformCapabilities(isWeb: kIsWeb, platform: defaultTargetPlatform);

  final bool isWeb;
  final TargetPlatform platform;

  bool get _mobile =>
      !isWeb &&
      (platform == TargetPlatform.iOS || platform == TargetPlatform.android);

  /// The system call UI of the phone platforms. The kit has no
  /// calls; a project that adds them gates the feature on this.
  bool get nativeCalls => _mobile;

  /// Store purchases. The kit has none; gate a project's on this.
  bool get inAppPurchase => _mobile;

  bool get biometrics => _mobile;

  /// Push notifications.
  bool get push => _mobile;

  /// A crash reporter with a native SDK has no web support.
  bool get crashReporting => _mobile;

  /// The platform keychain or keystore backs secure storage.
  bool get keychainStorage => _mobile;

  /// The Apple look: iOS and macOS apps. The web is always Material, even
  /// when the browser runs on an iPhone or a Mac.
  bool get cupertinoLook =>
      !isWeb &&
      (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS);

  /// A backdrop blur behind sheets, dialogs and the glass bar. On the web it
  /// is costly and uneven, so only the scrim or the translucent fill shows.
  bool get backdropBlur => !isWeb;

  /// The system share sheet. The web copies to the clipboard instead.
  bool get shareSheet => _mobile;

  /// `tel:` links. Desktop and the web have no dialer.
  bool get dial => _mobile;

  /// Notifications shown by the app itself. The web build has none.
  bool get localNotifications => _mobile;

  /// Whether reading the photo library asks a permission. The web picks
  /// files through the browser and never asks.
  bool get photoLibraryPermission => _mobile;

  /// The system's own page for this app's permissions, which the app can
  /// open. A browser has none: the user changes a site's permissions in the
  /// browser itself.
  bool get appSettingsPage => _mobile;

  /// Taking a photo with a camera. The web and desktop choose a file.
  bool get cameraCapture => _mobile;
}
