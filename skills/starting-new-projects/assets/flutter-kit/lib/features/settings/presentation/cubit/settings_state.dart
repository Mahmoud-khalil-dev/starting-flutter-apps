import 'package:equatable/equatable.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';

/// The settings in force, whether the saved ones have been read yet, and
/// the failure of the last read or save until the screen has shown it.
class SettingsState extends Equatable {
  const SettingsState({
    this.settings = AppSettings.defaults,
    this.loaded = false,
    this.failure,
  });

  final AppSettings settings;
  final bool loaded;
  final Failure? failure;

  SettingsState copyWith({
    AppSettings? settings,
    bool? loaded,
    Failure? failure,
    bool clearFailure = false,
  }) => SettingsState(
    settings: settings ?? this.settings,
    loaded: loaded ?? this.loaded,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [settings, loaded, failure];
}
