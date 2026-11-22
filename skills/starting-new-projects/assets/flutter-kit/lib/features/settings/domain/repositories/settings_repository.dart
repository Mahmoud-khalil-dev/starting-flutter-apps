import 'package:dartz/dartz.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';

/// What the Settings Cubit depends on. The data layer implements it.
abstract interface class SettingsRepository {
  Future<Either<Failure, AppSettings>> load();

  Future<Either<Failure, Unit>> save(AppSettings settings);
}
