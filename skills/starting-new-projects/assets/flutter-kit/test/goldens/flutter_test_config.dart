import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/golden_fonts.dart';
import 'helpers/tolerant_comparator.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadGoldenFonts();
  final local = goldenFileComparator;
  if (local is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenComparator(
      local.basedir.resolve('flutter_test_config.dart'),
    );
  }
  await testMain();
}
