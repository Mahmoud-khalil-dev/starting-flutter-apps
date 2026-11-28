import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compares goldens like [LocalFileComparator], but passes when at most
/// [tolerance] of the pixels differ. Two Macs on the same Flutter still
/// antialias text edges a little differently, so an exact match fails on a
/// CI runner for images made on a laptop. The default, 0.1%, is ten times
/// the edge noise seen between machines, and far below a moved widget or a
/// changed colour.
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.tolerance = 0.001});

  /// The largest share of differing pixels that still passes, from 0 to 1.
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
