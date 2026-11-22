import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kit_app/core/logging/app_log.dart';

/// The API client. Pass the interceptors in this order: policy, auth,
/// health, retry, status (lib/app/di/modules/network_module.dart). Debug
/// builds log method, URL and status only: never headers, never bodies.
Dio createDio({
  required String baseUrl,
  required List<Interceptor> interceptors,
  HttpClientAdapter? adapter,
  bool logRequests = kDebugMode,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.interceptors.addAll(interceptors);
  if (logRequests) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        // Through AppLog: the URI's query and `extra` are redacted, and a
        // release build prints nothing.
        logPrint: (line) => AppLog.debug('$line'),
      ),
    );
  }
  return dio;
}
