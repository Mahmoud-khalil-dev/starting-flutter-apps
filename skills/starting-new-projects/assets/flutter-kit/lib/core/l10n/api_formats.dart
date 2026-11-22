import 'package:intl/intl.dart';
import 'package:kit_app/core/l10n/digits.dart';

/// Dates and times for the API: always 'en' and Western digits, whatever the
/// UI language. Rule `api-locale` checks every
/// DateFormat here names 'en'.
abstract final class ApiFormats {
  static final _date = DateFormat('yyyy-MM-dd', 'en');
  static final _time = DateFormat('HH:mm', 'en');
  static final _weekday = DateFormat('EEE', 'en');

  static String date(DateTime d) => _date.format(d);

  static String time(DateTime d) => _time.format(d);

  /// `MON` to `SUN`.
  static String weekday(DateTime d) => _weekday.format(d).toUpperCase();

  static DateTime parseDate(String text) =>
      _date.parseStrict(normalizeDigits(text));

  static DateTime parseDateTime(String text) =>
      DateTime.parse(normalizeDigits(text));
}
