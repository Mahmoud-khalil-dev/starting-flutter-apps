import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/utils/string_extensions.dart';

void main() {
  test('KIT-T15: blank text is spaces only', () {
    expect('  '.isBlank, isTrue);
    expect(' a '.isBlank, isFalse);
    expect('  '.nullIfBlank, isNull);
    expect(' a '.nullIfBlank, 'a');
  });

  test('KIT-T15: typed Arabic-Indic digits go to the API as Western', () {
    expect('٠١٢٣٤٥٦٧٨٩'.westernDigits, '0123456789');
    expect('١٢٫٥'.asNumber, 12.5);
    expect('abc'.asNumber, isNull);
  });

  test('KIT-T15: initials take the first letter of two words', () {
    expect('Sara Ali Khan'.initials, 'SA');
    expect('  nour  '.initials, 'N');
    expect('سارة علي'.initials, 'سع');
    expect(''.initials, '');
  });

  test('KIT-T15: ellipsize cuts on characters, not code units', () {
    expect('abcdef'.ellipsize(4), 'abc…');
    expect('abc'.ellipsize(4), 'abc');
    expect('👋🏽👋🏽👋🏽'.ellipsize(2), '👋🏽…');
  });

  test('KIT-T15: ellipsize keeps an Arabic letter with its vowel mark', () {
    expect('يُرجى'.ellipsize(3), 'يُر…');
    expect('يُر'.ellipsize(2), 'يُر');
  });
}
