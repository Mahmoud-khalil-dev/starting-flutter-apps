import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/golden_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadGoldenFonts();
  await testMain();
}
