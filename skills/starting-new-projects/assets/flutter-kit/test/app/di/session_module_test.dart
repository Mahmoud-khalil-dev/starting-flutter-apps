import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_app/app/di/modules/session_module.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecure extends Mock implements SecureStorage {}

class _MockPreferences extends Mock implements AppPreferences {}

class _MockDio extends Mock implements Dio {}

class _MockSignOut extends Mock implements SignOutService {}

void main() {
  testWidgets(
    'KIT-T10: the injector wires the real foreground check into the session',
    (tester) async {
      final secure = _MockSecure();
      final preferences = _MockPreferences();
      when(secure.readToken).thenAnswer((_) async => null);
      when(() => preferences.userJson).thenReturn(null);
      final locator = GetIt.asNewInstance()
        ..registerSingleton<SecureStorage>(secure)
        ..registerSingleton<AppPreferences>(preferences)
        ..registerSingleton<Dio>(_MockDio());
      addTearDown(locator.reset);
      registerSessionModule(locator);
      final repository = locator<SessionRepository>();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect((await repository.restore()).tokenUnreadable, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect((await repository.restore()).tokenUnreadable, isFalse);
    },
  );

  test('KIT-T10: resetting the locator closes the session cubit', () async {
    final secure = _MockSecure();
    final preferences = _MockPreferences();
    when(secure.readToken).thenAnswer((_) async => null);
    when(() => preferences.userJson).thenReturn(null);
    final locator = GetIt.asNewInstance()
      ..allowReassignment = true
      ..registerSingleton<SecureStorage>(secure)
      ..registerSingleton<AppPreferences>(preferences)
      ..registerSingleton<Dio>(_MockDio());
    registerSessionModule(locator);
    locator.registerSingleton<SignOutService>(_MockSignOut());
    final cubit = locator<SessionCubit>();

    await locator.reset();

    expect(cubit.isClosed, isTrue);
  });
}
