/// Digit sets and bidi isolates. Display text uses Arabic-Indic digits
/// in Arabic; anything sent to the API is normalized to Western digits first.
library;

const _western = '0123456789';
const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
const _persian = '۰۱۲۳۴۵۶۷۸۹';
const _arabicDecimal = '٫';
const _arabicGroup = '٬';

final _westernDigit = RegExp('[0-9]');

/// Western digits to Arabic-Indic; every other character stays.
String localizeDigits(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final i = _western.indexOf(char);
    out.write(i < 0 ? char : _arabicIndic[i]);
  }
  return out.toString();
}

/// Arabic-Indic and Persian digits to Western, the Arabic decimal separator
/// to `.`, the Arabic group separator dropped. For input before validation
/// and before sending.
String normalizeDigits(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final a = _arabicIndic.indexOf(char);
    final p = _persian.indexOf(char);
    if (a >= 0) {
      out.write(_western[a]);
    } else if (p >= 0) {
      out.write(_western[p]);
    } else if (char == _arabicDecimal) {
      out.write('.');
    } else if (char != _arabicGroup) {
      out.write(char);
    }
  }
  return out.toString();
}

/// Western digits and `.` `,` separators of a formatted number to Arabic.
String localizeNumber(String formatted) => localizeDigits(
  formatted.replaceAll(',', _arabicGroup).replaceAll('.', _arabicDecimal),
);

/// First-strong isolate: a time or date that must not reorder inside text
/// of the other direction.
String isolate(String text) => '\u2068$text\u2069';

/// Left-to-right isolate: phone numbers, amounts and clocks.
String ltrIsolate(String text) => '\u2066$text\u2069';

bool hasWesternDigit(String text) => _westernDigit.hasMatch(text);
