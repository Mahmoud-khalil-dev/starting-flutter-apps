import 'package:get_it/get_it.dart';
import 'package:kit_app/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:kit_app/features/settings/data/sources/settings_local_source.dart';
import 'package:kit_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_cubit.dart';

/// The settings feature. Its Cubit is one app-wide instance: `App` reads
/// the theme, language and text size from it. It is not session-bound,
/// because these are device choices that outlive a sign-out. The module
/// registers the contract, never the implementation's own type.
void registerSettingsModule(GetIt sl) {
  sl
    ..registerLazySingleton<SettingsLocalSource>(
      () => SettingsLocalSource(sl()),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(sl()),
    )
    ..registerLazySingleton<SettingsCubit>(
      () => SettingsCubit(sl()),
      dispose: (cubit) => cubit.close(),
    );
}
