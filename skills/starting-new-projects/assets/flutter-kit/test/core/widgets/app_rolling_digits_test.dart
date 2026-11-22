import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_rolling_digits.dart';

import '../../goldens/helpers/golden_fonts.dart';
import '../../helpers/pump_app.dart';

Widget _subject(ValueNotifier<String> text) => ValueListenableBuilder<String>(
  valueListenable: text,
  builder: (_, t, _) => AppRollingDigits(t),
);

/// Loads the SDK's Roboto under [family], as a web build does after the first frame.
/// The engine tells Flutter a font changed with a `fontsChange` system message,
/// which notifies `systemFonts`; `systemFonts` is a plain `Listenable`, so the
/// helper sends that message after the load, as the engine does.
Future<void> _loadLate(String family) async {
  final bytes = File(sdkFontPath('Roboto-Regular.ttf')).readAsBytes();
  final loader = FontLoader(family)..addFont(bytes.then(ByteData.sublistView));
  await loader.load();
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter/system',
        const JSONMessageCodec().encodeMessage(<String, dynamic>{
          'type': 'fontsChange',
        }),
        (_) {},
      );
}

/// The widest digit of [digits] in [style], measured directly.
double _widest(String digits, TextStyle style) {
  var widest = 0.0;
  for (final digit in digits.characters) {
    final painter = TextPainter(
      text: TextSpan(text: digit, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  return widest;
}

void main() {
  testWidgets('KIT-T11: only the changed characters roll, vertically', (
    tester,
  ) async {
    final text = ValueNotifier('12:05');
    await pumpApp(tester, _subject(text));
    text.value = '12:04';
    await tester.pump();
    await tester.pump(Motion.quick ~/ 2);
    final moving = tester
        .widgetList<SlideTransition>(find.byType(SlideTransition))
        .where((s) => s.position.value != Offset.zero)
        .toList();
    expect(moving, hasLength(2), reason: 'old 5 out, new 4 in');
    expect(moving.every((s) => s.position.value.dx == 0), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('KIT-T11: under reduce motion digits fade in place', (
    tester,
  ) async {
    final text = ValueNotifier('٠٥');
    await pumpApp(tester, _subject(text), reduceMotion: true);
    text.value = '٠٤';
    await tester.pump();
    await tester.pump(Motion.quick ~/ 2);
    expect(
      tester
          .widgetList<SlideTransition>(find.byType(SlideTransition))
          .every((s) => s.position.value == Offset.zero),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(find.text('٤'), findsOneWidget);
  });

  testWidgets('KIT-T11: Arabic digits keep left-to-right order', (
    tester,
  ) async {
    await pumpApp(tester, const AppRollingDigits('١٢٠'), language: 'ar');
    final xs = [
      '١',
      '٢',
      '٠',
    ].map((c) => tester.getTopLeft(find.text(c)).dx).toList();
    expect(xs[0] < xs[1] && xs[1] < xs[2], isTrue, reason: '$xs');
  });

  testWidgets('KIT-T11: a length change rolls only the changed end', (
    tester,
  ) async {
    final text = ValueNotifier('9:59');
    await pumpApp(tester, _subject(text));
    text.value = '10:00';
    await tester.pump();
    await tester.pump(Motion.quick ~/ 2);
    // ':' stays still; the minutes (59 -> 00) roll, the new leading 1 enters.
    expect(find.text(':'), findsOneWidget);
    final colonSlide = tester.widget<SlideTransition>(
      find
          .ancestor(of: find.text(':'), matching: find.byType(SlideTransition))
          .first,
    );
    expect(colonSlide.position.value, Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
  });

  testWidgets('KIT-T11: a change mid-roll settles on the last value', (
    tester,
  ) async {
    final text = ValueNotifier('12:05');
    await pumpApp(tester, _subject(text));
    text.value = '12:04';
    await tester.pump();
    await tester.pump(Motion.quick ~/ 2);
    text.value = '12:03';
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('KIT-T11: digits are tabular and not clipped at 2x text', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(child: AppRollingDigits('12:05')),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    final style = tester.widget<Text>(find.text('1')).style;
    expect(style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    final clip = tester.getSize(find.byType(ClipRect).first);
    final glyph = tester.getSize(find.text('1'));
    expect(clip.height, greaterThanOrEqualTo(glyph.height));
    expect(clip.width, greaterThanOrEqualTo(glyph.width));
  });

  testWidgets('KIT-T11: every digit sits in a cell of one width', (
    tester,
  ) async {
    await pumpApp(tester, const AppRollingDigits('١٢:٠٤'), language: 'ar');
    final finder = find.descendant(
      of: find.byType(AppRollingDigits),
      matching: find.byKey(const ValueKey('digit-cell')),
    );
    final cells = tester
        .widgetList<SizedBox>(finder)
        .map((b) => b.width)
        .toSet();
    // Four digits, one width; the colon keeps its own.
    expect(cells, hasLength(1));
    expect(finder, findsNWidgets(4));
  });

  test('KIT-T11: the digit cells are measured once per style and scale', () {
    const scaler = TextScaler.linear(1.5);
    final first = AppRollingDigits.cellsOf(
      const TextStyle(fontSize: 20),
      scaler,
    );
    // An equal style and scaler, built afresh, as each rebuild does.
    final again = AppRollingDigits.cellsOf(
      const TextStyle(fontSize: 10).copyWith(fontSize: 20),
      const TextScaler.linear(1.5),
    );
    expect(identical(first, again), isTrue);
    final other = AppRollingDigits.cellsOf(
      const TextStyle(fontSize: 30),
      scaler,
    );
    expect(identical(first, other), isFalse);
    expect(other.western, greaterThan(first.western));
    expect(other.eastern, greaterThan(first.eastern));
  });

  test(
    'KIT-T11: a font that loads late re-measures the digit cells (BH-4)',
    () async {
      const family = 'BhLateFontUnit';
      const style = TextStyle(fontFamily: family, fontSize: 20);
      const scaler = TextScaler.noScaling;
      final before = AppRollingDigits.cellsOf(style, scaler);
      await _loadLate(family);
      final after = AppRollingDigits.cellsOf(style, scaler);
      expect(after.western, _widest('0123456789', style));
      expect(after.eastern, _widest('٠١٢٣٤٥٦٧٨٩', style));
      expect(after.western, isNot(before.western));
    },
  );

  testWidgets('KIT-T11: digit cells follow a font that loads late (BH-4)', (
    tester,
  ) async {
    const family = 'BhLateFontWidget';
    const style = TextStyle(fontFamily: family, fontSize: 20);
    await pumpApp(tester, const AppRollingDigits('12', style: style));
    final cell = find.byKey(const ValueKey('digit-cell')).first;
    final stale = tester.getSize(cell).width;
    await tester.runAsync(() => _loadLate(family));
    await tester.pump();
    final fresh = tester.getSize(cell).width;
    expect(
      fresh,
      _widest(
        '0123456789',
        style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
    expect(fresh, isNot(stale));
  });
}
