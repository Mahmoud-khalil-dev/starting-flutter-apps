import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/core/network/retry_interceptor.dart';

import '../../helpers/stub_adapter.dart';

class _Run {
  _Run(
    Future<ResponseBody> Function(RequestOptions) respond, {
    this.answer = false,
  }) : adapter = StubAdapter(respond) {
    dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.addAll([
      PolicyInterceptor(),
      RetryInterceptor(
        fetch: dio.fetch,
        askRetry: () async {
          asks++;
          return answer;
        },
        wait: (d) async => waits.add(d),
        jitter: () => 0,
      ),
    ]);
  }

  final StubAdapter adapter;
  final bool answer;
  late final Dio dio;
  final waits = <Duration>[];
  int asks = 0;

  int get sent => adapter.requests.length;
}

void main() {
  group('KIT-T9: RetryInterceptor', () {
    test(
      'a read retries twice silently after 1 s and 3 s, then asks once',
      () async {
        final run = _Run(failWith(DioExceptionType.connectionTimeout));
        await expectLater(
          run.dio.get<void>('/items'),
          throwsA(isA<DioException>()),
        );
        expect(run.sent, 3);
        expect(run.waits, const [Duration(seconds: 1), Duration(seconds: 3)]);
        expect(run.asks, 1);
      },
    );

    test('a read resent from the prompt can succeed', () async {
      var calls = 0;
      final run = _Run(
        (o) => ++calls <= 3
            ? failWith(DioExceptionType.receiveTimeout)(o)
            : Future.value(jsonBody({'ok': true})),
        answer: true,
      );
      final response = await run.dio.get<Map<String, dynamic>>('/items');
      expect(response.data, {'ok': true});
      expect(run.sent, 4);
      expect(run.asks, 1);
    });

    test('a GET resend-code asks once and never retries silently', () async {
      final run = _Run(
        failWith(DioExceptionType.connectionTimeout),
        answer: true,
      );
      await expectLater(
        run.dio.get<void>(ApiEndpoints.resendCode),
        throwsA(isA<DioException>()),
      );
      expect(run.sent, 2);
      expect(run.asks, 1);
      expect(run.waits, isEmpty);
    });

    test('auth asks once and never retries silently', () async {
      final run = _Run(
        failWith(DioExceptionType.connectionTimeout),
        answer: true,
      );
      await expectLater(
        run.dio.post<void>(ApiEndpoints.signIn),
        throwsA(isA<DioException>()),
      );
      expect(run.sent, 2);
      expect(run.asks, 1);
      expect(run.waits, isEmpty);
    });

    test(
      'an order, confirmation, cancel or discount is never resent',
      () async {
        for (final path in [
          '/orders',
          '/orders/7/confirmation',
          '/orders/7/cancel',
          '/orders/preview',
        ]) {
          final run = _Run(
            failWith(DioExceptionType.receiveTimeout),
            answer: true,
          );
          await expectLater(
            run.dio.post<void>(path),
            throwsA(isA<DioException>()),
          );
          expect(run.sent, 1, reason: path);
          expect(run.asks, 0, reason: path);
        }
      },
    );

    test('an upload retries once silently', () async {
      final run = _Run(failWith(DioExceptionType.sendTimeout));
      await expectLater(
        run.dio.post<void>(
          '/x',
          options: RequestPolicy.as(RequestClass.upload),
        ),
        throwsA(isA<DioException>()),
      );
      expect(run.sent, 2);
      expect(run.asks, 0);
    });

    test(
      'KIT-T9: an upload with a FormData body is resent with a rebuilt body',
      () async {
        var calls = 0;
        final run = _Run(
          (o) => ++calls == 1
              ? failWith(DioExceptionType.receiveTimeout)(o)
              : Future.value(jsonBody({'ok': true})),
        );
        var built = 0;
        final first = FormData.fromMap({'photo': 'a'});
        final response = await run.dio.post<Map<String, dynamic>>(
          '/x',
          data: first,
          options: Options(
            extra: {
              RequestPolicy.extraKey: RequestClass.upload,
              RequestPolicy.bodyFactoryKey: () {
                built++;
                return FormData.fromMap({'photo': 'a'});
              },
            },
          ),
        );
        expect(response.data, {'ok': true});
        expect(run.sent, 2);
        expect(built, 1);
        expect(run.adapter.requests[1].data, isA<FormData>());
        expect(run.adapter.requests[1].data, isNot(same(first)));
      },
    );

    test('KIT-T9: a FormData body with no factory is never resent', () async {
      final run = _Run(failWith(DioExceptionType.receiveTimeout));
      await expectLater(
        run.dio.post<void>(
          '/x',
          data: FormData.fromMap({'photo': 'a'}),
          options: RequestPolicy.as(RequestClass.upload),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.receiveTimeout,
          ),
        ),
      );
      expect(run.sent, 1);
      expect(run.asks, 0);
    });

    test('KIT-T9: a Stream body with no factory is never resent', () async {
      final run = _Run(failWith(DioExceptionType.receiveTimeout));
      await expectLater(
        run.dio.put<void>(
          '/x',
          data: Stream<List<int>>.fromIterable([
            [1, 2, 3],
          ]),
          options: RequestPolicy.as(RequestClass.upload),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.receiveTimeout,
          ),
        ),
      );
      expect(run.sent, 1);
      expect(run.asks, 0);
    });

    test(
      'KIT-T9: a registration that timed out after sending is not resent or prompted',
      () async {
        for (final type in [
          DioExceptionType.receiveTimeout,
          DioExceptionType.sendTimeout,
        ]) {
          final run = _Run(failWith(type), answer: true);
          await expectLater(
            run.dio.post<void>(ApiEndpoints.signUp),
            throwsA(isA<DioException>().having((e) => e.type, 'type', type)),
          );
          expect(run.sent, 1, reason: '$type');
          expect(run.asks, 0, reason: '$type');
        }
      },
    );

    test('KIT-T9: a registration that never connected still prompts', () async {
      final run = _Run(
        failWith(DioExceptionType.connectionTimeout),
        answer: true,
      );
      await expectLater(
        run.dio.post<void>(ApiEndpoints.signUp),
        throwsA(isA<DioException>()),
      );
      expect(run.sent, 2);
      expect(run.asks, 1);
    });

    test('an HTTP error is not retried', () async {
      final run = _Run((_) async => jsonBody({'message': 'x'}, status: 500));
      await expectLater(
        run.dio.get<void>('/items'),
        throwsA(isA<DioException>()),
      );
      expect(run.sent, 1);
      expect(run.asks, 0);
    });

    test('a connection error counts like a timeout', () async {
      final run = _Run(failWith(DioExceptionType.connectionError));
      await expectLater(
        run.dio.get<void>('/items'),
        throwsA(isA<DioException>()),
      );
      expect(run.sent, 3);
      expect(run.asks, 1);
    });

    test('jitter adds at most 300 ms', () {
      final interceptor = RetryInterceptor(
        fetch: Dio().fetch,
        askRetry: () async => false,
        jitter: () => 1,
      );
      expect(interceptor.delayFor(0), const Duration(milliseconds: 1300));
      expect(interceptor.delayFor(1), const Duration(milliseconds: 3300));
    });

    test('a resend keeps the same extra map, so flags survive', () async {
      final adapter = StubAdapter(failWith(DioExceptionType.connectionError));
      final seen = <Object?>[];
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.addAll([
        PolicyInterceptor(),
        InterceptorsWrapper(
          onRequest: (options, handler) {
            seen.add(options.extra['statusReported']);
            options.extra['statusReported'] = true;
            handler.next(options);
          },
        ),
        RetryInterceptor(
          fetch: dio.fetch,
          askRetry: () async => false,
          wait: (_) async {},
          jitter: () => 0,
        ),
      ]);
      await expectLater(dio.get<void>('/items'), throwsA(isA<DioException>()));
      expect(seen, [null, true, true]);
      final extras = adapter.requests.map((r) => r.extra).toList();
      expect(extras.every((e) => identical(e, extras.first)), isTrue);
    });
  });
  group('KIT-T9: a write that may have reached the server', () {
    // A socket reset after the request left, and every XHR error on the web,
    // arrive as a connection error: only the table keeps a write from being
    // sent again.
    const failures = [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ];
    for (final requestClass in [
      RequestClass.mutation,
      RequestClass.callControl,
      RequestClass.background,
    ]) {
      for (final type in failures) {
        test('a ${requestClass.name} POST that fails with ${type.name} is '
            'sent once and never asks', () async {
          final run = _Run(failWith(type), answer: true);
          await expectLater(
            run.dio.post<void>(
              '/orders',
              options: RequestPolicy.as(requestClass),
            ),
            throwsA(isA<DioException>()),
          );
          expect(run.sent, 1);
          expect(run.asks, 0);
        });
      }
    }

    test(
      'an unnamed POST is a mutation: a connection error sends it once',
      () async {
        final run = _Run(
          failWith(DioExceptionType.connectionError),
          answer: true,
        );
        await expectLater(
          run.dio.post<void>('/orders'),
          throwsA(isA<DioException>()),
        );
        expect(run.sent, 1);
        expect(run.asks, 0);
      },
    );

    test('an auth POST that fails with a connection error asks once, then '
        'resends', () async {
      final run = _Run(
        failWith(DioExceptionType.connectionError),
        answer: true,
      );
      await expectLater(
        run.dio.post<void>(
          ApiEndpoints.signIn,
          options: RequestPolicy.as(RequestClass.auth),
        ),
        throwsA(isA<DioException>()),
      );
      expect(run.sent, 2);
      expect(run.asks, 1);
      expect(run.waits, isEmpty);
    });

    test('an upload that fails with a connection error is resent once and '
        'never asks', () async {
      final run = _Run(
        failWith(DioExceptionType.connectionError),
        answer: true,
      );
      await expectLater(
        run.dio.post<void>(
          '/avatar',
          options: RequestPolicy.as(RequestClass.upload),
        ),
        throwsA(isA<DioException>()),
      );
      expect(run.sent, 2);
      expect(run.asks, 0);
    });
  });
}
