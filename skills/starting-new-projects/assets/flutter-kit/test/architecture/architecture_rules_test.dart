import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture_rules.dart';
import '../../tool/legacy_paths.dart';
import '../../tool/strict_dart_files.dart';

List<String> _rules(String path, String content) =>
    checkDartFile(path, content).map((v) => v.rule).toList();

// Fixtures are joined at run time so this file does not flag itself.
final String _ignoreComment = ['// ig', 'nore: x'].join();
final String _skipArg = ['sk', 'ip: true'].join();
final String _skipAnnotation = ['@Sk', 'ip'].join();
final String _importKeyword = ['imp', 'ort'].join();
final String _exportKeyword = ['exp', 'ort'].join();
final String _scheme = ['ht', 'tps://'].join();

String _import(String target) => "$_importKeyword 'package:kit_app/$target';";

void main() {
  group('KIT-T7: new code', () {
    test('a file over 400 lines is flagged', () {
      final big = List.filled(401, '// x').join('\n');
      expect(_rules('lib/features/a/a.dart', big), contains('max-lines'));
    });

    test('importing old-layout code is flagged', () {
      for (final folder in ['business_logic', 'data', 'presentation']) {
        expect(
          _rules('lib/features/a/a.dart', _import('$folder/constants.dart')),
          contains('legacy-import'),
          reason: folder,
        );
      }
    });

    test('a relative import of old-layout code is flagged too', () {
      expect(
        _rules(
          'lib/features/a/a.dart',
          "$_importKeyword '../../data/constants.dart';",
        ),
        contains('legacy-import'),
      );
    });

    test('an import wrapped by dart format is still caught', () {
      expect(
        _rules(
          'lib/app/a.dart',
          "$_importKeyword\n    'package:kit_app/data/a.dart';",
        ),
        contains('legacy-import'),
      );
    });

    test('importing new code is fine', () {
      expect(
        _rules('lib/features/a/a.dart', _import('core/config/env.dart')),
        isEmpty,
      );
    });

    test('an ignore comment is flagged', () {
      expect(
        _rules('lib/core/config/a.dart', _ignoreComment),
        contains('ignore-comment'),
      );
    });
  });

  group('KIT-T7: features never import each other', () {
    test('another feature by package path is flagged', () {
      expect(
        _rules(
          'lib/features/a/presentation/view/a.dart',
          _import('features/b/data/b.dart'),
        ),
        contains('cross-feature-import'),
      );
    });

    test('another feature by relative path is flagged', () {
      expect(
        _rules(
          'lib/features/a/presentation/view/a.dart',
          "$_importKeyword '../../../b/data/b.dart';",
        ),
        contains('cross-feature-import'),
      );
    });

    test('the feature is the folder, not the file name', () {
      const from = 'lib/features/orders/presentation/view/list_screen.dart';
      expect(
        _rules(from, _import('features/profile/data/models/user.dart')),
        contains('cross-feature-import'),
      );
      expect(
        _rules(from, _import('features/orders/data/models/user.dart')),
        isNot(contains('cross-feature-import')),
      );
      expect(
        _rules(from, _import('features/list_screen/data/a.dart')),
        contains('cross-feature-import'),
      );
    });

    test('an export of another feature is flagged', () {
      expect(
        _rules(
          'lib/features/a/a.dart',
          "$_exportKeyword 'package:kit_app/features/b/b.dart';",
        ),
        contains('cross-feature-import'),
      );
    });

    test('the same feature, core and app are fine', () {
      for (final target in [
        'features/a/data/a.dart',
        'core/widgets/app_button.dart',
        'app/router/routes.dart',
      ]) {
        expect(
          _rules('lib/features/a/presentation/view/a.dart', _import(target)),
          isNot(contains('cross-feature-import')),
          reason: target,
        );
      }
      expect(
        _rules('lib/app/router/a.dart', _import('features/b/b.dart')),
        isNot(contains('cross-feature-import')),
      );
    });
  });

  group('KIT-T7: tests and tools are strict too', () {
    test('an ignore comment in test/ or tool/ is flagged', () {
      for (final path in ['test/a_test.dart', 'tool/a.dart']) {
        expect(_rules(path, _ignoreComment), contains('ignore-comment'));
      }
    });

    test('a skip argument in a test is flagged', () {
      expect(
        _rules('test/a_test.dart', "test('x', () {}, $_skipArg);"),
        contains('skipped-test'),
      );
    });

    test('a Skip annotation in a test is flagged', () {
      expect(
        _rules('test/a_test.dart', "$_skipAnnotation('why')\nvoid main() {}"),
        contains('skipped-test'),
      );
    });

    test('skip outside test/ is not a test skip', () {
      expect(_rules('lib/features/a/a.dart', 'final x = $_skipArg;'), isEmpty);
    });
  });

  group('KIT-T7: everywhere in lib', () {
    test('a hard-coded URL is flagged', () {
      for (final quote in ["'", '"']) {
        expect(
          _rules(
            'lib/features/a/data/a.dart',
            'const u = $quote${_scheme}host.example/v1$quote;',
          ),
          contains('raw-host'),
          reason: quote,
        );
      }
    });

    test('a URL anywhere in a string is flagged, not only at its start', () {
      expect(
        _rules(
          'lib/features/a/a.dart',
          "const m = 'see ${_scheme}api.acme.test/docs';",
        ),
        contains('raw-host'),
      );
    });

    test('a literal host in Uri.https, Uri.http or Uri(host:) is flagged', () {
      for (final code in [
        "final u = Uri.https('api.acme.test', '/v1');",
        "final u = Uri.http('api.acme.test');",
        "final u = Uri.https(\n  'api.acme.test',\n  '/v1',\n);",
        "final u = Uri(scheme: 'https', host: 'api.acme.test');",
      ]) {
        expect(
          _rules('lib/core/network/a.dart', code),
          contains('raw-host'),
          reason: code,
        );
      }
    });

    test('a host from Env in Uri.https is fine, and so is a URL in a doc '
        'comment', () {
      expect(
        _rules(
          'lib/core/network/a.dart',
          "final u = Uri.https(Env.host, '/v1');\n"
              '/// See ${_scheme}www.w3.org/WAI/ for the rule.',
        ),
        isEmpty,
      );
    });

    test('a URL in a test is not a hard-coded host', () {
      expect(
        _rules('test/a_test.dart', "const u = '${_scheme}host.example';"),
        isEmpty,
      );
    });

    test('the Env read is fine', () {
      expect(
        _rules('lib/core/network/a.dart', 'final u = Env.baseUrl;'),
        isEmpty,
      );
    });
  });

  group('KIT-T7: platform rules', () {
    test('kIsWeb or Platform.isX outside core/platform is flagged', () {
      expect(
        _rules('lib/features/a/a.dart', 'if (kIsWeb) {}'),
        contains('platform-check'),
      );
      expect(
        _rules('lib/app/a.dart', 'if (Platform.isIOS) {}'),
        contains('platform-check'),
      );
      expect(_rules('lib/core/platform/a.dart', 'if (kIsWeb) {}'), isEmpty);
    });
  });

  test('KIT-T7: strict lib, test and tool files break no rule', () {
    final all = [
      for (final root in ['lib', 'test', 'tool'])
        for (final f in Directory(root).listSync(recursive: true))
          if (f is File) f.path.replaceAll(r'\', '/'),
    ];
    final violations = [
      for (final path in strictDartFiles(all))
        ...checkDartFile(path, File(path).readAsStringSync()),
    ];
    expect(violations.map((v) => v.toString()), isEmpty);
  });

  test('KIT-T7: a new project starts with no legacy code', () {
    expect(legacyPaths, isEmpty);
    expect(isLegacy('lib/main.dart'), isFalse);
  });

  test('KIT-T7: a legacy folder and its analysis_options.yaml agree', () {
    final folders = legacyPaths.where((p) => p.endsWith('/'));
    for (final p in folders) {
      expect(
        File('${p}analysis_options.yaml').existsSync(),
        isTrue,
        reason: '$p is legacy but has no analysis_options.yaml',
      );
    }
    final nested = [
      for (final root in ['lib', 'test', 'tool'])
        if (Directory(root).existsSync())
          for (final f in Directory(root).listSync(recursive: true))
            if (f is File && f.path.endsWith('/analysis_options.yaml'))
              f.path.substring(
                0,
                f.path.length - 'analysis_options.yaml'.length,
              ),
    ];
    for (final n in nested) {
      expect(
        folders,
        contains(n),
        reason: '$n has a legacy YAML but is not in legacyPaths',
      );
    }
  });
}
