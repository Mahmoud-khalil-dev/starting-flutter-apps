import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:kit_app/core/l10n/digits.dart';

/// Arabic Material strings with Arabic-Indic digits: the stock date
/// and time pickers print Western digits in `ar`. Every method that returns
/// a number maps the stock result through [localizeDigits].
class ArabicDigitMaterialLocalizations extends MaterialLocalizationAr {
  const ArabicDigitMaterialLocalizations({
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

  /// Loads this class for `ar` and the stock Material strings otherwise.
  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _MaterialDelegate();

  @override
  String formatHour(
    TimeOfDay timeOfDay, {
    bool alwaysUse24HourFormat = false,
  }) => localizeDigits(
    super.formatHour(timeOfDay, alwaysUse24HourFormat: alwaysUse24HourFormat),
  );

  @override
  String formatMinute(TimeOfDay timeOfDay) =>
      localizeDigits(super.formatMinute(timeOfDay));

  @override
  String formatYear(DateTime date) => localizeDigits(super.formatYear(date));

  @override
  String formatCompactDate(DateTime date) =>
      localizeDigits(super.formatCompactDate(date));

  @override
  String formatShortDate(DateTime date) =>
      localizeDigits(super.formatShortDate(date));

  @override
  String formatMediumDate(DateTime date) =>
      localizeDigits(super.formatMediumDate(date));

  @override
  String formatFullDate(DateTime date) =>
      localizeDigits(super.formatFullDate(date));

  @override
  String formatMonthYear(DateTime date) =>
      localizeDigits(super.formatMonthYear(date));

  @override
  String formatShortMonthDay(DateTime date) =>
      localizeDigits(super.formatShortMonthDay(date));

  /// The stock parser only knows Western digits. The bidi marks stay: the
  /// Arabic pattern itself contains them.
  @override
  DateTime? parseCompactDate(String? inputString) => super.parseCompactDate(
    inputString == null ? null : normalizeDigits(inputString),
  );

  @override
  String formatDecimal(int number) =>
      localizeDigits(super.formatDecimal(number));

  @override
  String formatTimeOfDay(
    TimeOfDay timeOfDay, {
    bool alwaysUse24HourFormat = false,
  }) => localizeDigits(
    super.formatTimeOfDay(
      timeOfDay,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    ),
  );

  @override
  String dateRangeStartDateSemanticLabel(String formattedDate) =>
      localizeDigits(super.dateRangeStartDateSemanticLabel(formattedDate));

  @override
  String dateRangeEndDateSemanticLabel(String formattedDate) =>
      localizeDigits(super.dateRangeEndDateSemanticLabel(formattedDate));

  @override
  String pageRowsInfoTitle(
    int firstRow,
    int lastRow,
    int rowCount,
    bool rowCountIsApproximate,
  ) => localizeDigits(
    super.pageRowsInfoTitle(firstRow, lastRow, rowCount, rowCountIsApproximate),
  );

  @override
  String tabLabel({required int tabIndex, required int tabCount}) =>
      localizeDigits(super.tabLabel(tabIndex: tabIndex, tabCount: tabCount));

  @override
  String selectedRowCountTitle(int selectedRowCount) =>
      localizeDigits(super.selectedRowCountTitle(selectedRowCount));

  @override
  String licensesPackageDetailText(int licenseCount) =>
      localizeDigits(super.licensesPackageDetailText(licenseCount));

  @override
  String remainingTextFieldCharacterCount(int remaining) =>
      localizeDigits(super.remainingTextFieldCharacterCount(remaining));
}

class _MaterialDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialDelegate();

  @override
  bool isSupported(Locale locale) =>
      GlobalMaterialLocalizations.delegate.isSupported(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final stock = GlobalMaterialLocalizations.delegate.load(locale);
    if (locale.languageCode != 'ar') return stock;
    // The stock load also makes sure the intl date data is in memory.
    return stock.then(
      (_) => SynchronousFuture<MaterialLocalizations>(
        ArabicDigitMaterialLocalizations(
          fullYearFormat: intl.DateFormat.y('ar'),
          compactDateFormat: intl.DateFormat.yMd('ar'),
          shortDateFormat: intl.DateFormat.yMMMd('ar'),
          mediumDateFormat: intl.DateFormat.MMMEd('ar'),
          longDateFormat: intl.DateFormat.yMMMMEEEEd('ar'),
          yearMonthFormat: intl.DateFormat.yMMMM('ar'),
          shortMonthDayFormat: intl.DateFormat.MMMd('ar'),
          decimalFormat: intl.NumberFormat.decimalPattern('ar'),
          twoDigitZeroPaddedFormat: intl.NumberFormat('00', 'ar'),
        ),
      ),
    );
  }

  @override
  bool shouldReload(_MaterialDelegate old) => false;
}

/// Arabic Cupertino strings with Arabic-Indic digits, for the date and time
/// wheels.
class ArabicDigitCupertinoLocalizations extends CupertinoLocalizationAr {
  const ArabicDigitCupertinoLocalizations({
    required super.fullYearFormat,
    required super.dayFormat,
    required super.weekdayFormat,
    required super.mediumDateFormat,
    required super.singleDigitHourFormat,
    required super.singleDigitMinuteFormat,
    required super.doubleDigitMinuteFormat,
    required super.singleDigitSecondFormat,
    required super.decimalFormat,
  });

  /// Loads this class for `ar` and the stock Cupertino strings otherwise.
  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _CupertinoDelegate();

  @override
  String datePickerYear(int yearIndex) =>
      localizeDigits(super.datePickerYear(yearIndex));

  @override
  String datePickerMonth(int monthIndex) =>
      localizeDigits(super.datePickerMonth(monthIndex));

  @override
  String datePickerStandaloneMonth(int monthIndex) =>
      localizeDigits(super.datePickerStandaloneMonth(monthIndex));

  @override
  String datePickerDayOfMonth(int dayIndex, [int? weekDay]) =>
      localizeDigits(super.datePickerDayOfMonth(dayIndex, weekDay));

  @override
  String datePickerMediumDate(DateTime date) =>
      localizeDigits(super.datePickerMediumDate(date));

  @override
  String datePickerHour(int hour) => localizeDigits(super.datePickerHour(hour));

  @override
  String? datePickerHourSemanticsLabel(int hour) {
    final label = super.datePickerHourSemanticsLabel(hour);
    return label == null ? null : localizeDigits(label);
  }

  @override
  String datePickerMinute(int minute) =>
      localizeDigits(super.datePickerMinute(minute));

  @override
  String? datePickerMinuteSemanticsLabel(int minute) {
    final label = super.datePickerMinuteSemanticsLabel(minute);
    return label == null ? null : localizeDigits(label);
  }

  @override
  String tabSemanticsLabel({required int tabIndex, required int tabCount}) =>
      localizeDigits(
        super.tabSemanticsLabel(tabIndex: tabIndex, tabCount: tabCount),
      );

  @override
  String timerPickerHour(int hour) =>
      localizeDigits(super.timerPickerHour(hour));

  @override
  String timerPickerMinute(int minute) =>
      localizeDigits(super.timerPickerMinute(minute));

  @override
  String timerPickerSecond(int second) =>
      localizeDigits(super.timerPickerSecond(second));
}

class _CupertinoDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoDelegate();

  @override
  bool isSupported(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.isSupported(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    final stock = GlobalCupertinoLocalizations.delegate.load(locale);
    if (locale.languageCode != 'ar') return stock;
    return stock.then(
      (_) => SynchronousFuture<CupertinoLocalizations>(
        ArabicDigitCupertinoLocalizations(
          fullYearFormat: intl.DateFormat.y('ar'),
          dayFormat: intl.DateFormat.d('ar'),
          weekdayFormat: intl.DateFormat.E('ar'),
          mediumDateFormat: intl.DateFormat.MMMEd('ar'),
          singleDigitHourFormat: intl.DateFormat('HH', 'ar'),
          singleDigitMinuteFormat: intl.DateFormat.m('ar'),
          doubleDigitMinuteFormat: intl.DateFormat('mm', 'ar'),
          singleDigitSecondFormat: intl.DateFormat.s('ar'),
          decimalFormat: intl.NumberFormat.decimalPattern('ar'),
        ),
      ),
    );
  }

  @override
  bool shouldReload(_CupertinoDelegate old) => false;
}
