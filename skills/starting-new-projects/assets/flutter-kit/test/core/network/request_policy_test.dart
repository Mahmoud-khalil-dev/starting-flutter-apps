import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/request_policy.dart';

import '../../helpers/stub_adapter.dart';

RequestClass _class(String method, String path, [RequestClass? named]) =>
    RequestPolicy.classify(
      RequestOptions(
        method: method,
        path: path,
        extra: {RequestPolicy.extraKey: ?named},
      ),
    );

void main() {
  group('KIT-T9: request classes', () {
    test('a GET is a read', () {
      expect(_class('GET', '/items'), RequestClass.read);
    });

    test('a sign-in path is auth even as a GET, so a code is never resent '
        'silently', () {
      expect(_class('get', ApiEndpoints.resendCode), RequestClass.auth);
    });

    test('auth is exactly the sign-in paths AuthInterceptor gets', () {
      for (final path in ApiEndpoints.signInPaths) {
        expect(_class('POST', path), RequestClass.auth, reason: path);
      }
    });

    test('a path that only holds an auth word is not auth', () {
      expect(_class('POST', '/devices/deactivate'), RequestClass.mutation);
      expect(_class('POST', '/account/login-history'), RequestClass.mutation);
      expect(_class('GET', '/password-policy'), RequestClass.read);
      expect(_class('GET', '/otp-settings'), RequestClass.read);
    });

    test('every other write is a mutation', () {
      expect(_class('POST', '/orders'), RequestClass.mutation);
      expect(_class('PATCH', '/orders/7/reschedule'), RequestClass.mutation);
      expect(_class('POST', '/account/logout'), RequestClass.mutation);
      expect(_class('POST', '/me/update'), RequestClass.mutation);
      expect(_class('POST', '/orders/preview'), RequestClass.mutation);
    });

    test('an explicit class wins', () {
      expect(
        _class('POST', '/uploads/confirm', RequestClass.upload),
        RequestClass.upload,
      );
    });
  });

  test('KIT-T9: each class gets its timeouts', () async {
    final adapter = StubAdapter((_) async => jsonBody({}));
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(PolicyInterceptor());
    await dio.get<void>('/items');
    await dio.post<void>('/orders');
    await dio.post<void>('/x', options: RequestPolicy.as(RequestClass.upload));
    await dio.patch<void>(
      '/orders/1/status',
      options: RequestPolicy.as(RequestClass.callControl),
    );
    final seen = [
      for (final r in adapter.requests)
        [
          r.connectTimeout,
          r.receiveTimeout,
          r.sendTimeout,
        ].map((d) => d!.inSeconds).toList(),
    ];
    expect(seen, [
      [15, 30, 30],
      [15, 45, 30],
      [15, 60, 60],
      [10, 15, 15],
    ]);
  });
  test('KIT-T9: the retry table, class by class: only a read and an upload '
      'resend silently, only a read and auth ask', () {
    final table = {
      for (final MapEntry(:key, :value) in RequestPolicy.byClass.entries)
        key: (
          value.silentRetries,
          value.askUser,
          value.connect.inSeconds,
          value.receive.inSeconds,
          value.send.inSeconds,
        ),
    };
    expect(table, {
      RequestClass.read: (2, true, 15, 30, 30),
      RequestClass.auth: (0, true, 15, 30, 30),
      RequestClass.mutation: (0, false, 15, 45, 30),
      RequestClass.upload: (1, false, 15, 60, 60),
      RequestClass.callControl: (0, false, 10, 15, 15),
      RequestClass.background: (0, false, 15, 30, 30),
    });
  });
}
