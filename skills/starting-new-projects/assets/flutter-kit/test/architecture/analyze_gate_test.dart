import 'package:flutter_test/flutter_test.dart';

import '../../tool/analyze_gate.dart';
import '../../tool/legacy_paths.dart';

String _issue(String file) =>
    'INFO|LINT|prefer_const_constructors|/repo/$file|1|1|1|Use const.';

void main() {
  group('KIT-T7: legacy paths', () {
    test('new folders are not legacy', () {
      expect(isLegacy('lib/core/config/env.dart'), isFalse);
      expect(isLegacy('lib/features/auth/a.dart'), isFalse);
      expect(isLegacy('tool/verify.sh'), isFalse);
    });
  });

  group('KIT-T7: analyze gate', () {
    test('any issue in new code fails', () {
      final r = checkAnalyze(_issue('lib/core/config/env.dart'), 0, '/repo/');
      expect(r.passed, isFalse);
      expect(r.messages.single, contains('lib/core/config/env.dart'));
    });

    test('lines that are not issues are ignored', () {
      expect(
        checkAnalyze('Analyzing kit_app...\n', 0, '/repo/').passed,
        isTrue,
      );
    });

    test('an empty baseline and no issues pass', () {
      final r = checkAnalyze('', 0, '/repo/');
      expect(r.passed, isTrue);
      expect(r.messages.single, contains('0 legacy issues, baseline 0'));
    });

    test('an analyzer that fails without reporting an issue fails', () {
      final r = checkAnalyze(
        'Could not resolve package',
        0,
        '/repo/',
        exit: 64,
      );
      expect(r.passed, isFalse);
      expect(r.messages.single, contains('exit code 64'));
    });

    test('a non-zero exit with issues is judged by the issues', () {
      final r = checkAnalyze(_issue('lib/a.dart'), 0, '/repo/', exit: 1);
      expect(r.passed, isFalse);
      expect(r.messages.single, startsWith('lib/a.dart:1'));
    });
  });
}
