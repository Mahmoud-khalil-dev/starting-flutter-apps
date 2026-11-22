import 'package:dartz/dartz.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

/// A loaded [SettingsCubit] on an in-test repository that holds [initial]
/// and answers every save with [saveResult]. Close it with the test.
Future<(SettingsCubit, MockSettingsRepository)> loadedSettings({
  AppSettings initial = AppSettings.defaults,
  Either<Failure, Unit> saveResult = const Right(unit),
}) async {
  registerFallbackValue(AppSettings.defaults);
  final repository = MockSettingsRepository();
  when(repository.load).thenAnswer((_) async => Right(initial));
  when(() => repository.save(any())).thenAnswer((_) async => saveResult);
  final cubit = SettingsCubit(repository);
  await cubit.load();
  return (cubit, repository);
}
