import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/traceability.dart';

void main() {
  group('KIT-T7: traceability', () {
    test('plan headings give task ids, with the manual marker', () {
      const plan =
          '# Plan\n### Task M99-T1: a\ntext\n### Task M99-T2: b\n**Tests:** manual\n';
      expect(planTasks(plan), {'M99-T1': false, 'M99-T2': true});
    });

    test('KIT-T7: a marker quoted inline does not make a task manual', () {
      const plan =
          '### Task M99-T1: a\nA line with `**Tests:** manual` in backticks.\n';
      expect(planTasks(plan), {'M99-T1': false});
    });

    test('test, testWidgets, group and blocTest names are found', () {
      final found = testsByTask({
        'test/a_test.dart':
            "test('M99-T1: x', () {});\ntestWidgets('M99-T2: y', (t) async {});",
        'test/b_test.dart':
            "blocTest<A, B>(\n  'M99-T3: z',\n);\ngroup('M99-T1: w', () {});",
      });
      expect(found['M99-T1'], {'test/a_test.dart', 'test/b_test.dart'});
      expect(found['M99-T2'], {'test/a_test.dart'});
      expect(found['M99-T3'], {'test/b_test.dart'});
    });

    test('a built automated task with no test is a gap', () {
      final traces = trace({
        'M99-T1': false,
        'M99-T2': true,
        'M98-T1': false,
      }, {});
      expect(gaps(traces, ['M99']), ['M99-T1']);
    });

    test('the yaml lists kind and tests per task', () {
      final yaml = toYaml(
        trace(
          {'M99-T1': false, 'M99-T2': true},
          {
            'M99-T1': {'test/a_test.dart'},
          },
        ),
      );
      expect(
        yaml,
        contains(
          'M99-T1:\n  kind: automated\n  tests:\n    - test/a_test.dart\n',
        ),
      );
      expect(yaml, contains('M99-T2:\n  kind: manual\n  tests: []\n'));
    });

    test('KIT-T7: a milestone id with a letter, such as M2R, is traced', () {
      const plan = '# Plan\n### Task M2R-T1: a\ntext\n### Task M2R-T2: b\n';
      expect(planTasks(plan), {'M2R-T1': false, 'M2R-T2': false});
      final found = testsByTask({
        'test/a_test.dart':
            "testWidgets('M2R-T"
            "2: x', (t) async {});",
      });
      expect(found['M2R-T2'], {'test/a_test.dart'});
      final traces = trace({'M2R-T1': false, 'M2R-T2': false}, found);
      expect(traces.first.milestone, 'M2R');
      expect(gaps(traces, ['M2R']), ['M2R-T1']);
    });

    test('KIT-T7: a KIT task id is traced like any other', () {
      const plan = '### Task KIT-T7: a\ntext\n### Task KIT-T8: b\n';
      expect(planTasks(plan), {'KIT-T7': false, 'KIT-T8': false});
      final traces = trace(planTasks(plan), {
        'KIT-T7': {'test/a_test.dart'},
      });
      expect(gaps(traces, builtMilestones), ['KIT-T8']);
    });
  });

  test('KIT-T7: a project with no plan files has nothing to trace', () {
    final script = File('tool/traceability.dart').absolute.path;
    final empty = Directory.systemTemp.createTempSync('trace_none');
    addTearDown(() => empty.deleteSync(recursive: true));
    final run = Process.runSync('dart', [
      script,
      '--check',
    ], workingDirectory: empty.path);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    expect(run.stdout, contains('nothing to trace'));
  });
}
