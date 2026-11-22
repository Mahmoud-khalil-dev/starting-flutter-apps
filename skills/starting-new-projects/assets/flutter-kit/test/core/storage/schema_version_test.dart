import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/schema_version.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppPreferences> _prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return AppPreferences(await SharedPreferences.getInstance());
}

void main() {
  late List<String?> lines;

  setUp(() {
    lines = [];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => lines.add(message);
    addTearDown(() => debugPrint = original);
  });

  test('KIT-T9: a fresh install is stamped with the current version', () async {
    final prefs = await _prefs();
    await const SchemaVersion().ensure(prefs);
    expect(prefs.storageSchema, SchemaVersion.current);
  });

  test('KIT-T9: the stamp is written after the migrations succeed', () async {
    final prefs = await _prefs();
    int? stampSeenByMigration;
    await const SchemaVersion().ensure(
      prefs,
      migrations: {1: () async => stampSeenByMigration = prefs.storageSchema},
    );
    expect(stampSeenByMigration, 0);
    expect(prefs.storageSchema, 1);
  });

  test('KIT-T9: migrations above the stored version run in order', () async {
    final prefs = await _prefs({'storage_schema': 1});
    final ran = <int>[];
    await const SchemaVersion().ensure(
      prefs,
      migrations: {
        4: () async => ran.add(4),
        2: () async => ran.add(2),
        1: () async => ran.add(1),
        3: () async => ran.add(3),
      },
    );
    expect(ran, [2, 3, 4]);
    expect(prefs.storageSchema, 4);
  });

  test('KIT-T9: a current install runs nothing and stays put', () async {
    final prefs = await _prefs({'storage_schema': 1});
    var ran = false;
    await const SchemaVersion().ensure(
      prefs,
      migrations: {1: () async => ran = true},
    );
    expect(ran, isFalse);
    expect(prefs.storageSchema, 1);
  });

  test('KIT-T9: data from a newer app is never stamped down', () async {
    final prefs = await _prefs({'storage_schema': 9});
    await const SchemaVersion().ensure(prefs);
    expect(prefs.storageSchema, 9);
  });

  test(
    'KIT-T9: a throwing migration leaves the stamp and never throws',
    () async {
      final prefs = await _prefs();
      final ran = <int>[];
      await const SchemaVersion().ensure(
        prefs,
        migrations: {
          1: () async => throw StateError('user@example.com'),
          2: () async => ran.add(2),
        },
      );
      expect(prefs.storageSchema, 0);
      expect(ran, isEmpty, reason: 'a later step must not run after a failure');
    },
  );

  test('KIT-T9: progress before a failure is kept', () async {
    final prefs = await _prefs();
    await const SchemaVersion().ensure(
      prefs,
      migrations: {1: () async {}, 2: () async => throw StateError('x')},
    );
    expect(prefs.storageSchema, 1);
  });

  test('KIT-T9: a failure is logged by type, never by message', () async {
    final prefs = await _prefs();
    await const SchemaVersion().ensure(
      prefs,
      migrations: {1: () async => throw StateError('user@example.com')},
    );
    expect(lines, ['[warn] Boot step schema migration failed: StateError']);
  });
}
