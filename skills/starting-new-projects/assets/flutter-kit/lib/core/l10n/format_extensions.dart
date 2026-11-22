import 'package:kit_app/core/l10n/api_formats.dart';
import 'package:kit_app/core/l10n/app_formats.dart';

/// Dates go to the API through [apiDate] and [apiTime] (UTC, 'en', Western
/// digits) and to the screen through the display getters (local time, the
/// screen language, Arabic-Indic digits in Arabic). Nothing else formats a
/// date. A day with no time, such as a birthday, travels as a [dateOnly]
/// value built from its calendar fields, so convert it only if you mean to.
extension AppDateX on DateTime {
  String get apiDate => ApiFormats.date(toUtc());

  String get apiTime => ApiFormats.time(toUtc());

  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  String displayDate(AppFormats formats) => formats.formatDate(toLocal());

  String displayShortDate(AppFormats formats) =>
      formats.formatShortDate(toLocal());

  String displayTime(AppFormats formats) => formats.formatTime(toLocal());
}

extension AppNumX on num {
  String display(AppFormats formats, {int decimals = 0}) =>
      formats.formatNumber(this, decimals: decimals);
}
