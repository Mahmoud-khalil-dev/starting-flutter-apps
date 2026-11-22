import 'package:flutter_test/flutter_test.dart';

import '../../tool/strict_dart_files.dart';

void main() {
  group('KIT-T7: strict Dart file list', () {
    test('keeps Dart files and drops generated ones', () {
      expect(
        strictDartFiles([
          'lib/core/config/env.dart',
          'lib/features/a/a_cubit.dart',
          'test/a_test.dart',
          'tool/x.dart',
          'lib/l10n/app_localizations_en.dart',
          'lib/features/a/a.g.dart',
          'lib/features/a/a.freezed.dart',
          'lib/features/a/readme.md',
        ]),
        [
          'lib/core/config/env.dart',
          'lib/features/a/a_cubit.dart',
          'test/a_test.dart',
          'tool/x.dart',
        ],
      );
    });
  });
}
