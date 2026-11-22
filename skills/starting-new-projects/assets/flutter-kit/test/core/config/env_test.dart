import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/config/env.dart';

void main() {
  group('KIT-T7: Env.validate', () {
    test('a build with no values compiled in names every empty key', () {
      expect(
        () => Env.validate(baseUrl: '', flavor: '', isRelease: false),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('BASE_URL'), contains('FLAVOR')),
          ),
        ),
      );
    });

    test('Env has no default value that looks like a host', () {
      final source = File('lib/core/config/env.dart').readAsStringSync();
      expect(source, isNot(contains('://')));
      expect(
        RegExp(
          r"fromEnvironment\(\s*'[A-Z_]+',\s*defaultValue",
        ).hasMatch(source),
        isFalse,
      );
    });

    test('a debug build accepts a dev host over http', () {
      expect(
        () => Env.validate(
          baseUrl: 'http://dev.example.com/v1',
          flavor: 'dev',
          isRelease: false,
        ),
        returnsNormally,
      );
    });

    test('a release build must use https', () {
      expect(
        () => Env.validate(
          baseUrl: 'http://api.example.com/v1',
          flavor: 'prod',
          isRelease: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('a release build must not use a dev host', () {
      for (final host in ['dev-api.example.com', 'dev.example.com']) {
        expect(
          () => Env.validate(
            baseUrl: 'https://$host/v1',
            flavor: 'prod',
            isRelease: true,
          ),
          throwsA(isA<StateError>()),
          reason: host,
        );
      }
    });

    test('a release build on https with a prod host passes', () {
      expect(
        () => Env.validate(
          baseUrl: 'https://api.example.com/v1',
          flavor: 'prod',
          isRelease: true,
        ),
        returnsNormally,
      );
    });
  });
}
