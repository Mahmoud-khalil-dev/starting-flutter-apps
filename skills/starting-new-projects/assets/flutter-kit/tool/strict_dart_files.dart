/// Prints the Dart files that follow the strict rules (everything outside
/// tool/legacy_paths.dart and outside generated code), one per line.
///
/// Usage: dart run tool/strict_dart_files.dart
library;

import 'dart:io';

import 'legacy_paths.dart';

const _generatedNames = ['app_localizations'];
const _generatedSuffixes = ['.g.dart', '.freezed.dart'];

bool _isGenerated(String path) {
  final name = path.split('/').last;
  return _generatedSuffixes.any(name.endsWith) ||
      _generatedNames.any(name.startsWith);
}

/// The strict Dart files among [paths] (forward-slash, repo-relative).
List<String> strictDartFiles(Iterable<String> paths) => [
  for (final path in paths)
    if (path.endsWith('.dart') && !isLegacy(path) && !_isGenerated(path)) path,
];

void main() {
  final all = [
    for (final root in ['lib', 'test', 'tool'])
      if (Directory(root).existsSync())
        for (final e in Directory(root).listSync(recursive: true))
          if (e is File) e.path.replaceAll(r'\', '/'),
  ]..sort();
  strictDartFiles(all).forEach(stdout.writeln);
}
