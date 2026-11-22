import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';

void main() {
  test('KIT-T12: the defaults follow the system at normal size', () {
    expect(AppSettings.defaults.themeMode, ThemeMode.system);
    expect(AppSettings.defaults.locale, isNull);
    expect(AppSettings.defaults.textScale, 1.0);
  });

  test('KIT-T12: copyWith changes one field and keeps the others', () {
    final changed = AppSettings.defaults.copyWith(themeMode: ThemeMode.dark);
    expect(changed.themeMode, ThemeMode.dark);
    expect(changed.locale, isNull);
    expect(changed.textScale, 1.0);
    final sized = changed.copyWith(textScale: 1.3);
    expect(sized.themeMode, ThemeMode.dark);
    expect(sized.textScale, 1.3);
  });

  test('KIT-T12: copyWith sets a locale and clears it again', () {
    final arabic = AppSettings.defaults.copyWith(locale: const Locale('ar'));
    expect(arabic.locale, const Locale('ar'));
    expect(arabic.copyWith(textScale: 1.1).locale, const Locale('ar'));
    expect(arabic.copyWith(clearLocale: true).locale, isNull);
  });

  test('KIT-T12: settings with the same values are equal', () {
    expect(
      AppSettings.defaults.copyWith(locale: const Locale('en')),
      AppSettings.defaults.copyWith(locale: const Locale('en')),
    );
    expect(
      AppSettings.defaults,
      isNot(AppSettings.defaults.copyWith(textScale: 1.2)),
    );
  });

  test('KIT-T12: clampScale keeps text size between 0.85 and 1.6', () {
    expect(AppSettings.minTextScale, 0.85);
    expect(AppSettings.maxTextScale, 1.6);
    expect(AppSettings.clampScale(0.2), 0.85);
    expect(AppSettings.clampScale(3), 1.6);
    expect(AppSettings.clampScale(1.25), 1.25);
  });
}
