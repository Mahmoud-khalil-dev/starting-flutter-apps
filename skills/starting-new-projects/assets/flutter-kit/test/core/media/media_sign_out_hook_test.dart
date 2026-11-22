import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/media/media_sign_out_hook.dart';
import 'package:mocktail/mocktail.dart';

class _Cache extends Mock implements BaseCacheManager {}

class _Reporter extends Mock implements CrashReporter {}

class _Pending extends ImageStreamCompleter {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Cache cache;
  late _Reporter reporter;

  setUp(() {
    cache = _Cache();
    reporter = _Reporter();
    when(
      () => reporter.recordError(any(), any(), fatal: any(named: 'fatal')),
    ).thenAnswer((_) async {});
    registerFallbackValue(StackTrace.empty);
  });

  MediaSignOutHook hook({Duration? wait}) => MediaSignOutHook(
    () => cache,
    reporter,
    wait: wait ?? const Duration(seconds: 2),
  );

  test('KIT-T18: sign-out waits until the disk cache is empty', () async {
    final emptied = Completer<void>();
    when(cache.emptyCache).thenAnswer((_) => emptied.future);
    var done = false;
    final run = hook().onSignOut(byUser: true).then((_) => done = true);
    await pumpEventQueue();
    expect(done, isFalse);
    emptied.complete();
    await run;
    expect(done, isTrue);
    verify(cache.emptyCache).called(1);
  });

  test('KIT-T18: sign-out drops decoded images from memory', () async {
    when(cache.emptyCache).thenAnswer((_) async {});
    final images = PaintingBinding.instance.imageCache
      ..clear()
      ..putIfAbsent('last-account-photo', _Pending.new);
    expect(images.containsKey('last-account-photo'), isTrue);
    await hook().onSignOut(byUser: false);
    expect(images.pendingImageCount, 0);
    expect(images.liveImageCount, 0);
    expect(images.containsKey('last-account-photo'), isFalse);
  });

  test(
    'KIT-T18: a cache that fails is reported by type, never blocks',
    () async {
      when(cache.emptyCache).thenThrow(StateError('/Users/someone/cache.db'));
      await hook().onSignOut(byUser: true);
      final reported = verify(
        () => reporter.recordError(captureAny(), any()),
      ).captured.single;
      expect(reported, contains('StateError'));
      expect(reported, isNot(contains('someone')));
    },
  );

  test('KIT-T18: a cache that never answers is cut off and reported', () async {
    when(cache.emptyCache).thenAnswer((_) => Completer<void>().future);
    await hook(wait: const Duration(milliseconds: 20)).onSignOut(byUser: true);
    verify(() => reporter.recordError(any(), any())).called(1);
  });

  test(
    'KIT-T18: a factory that throws is reported and memory is cleared',
    () async {
      final images = PaintingBinding.instance.imageCache
        ..clear()
        ..putIfAbsent('k', _Pending.new);
      await MediaSignOutHook(
        () => throw StateError('no path'),
        reporter,
      ).onSignOut(byUser: false);
      expect(images.currentSize, 0);
      verify(() => reporter.recordError(any(), any())).called(1);
    },
  );

  test('KIT-T18: the web has no disk cache of ours to empty', () async {
    await MediaSignOutHook(() => null, reporter).onSignOut(byUser: true);
    verifyNever(() => reporter.recordError(any(), any()));
  });
}
