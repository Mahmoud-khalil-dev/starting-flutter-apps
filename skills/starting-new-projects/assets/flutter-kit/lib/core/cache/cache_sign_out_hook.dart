import 'package:kit_app/core/cache/cache_layer.dart';
import 'package:kit_app/core/session/sign_out_service.dart';

/// Clears the cache when a session ends: the next account never sees the
/// last one's data.
class CacheSignOutHook implements SignOutHook {
  const CacheSignOutHook(this._cache);

  final CacheLayer _cache;

  @override
  Future<void> onSignOut({required bool byUser}) => _cache.clear();
}
