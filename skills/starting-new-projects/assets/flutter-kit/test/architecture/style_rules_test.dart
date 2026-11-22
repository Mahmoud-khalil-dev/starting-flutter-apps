import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture_rules.dart';

List<String> _rules(String path, String content) =>
    checkDartFile(path, content).map((v) => v.rule).toList();

// Fixtures are joined at run time so this file does not flag itself.
final String _importKeyword = ['imp', 'ort'].join();

void main() {
  group('KIT-T7: style rules', () {
    const feature = 'lib/features/a/presentation/view/a_screen.dart';
    const kit = 'lib/core/widgets/app_a.dart';
    const theme = 'lib/core/theme/app_palette.dart';
    const data = 'lib/features/a/data/repositories/a_repository.dart';

    test('raw colours are flagged in features and the kit, not the theme', () {
      for (final line in [
        'color: Color(0xFF445566),',
        'color: Colors.white,',
        'Color.fromARGB(255, 0, 0, 0)',
      ]) {
        expect(_rules(feature, line), contains('raw-colour'), reason: line);
        expect(_rules(kit, line), contains('raw-colour'), reason: line);
        expect(_rules(theme, line), isNot(contains('raw-colour')));
      }
      expect(_rules(kit, 'color: Colors.transparent,'), isEmpty);
      expect(_rules(kit, 'color: context.colors.ink,'), isEmpty);
    });

    test('inline text styles are flagged', () {
      for (final line in [
        'style: TextStyle(color: c),',
        'fontSize: 14,',
        "fontFamily: 'Inter',",
        'fontWeight: FontWeight.w600,',
      ]) {
        expect(_rules(feature, line), contains('inline-text-style'));
      }
      expect(_rules(feature, 'style: context.text.body,'), isEmpty);
    });

    test('raw dimensions are flagged; tokens pass', () {
      for (final line in [
        'SizedBox(height: 12)',
        'width: 48,',
        'padding: EdgeInsets.all(16),',
        'EdgeInsetsDirectional.only(start: 8)',
        'BorderRadius.circular(12)',
        'elevation: 0,',
      ]) {
        expect(_rules(feature, line), contains('raw-dimension'), reason: line);
      }
      for (final line in [
        'SizedBox(height: AppDimensions.sm)',
        'padding: EdgeInsetsDirectional.only(start: AppDimensions.xs),',
        'padding: EdgeInsets.zero,',
        'BorderRadius.circular(AppDimensions.radiusMd)',
      ]) {
        expect(_rules(feature, line), isEmpty, reason: line);
      }
    });

    test('non-directional layout is flagged', () {
      for (final line in [
        'EdgeInsets.only(left: AppDimensions.md)',
        'EdgeInsets.fromLTRB(a, b, c, d)',
        'alignment: Alignment.centerLeft,',
        'textAlign: TextAlign.right,',
        'Positioned(left: x, child: c)',
        'BorderRadius.only(topLeft: r)',
      ]) {
        expect(
          _rules(feature, line),
          contains('non-directional'),
          reason: line,
        );
      }
      for (final line in [
        'alignment: AlignmentDirectional.centerStart,',
        'textAlign: TextAlign.start,',
        'PositionedDirectional(start: x, child: c)',
        'Positioned.fill(child: c)',
        'alignment: Alignment.topCenter,',
      ]) {
        expect(_rules(feature, line), isEmpty, reason: line);
      }
    });

    test('raw motion is banned in presentation and the kit, not in data', () {
      for (final line in [
        'duration: Duration(milliseconds: 300),',
        'curve: Curves.easeIn,',
      ]) {
        expect(_rules(feature, line), contains('raw-motion'), reason: line);
        expect(_rules(kit, line), contains('raw-motion'), reason: line);
        expect(_rules(data, line), isNot(contains('raw-motion')));
      }
      expect(_rules(kit, 'duration: Motion.standard,'), isEmpty);
      expect(_rules(kit, 'Duration.zero'), isEmpty);
    });

    test('DateFormat and NumberFormat live in core/l10n only', () {
      const line = "DateFormat('yyyy-MM-dd', 'en').format(d)";
      expect(_rules(feature, line), contains('intl-format'));
      expect(
        _rules('lib/core/widgets/a.dart', 'NumberFormat.compact()'),
        contains('intl-format'),
      );
      expect(_rules('lib/core/l10n/app_formats.dart', line), isEmpty);
    });

    test("every API format names 'en'", () {
      expect(
        _rules(apiFormatsPath, "final f = DateFormat('yyyy-MM-dd');"),
        contains('api-locale'),
      );
      expect(
        _rules(apiFormatsPath, "final f = DateFormat('yyyy-MM-dd', 'en');"),
        isEmpty,
      );
    });

    test('numbers interpolated into a feature Text are flagged', () {
      expect(
        _rules(feature, r"Text('$count items')"),
        contains('text-interpolation'),
      );
      expect(
        _rules(feature, 'Text(count.toString())'),
        contains('text-interpolation'),
      );
      expect(
        _rules(feature, 'Text(l10n.items(formats.formatNumber(n)))'),
        isEmpty,
      );
      expect(_rules(feature, 'AutoDirectionText(name)'), isEmpty);
    });

    test('google_fonts is banned in new code', () {
      final line = "$_importKeyword 'package:google_fonts/google_fonts.dart';";
      expect(_rules(kit, line), contains('google-fonts'));
    });
  });

  group('KIT-T7: wrapped, spaced and extra style variants', () {
    const feature = 'lib/features/a/presentation/view/a_screen.dart';
    const kit = 'lib/core/widgets/app_a.dart';
    const shell = 'lib/app/shell/app_shell.dart';
    const gallery = 'lib/app/kit_gallery/gallery.dart';
    const testPath = 'test/a_test.dart';

    void flagged(
      String rule,
      String bad,
      String good, {
      String path = feature,
    }) {
      expect(_rules(path, bad), contains(rule), reason: bad);
      expect(_rules(path, good), isNot(contains(rule)), reason: good);
    }

    test('a call wrapped after the paren is caught, on its start line', () {
      flagged(
        'raw-colour',
        'a(\n  Color(\n    0xFF445566,\n  ),\n)',
        'a(\n  c,\n)',
      );
      flagged(
        'raw-dimension',
        'SizedBox(\n  height:\n      12,\n)',
        'SizedBox(\n  height:\n      AppDimensions.sm,\n)',
      );
      flagged(
        'raw-dimension',
        'EdgeInsets.all(\n  8,\n)',
        'EdgeInsets.all(\n  AppDimensions.sm,\n)',
      );
      flagged(
        'raw-motion',
        'x(\n  Duration(\n    milliseconds: 3,\n  ),\n)',
        'x(\n  Motion.standard,\n)',
      );
      flagged(
        'text-interpolation',
        "Text(\n  '\$a',\n)",
        'Text(\n  l10n.a,\n)',
      );
      flagged(
        'inline-text-style',
        'TextStyle(\n  color: c,\n)',
        'context.text.body',
      );
      final v = checkDartFile(
        feature,
        'a\nb\nColor(\n0xFF000000)',
      ).where((v) => v.rule == 'raw-colour');
      expect(v.single.line, 3);
    });

    test('a space before the paren does not hide a violation', () {
      flagged(
        'non-directional',
        'Positioned (left: x, child: c)',
        'Positioned.fill(child: c)',
      );
      flagged('raw-motion', 'Duration (seconds: 1)', 'Duration.zero');
      flagged('inline-text-style', 'TextStyle (color: c)', 'context.text.body');
      flagged('raw-colour', 'Color (0xFF000000)', 'context.colors.ink');
      flagged('intl-format', "DateFormat ('y')", 'AppFormats.date');
    });

    test('Color.from, min/max sizes, size: and SizedBox.square are raw', () {
      flagged(
        'raw-colour',
        'Color.from(alpha: 1, red: 0, green: 0, blue: 0)',
        'Color.lerp(a, b, t)',
      );
      for (final bad in [
        'minHeight: 44,',
        'maxHeight: 44,',
        'minWidth: 44,',
        'maxWidth: 44,',
        'size: 24,',
        'SizedBox.square(dimension: 8)',
      ]) {
        flagged('raw-dimension', bad, 'x: AppDimensions.md');
      }
      expect(_rules(feature, 'minHeight: AppDimensions.tap,'), isEmpty);
      expect(_rules(feature, 'size: AppDimensions.icon,'), isEmpty);
    });

    test('Text.rich and SelectableText are checked for interpolation', () {
      flagged(
        'text-interpolation',
        r"SelectableText('$n')",
        'SelectableText(s)',
      );
      flagged(
        'text-interpolation',
        r"Text.rich(TextSpan(text: '$n'))",
        'Text.rich(TextSpan(text: s))',
      );
      flagged(
        'text-interpolation',
        'SelectableText(n.toString())',
        'SelectableText(s)',
      );
    });

    test(r'an escaped \$ in a Text is not interpolation', () {
      expect(_rules(feature, r"Text('\$5 off')"), isEmpty);
      expect(_rules(feature, r"Text('a \$ b')"), isEmpty);
    });

    test('named DateFormat and NumberFormat constructors are caught', () {
      flagged('intl-format', 'NumberFormat.compact()', 'AppFormats.compact');
      flagged('intl-format', 'DateFormat.jm(l)', 'AppFormats.time');
      flagged(
        'api-locale',
        'final f = DateFormat.jm(l);',
        "final f = DateFormat.jm('en');",
        path: apiFormatsPath,
      );
      flagged(
        'api-locale',
        'final f = NumberFormat.compact();',
        "final f = NumberFormat.compact(locale: 'en');",
        path: apiFormatsPath,
      );
      flagged(
        'api-locale',
        "DateFormat(\n  'yyyy',\n)",
        "DateFormat(\n  'yyyy',\n  'en',\n)",
        path: apiFormatsPath,
      );
    });

    test('the kit paths obey inline-text-style, raw-dimension, direction', () {
      for (final path in [kit, shell, gallery]) {
        flagged(
          'inline-text-style',
          'fontSize: 14,',
          'context.text.body',
          path: path,
        );
        flagged(
          'raw-dimension',
          'width: 48,',
          'width: AppDimensions.md,',
          path: path,
        );
        flagged(
          'non-directional',
          'TextAlign.left',
          'TextAlign.start',
          path: path,
        );
      }
    });

    test('isStyled and isMotionScoped cover the right folders', () {
      for (final p in [
        feature,
        'lib/features/a/data/repositories/a_repository.dart',
        kit,
        shell,
        gallery,
      ]) {
        expect(isStyled(p), isTrue, reason: p);
      }
      for (final p in [
        'lib/core/theme/a.dart',
        'lib/core/l10n/a.dart',
        'lib/app/a.dart',
      ]) {
        expect(isStyled(p), isFalse, reason: p);
      }
      for (final p in [feature, kit, shell, gallery]) {
        expect(isMotionScoped(p), isTrue, reason: p);
      }
      for (final p in [
        'lib/features/a/data/repositories/a_repository.dart',
        'lib/core/theme/a.dart',
        'lib/features/a/domain/b.dart',
      ]) {
        expect(isMotionScoped(p), isFalse, reason: p);
      }
    });

    test('test paths are out of scope of the style rules', () {
      const bad =
          'Color(0xFF000000) TextStyle(fontSize: 1) Duration(seconds: 1)';
      expect(_rules(testPath, bad), isEmpty);
    });
  });
}
