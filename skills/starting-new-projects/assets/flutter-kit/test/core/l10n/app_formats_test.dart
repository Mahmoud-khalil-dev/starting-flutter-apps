import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kit_app/core/l10n/app_formats.dart';
import 'package:kit_app/core/l10n/digits.dart';

const en = AppFormats('en');
const ar = AppFormats('ar');
final _latin = RegExp('[A-Za-z]');

String _plain(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');

final lri = String.fromCharCode(0x2066);
final fsi = String.fromCharCode(0x2068);
final pdi = String.fromCharCode(0x2069);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  test('KIT-T8: numbers group and localize', () {
    expect(en.formatNumber(1234567), '1,234,567');
    expect(ar.formatNumber(1234567), '١٬٢٣٤٬٥٦٧');
    expect(en.formatNumber(12.5, decimals: 2), '12.50');
    expect(ar.formatNumber(12.5, decimals: 2), '١٢٫٥٠');
  });

  test('KIT-T8: amounts put the symbol first and isolate it in Arabic', () {
    expect(en.formatAmount(150, symbol: r'$'), r'$150');
    expect(en.formatAmount(149.5, symbol: r'$'), r'$149.50');
    expect(ar.formatAmount(150, symbol: r'$'), '$lri\$١٥٠$pdi');
  });

  test('KIT-T8: durations and countdowns read as clocks', () {
    expect(en.formatDuration(const Duration(minutes: 5, seconds: 9)), '05:09');
    expect(
      en.formatDuration(const Duration(hours: 1, minutes: 5, seconds: 9)),
      '1:05:09',
    );
    expect(
      ar.formatDuration(const Duration(minutes: 5, seconds: 9)),
      '$lri٠٥:٠٩$pdi',
    );
    expect(
      en.formatCountdown(const Duration(hours: 3, minutes: 4, seconds: 5)),
      '03:04:05',
    );
    expect(en.formatCountdown(const Duration(seconds: -4)), '00:00:00');
    expect(en.formatCountdown(const Duration(days: 1, hours: 2)), '26:00:00');
  });

  test('KIT-T8: phone numbers keep their order in Arabic', () {
    expect(en.formatPhone(' +20 100 123 4567 '), '+20 100 123 4567');
    expect(ar.formatPhone('+20 100'), '$lri+٢٠ ١٠٠$pdi');
  });

  test('KIT-T8: times and dates in English', () {
    final t = DateTime(2026, 11, 24, 9, 5);
    expect(_plain(en.formatTime(t)), '9:05 AM');
    expect(en.formatDate(t), 'Tuesday, November 24, 2026');
    expect(en.formatShortDate(t), 'Nov 24');
    expect(
      _plain(en.formatTimeRange(t, DateTime(2026, 11, 24, 17))),
      '9:05 AM – 5:00 PM',
    );
  });

  test('KIT-T8: times and dates in Arabic carry Arabic-Indic digits only', () {
    final t = DateTime(2026, 11, 24, 9, 5);
    for (final text in [
      ar.formatTime(t),
      ar.formatDate(t),
      ar.formatShortDate(t),
      ar.formatTimeRange(t, DateTime(2026, 11, 24, 17)),
    ]) {
      expect(hasWesternDigit(text), isFalse, reason: text);
      expect(_latin.hasMatch(text), isFalse, reason: text);
    }
    expect(ar.formatDate(t), contains('٢٤'));
    expect(ar.formatDate(t), contains('٢٠٢٦'));
    expect(ar.formatTime(t), contains('٠٥'));
    expect(ar.formatTimeRange(t, t), startsWith(fsi));
  });

  test('KIT-T8: Arabic time range isolates both ends and keeps the digits', () {
    final t = DateTime(2026, 11, 24, 9, 5);
    final range = ar.formatTimeRange(t, DateTime(2026, 11, 24, 17));
    expect(range, contains(pdi));
    expect(fsi.allMatches(range), hasLength(2));
    expect(pdi.allMatches(range), hasLength(2));
    expect(range, contains('٩'));
    expect(range, contains('٥'));
    expect(range, contains('٥:٠٠'));
  });

  test('KIT-T8: digits() localizes free text for Arabic only', () {
    expect(en.digits('3 days'), '3 days');
    expect(ar.digits('3'), '٣');
  });

  test('KIT-T18: percentages follow the screen language', () {
    expect(en.formatPercent(42), '42%');
    expect(ar.formatPercent(42), '٤٢٪');
  });
}
