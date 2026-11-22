import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kit_app/core/theme/app_fonts.dart';

/// Loads the SDK's Roboto and Material Icons into the test engine, so
/// goldens show real glyphs instead of Ahem boxes. The kit bundles no font
/// files; a project that bundles its brand fonts loads them here too (see
/// `Brand`). Arabic draws in the machine's own Arabic face when one is
/// found, and in Ahem boxes otherwise, so an Arabic golden is a layout
/// check, not a type check.
Future<void> loadGoldenFonts() async {
  final sdk = _sdkFonts();
  await _load('Roboto', [
    '$sdk/Roboto-Regular.ttf',
    '$sdk/Roboto-Medium.ttf',
    '$sdk/Roboto-Bold.ttf',
  ]);
  await _load('MaterialIcons', [materialIconsPath()]);
  for (final path in _machineArabic) {
    if (File(path).existsSync()) {
      await _load(arabicGoldenFamily, [path]);
      AppFonts.fallbackOverride = [arabicGoldenFamily];
      break;
    }
  }
}

/// The family an Arabic face found on the machine is loaded under.
const arabicGoldenFamily = 'KitGoldenArabic';

const _machineArabic = ['/System/Library/Fonts/SFArabic.ttf'];

/// The directory of the SDK's bundled fonts.
String _sdkFonts() => File(materialIconsPath()).parent.path;

/// A font file the SDK bundles, by name (`Roboto-Regular.ttf`).
String sdkFontPath(String name) => '${_sdkFonts()}/$name';

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
  }
  await loader.load();
}

/// The SDK ships the icon font under bin/cache/artifacts/material_fonts.
/// FLUTTER_ROOT is set by `flutter test`; the executable path is the
/// fallback (fvm links the SDK under .fvm/). Throws when the font is not
/// found: a golden drawn without it would show tofu for every icon.
///
/// [flutterRoot] and [executable] default to the environment and the
/// running executable; tests pass their own.
String materialIconsPath({String? flutterRoot, String? executable}) {
  const relative =
      'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  final root = flutterRoot ?? Platform.environment['FLUTTER_ROOT'];
  if (root != null && File('$root/$relative').existsSync()) {
    return '$root/$relative';
  }
  var dir = File(executable ?? Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/material_fonts/MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) return candidate.path;
    dir = dir.parent;
  }
  throw StateError(
    'MaterialIcons-Regular.otf not found (looked under FLUTTER_ROOT '
    '"${root ?? 'unset'}" and above "${executable ?? Platform.resolvedExecutable}"). '
    'Goldens would draw every icon as tofu. Run through `flutter test` or '
    'set FLUTTER_ROOT to the SDK.',
  );
}
