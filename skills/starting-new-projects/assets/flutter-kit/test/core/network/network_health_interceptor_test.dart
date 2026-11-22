import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:kit_app/core/network/network_health_interceptor.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/core/network/retry_interceptor.dart';

import '../../helpers/stub_adapter.dart';

Future<List<RequestOutcome>> _record(
  Future<ResponseBody> Function(RequestOptions) respond,
) async {
  final recorded = <RequestOutcome>[];
  final dio = Dio()
    ..httpClientAdapter = StubAdapter(respond)
    ..interceptors.add(
      NetworkHealthInterceptor(({required outcome}) => recorded.add(outcome)),
    );
  try {
    await dio.get<void>('/x');
  } on DioException {
    // Recorded either way.
  }
  return recorded;
}

void main() {
  group('KIT-T9: NetworkHealthInterceptor', () {
    test('KIT-T9: a connectionError is not a success', () async {
      expect(await _record(failWith(DioExceptionType.connectionError)), [
        RequestOutcome.failed,
      ]);
    });

    test('KIT-T9: a 500 answer is a received response', () async {
      expect(await _record((_) async => jsonBody({}, status: 500)), [
        RequestOutcome.ok,
      ]);
    });

    test('KIT-T9: a timeout is a timeout', () async {
      expect(await _record(failWith(DioExceptionType.receiveTimeout)), [
        RequestOutcome.timedOut,
      ]);
    });

    test('KIT-T9: one slow request is recorded as one timeout', () async {
      final recorded = <RequestOutcome>[];
      final adapter = StubAdapter(failWith(DioExceptionType.receiveTimeout));
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.addAll([
        PolicyInterceptor(),
        NetworkHealthInterceptor(({required outcome}) => recorded.add(outcome)),
        RetryInterceptor(
          fetch: dio.fetch,
          askRetry: () async => false,
          wait: (_) async {},
          jitter: () => 0,
        ),
      ]);
      await expectLater(dio.get<void>('/items'), throwsA(isA<DioException>()));
      expect(adapter.requests, hasLength(3));
      expect(recorded, [RequestOutcome.timedOut]);
    });
  });
}
