import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kit_app/core/l10n/app_formats.dart';
import 'package:kit_app/core/l10n/format_extensions.dart';

void main() {
  final day = DateTime(2026, 11, 21, 9, 5);
  final utcDay = DateTime.utc(2026, 11, 21, 9, 5);

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  test('KIT-T15: the API gets English dates with Western digits', () {
    expect(utcDay.apiDate, '2026-11-21');
    expect(utcDay.apiTime, '09:05');
  });

  test('KIT-T15: display dates use the screen language', () {
    const ar = AppFormats('ar');
    expect(day.displayDate(ar), ar.formatDate(day));
    expect(day.displayDate(ar), contains('٢١'));
    expect(day.displayShortDate(ar), ar.formatShortDate(day));
    expect(day.displayTime(const AppFormats('en')), contains('9'));
    expect(day.displayTime(ar), ar.formatTime(day));
    expect(42.display(ar), '٤٢');
    expect(1234.5.display(const AppFormats('en'), decimals: 1), '1,234.5');
  });

  test('KIT-T15: dateOnly and isSameDay ignore the time', () {
    expect(day.dateOnly, DateTime(2026, 11, 21));
    expect(day.isSameDay(DateTime(2026, 11, 21, 23, 59)), isTrue);
    expect(day.isSameDay(DateTime(2026, 11, 22)), isFalse);
  });

  test('KIT-T15: API dates are UTC, English, Western digits', () {
    final instant = DateTime.parse('2026-11-21T23:30:00Z');
    expect(instant.apiDate, '2026-11-21');
    expect(instant.apiTime, '23:30');
    // The same instant held as a local value sends the same text.
    expect(instant.toLocal().apiDate, '2026-11-21');
    expect(instant.toLocal().apiTime, '23:30');
    final late = DateTime.parse('2026-11-21T23:30:00-05:00');
    expect(late.apiDate, '2026-11-22');
    expect(late.apiTime, '04:30');
  });

  test('KIT-T15: display shows local time for a UTC instant', () {
    final instant = DateTime.parse('2026-11-21T23:30:00Z');
    const en = AppFormats('en');
    const ar = AppFormats('ar');
    expect(instant.displayTime(en), en.formatTime(instant.toLocal()));
    expect(instant.displayDate(ar), ar.formatDate(instant.toLocal()));
    expect(instant.displayShortDate(en), en.formatShortDate(instant.toLocal()));
  });
}
