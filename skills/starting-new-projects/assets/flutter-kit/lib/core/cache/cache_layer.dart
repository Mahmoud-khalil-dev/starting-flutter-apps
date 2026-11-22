import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:kit_app/core/cache/cache_entry.dart';
import 'package:kit_app/core/cache/cache_store.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/session/stale_session_guard.dart';
import 'package:kit_app/core/time/app_clock.dart';

enum CacheSource { memory, disk, network }

/// A value and where it came from. [stale] is true past its time to live;
/// [failure] is set when the network failed and this is the saved value.
class Cached<T> extends Equatable {
  const Cached(
    this.value, {
    required this.source,
    this.stale = false,
    this.failure,
  });

  final T value;
  final CacheSource source;
  final bool stale;
  final Failure? failure;

  @override
  List<Object?> get props => [value, source, stale, failure];
}

/// Memory, then disk, then the network. A fresh entry answers alone; a
/// stale one shows first and the network answer follows; offline, the
/// saved value stays and carries the failure. An answer from a session
/// that has since ended is neither shown nor stored.
class CacheLayer with StaleSessionGuard {
  CacheLayer({
    required this._memory,
    required this._disk,
    required this._clock,
    required this._sessionGeneration,
  });

  final CacheStore _memory;
  final CacheStore _disk;
  final AppClock _clock;
  final int Function() _sessionGeneration;

  @override
  int Function() get sessionGeneration => _sessionGeneration;

  Stream<Either<Failure, Cached<T>>> cacheThenNetwork<T>({
    required String key,
    required Duration ttl,
    required Future<Either<Failure, T>> Function() fetch,
    required T Function(Object? json) decode,
    required Object? Function(T value) encode,
    bool refresh = false,
  }) async* {
    final generation = sessionGeneration();
    Cached<T>? saved;
    final hit = await _read(key, generation);
    // A sign-out landed while the entry was read: it is the last account's.
    if (isStale(generation)) return;
    if (hit != null) {
      final (entry, source) = hit;
      final decoded = _decode(entry.value, decode);
      if (decoded == null) {
        await remove(key);
      } else {
        final fresh = entry.isFresh(_clock.now(), ttl);
        saved = Cached<T>(decoded.$1, source: source, stale: !fresh);
        yield Right(saved);
        if (fresh && !refresh) return;
      }
    }
    final result = await fetch();
    if (isStale(generation)) return;
    final (failure, fetched) = result.fold(
      (failure) => (failure, null),
      (value) => (null, (value,)),
    );
    if (failure != null) {
      yield saved == null
          ? Left(failure)
          : Right(
              Cached<T>(
                saved.value,
                source: saved.source,
                stale: true,
                failure: failure,
              ),
            );
      return;
    }
    final value = fetched!.$1;
    await _write(key, encode(value), generation);
    yield Right(Cached<T>(value, source: CacheSource.network));
  }

  Future<void> remove(String key) async {
    await _memory.remove(key);
    await _disk.remove(key);
  }

  Future<void> clear() async {
    await _memory.clear();
    await _disk.clear();
  }

  static (T,)? _decode<T>(Object? json, T Function(Object? json) decode) {
    try {
      return (decode(json),);
    } on Object {
      // The shape changed since this entry was written.
      return null;
    }
  }

  Future<(CacheEntry, CacheSource)?> _read(String key, int generation) async {
    final inMemory = await _memory.read(key);
    if (inMemory != null) return (inMemory, CacheSource.memory);
    final onDisk = await _disk.read(key);
    if (onDisk == null || isStale(generation)) return null;
    await _memory.write(key, onDisk);
    // A sign-out that cleared memory during the warm write: undo it.
    if (isStale(generation)) {
      await _memory.remove(key);
      return null;
    }
    return (onDisk, CacheSource.disk);
  }

  Future<void> _write(String key, Object? json, int generation) async {
    final entry = CacheEntry(value: json, storedAt: _clock.now());
    await _memory.write(key, entry);
    // A sign-out may have landed while memory was written: leave no entry.
    if (isStale(generation)) return;
    try {
      await _disk.write(key, entry);
    } on Object {
      // A full disk must not fail a screen that already has its data.
    }
  }
}
