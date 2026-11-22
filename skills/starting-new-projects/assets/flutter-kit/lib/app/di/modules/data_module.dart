import 'package:get_it/get_it.dart';
import 'package:kit_app/core/cache/cache_layer.dart';
import 'package:kit_app/core/cache/cache_store.dart';
import 'package:kit_app/core/session/session_repository.dart';

/// The data services every feature shares: the cache. Registered after the
/// session, whose generation drops answers from an ended session.
void registerDataModule(GetIt sl) {
  sl.registerLazySingleton<CacheLayer>(
    () => CacheLayer(
      memory: MemoryCacheStore(),
      disk: PreferencesCacheStore(sl()),
      clock: sl(),
      sessionGeneration: () => sl<SessionRepository>().generation,
    ),
  );
}
