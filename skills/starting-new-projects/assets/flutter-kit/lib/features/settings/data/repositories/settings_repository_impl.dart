import 'package:dartz/dartz.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/data/sources/settings_local_source.dart';
import 'package:kit_app/features/settings/domain/repositories/settings_repository.dart';

/// The settings on the device. A read or write that throws is a failure
/// the Cubit can show, never an exception that escapes.
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._source);

  final SettingsLocalSource _source;

  @override
  Future<Either<Failure, AppSettings>> load() async {
    try {
      return Right(_source.read());
    } on Object catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> save(AppSettings settings) async {
    try {
      await _source.write(settings);
      return const Right(unit);
    } on Object catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
