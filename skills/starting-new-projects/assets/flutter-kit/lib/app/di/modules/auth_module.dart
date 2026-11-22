import 'package:get_it/get_it.dart';
import 'package:kit_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kit_app/features/auth/data/sources/auth_remote_source.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/cubit/resend_code_cubit.dart';

/// The auth feature. The Cubits are factories: each screen gets its own.
void registerAuthModule(GetIt sl) {
  sl
    ..registerLazySingleton<AuthRemoteSource>(() => AuthRemoteSource(sl()))
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl()),
    )
    ..registerFactory<AuthCubit>(() => AuthCubit(sl()))
    ..registerFactory<ResendCodeCubit>(() => ResendCodeCubit(sl()));
}
