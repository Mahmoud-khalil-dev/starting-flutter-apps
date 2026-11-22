import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/storage_keys.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/data/sources/settings_local_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(SettingsLocalSource, AppPreferences)> _source(
  Map<String, Object> values,
) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = AppPreferences(await SharedPreferences.getInstance());
  return (SettingsLocalSource(prefs), prefs);
}

void main() {
  test('KIT-T12: the keys are fixed', () {
    expect(StorageKeys.settingsThemeMode, 'settings.themeMode');
    expect(StorageKeys.settingsLocale, 'settings.locale');
    expect(StorageKeys.settingsTextScale, 'settings.textScale');
    expect(
      StorageKeys.device,
      containsAll([
        'settings.themeMode',
        'settings.locale',
        'settings.textScale',
      ]),
    );
  });

  test('KIT-T12: nothing stored reads as the defaults', () async {
    final (source, _) = await _source({});
    expect(source.read(), AppSettings.defaults);
  });

  test('KIT-T12: a write reads back', () async {
    final (source, prefs) = await _source({});
    const saved = AppSettings(
      themeMode: ThemeMode.dark,
      locale: Locale('ar'),
      textScale: 1.3,
    );
    await source.write(saved);
    expect(source.read(), saved);
    expect(prefs.read('settings.themeMode'), 'dark');
    expect(prefs.read('settings.locale'), 'ar');
    expect(prefs.read('settings.textScale'), 1.3);
  });

  test('KIT-T12: writing no locale removes the stored one', () async {
    final (source, prefs) = await _source({'settings.locale': 'ar'});
    await source.write(AppSettings.defaults);
    expect(prefs.read('settings.locale'), isNull);
    expect(source.read().locale, isNull);
  });

  test('KIT-T12: an unknown theme or language reads as the default', () async {
    final (source, _) = await _source({
      'settings.themeMode': 'sepia',
      'settings.locale': 'fr',
    });
    final read = source.read();
    expect(read.themeMode, ThemeMode.system);
    expect(read.locale, isNull);
  });

  test('KIT-T12: a stored text size outside the range is clamped', () async {
    final (high, _) = await _source({'settings.textScale': 9.0});
    expect(high.read().textScale, 1.6);
    final (low, _) = await _source({'settings.textScale': 0.1});
    expect(low.read().textScale, 0.85);
  });

  test(
    'KIT-T12: a stored value of the wrong type reads as the default',
    () async {
      final (source, _) = await _source({
        'settings.themeMode': 3,
        'settings.textScale': 'big',
      });
      expect(source.read(), AppSettings.defaults);
    },
  );
}
