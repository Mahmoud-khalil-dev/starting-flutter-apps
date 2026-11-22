import 'package:flutter/material.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/storage_keys.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';

/// Reads and writes the settings in the device preferences: the only reader
/// and writer of its three keys. A stored value that is missing, of another
/// type or no longer valid reads as the default.
class SettingsLocalSource {
  const SettingsLocalSource(this._preferences);

  /// The languages the app has strings for.
  static const supportedLanguages = {'en', 'ar'};

  final AppPreferences _preferences;

  AppSettings read() {
    final theme = _preferences.readString(StorageKeys.settingsThemeMode);
    final language = _preferences.readString(StorageKeys.settingsLocale);
    final scale = _preferences.readDouble(StorageKeys.settingsTextScale);
    return AppSettings(
      themeMode: ThemeMode.values.asNameMap()[theme] ?? ThemeMode.system,
      locale: supportedLanguages.contains(language) ? Locale(language!) : null,
      textScale: scale == null ? 1 : AppSettings.clampScale(scale),
    );
  }

  Future<void> write(AppSettings settings) async {
    final language = settings.locale?.languageCode;
    await _preferences.writeString(
      StorageKeys.settingsThemeMode,
      settings.themeMode.name,
    );
    // No choice removes the key: the device language applies.
    if (language == null) {
      await _preferences.remove([StorageKeys.settingsLocale]);
    } else {
      await _preferences.writeString(StorageKeys.settingsLocale, language);
    }
    await _preferences.writeDouble(
      StorageKeys.settingsTextScale,
      settings.textScale,
    );
  }
}
