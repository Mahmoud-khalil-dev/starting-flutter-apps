import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

YamlMap _workflow() =>
    loadYaml(File('.github/workflows/verify.yml').readAsStringSync())
        as YamlMap;

List<YamlMap> _steps() => [
  for (final step
      in ((_workflow()['jobs'] as YamlMap)['verify'] as YamlMap)['steps']
          as YamlList)
    step as YamlMap,
];

bool _uses(YamlMap step, String action) =>
    '${step['uses']}'.startsWith('$action@');

void main() {
  test('KIT-T19: the CI workflow exists and parses', () {
    expect(File('.github/workflows/verify.yml').existsSync(), isTrue);
    expect(_workflow, returnsNormally);
  });

  test('KIT-T19: pull requests run verify.sh', () {
    final on = _workflow()['on'] as YamlMap;
    expect(on.containsKey('pull_request'), isTrue);
    expect(_steps().last['run'], 'bash tool/verify.sh');
  });

  test('KIT-T19: Flutter is pinned and cached, and so is pub', () {
    final flutter = _steps().singleWhere(
      (step) => _uses(step, 'subosito/flutter-action'),
    );
    final settings = flutter['with'] as YamlMap;
    expect(settings['flutter-version'], '3.44.9');
    expect(settings['cache'], isTrue);
    final pub = _steps().singleWhere((step) => _uses(step, 'actions/cache'));
    expect((pub['with'] as YamlMap)['path'], '~/.pub-cache');
  });

  test('KIT-T19: the workflow can only read the repository', () {
    expect(_workflow()['permissions'], {'contents': 'read'});
  });

  test('KIT-T19: every action is pinned to a full commit SHA', () {
    final pinned = RegExp(r'^[\w.-]+/[\w.-]+@[0-9a-f]{40}$');
    final uses = [
      for (final step in _steps())
        if (step['uses'] != null) '${step['uses']}',
    ];
    expect(uses, isNotEmpty);
    for (final action in uses) {
      expect(action, matches(pinned));
    }
  });

  test('KIT-T19: a new push cancels the run it replaces', () {
    final concurrency = _workflow()['concurrency'] as YamlMap;
    expect(concurrency['cancel-in-progress'], isTrue);
  });

  test('KIT-T19: the workflow never runs on pull_request_target', () {
    final on = _workflow()['on'] as YamlMap;
    expect(on.containsKey('pull_request_target'), isFalse);
  });

  test('KIT-T19: the pub cache key hashes pubspec.yaml and pubspec.lock', () {
    final pub = _steps().singleWhere((step) => _uses(step, 'actions/cache'));
    final key = '${(pub['with'] as YamlMap)['key']}';
    expect(key, contains("hashFiles('pubspec.yaml', 'pubspec.lock')"));
  });

  test('KIT-T19: checkout is the first step', () {
    expect(_uses(_steps().first, 'actions/checkout'), isTrue);
  });

  test('KIT-T19: CI resolves packages from the lock, never past it', () {
    final runs = [for (final step in _steps()) '${step['run'] ?? ''}'];
    final gets = [
      for (final (i, run) in runs.indexed)
        if (run.contains('pub get')) (i, run),
    ];
    expect(gets, isNotEmpty);
    for (final (i, run) in gets) {
      expect(run, 'flutter pub get --enforce-lockfile');
      expect(i, lessThan(runs.indexOf('bash tool/verify.sh')));
    }
  });
}
