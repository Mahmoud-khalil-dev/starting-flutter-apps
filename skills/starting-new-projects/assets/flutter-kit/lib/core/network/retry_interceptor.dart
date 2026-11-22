import 'dart:math';

import 'package:dio/dio.dart';
import 'package:kit_app/core/network/request_policy.dart';

typedef Fetch = Future<Response<dynamic>> Function(RequestOptions options);

/// Resends a request that failed for network reasons, as far as its
/// [RequestPolicy] allows: silent retries first, then at most one
/// Retry/Cancel prompt. A mutation (an order, a transfer, any write that is not
/// auth) is never resent, because it may have reached the server.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this._fetch,
    required this._askRetry,
    Future<void> Function(Duration delay)? wait,
    double Function()? jitter,
  }) : _wait = wait ?? _sleep,
       _jitter = jitter ?? Random().nextDouble;

  static const backoff = [Duration(seconds: 1), Duration(seconds: 3)];
  static const maxJitter = Duration(milliseconds: 300);
  static const attemptKey = 'retry_attempt';
  static const askedKey = 'retry_asked';
  static const Set<DioExceptionType> _networkErrors = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  /// Most often the server never saw the request, so a write may be sent
  /// again as far as its class allows. Not always: a socket reset after the
  /// request left arrives as a connection error, and on the web Dio's browser
  /// adapter reports every XHR error as one. So the table is what keeps a
  /// write from being sent twice: a mutation, a call control and a background
  /// write have no silent retry and no prompt. Tests pin it.
  static const Set<DioExceptionType> _beforeSending = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.connectionError,
  };

  /// A body that can be read once.
  static bool _isOneShot(Object? data) => data is FormData || data is Stream;

  final Fetch _fetch;
  final Future<bool> Function() _askRetry;
  final Future<void> Function(Duration delay) _wait;
  final double Function() _jitter;

  static Future<void> _sleep(Duration delay) => Future<void>.delayed(delay);

  Duration delayFor(int attempt) =>
      backoff[min(attempt, backoff.length - 1)] + maxJitter * _jitter();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (!_networkErrors.contains(err.type)) {
      handler.next(err);
      return;
    }
    // A write that timed out after it was sent may have reached the server;
    // resending it, or telling the user it failed, would be a lie.
    // An upload is the exception: it is built to be sent again.
    final policy = RequestPolicy.of(options);
    final isUpload = RequestPolicy.classify(options) == RequestClass.upload;
    if (options.method.toUpperCase() != 'GET' &&
        !isUpload &&
        !_beforeSending.contains(err.type)) {
      handler.next(err);
      return;
    }
    // Dio cannot send one FormData or one Stream twice, so without a factory
    // for a fresh body the request is never resent and the original error
    // stands.
    if (_isOneShot(options.data) &&
        options.extra[RequestPolicy.bodyFactoryKey] is! Object Function()) {
      handler.next(err);
      return;
    }
    final attempt = options.extra[attemptKey] as int? ?? 0;
    if (attempt < policy.silentRetries) {
      await _wait(delayFor(attempt));
      options.extra[attemptKey] = attempt + 1;
      await _resend(options, handler);
      return;
    }
    if (policy.askUser && options.extra[askedKey] != true) {
      options.extra[askedKey] = true;
      if (await _askRetry()) {
        await _resend(options, handler);
        return;
      }
    }
    handler.next(err);
  }

  /// A resend runs through every interceptor again, so a failing resend has
  /// already had its own retries and prompt when it lands here.
  Future<void> _resend(
    RequestOptions options,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final factory = options.extra[RequestPolicy.bodyFactoryKey];
      if (_isOneShot(options.data) && factory is Object Function()) {
        options.data = factory();
      }
      handler.resolve(await _fetch(options));
    } on DioException catch (error) {
      handler.next(error);
    }
  }
}
