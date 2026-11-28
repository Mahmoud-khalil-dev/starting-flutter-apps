import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/tolerant_comparator.dart';

/// A 100 by 100 white PNG with [dots] black pixels in its first row.
Future<Uint8List> _png(int dots) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  for (var x = 0; x < dots; x++) {
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), 0, 1, 1),
      Paint()..color = const Color(0xFF000000),
    );
  }
  final image = await recorder.endRecording().toImage(100, 100);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

class _Fixed extends TolerantGoldenComparator {
  _Fixed(this.golden, Directory dir)
    : super(Uri.file('${dir.path}/a_test.dart'));

  final Uint8List golden;

  @override
  Future<List<int>> getGoldenBytes(Uri golden) async => this.golden;
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('golden'));
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('KIT-T11: an edge difference under 0.1% passes', (tester) async {
    await tester.runAsync(() async {
      final comparator = _Fixed(await _png(0), dir);
      expect(
        await comparator.compare(await _png(5), Uri.parse('a.png')),
        isTrue,
      );
    });
  });

  testWidgets('KIT-T11: a difference over 0.1% fails', (tester) async {
    await tester.runAsync(() async {
      final comparator = _Fixed(await _png(0), dir);
      final changed = await _png(50);
      await expectLater(
        comparator.compare(changed, Uri.parse('a.png')),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}
