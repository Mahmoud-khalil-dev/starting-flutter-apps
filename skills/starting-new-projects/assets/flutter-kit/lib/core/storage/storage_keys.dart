/// Every key the app persists. Installed users depend on them byte for byte:
/// rename one only with a migration (see `SchemaVersion`).
abstract final class StorageKeys {
  /// Secure storage, read with default FlutterSecureStorage options.
  static const token = 'token';

  // SharedPreferences.
  /// The signed-in user object, kept for an offline start.
  static const user = 'user';
  static const endOnboarding = 'endOnboarding';

  // The settings feature's device choices.
  static const settingsThemeMode = 'settings.themeMode';
  static const settingsLocale = 'settings.locale';
  static const settingsTextScale = 'settings.textScale';

  /// Which permissions the app has asked for, and which were granted once.
  /// Device facts, kept across sign-outs.
  static const permissionsAsked = 'permissions_asked';
  static const permissionsGranted = 'permissions_granted';

  /// The stamp `SchemaVersion` keeps.
  static const storageSchema = 'storage_schema';

  /// Every cache entry's key starts with this. The cache owns these keys;
  /// they are not listed in [preferences] and are wiped through
  /// `CacheSignOutHook`, not [userData].
  static const cachePrefix = 'cache.';

  static const List<String> secure = [token];

  /// Removed on every sign-out. Add the keys the signed-in user owns.
  static const List<String> userData = [user];

  /// Device choices, kept across sign-outs.
  static const List<String> device = [
    endOnboarding,
    settingsThemeMode,
    settingsLocale,
    settingsTextScale,
    storageSchema,
    permissionsAsked,
    permissionsGranted,
  ];

  /// Every preferences key.
  static const List<String> preferences = [...userData, ...device];
}
