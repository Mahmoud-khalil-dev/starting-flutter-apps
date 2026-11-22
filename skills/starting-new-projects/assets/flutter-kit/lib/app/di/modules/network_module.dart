import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_app/app/di/retry_prompt.dart';
import 'package:kit_app/core/config/env.dart';
import 'package:kit_app/core/l10n/app_language.dart';
import 'package:kit_app/core/logging/app_log.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/api_reachability.dart';
import 'package:kit_app/core/network/auth_interceptor.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:kit_app/core/network/dio_client.dart';
import 'package:kit_app/core/network/network_health_interceptor.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/core/network/retry_interceptor.dart';
import 'package:kit_app/core/network/status_interceptor.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/features/settings/data/sources/settings_local_source.dart';

/// The API client's interceptors run in this order: policy (timeouts),
/// auth (headers, 401), health (feeds ConnectivityService), retry, status
/// (reports a failed write once). Dio's own content-type interceptor runs
/// first and the debug log last (createDio).
///
/// [askRetry] asks the user whether to try a timed-out request again. By
/// default it shows the kit's dialog on the router's navigator
/// (`askRetryWithDialog`); pass a function to ask another way.
void registerNetworkModule(GetIt sl, {Future<bool> Function()? askRetry}) {
  sl
    ..registerLazySingleton<ConnectivityService>(() {
      final probeDio = createProbeDio();
      return ConnectivityService(
        changes: Connectivity().onConnectivityChanged,
        probe: () => apiReachable(probeDio, Env.baseUrl),
      );
    })
    ..registerLazySingleton<ApiMessages>(ApiMessages.new)
    ..registerLazySingleton<Dio>(() {
      late final Dio dio;
      return dio = createDio(
        baseUrl: Env.baseUrl,
        interceptors: [
          PolicyInterceptor(),
          AuthInterceptor(
            readToken: () => sl<SessionRepository>().token,
            // The language chosen in Settings, checked the way Settings
            // checks it, else the device's.
            readLanguage: () => appLanguage(
              chosen: sl<SettingsLocalSource>().read().locale?.languageCode,
              device: systemLanguage(),
            ),
            signInPaths: ApiEndpoints.signInPaths,
            onSessionExpired: () =>
                unawaited(expireSession(sl<SessionCubit>())),
          ),
          NetworkHealthInterceptor(sl<ConnectivityService>().recordRequest),
          RetryInterceptor(
            fetch: (o) => dio.fetch<dynamic>(o),
            askRetry:
                askRetry ??
                () => askRetryWithDialog(sl<GlobalKey<NavigatorState>>()),
          ),
          StatusInterceptor(sl<ApiMessages>().report),
        ],
      );
    })
    ..registerLazySingleton<ConnectivityLifecycle>(ConnectivityLifecycle.new);
}

/// The device language, as `appLanguage` resolves it.
String systemLanguage() => appLanguage(
  chosen: null,
  device: WidgetsBinding.instance.platformDispatcher.locale.languageCode,
);

/// Holds the listener that pauses ConnectivityService in the background and
/// resumes it in the foreground, for as long as the app runs.
class ConnectivityLifecycle {
  AppLifecycleListener? listener;
}

/// Ends the session for a 401. [SessionCubit.expire] has already deleted the
/// token when it rethrows a bound's reset error, so the error is logged here
/// and never escapes the interceptor as an uncaught zone error.
Future<void> expireSession(SessionCubit session) async {
  try {
    await session.expire();
  } on Object catch (error) {
    AppLog.error('Session end: a session-bound reset failed', error);
  }
}
