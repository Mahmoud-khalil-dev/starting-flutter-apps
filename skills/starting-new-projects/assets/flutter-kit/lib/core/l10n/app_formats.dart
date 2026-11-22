import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:kit_app/core/l10n/digits.dart';

/// Every displayed number, date and time goes through here. Numbers
/// are formatted with 'en' and then mapped, so Arabic gets Arabic-Indic
/// digits and separators whatever intl's data says; names (weekdays, months,
/// AM and PM) come from intl for the UI language. API text never comes from
/// here: see ApiFormats.
@immutable
class AppFormats {
  const AppFormats(this.language);

  factory AppFormats.of(BuildContext context) =>
      AppFormats(Localizations.localeOf(context).languageCode);

  final String language;

  bool get _arabic => language == 'ar';

  /// Free text holding numbers, such as a value from the backend.
  String digits(String text) => _arabic ? localizeDigits(text) : text;

  String formatNumber(num value, {int decimals = 0}) {
    final western = NumberFormat.decimalPatternDigits(
      locale: 'en',
      decimalDigits: decimals,
    ).format(value);
    return _arabic ? localizeNumber(western) : western;
  }

  /// A whole percentage: `42%` in English, `٤٢٪` in Arabic.
  String formatPercent(int percent) =>
      '${formatNumber(percent)}${_arabic ? '٪' : '%'}';

  /// The symbol first; whole amounts without decimals.
  String formatAmount(num amount, {required String symbol}) {
    final whole = amount == amount.roundToDouble();
    final text = '$symbol${formatNumber(amount, decimals: whole ? 0 : 2)}';
    return _arabic ? ltrIsolate(text) : text;
  }

  String formatTime(DateTime time) =>
      digits(DateFormat.jm(language).format(time));

  /// "9:00 AM – 5:00 PM"; in Arabic each end is isolated so the range
  /// does not reorder.
  String formatTimeRange(DateTime start, DateTime end) {
    final a = formatTime(start);
    final b = formatTime(end);
    return _arabic ? '${isolate(a)} – ${isolate(b)}' : '$a – $b';
  }

  String formatDate(DateTime date) =>
      digits(DateFormat.yMMMMEEEEd(language).format(date));

  String formatShortDate(DateTime date) =>
      digits(DateFormat.MMMd(language).format(date));

  /// A call duration: "05:09", or "1:05:09" from one hour.
  String formatDuration(Duration duration) {
    final d = duration.isNegative ? Duration.zero : duration;
    final m = _two(d.inMinutes.remainder(60));
    final s = _two(d.inSeconds.remainder(60));
    final text = d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
    return _arabic ? ltrIsolate(localizeDigits(text)) : text;
  }

  /// Time left as "HH:MM:SS", never negative. Days are worded by the caller
  /// (`kitStartsInDays`).
  String formatCountdown(Duration left) {
    final d = left.isNegative ? Duration.zero : left;
    final text =
        '${_two(d.inHours)}:${_two(d.inMinutes.remainder(60))}:'
        '${_two(d.inSeconds.remainder(60))}';
    return _arabic ? ltrIsolate(localizeDigits(text)) : text;
  }

  /// Shown as given, digits localized, kept left to right.
  String formatPhone(String phone) {
    final text = phone.trim();
    return _arabic ? ltrIsolate(localizeDigits(text)) : text;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
