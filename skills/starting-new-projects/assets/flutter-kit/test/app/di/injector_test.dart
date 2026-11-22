import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/app/boot/boot_retry.dart';
import 'package:kit_app/app/di/injector.dart';
import 'package:kit_app/app/di/modules/network_module.dart';
import 'package:kit_app/app/router/route_guard.dart';
import 'package:kit_app/core/cache/cache_layer.dart';
import 'package:kit_app/core/cache/cache_sign_out_hook.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/di/service_locator.dart';
import 'package:kit_app/core/media/avatar_uploader.dart';
import 'package:kit_app/core/media/image_crop_slot.dart';
import 'package:kit_app/core/media/media_sign_out_hook.dart';
import 'package:kit_app/core/media/picked_image.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/auth_interceptor.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:kit_app/core/network/network_health_interceptor.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/core/network/retry_interceptor.dart';
import 'package:kit_app/core/network/status_interceptor.dart';
import 'package:kit_app/core/notifications/local_notifications.dart';
import 'package:kit_app/core/notifications/notifications_sign_out_hook.dart';
import 'package:kit_app/core/notifications/push_service.dart';
import 'package:kit_app/core/permissions/permissions.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/router/pending_deep_link.dart';
import 'package:kit_app/core/router/pending_deep_link_hook.dart';
import 'package:kit_app/core/session/session_bound.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/secure_storage.dart';
import 'package:kit_app/core/telemetry/analytics_sink.dart';
import 'package:kit_app/core/theme/app_theme.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/time/app_clock.dart';
import 'package:kit_app/core/utils/responsive.dart';
import 'package:kit_app/features/auth/data/repositories/auth_sign_out_hook.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:kit_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:kit_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/stub_adapter.dart';

class _Analytics extends Mock implements AnalyticsSink {}

class _FailingBound implements SessionBound {
  @override
  void reset() => throw StateError('reset failed');
}

Future<GetIt> _graph({
  Map<String, String> secure = const {},
  Map<String, Object> prefs = const {},
  void Function(GetIt locator)? before,
}) async {
  SharedPreferences.setMockInitialValues(Map.of(prefs));
  FlutterSecureStorage.setMockInitialValues(Map.of(secure));
  final locator = GetIt.asNewInstance();
  addTearDown(locator.reset);
  before?.call(locator);
  await initDependencies(locator: locator);
  return locator;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KIT-T10: the graph resolves to the concrete types', () async {
    final locator = await _graph();
    expect(locator<PlatformCapabilities>(), isA<PlatformCapabilities>());
    expect(locator<AppClock>(), isA<SystemClock>());
    expect(locator<AppPreferences>(), isA<AppPreferences>());
    expect(locator<SecureStorage>(), isA<SecureStorage>());
    expect(locator<ConnectivityService>(), isA<ConnectivityService>());
    expect(locator<ApiMessages>(), isA<ApiMessages>());
    expect(locator<SessionRepository>(), isA<SessionRepository>());
    expect(locator<SessionBoundRegistry>(), isA<SessionBoundRegistry>());
    expect(locator<SessionCubit>(), isA<SessionCubit>());
    expect(locator<SessionCubit>(), same(locator<SessionCubit>()));
    expect(locator<PendingDeepLink>(), isA<PendingDeepLink>());
    expect(locator<RouteGuard>(), isA<RouteGuard>());
    expect(locator<Dio>(), isA<Dio>());
    expect(locator<ConnectivityLifecycle>(), isA<ConnectivityLifecycle>());
  });

  test('KIT-T10: the telemetry defaults are in the graph', () async {
    final locator = await _graph();
    expect(locator<CrashReporter>(), isA<NoopCrashReporter>());
    expect(locator<AnalyticsSink>(), isA<NoopAnalyticsSink>());
  });

  test('KIT-T10: a sink the project registered first is kept', () async {
    final mine = _Analytics();
    final locator = await _graph(
      before: (l) => l.registerSingleton<AnalyticsSink>(mine),
    );
    expect(locator<AnalyticsSink>(), same(mine));
  });

  test(
    'KIT-T10: a project reporter survives the first boot and a retry',
    () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final locator = GetIt.asNewInstance();
      addTearDown(locator.reset);
      const mine = DebugCrashReporter();
      locator.registerSingleton<CrashReporter>(mine);
      final step = freshDependencies(
        reset: () => resetLocator(locator: locator),
        init: () => initDependencies(locator: locator),
      );
      await step();
      expect(locator<CrashReporter>(), same(mine));
      await step();
      expect(locator<CrashReporter>(), same(mine));
    },
  );

  test('KIT-T10: a project sink survives the first boot and a retry', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final locator = GetIt.asNewInstance();
    addTearDown(locator.reset);
    final mine = _Analytics();
    locator.registerSingleton<AnalyticsSink>(mine);
    final step = freshDependencies(
      reset: () => resetLocator(locator: locator),
      init: () => initDependencies(locator: locator),
    );
    await step();
    expect(locator<AnalyticsSink>(), same(mine));
    await step();
    expect(locator<AnalyticsSink>(), same(mine));
  });

  test('KIT-T10: the sign-out service and its hooks resolve', () async {
    final locator = await _graph();
    expect(locator<SignOutService>(), same(locator<SignOutService>()));
    final hooks = locator<List<SignOutHook>>();
    expect(hooks, hasLength(6));
    expect(hooks[0], isA<AnalyticsSignOutHook>());
    expect(hooks[1], isA<NotificationsSignOutHook>());
    expect(hooks[2], isA<PendingDeepLinkHook>());
    expect(hooks[3], isA<CacheSignOutHook>());
    expect(hooks[4], isA<MediaSignOutHook>());
    expect(hooks[5], isA<AuthSignOutHook>());
  });

  test(
    'KIT-T18: the kit crops nothing until a project adds a cropper',
    () async {
      final locator = await _graph();
      expect(locator<ImageCropSlot>(), isA<NoCrop>());
    },
  );

  test('KIT-T18: sign-out cancels an avatar upload in flight', () async {
    final locator = await _graph();
    final uploader = locator<DioAvatarUploader>();
    expect(locator<AvatarUploader>(), same(uploader));
    final token = CancelToken();
    final run = uploader.upload(
      PickedImage(bytes: Uint8List(1), name: 'a.png', mimeType: 'image/png'),
      onProgress: (_) {},
      cancelToken: token,
    );
    locator<SessionBoundRegistry>().resetAll();
    expect(token.isCancelled, isTrue);
    expect((await run).isLeft(), isTrue);
  });

  test(
    'KIT-T17: the held link is cleared after the notifications are',
    () async {
      final locator = await _graph();
      final hooks = locator<List<SignOutHook>>();
      expect(
        hooks.indexWhere((h) => h is PendingDeepLinkHook),
        greaterThan(hooks.indexWhere((h) => h is NotificationsSignOutHook)),
      );
    },
  );

  test('KIT-T17: the kit ships no push vendor', () async {
    final locator = await _graph();
    expect(locator<PushService>(), isA<NoopPushService>());
    expect(locator<Permissions>(), same(locator<Permissions>()));
    // Tests run on a platform with no notification plugin behind it.
    expect(locator<LocalNotifications>(), isNotNull);
  });

  test('KIT-T14: one cache layer is in the graph', () async {
    final locator = await _graph();
    expect(locator<CacheLayer>(), same(locator<CacheLayer>()));
  });

  test('KIT-T10: the graph builds the app router', () async {
    final locator = await _graph();
    expect(locator<GoRouter>(), isNotNull);
  });

  test('KIT-T10: the API Dio runs its interceptors in this order', () async {
    final locator = await _graph();
    final types = locator<Dio>().interceptors.map((i) => '${i.runtimeType}');
    expect(types.toList(), [
      // Dio's own, always first; not exported, so named as text.
      'ImplyContentTypeInterceptor',
      '$PolicyInterceptor',
      '$AuthInterceptor',
      '$NetworkHealthInterceptor',
      '$RetryInterceptor',
      '$StatusInterceptor',
      // Debug builds only (createDio): tests run in debug.
      if (kDebugMode) '$LogInterceptor',
    ]);
  });

  test('KIT-T10: a 401 on a sign-in path keeps the session', () async {
    final locator = await _graph(secure: {'token': 'session-token'});
    await locator<SessionCubit>().restore();
    final dio = locator<Dio>()
      ..httpClientAdapter = StubAdapter(
        (_) async => jsonBody({'message': 'wrong'}, status: 401),
      );
    final path = ApiEndpoints.signInPaths.first;
    try {
      await dio.get<void>(path);
    } on DioException catch (e) {
      expect(e.response?.statusCode, 401);
    }
    await pumpEventQueue();
    expect(locator<SessionCubit>().state.status, SessionStatus.authenticated);
  });

  test('KIT-T10: a 401 ends the session; a bound reset error is logged, '
      'never uncaught', () async {
    final locator = await _graph(secure: {'token': 'session-token'});
    await locator<SessionCubit>().restore();
    expect(locator<SessionCubit>().state.status, SessionStatus.authenticated);
    locator<SessionBoundRegistry>().add(_FailingBound.new);
    final dio = locator<Dio>()
      ..httpClientAdapter = StubAdapter(
        (_) async => jsonBody({'message': 'expired'}, status: 401),
      );

    final logs = <String>[];
    final uncaught = <Object>[];
    final originalPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add('$message');
    addTearDown(() => debugPrint = originalPrint);

    // The sign-out run is on its own clock (hooks): wait on its completion
    // signal, not on a timer.
    final wiped = locator<SignOutService>().wiped.first;
    await runZonedGuarded(() async {
      try {
        await dio.get<void>(ApiEndpoints.profile);
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
      }
      await wiped;
      await pumpEventQueue();
    }, (error, _) => uncaught.add(error));

    expect(uncaught, isEmpty);
    expect(logs.where((l) => l.contains('reset failed')), hasLength(1));
    expect(locator<SessionCubit>().state.status, SessionStatus.unauthenticated);
    expect(await locator<SecureStorage>().readToken(), isNull);
  });

  test(
    'KIT-T11: the router runs on the navigator key the graph holds',
    () async {
      final locator = await _graph();
      expect(
        locator<GoRouter>().routerDelegate.navigatorKey,
        same(locator<GlobalKey<NavigatorState>>()),
      );
    },
  );

  testWidgets(
    'KIT-T11: with no askRetry given, a timed-out read asks in a dialog',
    (tester) async {
      final locator = (await tester.runAsync(_graph))!;
      final dio = locator<Dio>();
      var calls = 0;
      dio.httpClientAdapter = StubAdapter(
        (o) => ++calls <= 3
            ? failWith(DioExceptionType.receiveTimeout)(o)
            : Future.value(jsonBody({'ok': true})),
      );
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: locator<GlobalKey<NavigatorState>>(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.build(
            brightness: Brightness.light,
            language: 'en',
            scale: ResponsiveScale.forWidth(390),
          ),
          home: const SizedBox(),
        ),
      );

      final reply = dio.get<Object?>('/items');
      // Two silent retries, after 1 s and 3 s, then the prompt.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(Motion.slow);
      expect(find.text('The connection is slow'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump(Motion.slow);
      expect((await reply).statusCode, 200);
      expect(calls, 4);
    },
  );

  test(
    'KIT-T12: the settings cubit is one app-wide instance on the contract',
    () async {
      final locator = await _graph();
      expect(locator<SettingsRepository>(), isA<SettingsRepositoryImpl>());
      expect(locator<SettingsCubit>(), same(locator<SettingsCubit>()));
      await locator<SettingsCubit>().load();
      expect(locator<SettingsCubit>().state.settings, AppSettings.defaults);
    },
  );

  test('KIT-T12: a chosen language is the one the API is asked in', () async {
    final locator = await _graph(prefs: {'settings.locale': 'ar'});
    final adapter = StubAdapter((_) async => jsonBody({'ok': true}));
    locator<Dio>().httpClientAdapter = adapter;
    await locator<Dio>().get<Object?>('/items');
    expect(adapter.requests.single.headers['Accept-Language'], 'ar');
  });

  test(
    'KIT-T12: a stored language the app lacks falls back to the device',
    () async {
      final locator = await _graph(prefs: {'settings.locale': 'fr'});
      final adapter = StubAdapter((_) async => jsonBody({'ok': true}));
      locator<Dio>().httpClientAdapter = adapter;
      await locator<Dio>().get<Object?>('/items');
      expect(adapter.requests.single.headers['Accept-Language'], 'en');
    },
  );

  test('KIT-T12: settings survive a sign-out', () async {
    final locator = await _graph(
      prefs: {'settings.themeMode': 'dark', 'user': '{}'},
    );
    await locator<SignOutService>().run(byUser: false);
    final prefs = locator<AppPreferences>();
    expect(prefs.readString('settings.themeMode'), 'dark');
    expect(prefs.userJson, isNull);
  });
}
