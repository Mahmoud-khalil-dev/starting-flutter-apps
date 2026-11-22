import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:kit_app/features/settings/data/sources/settings_local_source.dart';
import 'package:kit_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockSource extends Mock implements SettingsLocalSource {}

const _dark = AppSettings(
  themeMode: ThemeMode.dark,
  locale: Locale('ar'),
  textScale: 1.2,
);

void main() {
  late _MockSource source;
  late SettingsRepository repository;

  setUpAll(() => registerFallbackValue(AppSettings.defaults));
  setUp(() {
    source = _MockSource();
    repository = SettingsRepositoryImpl(source);
  });

  test('KIT-T12: load returns what the source read', () async {
    when(() => source.read()).thenReturn(_dark);
    expect(await repository.load(), const Right<Failure, AppSettings>(_dark));
  });

  test(
    'KIT-T12: load fails with UnknownFailure when the read throws',
    () async {
      when(() => source.read()).thenThrow(StateError('unreadable'));
      expect(
        await repository.load(),
        const Left<Failure, AppSettings>(UnknownFailure()),
      );
    },
  );

  test('KIT-T12: save writes through the source and returns unit', () async {
    when(() => source.write(any())).thenAnswer((_) async {});
    expect(await repository.save(_dark), const Right<Failure, Unit>(unit));
    verify(() => source.write(_dark)).called(1);
  });

  test(
    'KIT-T12: save fails with UnknownFailure when the write throws',
    () async {
      when(() => source.write(any())).thenThrow(StateError('disk full'));
      expect(
        await repository.save(_dark),
        const Left<Failure, Unit>(UnknownFailure()),
      );
    },
  );
}
