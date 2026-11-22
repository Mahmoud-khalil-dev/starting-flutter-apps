/// New code has zero analyzer issues; legacy code stays at its baseline.
///
/// Usage:
///   dart run tool/analyze_gate.dart          check the gate
///   dart run tool/analyze_gate.dart --count  print the legacy issue count,
///                                            to regenerate the baseline file
library;

import 'dart:io';

import 'legacy_paths.dart';

class GateResult {
  const GateResult({required this.passed, required this.messages});
  final bool passed;
  final List<String> messages;
}

const _baselineFile = 'tool/legacy_analyze_baseline.txt';

/// Splits `dart analyze --format=machine` output into issue lines whose file
/// path (relative to [root]) is legacy or not.
({List<String> strict, int legacy}) _classify(
  String machineOutput,
  String root,
) {
  final strict = <String>[];
  var legacy = 0;
  for (final line in machineOutput.split('\n')) {
    final parts = line.split('|');
    if (parts.length < 8) continue;
    final file = parts[3].replaceFirst(root, '');
    if (isLegacy(file)) {
      legacy++;
    } else {
      strict.add('$file:${parts[4]} ${parts[2]} ${parts[7]}');
    }
  }
  return (strict: strict, legacy: legacy);
}

/// Number of issues the gate counts as legacy; this is the baseline value.
int legacyIssueCount(String machineOutput, String root) =>
    _classify(machineOutput, root).legacy;

/// [machineOutput] is `dart analyze --format=machine`. [root] is the absolute
/// repo path with a trailing slash, stripped from each file.
GateResult checkAnalyze(String machineOutput, int baseline, String root) {
  final (:strict, :legacy) = _classify(machineOutput, root);
  if (strict.isNotEmpty) return GateResult(passed: false, messages: strict);
  if (legacy > baseline) {
    return GateResult(
      passed: false,
      messages: ['$legacy legacy issues, baseline $baseline'],
    );
  }
  if (legacy < baseline) {
    return GateResult(
      passed: false,
      messages: ['lower $_baselineFile to $legacy'],
    );
  }
  return GateResult(
    passed: true,
    messages: ['$legacy legacy issues, baseline $baseline'],
  );
}

void main(List<String> args) {
  final run = Process.runSync('dart', ['analyze', '--format=machine']);
  final output = '${run.stdout}\n${run.stderr}';
  final root = '${Directory.current.path}/';
  if (args.contains('--count')) {
    stdout.writeln(legacyIssueCount(output, root));
    return;
  }
  final baseline = int.parse(File(_baselineFile).readAsStringSync().trim());
  final result = checkAnalyze(output, baseline, root);
  result.messages.forEach(result.passed ? stdout.writeln : stderr.writeln);
  if (!result.passed) exitCode = 1;
}
