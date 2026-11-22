import 'package:dio/dio.dart';
import 'package:kit_app/core/network/request_policy.dart';

/// Adds Accept-Language and the bearer token to every request, and ends the
/// session on a 401 (the API has no refresh token). On a sign-in path a
/// 401 means wrong credentials, so it does not end anything. Each token ends
/// the session at most once, however many requests fail with it.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._readToken,
    required this._readLanguage,
    required this._onSessionExpired,
    required this._signInPaths,
  });

  /// Set in `extra` when this interceptor attached the bearer.
  static const attachedKey = 'auth_attached';

  /// Paths where a 401 means wrong credentials, as `ApiEndpoints` writes
  /// them. Pass `ApiEndpoints.signInPaths`, holding the sign-in, sign-up,
  /// one-time-code and password-reset paths of your API. Required: a path
  /// left out signs the user out on a wrong password.
  final Set<String> _signInPaths;

  final String? Function() _readToken;
  final String Function() _readLanguage;
  final void Function() _onSessionExpired;
  String? _expiredToken;

  /// The bearer goes only to the API host: an absolute URL on another host
  /// (a presigned upload, a CDN) never carries the session token, and any
  /// Authorization header on it is removed. On the API host a held
  /// token is attached; with none held, a header the caller set itself stays
  /// (the logout request carries its own, and a screen may pass the token
  /// it read from storage).
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _readLanguage();
    final token = _readToken();
    final sameHost = options.uri.host == Uri.parse(options.baseUrl).host;
    if (!sameHost) {
      options.headers.remove('Authorization');
    } else if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      options.extra[attachedKey] = true;
    } else if (options.extra.remove(attachedKey) == true) {
      // A resend after the session ended: the header is the one this
      // interceptor added, so it goes. A header the caller set stays.
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  /// A 401 ends the session only when it answers a request that carried the
  /// token held now: a late 401 for a signed-out token, or for a
  /// request sent before sign-in, says nothing about the new session.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final carried = _carriedToken(err.requestOptions);
    if (err.response?.statusCode == 401 &&
        !_signInPaths.contains(apiPath(err.requestOptions)) &&
        carried.isNotEmpty &&
        carried == _readToken() &&
        carried != _expiredToken) {
      _expiredToken = carried;
      _onSessionExpired();
    }
    handler.next(err);
  }

  static String _carriedToken(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String) return '';
    const prefix = 'Bearer ';
    return header.startsWith(prefix) ? header.substring(prefix.length) : '';
  }
}
