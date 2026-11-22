import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kit_app/core/l10n/api_formats.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  tearDown(() => Intl.defaultLocale = null);

  test(
    'KIT-T8: API formats stay Western and English while the UI is Arabic',
    () {
      Intl.defaultLocale = 'ar';
      final d = DateTime(2026, 11, 24, 9, 5);
      expect(ApiFormats.date(d), '2026-11-24');
      expect(ApiFormats.time(d), '09:05');
      expect(ApiFormats.weekday(d), 'TUE');
    },
  );

  test('KIT-T8: API parses accept digits typed in either set', () {
    expect(ApiFormats.parseDate('٢٠٢٦-١١-٢٤'), DateTime(2026, 11, 24));
    expect(ApiFormats.parseDate('2026-11-24'), DateTime(2026, 11, 24));
    expect(ApiFormats.parseDate('۲۰۲٦-۱۱-۲٤'), DateTime(2026, 11, 24));
    expect(
      ApiFormats.parseDateTime('2026-11-24T09:05:00.000Z'),
      DateTime.utc(2026, 11, 24, 9, 5),
    );
  });
}
