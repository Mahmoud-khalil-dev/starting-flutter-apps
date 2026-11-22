import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements SettingsRepository {}

const _dark = AppSettings(
  themeMode: ThemeMode.dark,
  locale: null,
  textScale: 1,
);

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(AppSettings.defaults));
  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.save(any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  SettingsCubit build() => SettingsCubit(repository);

  test('KIT-T12: it starts with the defaults, not yet loaded', () {
    expect(build().state, const SettingsState());
    expect(build().state.settings, AppSettings.defaults);
    expect(build().state.loaded, isFalse);
  });

  blocTest<SettingsCubit, SettingsState>(
    'KIT-T12: load puts the saved settings in the state',
    setUp: () => when(
      () => repository.load(),
    ).thenAnswer((_) async => const Right(_dark)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const SettingsState(settings: _dark, loaded: true)],
  );

  blocTest<SettingsCubit, SettingsState>(
    'KIT-T12: a failed load keeps the defaults and carries the failure',
    setUp: () => when(
      () => repository.load(),
    ).thenAnswer((_) async => const Left(UnknownFailure())),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const SettingsState(loaded: true, failure: UnknownFailure()),
    ],
  );

  blocTest<SettingsCubit, SettingsState>(
    'KIT-T12: setThemeMode saves, then shows the new theme',
    build: build,
    act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
    expect: () => [const SettingsState(settings: _dark)],
    verify: (_) => verify(() => repository.save(_dark)).called(1),
  );

  blocTest<SettingsCubit, SettingsState>(
    'KIT-T12: setLocale saves the language and null returns to the device',
    build: build,
    act: (cubit) async {
      await cubit.setLocale(const Locale('ar'));
      await cubit.setLocale(null);
    },
    expect: () => [
      SettingsState(
        settings: AppSettings.defaults.copyWith(locale: const Locale('ar')),
      ),
      const SettingsState(),
    ],
  );

  blocTest<SettingsCubit, SettingsState>(
    'KIT-T12: setTextScale is clamped to 0.85 and 1.6',
    build: build,
    act: (cubit) async {
      await cubit.setTextScale(5);
      await cubit.setTextScale(0.1);
    },
    expect: () => [
      SettingsState(settings: AppSettings.defaults.copyWith(textScale: 1.6)),
      SettingsState(settings: AppSettings.defaults.copyWith(textScale: 0.85)),
    ],
  );

  blocTest<SettingsCubit, SettingsState>(
    'KIT-T12: a failed save keeps the old value and carries the failure',
    setUp: () => when(
      () => repository.save(any()),
    ).thenAnswer((_) async => const Left(UnknownFailure())),
    build: build,
    act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
    expect: () => [const SettingsState(failure: UnknownFailure())],
  );

  blocTest<SettingsCubit, SettingsState>(
    'KIT-T12: the failure is cleared when the screen has shown it',
    setUp: () => when(
      () => repository.save(any()),
    ).thenAnswer((_) async => const Left(UnknownFailure())),
    build: build,
    act: (cubit) async {
      await cubit.setThemeMode(ThemeMode.dark);
      cubit.failureShown();
    },
    expect: () => [
      const SettingsState(failure: UnknownFailure()),
      const SettingsState(),
    ],
  );

  blocTest<SettingsCubit, SettingsState>(
    'KIT-T12: a later save that works clears the failure',
    build: build,
    seed: () => const SettingsState(failure: UnknownFailure()),
    act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
    expect: () => [const SettingsState(settings: _dark)],
  );

  test('KIT-T12: a save that finishes after close does not emit', () async {
    final cubit = build();
    await cubit.close();
    await cubit.setThemeMode(ThemeMode.dark);
    expect(cubit.state.settings, AppSettings.defaults);
  });

  test('KIT-T12: a load that finishes after close does not emit', () async {
    final answer = Completer<Either<Failure, AppSettings>>();
    when(() => repository.load()).thenAnswer((_) => answer.future);
    final cubit = build();
    final loading = cubit.load();
    await cubit.close();
    answer.complete(const Right(_dark));
    await loading;
    expect(cubit.state, const SettingsState());
  });

  test('KIT-T12: overlapping saves of different fields both survive', () async {
    final first = Completer<Either<Failure, Unit>>();
    var calls = 0;
    when(() => repository.save(any())).thenAnswer(
      (_) => ++calls == 1 ? first.future : Future.value(const Right(unit)),
    );
    final cubit = build();
    final theme = cubit.setThemeMode(ThemeMode.dark);
    final size = cubit.setTextScale(1.3);
    first.complete(const Right(unit));
    await Future.wait([theme, size]);
    const both = AppSettings(
      themeMode: ThemeMode.dark,
      locale: null,
      textScale: 1.3,
    );
    expect(cubit.state.settings, both);
    verify(() => repository.save(both)).called(1);
    await cubit.close();
  });
}
