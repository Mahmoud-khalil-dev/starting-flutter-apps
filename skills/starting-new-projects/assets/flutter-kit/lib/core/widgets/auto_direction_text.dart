import 'package:flutter/widgets.dart';

// Hebrew, Arabic, Syriac, Thaana, NKo, Arabic extended, and the Hebrew and
// Arabic presentation forms.
final _rtl = RegExp(r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');
final _ltr = RegExp(r'[A-Za-z\u00C0-\u024F]');
// Direction-neutral: Western, Arabic-Indic and extended digits, and the
// Arabic comma, percent sign, decimal and thousands separators.
final _neutral = RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9\u060C\u066A-\u066C]');

/// The direction of the first strong character, or null when there is none
/// (digits of any script, punctuation, symbols).
TextDirection? firstStrongDirection(String text) {
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (_neutral.hasMatch(char)) continue;
    if (_rtl.hasMatch(char)) return TextDirection.rtl;
    if (_ltr.hasMatch(char)) return TextDirection.ltr;
  }
  return null;
}

/// Text from users or the API (a person's name, a note) laid out in its
/// own direction, whatever the app language.
class AutoDirectionText extends StatelessWidget {
  const AutoDirectionText(
    this.text, {
    this.style,
    this.maxLines,
    this.textAlign,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: style,
    maxLines: maxLines,
    textAlign: textAlign,
    textDirection: firstStrongDirection(text),
  );
}
