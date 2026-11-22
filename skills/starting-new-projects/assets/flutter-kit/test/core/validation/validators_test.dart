import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/validation/validators.dart';

import '../../helpers/l10n.dart';

void main() {
  final en = Validators(l10nFor('en'));
  final ar = Validators(l10nFor('ar'));

  test('KIT-T15: required rejects empty and blank text', () {
    expect(en.required()(null), 'Please fill this in.');
    expect(en.required()('   '), 'Please fill this in.');
    expect(en.required()('x'), isNull);
    expect(ar.required()(''), 'يُرجى تعبئة هذا الحقل.');
  });

  test('KIT-T15: email accepts a plain address and trims it', () {
    expect(en.email()(' name@example.com '), isNull);
    expect(en.email()('name@example'), 'Please enter a valid email address.');
    expect(en.email()('name example.com'), isNotNull);
    expect(ar.email()('nope'), 'يُرجى إدخال بريد إلكتروني صحيح.');
  });

  test('KIT-T15: phone accepts Arabic-Indic digits and a plus', () {
    expect(en.phone()('+٩٦٦ ٥٠ ١٢٣ ٤٥٦٧'), isNull);
    expect(en.phone()('0501234567'), isNull);
    expect(en.phone()('12-ab'), 'Please enter a valid phone number.');
    expect(ar.phone()('12-ab'), 'يُرجى إدخال رقم هاتف صحيح.');
  });

  test('KIT-T15: password needs the length, a letter and a number', () {
    expect(en.password()('abcdefg1'), isNull);
    expect(en.password()('abcdefgh'), isNotNull);
    expect(en.password()('12345678'), isNotNull);
    expect(
      en.password()('ab1'),
      'Please use at least 8 characters, with a letter and a number.',
    );
    expect(
      ar.password()('ab1'),
      'يُرجى استخدام ٨ أحرف على الأقل، تتضمن حرفًا ورقمًا.',
    );
  });

  test('KIT-T15: length shows localized bounds', () {
    expect(en.length(min: 2)('a'), 'Please use at least 2 characters.');
    expect(ar.length(min: 3)('a'), 'يُرجى استخدام ٣ أحرف على الأقل.');
    expect(
      en.length(max: 3)('abcd'),
      'Please keep this to 3 characters or fewer.',
    );
    expect(ar.length(max: 3)('abcd'), 'يُرجى ألا يتجاوز النص ٣ أحرف.');
    expect(en.length(min: 2, max: 3)('ab'), isNull);
  });

  test('KIT-T15: matches compares with the other field now', () {
    var first = 'secret1a';
    final rule = en.matches(() => first);
    expect(rule('secret1a'), isNull);
    first = 'changed1a';
    expect(rule('secret1a'), 'These entries do not match.');
    expect(ar.matches(() => 'a')('b'), 'القيمتان غير متطابقتين.');
  });

  test('KIT-T15: all returns the first failing rule', () {
    final rule = Validators.all([en.required(), en.email()]);
    expect(rule(''), 'Please fill this in.');
    expect(rule('x'), 'Please enter a valid email address.');
    expect(rule('a@b.co'), isNull);
  });

  test('KIT-T15: an empty optional field passes every rule but required', () {
    expect(en.email()(''), isNull);
    expect(en.phone()(null), isNull);
    expect(en.length(min: 2)(''), isNull);
    expect(en.password()(''), isNull);
  });

  test('KIT-T15: length counts characters a reader sees', () {
    // One emoji with a skin tone is one character.
    expect(en.length(max: 1)('👋🏽'), isNull);
    expect(en.length(max: 2)('👋🏽👋🏽👋🏽'), isNotNull);
    expect(en.length(min: 2)('👋🏽'), isNotNull);
    // An Arabic letter with its vowel mark is one character.
    expect(ar.length(max: 2)('يُر'), isNull);
    expect(ar.length(max: 1)('يُر'), isNotNull);
    expect(ar.length(min: 2)('يُ'), isNotNull);
  });

  test('KIT-T15: Arabic counts use the right plural form and digits', () {
    String tooLong(int n) => ar.length(max: n)('a' * (n + 1))!;
    expect(tooLong(1), 'يُرجى ألا يتجاوز النص حرفًا واحدًا.');
    expect(tooLong(2), 'يُرجى ألا يتجاوز النص حرفين.');
    expect(tooLong(3), 'يُرجى ألا يتجاوز النص ٣ أحرف.');
    expect(tooLong(11), 'يُرجى ألا يتجاوز النص ١١ حرفًا.');
    expect(tooLong(100), 'يُرجى ألا يتجاوز النص ١٠٠ حرف.');
    String tooShort(int n) => ar.length(min: n)('a')!;
    expect(tooShort(2), 'يُرجى استخدام حرفين على الأقل.');
    expect(tooShort(3), 'يُرجى استخدام ٣ أحرف على الأقل.');
    expect(tooShort(11), 'يُرجى استخدام ١١ حرفًا على الأقل.');
    expect(tooShort(100), 'يُرجى استخدام ١٠٠ حرف على الأقل.');
    expect(
      ar.password(minLength: 11)('ab1'),
      'يُرجى استخدام ١١ حرفًا على الأقل، تتضمن حرفًا ورقمًا.',
    );
  });

  test('KIT-T15: English counts say one character', () {
    expect(
      en.length(max: 1)('ab'),
      'Please keep this to 1 character or fewer.',
    );
    expect(en.length(min: 1)(''), isNull);
    expect(en.length(max: 1000)('a' * 1001), contains('1,000'));
  });
}
