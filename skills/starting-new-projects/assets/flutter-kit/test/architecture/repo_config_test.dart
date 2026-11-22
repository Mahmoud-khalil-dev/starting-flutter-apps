import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final gitignore = File('.gitignore').readAsStringSync();

  group('KIT-T7: secrets stay out of the repository', () {
    test('real env files are ignored, examples are not', () {
      expect(gitignore, contains('env/*.json'));
      expect(gitignore, contains('!env/*.example.json'));
    });

    test('check_secrets fails when a key-like file is present', () {
      final repo = Directory.systemTemp.createTempSync('secrets_gate');
      addTearDown(() => repo.deleteSync(recursive: true));
      Directory('${repo.path}/tool').createSync();
      File(
        'tool/check_secrets.sh',
      ).copySync('${repo.path}/tool/check_secrets.sh');
      Process.runSync('git', ['init', '-q'], workingDirectory: repo.path);
      File('${repo.path}/x.p8').writeAsStringSync('not a real key');
      final run = Process.runSync('bash', [
        'tool/check_secrets.sh',
      ], workingDirectory: repo.path);
      expect(run.exitCode, isNot(0));
      expect(run.stderr, contains('x.p8'));
    });

    test('check_secrets finds nothing in the tree', () {
      final run = Process.runSync('bash', ['tool/check_secrets.sh']);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    });
  });

  group('KIT-T7: env examples', () {
    test('env examples hold exactly the keys Env reads', () {
      const keys = {'BASE_URL', 'FLAVOR'};
      for (final f in ['env/dev.example.json', 'env/prod.example.json']) {
        final found = RegExp(
          '"([A-Z_]+)":',
        ).allMatches(File(f).readAsStringSync()).map((m) => m.group(1)).toSet();
        expect(found, keys, reason: f);
      }
    });
  });
}
