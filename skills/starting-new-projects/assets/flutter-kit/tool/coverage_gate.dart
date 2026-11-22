/// Every Cubit in new code needs at least 80% line coverage. Legacy Cubits are
/// left out until they migrate (tool/legacy_paths.dart).
///
/// Usage: dart run tool/coverage_gate.dart coverage/lcov.info
library;

import 'dart:io';

import 'legacy_paths.dart';

const minimumCubitCoverage = 80.0;

/// A Cubit file in new code: `*_cubit.dart`, `*_cubits.dart`, `cubit.dart`
/// (the legacy `<feature>_cubit/cubit.dart` shape), or any other file inside a
/// `cubit/` or `*_cubit/` folder except state files.
bool _isCubitFile(String path) {
  if (isLegacy(path)) return false;
  final parts = path.split('/');
  final name = parts.last;
  if (name.endsWith('_cubit.dart') ||
      name.endsWith('_cubits.dart') ||
      name == 'cubit.dart') {
    return true;
  }
  final inCubitFolder = parts
      .take(parts.length - 1)
      .any((d) => d == 'cubit' || d.endsWith('_cubit'));
  return inCubitFolder && name.endsWith('.dart') && !name.contains('state');
}

/// Line coverage per new-code Cubit file in [lcov].
///
/// lcov lists only files some test loaded, so a Cubit that no test touches is
/// missing from it. Pass every Cubit file on disk as [cubitFiles]: those absent
/// from [lcov] count as 0%.
Map<String, double> cubitCoverage(
  String lcov, {
  Iterable<String> cubitFiles = const [],
}) {
  final result = <String, double>{};
  String? file;
  var total = 0;
  var hit = 0;
  for (final line in lcov.split('\n')) {
    if (line.startsWith('SF:')) {
      file = line.substring(3).trim();
      total = 0;
      hit = 0;
    } else if (line.startsWith('DA:')) {
      total++;
      if (!line.trim().endsWith(',0')) hit++;
    } else if (line.startsWith('end_of_record')) {
      if (file != null && _isCubitFile(file) && total > 0) {
        result[file] = hit * 100 / total;
      }
      file = null;
    }
  }
  for (final path in cubitFiles) {
    if (_isCubitFile(path)) result.putIfAbsent(path, () => 0.0);
  }
  return result;
}

List<String> belowMinimum(Map<String, double> coverage, double minimum) => [
  for (final MapEntry(key: file, value: percent) in coverage.entries)
    if (percent < minimum) '$file: ${percent.toStringAsFixed(1)}%',
];

List<String> _cubitFilesOnDisk() => [
  for (final entity in Directory('lib').listSync(recursive: true))
    if (entity is File) entity.path.replaceAll(r'\', '/'),
];

void main(List<String> args) {
  final coverage = cubitCoverage(
    File(args.single).readAsStringSync(),
    cubitFiles: _cubitFilesOnDisk(),
  );
  final failing = belowMinimum(coverage, minimumCubitCoverage);
  if (failing.isNotEmpty) {
    stderr.writeln('Cubits under $minimumCubitCoverage% line coverage:');
    failing.forEach(stderr.writeln);
    exitCode = 1;
  } else {
    stdout.writeln(
      '${coverage.length} new Cubits at $minimumCubitCoverage% or more.',
    );
  }
}
