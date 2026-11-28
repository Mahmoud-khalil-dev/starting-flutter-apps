import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture_rules.dart';

List<String> _rules(String path, String content) =>
    checkDartFile(path, content).map((v) => v.rule).toList();

// Fixtures are joined at run time so this file does not flag itself.
final String _importKeyword = ['imp', 'ort'].join();
final String _exportKeyword = ['exp', 'ort'].join();

void main() {
  group('KIT-T7: directives the regex could miss', () {
    const screen = 'lib/features/auth/presentation/view/a.dart';
    final partKeyword = ['pa', 'rt'].join();

    test('a conditional import of a data source is flagged', () {
      final source =
          "$_importKeyword 'stub.dart' "
          'if (dart.library.io) '
          "'package:kit_app/features/auth/data/sources/a.dart';";
      expect(_rules(screen, source), contains('presentation-imports-data'));
    });

    test('a part of another feature is flagged', () {
      expect(
        _rules(screen, "$partKeyword '../../../b/presentation/b.dart';"),
        contains('cross-feature-import'),
      );
    });

    test('an import inside a comment is not a directive', () {
      expect(
        _rules(screen, "// $_importKeyword 'package:dio/dio.dart';"),
        isNot(contains('presentation-imports-data')),
      );
    });

    test('the reported line is the line of the URI', () {
      final source = [
        "$_importKeyword 'package:flutter/widgets.dart';",
        "$_importKeyword 'package:dio/dio.dart';",
      ].join('\n');
      final found = checkDartFile(
        screen,
        source,
      ).where((v) => v.rule == 'presentation-imports-data');
      expect(found.single.line, 2);
    });
  });

  group('KIT-T7: a feature barrel never re-exports its data layer', () {
    test('a barrel outside data/ exporting a source is flagged', () {
      expect(
        _rules(
          'lib/features/auth/auth.dart',
          "$_exportKeyword 'package:kit_app/features/auth/data/sources/a.dart';",
        ),
        contains('feature-barrel-exports-data'),
      );
    });

    test('a barrel inside data/, or one exporting models, is fine', () {
      expect(
        _rules(
          'lib/features/auth/data/data.dart',
          "$_exportKeyword 'sources/a.dart';",
        ),
        isNot(contains('feature-barrel-exports-data')),
      );
      expect(
        _rules(
          'lib/features/auth/auth.dart',
          "$_exportKeyword 'data/models/user.dart';",
        ),
        isNot(contains('feature-barrel-exports-data')),
      );
    });

    test('a models file re-exporting a source is flagged, so no barrel '
        'reaches data/ in two steps', () {
      expect(
        _rules(
          'lib/features/auth/data/models/models.dart',
          "$_exportKeyword '../sources/a.dart';",
        ),
        contains('feature-barrel-exports-data'),
      );
      expect(
        _rules(
          'lib/features/auth/data/models/models.dart',
          "$_exportKeyword 'user.dart';",
        ),
        isNot(contains('feature-barrel-exports-data')),
      );
    });
  });
}
