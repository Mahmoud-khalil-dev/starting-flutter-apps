import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/session/sign_out_service.dart';

/// Drops what the last account's images left behind, in memory and on disk,
/// so the next account never sees them: the decoded images Flutter holds
/// (cleared at once) and the files the cache manager stored. The disk cache
/// is asked for only when a sign-out runs, so building the graph never
/// touches the disk. The factory returns null on the web, where the browser
/// owns the image cache.
///
/// It waits for the disk, at most [wait]. A cache that fails or is slow is
/// reported to the [CrashReporter] by error type only (a message can carry a
/// path) and never blocks the sign-out.
class MediaSignOutHook implements SignOutHook {
  const MediaSignOutHook(
    this._cache,
    this._reporter, {
    this.wait = const Duration(seconds: 2),
  });

  final BaseCacheManager? Function() _cache;
  final CrashReporter _reporter;
  final Duration wait;

  void _report(Object error) => unawaited(
    _reporter.recordError(
      'Image cache not emptied: ${error.runtimeType}',
      null,
    ),
  );

  @override
  Future<void> onSignOut({required bool byUser}) async {
    try {
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
    } on Object catch (error) {
      _report(error);
    }
    final done = Completer<void>();
    // Guarded: the cache's folder is found asynchronously, and a failure
    // there can surface outside the awaited call.
    unawaited(
      runZonedGuarded(
        () async {
          try {
            await _cache()?.emptyCache().timeout(wait);
          } on Object catch (error) {
            _report(error);
          }
          if (!done.isCompleted) done.complete();
        },
        (error, stack) {
          _report(error);
          if (!done.isCompleted) done.complete();
        },
      ),
    );
    await done.future;
  }
}
