import 'package:get_it/get_it.dart';
import 'package:kit_app/core/session/session_bound.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_remote_source.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/sign_out_service.dart';

void registerSessionModule(GetIt sl) {
  sl
    ..registerLazySingleton<SessionRemoteSource>(
      () => SessionRemoteSource(sl()),
    )
    ..registerLazySingleton<SessionRepository>(
      () => SessionRepository(
        sl(),
        sl(),
        sl(),
        isForeground: SessionRepository.appIsResumed,
      ),
    )
    ..registerLazySingleton<SessionBoundRegistry>(SessionBoundRegistry.new)
    ..registerLazySingleton<SignOutService>(
      () => SignOutService(
        session: sl(),
        remote: sl(),
        preferences: sl(),
        bound: sl(),
        hooks: () => sl<List<SignOutHook>>(),
      ),
    )
    // Closed on a locator reset, so a failed boot attempt leaves no live
    // listener behind.
    ..registerLazySingleton<SessionCubit>(
      () => SessionCubit(sl(), sl()),
      dispose: (cubit) => cubit.close(),
    );
}
