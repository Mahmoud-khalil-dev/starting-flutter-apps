import 'package:kit_app/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Typed reads and writes of the app's preferences.
class AppPreferences {
  const AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  /// A string stored under [key]. A value of another type, which an old
  /// build or a bad edit could leave behind, reads as unset.
  String? readString(String key) {
    final value = _prefs.get(key);
    return value is String ? value : null;
  }

  Future<void> writeString(String key, String value) async =>
      _prefs.setString(key, value);

  /// A double stored under [key], or null as for [readString].
  double? readDouble(String key) {
    final value = _prefs.get(key);
    return value is double ? value : null;
  }

  Future<void> writeDouble(String key, double value) async =>
      _prefs.setDouble(key, value);

  /// The saved user object as JSON text, or null.
  String? get userJson => _prefs.getString(StorageKeys.user);

  Future<void> setUserJson(String json) async =>
      _prefs.setString(StorageKeys.user, json);

  bool get endOnboarding => _prefs.getBool(StorageKeys.endOnboarding) ?? false;

  Future<void> setEndOnboarding() async =>
      _prefs.setBool(StorageKeys.endOnboarding, true);

  /// The version `SchemaVersion` last stamped; 0 on a fresh install.
  int get storageSchema => _prefs.getInt(StorageKeys.storageSchema) ?? 0;

  Future<void> setStorageSchema(int version) async =>
      _prefs.setInt(StorageKeys.storageSchema, version);

  Future<void> remove(Iterable<String> keys) async {
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// A raw read, for a migration that must see a value's stored type.
  Object? read(String key) => _prefs.get(key);

  /// Every stored key that starts with [prefix].
  Set<String> keysStartingWith(String prefix) => {
    for (final key in _prefs.getKeys())
      if (key.startsWith(prefix)) key,
  };
}
