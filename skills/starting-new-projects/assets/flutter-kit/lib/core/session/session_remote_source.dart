import 'package:dio/dio.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/core/network/status_interceptor.dart';

/// The two calls the session itself makes.
class SessionRemoteSource {
  const SessionRemoteSource(this._dio);

  final Dio _dio;

  Future<Object?> fetchProfile() async =>
      (await _dio.get<Object?>(ApiEndpoints.profile)).data;

  /// Carries [token] itself: the wipe may already have cleared the session
  /// when the interceptor runs.
  Future<void> logout(String token) => _dio.post<void>(
    ApiEndpoints.logout,
    options: Options(
      headers: {'Authorization': 'Bearer $token'},
      extra: {
        RequestPolicy.extraKey: RequestClass.background,
        StatusInterceptor.quietKey: true,
      },
    ),
  );
}
