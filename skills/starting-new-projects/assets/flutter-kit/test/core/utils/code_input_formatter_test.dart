import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/utils/code_input_formatter.dart';

TextEditingValue _typed(CodeInputFormatter formatter, String text) =>
    formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );

void main() {
  const formatter = CodeInputFormatter(maxLength: 8);

  test('KIT-T16: a pasted code with a space keeps only its digits', () {
    expect(_typed(formatter, '123 456').text, '123456');
  });

  test('KIT-T16: Arabic-Indic digits are shown as typed', () {
    expect(_typed(formatter, '١٢٣٤').text, '١٢٣٤');
    expect(_typed(formatter, '١٢٣-٤٥٦').text, '١٢٣٤٥٦');
    expect(_typed(formatter, '۱۲۳۴').text, '۱۲۳۴');
  });

  test('KIT-T16: the API gets Western digits whatever was typed', () {
    expect(CodeInputFormatter.clean('١٢٣٤'), '1234');
    expect(CodeInputFormatter.clean('١٢٣-٤٥٦'), '123456');
    expect(CodeInputFormatter.clean('۱۲۳۴'), '1234');
    expect(CodeInputFormatter.clean('12 34'), '1234');
  });

  test('KIT-T16: digits of other scripts are dropped, not sent', () {
    // Devanagari: no digit the API cannot read gets into the field.
    expect(_typed(formatter, '१२३4').text, '4');
  });

  test('KIT-T16: letters and marks are dropped', () {
    expect(_typed(formatter, 'a1‏2-b3').text, '123');
  });

  test('KIT-T16: the field holds at most maxLength digits', () {
    expect(_typed(formatter, '1234567890').text, '12345678');
    expect(_typed(formatter, '١٢٣٤٥٦٧٨٩٠').text, '١٢٣٤٥٦٧٨');
  });

  test('KIT-T16: the caret ends after the kept digits', () {
    expect(_typed(formatter, '12 34').selection.baseOffset, 4);
  });
}
