import 'package:dio/dio.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:kit_app/core/network/retry_interceptor.dart';

/// Feeds every request outcome to ConnectivityService.recordRequest, so two
/// timeouts out of five requests show as an unstable connection.
class NetworkHealthInterceptor extends Interceptor {
  NetworkHealthInterceptor(this._record);

  final void Function({required RequestOutcome outcome}) _record;

  static const Set<DioExceptionType> _timeouts = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
  };

  /// A resend is part of the same logical request, so only the first
  /// attempt is recorded: one slow request is one timeout, not three.
  static bool _isResend(RequestOptions options) =>
      (options.extra[RetryInterceptor.attemptKey] as int? ?? 0) > 0 ||
      options.extra[RetryInterceptor.askedKey] == true;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!_isResend(response.requestOptions)) {
      _record(outcome: RequestOutcome.ok);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.cancel || _isResend(err.requestOptions)) {
      return handler.next(err);
    }
    _record(
      outcome: switch (err.type) {
        DioExceptionType.badResponse => RequestOutcome.ok,
        _ when _timeouts.contains(err.type) => RequestOutcome.timedOut,
        _ => RequestOutcome.failed,
      },
    );
    handler.next(err);
  }
}
