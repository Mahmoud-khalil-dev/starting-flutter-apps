import 'package:dio/dio.dart';
import 'package:kit_app/core/network/api_endpoints.dart';

/// How a request is treated on a slow or failed network.
enum RequestClass { read, auth, mutation, upload, callControl, background }

class RequestPolicy {
  const RequestPolicy({
    required this.connect,
    required this.receive,
    required this.send,
    this.silentRetries = 0,
    this.askUser = false,
  });

  final Duration connect;
  final Duration receive;
  final Duration send;

  /// Resends without asking, after 1 s then 3 s, each with jitter.
  final int silentRetries;

  /// Offer the Retry/Cancel prompt once the silent retries are spent.
  final bool askUser;

  static const extraKey = 'request_class';

  /// An `extra` value of type `FormData Function()` or `Stream Function()`.
  /// Dio cannot send one `FormData` or one `Stream` twice, so a request with
  /// such a body names how to build a fresh one; without it the body is never
  /// resent. The upload class is for idempotent writes only (a presigned PUT,
  /// a profile photo): it is the one class a send or receive timeout may
  /// resend.
  static const bodyFactoryKey = 'body_factory';

  static const _s10 = Duration(seconds: 10);
  static const _s15 = Duration(seconds: 15);
  static const _s30 = Duration(seconds: 30);
  static const _s45 = Duration(seconds: 45);
  static const _s60 = Duration(seconds: 60);

  /// Only a read and an upload resend silently; only a read and auth ask
  /// the user. A write that may have reached the server (a mutation, a call
  /// control, a background write) is never sent again: change this table
  /// only with its tests (`request_policy_test.dart`).
  static const byClass = <RequestClass, RequestPolicy>{
    RequestClass.read: RequestPolicy(
      connect: _s15,
      receive: _s30,
      send: _s30,
      silentRetries: 2,
      askUser: true,
    ),
    RequestClass.auth: RequestPolicy(
      connect: _s15,
      receive: _s30,
      send: _s30,
      askUser: true,
    ),
    RequestClass.mutation: RequestPolicy(
      connect: _s15,
      receive: _s45,
      send: _s30,
    ),
    RequestClass.upload: RequestPolicy(
      connect: _s15,
      receive: _s60,
      send: _s60,
      silentRetries: 1,
    ),
    RequestClass.callControl: RequestPolicy(
      connect: _s10,
      receive: _s15,
      send: _s15,
    ),
    RequestClass.background: RequestPolicy(
      connect: _s15,
      receive: _s30,
      send: _s30,
    ),
  };

  static RequestPolicy of(RequestOptions options) =>
      byClass[classify(options)]!;

  /// A class named in `extra` wins. Otherwise a path in
  /// `ApiEndpoints.signInPaths` (the list `AuthInterceptor` gets) is auth,
  /// whatever its method (a `GET` that sends a one-time code must never be
  /// resent silently), a GET is a read, and anything else is a mutation,
  /// which is never resent.
  static RequestClass classify(RequestOptions options) {
    final named = options.extra[extraKey];
    if (named is RequestClass) return named;
    if (ApiEndpoints.signInPaths.contains(apiPath(options))) {
      return RequestClass.auth;
    }
    if (options.method.toUpperCase() == 'GET') return RequestClass.read;
    return RequestClass.mutation;
  }

  /// Options for a source that names its class.
  static Options as(RequestClass requestClass) =>
      Options(extra: {extraKey: requestClass});
}

/// The API path of a request, as `ApiEndpoints` writes it: the request URI's
/// path with the base URL's path prefix (such as `/api/v1`) removed. The
/// host and the query string are ignored, so `/account/login?x=1` and
/// `<BASE_URL>/account/login` both give `/account/login`. Every rule that matches
/// on a path uses this, so the rules cannot drift apart.
String apiPath(RequestOptions options) {
  final path = options.uri.path;
  var prefix = Uri.parse(options.baseUrl).path;
  if (prefix.endsWith('/')) prefix = prefix.substring(0, prefix.length - 1);
  if (prefix.isNotEmpty && path.startsWith('$prefix/')) {
    return path.substring(prefix.length);
  }
  return path;
}

/// Applies the class timeouts to every request.
class PolicyInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final policy = RequestPolicy.of(options);
    options
      ..connectTimeout = policy.connect
      ..receiveTimeout = policy.receive
      ..sendTimeout = policy.send;
    handler.next(options);
  }
}
