import 'dart:async';

import 'package:dio/dio.dart';
import 'package:kit_app/core/error/error_handler.dart';
import 'package:kit_app/core/error/failures.dart';

/// Reports a failed write once its retries are spent, so one place can show
/// it (`ApiMessagesListener` shows [ApiMessages] as a snackbar). A failed GET
/// stays quiet: its screen shows its own error state. A 401 is the session's
/// business. A request opts out with
/// `extra: {StatusInterceptor.quietKey: true}`.
/// A request is reported at most once: a resend reuses its options, so
/// [reportedKey] stops a resend that fails again from reporting twice.
class StatusInterceptor extends Interceptor {
  StatusInterceptor(this._onFailure);

  static const quietKey = 'quiet';
  static const reportedKey = 'statusReported';

  final void Function(Failure failure) _onFailure;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final failure = mapDioError(err);
    final quiet =
        options.method.toUpperCase() == 'GET' ||
        options.extra[quietKey] == true ||
        options.extra[reportedKey] == true ||
        failure is Cancelled ||
        failure is Unauthorized;
    if (!quiet) {
      options.extra[reportedKey] = true;
      _onFailure(failure);
    }
    handler.next(err);
  }
}

/// Failed writes for whoever shows them. Broadcast: no listener is fine.
class ApiMessages {
  final _failures = StreamController<Failure>.broadcast();

  Stream<Failure> get failures => _failures.stream;

  void report(Failure failure) => _failures.add(failure);

  Future<void> close() => _failures.close();
}
