import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/cache/cache_entry.dart';
import 'package:kit_app/core/cache/cache_store.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return AppPreferences(await SharedPreferences.getInstance());
}

void main() {
  final entry = CacheEntry(
    value: const {'a': 1},
    storedAt: DateTime.utc(2026, 11, 21),
  );

  test('KIT-T14: the disk store round-trips under the cache prefix', () async {
    final prefs = await _prefs({});
    final store = PreferencesCacheStore(prefs);
    await store.write('notes', entry);
    expect(prefs.read('cache.notes'), isA<String>());
    expect(await store.read('notes'), entry);
  });

  test('KIT-T14: a corrupt disk entry is a miss and is removed', () async {
    final prefs = await _prefs({'cache.notes': 'not json'});
    expect(await PreferencesCacheStore(prefs).read('notes'), isNull);
    expect(prefs.read('cache.notes'), isNull);
  });

  test(
    'KIT-T14: a stored value of another type is a miss and removed',
    () async {
      final prefs = await _prefs({'cache.notes': 42});
      expect(await PreferencesCacheStore(prefs).read('notes'), isNull);
      expect(prefs.read('cache.notes'), isNull);
    },
  );

  test('KIT-T14: clearing the disk store keeps every other key', () async {
    final prefs = await _prefs({'cache.a': '{}', 'settings.locale': 'ar'});
    await PreferencesCacheStore(prefs).clear();
    expect(prefs.read('cache.a'), isNull);
    expect(prefs.read('settings.locale'), 'ar');
  });

  test('KIT-T14: the memory store drops its oldest entry when full', () async {
    final store = MemoryCacheStore(maxEntries: 2);
    await store.write('a', entry);
    await store.write('b', entry);
    await store.write('c', entry);
    expect(await store.read('a'), isNull);
    expect(await store.read('c'), entry);
  });
}
