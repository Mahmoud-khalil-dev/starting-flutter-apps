import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_gate.dart';

const _lcov = '''
SF:lib/features/auth/presentation/cubit/login_cubit.dart
DA:1,1
DA:2,0
end_of_record
SF:lib/features/auth/data/a.dart
DA:1,0
end_of_record
''';

void main() {
  group('KIT-T7: coverage gate', () {
    test('counts only Cubits', () {
      expect(cubitCoverage(_lcov), {
        'lib/features/auth/presentation/cubit/login_cubit.dart': 50.0,
      });
    });

    test('counts cubit.dart and any file in a cubit folder', () {
      const files = [
        'lib/features/a/presentation/cubit/cubit.dart',
        'lib/features/b/presentation/b_cubit/cubit.dart',
        'lib/features/c/presentation/cubit/c_logic.dart',
        'lib/features/d/presentation/cubit/d_state.dart',
        'lib/features/e/presentation/e_cubit/e_state.dart',
        'lib/features/f/presentation/view/f_view.dart',
      ];
      expect(cubitCoverage('', cubitFiles: files).keys, [
        'lib/features/a/presentation/cubit/cubit.dart',
        'lib/features/b/presentation/b_cubit/cubit.dart',
        'lib/features/c/presentation/cubit/c_logic.dart',
      ]);
    });

    test('lists Cubits under the minimum', () {
      expect(belowMinimum({'a_cubit.dart': 50, 'b_cubit.dart': 90}, 80), [
        'a_cubit.dart: 50.0%',
      ]);
    });

    test('no Cubit yet is a pass, not a failure', () {
      expect(
        cubitCoverage('SF:lib/features/a/data/x.dart\nDA:1,0\nend_of_record'),
        isEmpty,
      );
      expect(belowMinimum(cubitCoverage(''), 80), isEmpty);
    });

    test('a new Cubit no test loads counts as 0%, not as absent', () {
      const missing = 'lib/features/chat/cubit/chat_cubit.dart';
      final coverage = cubitCoverage(
        _lcov,
        cubitFiles: [
          missing,
          'lib/features/auth/presentation/cubit/login_cubit.dart',
          'lib/features/a/presentation/view/a_view.dart',
        ],
      );
      expect(coverage[missing], 0.0);
      expect(coverage.keys, hasLength(2));
      expect(belowMinimum(coverage, 80), contains('$missing: 0.0%'));
    });
  });
}
