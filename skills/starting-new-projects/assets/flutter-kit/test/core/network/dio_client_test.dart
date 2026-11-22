import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/network/auth_interceptor.dart';
import 'package:kit_app/core/network/dio_client.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/core/network/status_interceptor.dart';

import '../../helpers/stub_adapter.dart';

const _signIn = {'/account/login', '/account/register', '/account/activate'};

class _Setup {
  _Setup(Future<ResponseBody> Function(RequestOptions) respond)
    : adapter = StubAdapter(respond) {
    dio = createDio(
      baseUrl: 'https://api.test/api/v1',
      adapter: adapter,
      logRequests: false,
      interceptors: [
        PolicyInterceptor(),
        AuthInterceptor(
          readToken: () => token,
          readLanguage: () => 'ar',
          onSessionExpired: () => expired++,
          signInPaths: _signIn,
        ),
        StatusInterceptor(reported.add),
      ],
    );
  }

  final StubAdapter adapter;
  late final Dio dio;
  String? token = 't1';
  int expired = 0;
  final reported = <Failure>[];
}

Future<void> _quietly(Future<void> request) async {
  try {
    await request;
  } on DioException {
    // The failure is what the test inspects.
  }
}

void main() {
  group('KIT-T9: createDio', () {
    test(
      'requests carry JSON accept, Accept-Language and the bearer token',
      () async {
        final s = _Setup((_) async => jsonBody({}));
        await s.dio.get<void>('/items');
        final headers = s.adapter.requests.single.headers;
        expect(headers['Accept'], 'application/json');
        expect(headers['Accept-Language'], 'ar');
        expect(headers['Authorization'], 'Bearer t1');
        expect(s.adapter.requests.single.contentType, Headers.jsonContentType);
      },
    );

    test('no token, no Authorization header', () async {
      final s = _Setup((_) async => jsonBody({}))..token = null;
      await s.dio.get<void>('/items');
      expect(
        s.adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('a 401 ends the session once per token', () async {
      final s = _Setup(
        (_) async => jsonBody({'message': 'expired'}, status: 401),
      );
      await _quietly(s.dio.get<void>('/orders'));
      await _quietly(s.dio.get<void>('/me'));
      expect(s.expired, 1);
      s.token = 't2';
      await _quietly(s.dio.get<void>('/orders'));
      expect(s.expired, 2);
    });

    test(
      'a 401 on a sign-in path is wrong credentials, not a session end',
      () async {
        final s = _Setup(
          (_) async => jsonBody({'message': 'bad'}, status: 401),
        );
        for (final path in _signIn) {
          await _quietly(s.dio.post<void>(path));
        }
        expect(s.expired, 0);
        await _quietly(s.dio.get<void>('/me'));
        expect(s.expired, 1);
      },
    );

    test(
      'a sign-in path with a query string is still exempt from a 401',
      () async {
        final s = _Setup(
          (_) async => jsonBody({'message': 'bad'}, status: 401),
        );
        await _quietly(s.dio.post<void>('/account/login?lang=ar'));
        expect(s.expired, 0);
        await _quietly(s.dio.get<void>('/me?lang=ar'));
        expect(s.expired, 1);
      },
    );

    test('a sign-in path as a full URL is still exempt from a 401', () async {
      final s = _Setup((_) async => jsonBody({'message': 'bad'}, status: 401));
      await _quietly(s.dio.post<void>('https://api.test/api/v1/account/login'));
      expect(s.expired, 0);
      await _quietly(s.dio.get<void>('https://api.test/api/v1/me'));
      expect(s.expired, 1);
    });

    test(
      'a failed write is reported; a read, a quiet write and a 401 are not',
      () async {
        final s = _Setup(
          (o) async => o.path == '/me'
              ? jsonBody({}, status: 401)
              : jsonBody({}, status: 500),
        );
        await _quietly(s.dio.post<void>('/orders'));
        await _quietly(s.dio.get<void>('/items'));
        await _quietly(
          s.dio.post<void>(
            '/orders',
            options: Options(extra: {StatusInterceptor.quietKey: true}),
          ),
        );
        await _quietly(s.dio.post<void>('/me'));
        expect(s.reported, const [ServerFailure(500)]);
      },
    );

    test(
      'a resend of a reported request that fails again is not reported twice',
      () async {
        final s = _Setup((_) async => jsonBody({}, status: 500));
        late RequestOptions sent;
        try {
          await s.dio.post<void>('/orders');
        } on DioException catch (e) {
          sent = e.requestOptions;
        }
        expect(sent.extra[StatusInterceptor.reportedKey], isTrue);
        // A resend reuses the same RequestOptions, as RetryInterceptor does.
        await _quietly(s.dio.fetch<void>(sent));
        expect(s.reported, const [ServerFailure(500)]);
      },
    );

    test('debug logging never logs headers or bodies', () {
      final dio = createDio(
        baseUrl: 'https://api.test',
        interceptors: const [],
      );
      final log = dio.interceptors.whereType<LogInterceptor>().single;
      expect(log.requestHeader, isFalse);
      expect(log.requestBody, isFalse);
      expect(log.responseHeader, isFalse);
      expect(log.responseBody, isFalse);
    });
  });
}
