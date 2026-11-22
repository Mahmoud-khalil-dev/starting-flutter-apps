import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/auth_interceptor.dart';

/// An error handler whose future nobody awaits in these tests.
class _ErrorHandler extends ErrorInterceptorHandler {
  _ErrorHandler() {
    future.ignore();
  }
}

class _Capture extends RequestInterceptorHandler {
  RequestOptions? passed;

  @override
  void next(RequestOptions requestOptions) => passed = requestOptions;
}

void main() {
  late String? token;
  late int expired;
  late AuthInterceptor interceptor;

  setUp(() {
    token = 'old';
    expired = 0;
    interceptor = AuthInterceptor(
      readToken: () => token,
      readLanguage: () => 'en',
      onSessionExpired: () => expired++,
      signInPaths: ApiEndpoints.signInPaths,
    );
  });

  RequestOptions optionsWith({String? bearer, String path = '/orders'}) {
    final options = RequestOptions(path: path, baseUrl: 'https://api.test');
    if (bearer != null) options.headers['Authorization'] = 'Bearer $bearer';
    return options;
  }

  void fail401(RequestOptions options) {
    final handler = _ErrorHandler();
    interceptor.onError(
      DioException(
        requestOptions: options,
        response: Response<void>(requestOptions: options, statusCode: 401),
      ),
      handler,
    );
  }

  Future<RequestOptions> send(RequestOptions options) async {
    final handler = _Capture();
    interceptor.onRequest(options, handler);
    return handler.passed!;
  }

  group('KIT-T9: AuthInterceptor', () {
    test(
      'KIT-T9: a 401 on a sign-in path keeps the session, elsewhere ends it',
      () {
        for (final path in ApiEndpoints.signInPaths) {
          fail401(optionsWith(bearer: 'old', path: path));
        }
        expect(expired, 0);
        fail401(optionsWith(bearer: 'old'));
        expect(expired, 1);
      },
    );

    test(
      'KIT-T9: a late 401 for an old token does not end the new session',
      () {
        final options = optionsWith(bearer: 'old');
        token = 'new';
        fail401(options);
        expect(expired, 0);
      },
    );

    test('KIT-T9: a 401 for the current token ends it once', () {
      fail401(optionsWith(bearer: 'old'));
      fail401(optionsWith(bearer: 'old'));
      expect(expired, 1);
    });

    test('KIT-T9: a request sent with no token never expires', () {
      fail401(optionsWith());
      expect(expired, 0);
    });

    test('KIT-T9: a token held now is not blamed for a tokenless 401', () {
      // Sent before sign-in, answered after it.
      final options = optionsWith();
      token = 'new';
      fail401(options);
      expect(expired, 0);
    });

    test('KIT-T9: the bearer goes only to the API host', () async {
      final own = await send(optionsWith());
      expect(own.headers['Authorization'], 'Bearer old');
      final other = await send(
        RequestOptions(
          path: 'https://files.example.test/photo.jpg',
          baseUrl: 'https://api.test',
        ),
      );
      expect(other.headers.containsKey('Authorization'), isFalse);
    });

    test(
      'KIT-T9: a bearer on another host is removed, held token or not',
      () async {
        token = null;
        final other = RequestOptions(
          path: 'https://files.example.test/photo.jpg',
          baseUrl: 'https://api.test',
        )..headers['Authorization'] = 'Bearer old';
        final sent = await send(other);
        expect(sent.headers.containsKey('Authorization'), isFalse);
      },
    );

    test(
      'KIT-T9: a resend after sign-out loses the bearer the interceptor attached',
      () async {
        final options = optionsWith();
        final first = await send(options);
        expect(first.headers['Authorization'], 'Bearer old');
        token = null; // The sign-out wiped the session before the resend.
        final resent = await send(first);
        expect(resent.headers.containsKey('Authorization'), isFalse);
      },
    );

    test(
      'KIT-T9: a bearer the caller set on the API host stays when no token is held',
      () async {
        token = null;
        final sent = await send(optionsWith(bearer: 'captured'));
        expect(sent.headers['Authorization'], 'Bearer captured');
      },
    );
  });
}
