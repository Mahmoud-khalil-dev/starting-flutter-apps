import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/l10n/arabic_digit_localizations.dart';

void main() {
  test('KIT-T8: the delegates load Arabic-Indic strings for ar only', () async {
    final material = await ArabicDigitMaterialLocalizations.delegate.load(
      const Locale('ar'),
    );
    final cupertino = await ArabicDigitCupertinoLocalizations.delegate.load(
      const Locale('ar'),
    );
    expect(material, isA<ArabicDigitMaterialLocalizations>());
    expect(cupertino, isA<ArabicDigitCupertinoLocalizations>());
    expect(material.formatYear(DateTime(2026)), '٢٠٢٦');
    expect(cupertino.datePickerDayOfMonth(20), '٢٠');
    final enMaterial = await ArabicDigitMaterialLocalizations.delegate.load(
      const Locale('en'),
    );
    final enCupertino = await ArabicDigitCupertinoLocalizations.delegate.load(
      const Locale('en'),
    );
    expect(enMaterial, isNot(isA<ArabicDigitMaterialLocalizations>()));
    expect(enCupertino, isNot(isA<ArabicDigitCupertinoLocalizations>()));
    expect(enMaterial.formatYear(DateTime(2026)), '2026');
    expect(enCupertino.datePickerDayOfMonth(20), '20');
    expect(
      ArabicDigitMaterialLocalizations.delegate.isSupported(const Locale('ar')),
      isTrue,
    );
  });

  test('KIT-T8: an Arabic compact date parses back to the same day', () async {
    final material = await ArabicDigitMaterialLocalizations.delegate.load(
      const Locale('ar'),
    );
    final date = DateTime(2026, 11, 20);
    final text = material.formatCompactDate(date);
    expect(text, contains('٢٠'));
    expect(material.parseCompactDate(text), date);
    expect(material.parseCompactDate(null), isNull);
  });
}
