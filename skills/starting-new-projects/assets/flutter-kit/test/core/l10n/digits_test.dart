import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/l10n/digits.dart';

final lri = String.fromCharCode(0x2066);
final fsi = String.fromCharCode(0x2068);
final pdi = String.fromCharCode(0x2069);

void main() {
  test('KIT-T8: localizeDigits maps Western digits only', () {
    expect(localizeDigits('0123456789'), '٠١٢٣٤٥٦٧٨٩');
    expect(localizeDigits('Room 12, floor 3'), 'Room ١٢, floor ٣');
    expect(localizeDigits('١٢'), '١٢');
  });

  test('KIT-T8: normalizeDigits accepts Arabic-Indic and Persian digits', () {
    expect(normalizeDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    expect(normalizeDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    expect(normalizeDigits('١٢٫٥'), '12.5');
    expect(normalizeDigits('١٬٠٠٠'), '1000');
    expect(normalizeDigits('+٢٠ 100'), '+20 100');
  });

  test(
    'KIT-T8: normalizeDigits handles mixed Arabic-Indic, Persian, Western',
    () {
      expect(normalizeDigits('٢۰2٦-۱١-2٤'), '2026-11-24');
    },
  );

  test('KIT-T8: isolates wrap text and Western digits are found', () {
    expect(isolate('a'), '${fsi}a$pdi');
    expect(ltrIsolate('+20'), '$lri+20$pdi');
    expect(hasWesternDigit('٠٩:٠٠'), isFalse);
    expect(hasWesternDigit('٠9'), isTrue);
  });
}
