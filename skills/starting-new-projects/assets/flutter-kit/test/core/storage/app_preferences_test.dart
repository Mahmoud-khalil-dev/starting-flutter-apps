import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return AppPreferences(await SharedPreferences.getInstance());
}

void main() {
  group('KIT-T9: AppPreferences', () {
    test('defaults when nothing is stored', () async {
      final prefs = await _prefs({});
      expect(prefs.endOnboarding, isFalse);
      expect(prefs.storageSchema, 0);
      expect(prefs.readString('any.key'), isNull);
      expect(prefs.readDouble('any.key'), isNull);
    });

    test('the preferences round-trip', () async {
      final prefs = await _prefs({});
      await prefs.setEndOnboarding();
      await prefs.setStorageSchema(1);
      expect(prefs.endOnboarding, isTrue);
      expect(prefs.storageSchema, 1);
    });

    test('strings and doubles round-trip under any key', () async {
      final prefs = await _prefs({});
      await prefs.writeString('a.text', 'dark');
      await prefs.writeDouble('a.size', 1.25);
      expect(prefs.readString('a.text'), 'dark');
      expect(prefs.readDouble('a.size'), 1.25);
      expect(prefs.read('a.text'), 'dark');
    });

    test('a value of another type reads as unset', () async {
      final prefs = await _prefs({'a.text': 3, 'a.size': 'big'});
      expect(prefs.readString('a.text'), isNull);
      expect(prefs.readDouble('a.size'), isNull);
    });

    test('remove deletes only the named keys', () async {
      final prefs = await _prefs({'a.text': 'en', 'b.text': 'dark'});
      await prefs.remove(['a.text']);
      expect(prefs.readString('a.text'), isNull);
      expect(prefs.readString('b.text'), 'dark');
    });
  });
}
