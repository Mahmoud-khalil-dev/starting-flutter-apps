import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/cache/cache_entry.dart';
import 'package:kit_app/core/cache/cache_layer.dart';
import 'package:kit_app/core/cache/cache_sign_out_hook.dart';
import 'package:kit_app/core/cache/cache_store.dart';
import 'package:kit_app/core/error/failures.dart';

import '../../helpers/fixed_clock.dart';

const _ttl = Duration(minutes: 5);

typedef _Result = Either<Failure, Cached<List<String>>>;

class _Harness {
  _Harness({CacheStore? disk}) : disk = disk ?? MemoryCacheStore();

  final FixedClock clock = FixedClock(DateTime.utc(2026, 11, 21, 9));
  final MemoryCacheStore memory = MemoryCacheStore();

  /// A second in-memory store stands in for the disk.
  final CacheStore disk;
  int generation = 0;
  int fetches = 0;

  late final layer = CacheLayer(
    memory: memory,
    disk: disk,
    clock: clock,
    sessionGeneration: () => generation,
  );

  Future<List<_Result>> load(
    Future<Either<Failure, List<String>>> Function() fetch,
  ) => layer
      .cacheThenNetwork<List<String>>(
        key: 'notes',
        ttl: _ttl,
        fetch: () {
          fetches++;
          return fetch();
        },
        decode: (json) => [
          for (final item in json! as List<Object?>) item! as String,
        ],
        encode: (notes) => notes,
      )
      .toList();
}

Future<Either<Failure, List<String>>> Function() _answer(List<String> v) =>
    () async => Right(v);

Future<Either<Failure, List<String>>> _offline() async =>
    const Left(NoConnection());

class _ThrowingStore extends MemoryCacheStore {
  @override
  Future<void> write(String key, CacheEntry entry) async =>
      throw StateError('disk full');
}

class _OnWriteStore extends MemoryCacheStore {
  _OnWriteStore(this.onWrite);

  final void Function() onWrite;

  @override
  Future<void> write(String key, CacheEntry entry) async {
    await super.write(key, entry);
    onWrite();
  }
}

/// A disk whose reads wait for [gate], as a slow flash read does.
class _SlowReadStore extends MemoryCacheStore {
  final gate = Completer<void>();

  @override
  Future<CacheEntry?> read(String key) async {
    final entry = await super.read(key);
    await gate.future;
    return entry;
  }
}

void main() {
  test('KIT-T14: a miss goes to the network and stores the answer', () async {
    final h = _Harness();
    expect(await h.load(_answer(['a'])), [
      const Right<Failure, Cached<List<String>>>(
        Cached(['a'], source: CacheSource.network),
      ),
    ]);
    expect(await h.memory.read('notes'), isNotNull);
    expect(await h.disk.read('notes'), isNotNull);
  });

  test('KIT-T14: a fresh hit answers from memory with no request', () async {
    final h = _Harness();
    await h.load(_answer(['a']));
    expect(await h.load(_answer(['b'])), [
      const Right<Failure, Cached<List<String>>>(
        Cached(['a'], source: CacheSource.memory),
      ),
    ]);
    expect(h.fetches, 1);
  });

  test('KIT-T14: a stale hit shows first, then the network answer', () async {
    final h = _Harness();
    await h.load(_answer(['a']));
    h.clock.advance(_ttl);
    expect(await h.load(_answer(['b'])), [
      const Right<Failure, Cached<List<String>>>(
        Cached(['a'], source: CacheSource.memory, stale: true),
      ),
      const Right<Failure, Cached<List<String>>>(
        Cached(['b'], source: CacheSource.network),
      ),
    ]);
  });

  test('KIT-T14: offline, the saved value stays with the failure', () async {
    final h = _Harness();
    await h.load(_answer(['a']));
    h.clock.advance(_ttl);
    final results = await h.load(_offline);
    expect(
      results.last,
      const Right<Failure, Cached<List<String>>>(
        Cached(
          ['a'],
          source: CacheSource.memory,
          stale: true,
          failure: NoConnection(),
        ),
      ),
    );
  });

  test('KIT-T14: offline with nothing saved is the failure', () async {
    expect(await _Harness().load(_offline), [
      const Left<Failure, Cached<List<String>>>(NoConnection()),
    ]);
  });

  test('KIT-T14: the disk answers after a restart', () async {
    final first = _Harness();
    await first.load(_answer(['a']));
    final restarted = _Harness(disk: first.disk);
    expect(await restarted.load(_answer(['b'])), [
      const Right<Failure, Cached<List<String>>>(
        Cached(['a'], source: CacheSource.disk),
      ),
    ]);
  });

  test('KIT-T14: an entry that no longer decodes is dropped', () async {
    final h = _Harness();
    await h.disk.write('notes', CacheEntry(value: 42, storedAt: h.clock.now()));
    expect(await h.load(_answer(['a'])), [
      const Right<Failure, Cached<List<String>>>(
        Cached(['a'], source: CacheSource.network),
      ),
    ]);
  });

  test('KIT-T14: an answer from before a sign-out is not stored', () async {
    final h = _Harness();
    final slow = Completer<Either<Failure, List<String>>>();
    final pending = h.load(() => slow.future);
    await pumpEventQueue();
    h.generation++;
    slow.complete(const Right(['old user']));
    expect(await pending, isEmpty);
    expect(await h.memory.read('notes'), isNull);
    expect(await h.disk.read('notes'), isNull);
  });

  test(
    'KIT-T14: refresh asks the network although the entry is fresh',
    () async {
      final h = _Harness();
      await h.load(_answer(['a']));
      final results = await h.layer
          .cacheThenNetwork<List<String>>(
            key: 'notes',
            ttl: _ttl,
            refresh: true,
            fetch: () {
              h.fetches++;
              return _answer(['b'])();
            },
            decode: (json) => [
              for (final item in json! as List<Object?>) item! as String,
            ],
            encode: (notes) => notes,
          )
          .toList();
      expect(results, [
        const Right<Failure, Cached<List<String>>>(
          Cached(['a'], source: CacheSource.memory),
        ),
        const Right<Failure, Cached<List<String>>>(
          Cached(['b'], source: CacheSource.network),
        ),
      ]);
      expect(h.fetches, 2);
    },
  );

  test('KIT-T14: a failing disk write does not fail the load', () async {
    final h = _Harness(disk: _ThrowingStore());
    expect(await h.load(_answer(['a'])), [
      const Right<Failure, Cached<List<String>>>(
        Cached(['a'], source: CacheSource.network),
      ),
    ]);
    expect(await h.memory.read('notes'), isNotNull);
  });

  test('KIT-T14: a sign-out between the memory and disk writes leaves '
      'no disk entry', () async {
    final h = _Harness();
    final memory = _OnWriteStore(() => h.generation++);
    final layer = CacheLayer(
      memory: memory,
      disk: h.disk,
      clock: h.clock,
      sessionGeneration: () => h.generation,
    );
    await layer
        .cacheThenNetwork<List<String>>(
          key: 'notes',
          ttl: _ttl,
          fetch: _answer(['a']),
          decode: (json) => [
            for (final item in json! as List<Object?>) item! as String,
          ],
          encode: (notes) => notes,
        )
        .toList();
    expect(await h.disk.read('notes'), isNull);
  });

  test('KIT-T14: a disk hit warms memory', () async {
    final first = _Harness();
    await first.load(_answer(['a']));
    final restarted = _Harness(disk: first.disk);
    await restarted.load(_answer(['b']));
    expect(await restarted.memory.read('notes'), isNotNull);
  });

  test('KIT-T14: the sign-out hook clears memory and disk', () async {
    final h = _Harness();
    await h.load(_answer(['a']));
    await CacheSignOutHook(h.layer).onSignOut(byUser: false);
    expect(await h.memory.read('notes'), isNull);
    expect(await h.disk.read('notes'), isNull);
  });

  test('KIT-T14: an entry read just before a sign-out is not shown or '
      'warmed after it', () async {
    final first = _Harness();
    await first.load(_answer(['old user']));
    final disk = _SlowReadStore();
    await disk.write('notes', (await first.disk.read('notes'))!);
    final h = _Harness(disk: disk);
    final pending = h.load(_answer(['new user']));
    await pumpEventQueue();
    // The sign-out lands while the disk read is in flight.
    h.generation++;
    await h.layer.clear();
    disk.gate.complete();
    final results = await pending;
    expect(
      results.whereType<Right<Failure, Cached<List<String>>>>().where(
        (r) => r.value.value.contains('old user'),
      ),
      isEmpty,
    );
    expect(await h.memory.read('notes'), isNull);
  });
}
