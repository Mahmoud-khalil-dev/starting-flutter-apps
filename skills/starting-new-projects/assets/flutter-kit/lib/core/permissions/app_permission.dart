enum AppPermission { notifications, camera, photos }

/// Every state a permission can be in, as the app sees it. [notAsked] is
/// the platform's "denied" before the app ever asked; [revoked] was granted
/// once and later turned off in Settings.
enum PermissionState {
  notAsked,
  granted,
  limited,
  denied,
  permanentlyDenied,
  revoked,
  unavailable;

  bool get usable => this == granted || this == limited;

  /// Only Settings can change it now.
  bool get needsSettings => this == permanentlyDenied || this == revoked;
}
