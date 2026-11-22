import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/l10n/app_language.dart';

void main() {
  test('KIT-T12: the chosen language wins when the app has it', () {
    expect(appLanguage(chosen: 'ar', device: 'en'), 'ar');
    expect(appLanguage(chosen: 'en', device: 'ar'), 'en');
  });

  test('KIT-T12: no choice, or one the app lacks, is the device language', () {
    expect(appLanguage(chosen: null, device: 'ar'), 'ar');
    expect(appLanguage(chosen: 'fr', device: 'ar'), 'ar');
    expect(appLanguage(chosen: null, device: 'en'), 'en');
  });

  test('KIT-T12: a device language the app lacks is English', () {
    expect(appLanguage(chosen: null, device: 'fr'), 'en');
    expect(appLanguage(chosen: 'de', device: null), 'en');
  });

  test('KIT-T12: the languages are the ones the ARB files ship', () {
    expect(appLanguages, {'en', 'ar'});
  });
}
