import 'package:flutter/services.dart';
import 'package:kit_app/core/utils/string_extensions.dart';

/// For a one-time code: the field keeps the digits as they were typed or
/// pasted, Western or Arabic-Indic, and drops everything else ("123 456"
/// gives 123456, "١٢٣-٤٥٦" gives ١٢٣٤٥٦), at most [maxLength] of them.
/// What is sent goes through [clean], so the API always gets Western digits.
class CodeInputFormatter extends TextInputFormatter {
  const CodeInputFormatter({required this.maxLength});

  final int maxLength;

  static final _notDigit = RegExp('[^0-9]');

  /// The digits [clean] can turn into Western ones: Western, Arabic-Indic
  /// and Persian.
  static final _notKnownDigit = RegExp('[^0-9٠-٩۰-۹]');

  /// [text] as the API wants a code: Western digits and nothing else.
  static String clean(String text) =>
      text.westernDigits.replaceAll(_notDigit, '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(_notKnownDigit, '');
    final kept = digits.length > maxLength
        ? digits.substring(0, maxLength)
        : digits;
    return TextEditingValue(
      text: kept,
      selection: TextSelection.collapsed(offset: kept.length),
    );
  }
}
