import 'dart:convert';

import 'package:kit_app/core/cache/cache_entry.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/storage_keys.dart';

/// Where cache entries live. The kit ships memory and shared preferences;
/// a project with large payloads writes a file or database store and
/// registers it as the disk store in `registerDataModule`.
abstract interface class CacheStore {
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, CacheEntry entry);
  Future<void> remove(String key);
  Future<void> clear();
}

/// The fast layer, gone when the app stops. Holds at most [maxEntries];
/// the oldest write goes first.
class MemoryCacheStore implements CacheStore {
  MemoryCacheStore({this.maxEntries = 200});

  final int maxEntries;
  final _entries = <String, CacheEntry>{};

  @override
  Future<CacheEntry?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, CacheEntry entry) async {
    _entries
      ..remove(key)
      ..[key] = entry;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  @override
  Future<void> remove(String key) async {
    _entries.remove(key);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}

/// The disk layer on shared preferences, for small JSON payloads (lists of
/// a few hundred records). An entry that does not read back is removed.
class PreferencesCacheStore implements CacheStore {
  const PreferencesCacheStore(this._preferences);

  final AppPreferences _preferences;

  static String _key(String key) => '${StorageKeys.cachePrefix}$key';

  @override
  Future<CacheEntry?> read(String key) async {
    final raw = _preferences.read(_key(key));
    if (raw == null) return null;
    CacheEntry? entry;
    try {
      entry = raw is String ? CacheEntry.fromJson(jsonDecode(raw)) : null;
    } on FormatException {
      entry = null;
    }
    if (entry == null) await remove(key);
    return entry;
  }

  @override
  Future<void> write(String key, CacheEntry entry) =>
      _preferences.writeString(_key(key), jsonEncode(entry.toJson()));

  @override
  Future<void> remove(String key) => _preferences.remove([_key(key)]);

  @override
  Future<void> clear() => _preferences.remove(
    _preferences.keysStartingWith(StorageKeys.cachePrefix),
  );
}
