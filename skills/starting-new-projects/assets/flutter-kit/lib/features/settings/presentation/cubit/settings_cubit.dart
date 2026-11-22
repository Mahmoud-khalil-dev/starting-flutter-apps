import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_state.dart';

/// The user's theme, language and text size. It lives for the whole app and
/// is not session-bound: these are device choices, kept across sign-outs.
///
/// A choice is saved first and shown after, so the screen never shows a
/// value the device did not keep. A failed save leaves the old value in
/// place and puts the failure in the state.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;
  Future<void>? _queue;

  Future<void> load() async {
    final result = await _repository.load();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => state.copyWith(loaded: true, failure: failure),
        (settings) => state.copyWith(
          settings: settings,
          loaded: true,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _save((current) => current.copyWith(themeMode: mode));

  /// A null [locale] follows the device language.
  Future<void> setLocale(Locale? locale) => _save(
    (current) => locale == null
        ? current.copyWith(clearLocale: true)
        : current.copyWith(locale: locale),
  );

  Future<void> setTextScale(double scale) => _save(
    (current) => current.copyWith(textScale: AppSettings.clampScale(scale)),
  );

  /// The screen has shown the failure.
  void failureShown() => emit(state.copyWith(clearFailure: true));

  /// Saves run one after another, each building on the settings the last
  /// one left, so two choices made close together both survive.
  Future<void> _save(AppSettings Function(AppSettings current) change) {
    final previous = _queue;
    final run = previous == null
        ? _apply(change)
        : previous.then((_) => _apply(change));
    _queue = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> _apply(AppSettings Function(AppSettings current) change) async {
    final next = change(state.settings);
    final result = await _repository.save(next);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => state.copyWith(failure: failure),
        (_) => state.copyWith(settings: next, clearFailure: true),
      ),
    );
  }
}
