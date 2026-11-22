import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/api_reachability.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:kit_app/core/network/network_health_interceptor.dart';

import '../../helpers/stub_adapter.dart';

void main() {
  group('KIT-T9: reachability', () {
    test('any HTTP answer is reachable, 404 included', () async {
      final adapter = StubAdapter((_) async => jsonBody({}, status: 404));
      final dio = createProbeDio()..httpClientAdapter = adapter;
      expect(await apiReachable(dio, 'https://api.test/api/v1'), isTrue);
      final request = adapter.requests.single;
      expect(request.method, 'HEAD');
      expect(request.connectTimeout, probeTimeout);
      expect(request.receiveTimeout, probeTimeout);
    });

    test('a network error is not reachable', () async {
      final dio = createProbeDio()
        ..httpClientAdapter = StubAdapter(
          failWith(DioExceptionType.connectionError),
        );
      expect(await apiReachable(dio, 'https://api.test/api/v1'), isFalse);
    });
  });

  test('KIT-T9: the health interceptor records timeouts and answers', () async {
    final recorded = <bool>[];
    var next = 0;
    final answers = [
      (RequestOptions o) async => jsonBody({}),
      failWith(DioExceptionType.receiveTimeout),
      (RequestOptions o) async => jsonBody({}, status: 500),
    ];
    final dio = Dio()
      ..httpClientAdapter = StubAdapter((o) => answers[next++](o))
      ..interceptors.add(
        NetworkHealthInterceptor(
          ({required outcome}) =>
              recorded.add(outcome == RequestOutcome.timedOut),
        ),
      );
    for (var i = 0; i < 3; i++) {
      try {
        await dio.get<void>('/x');
      } on DioException {
        // Recorded either way.
      }
    }
    expect(recorded, [false, true, false]);
  });

  test('KIT-T9: the health interceptor ignores cancelled requests', () async {
    final recorded = <bool>[];
    final dio = Dio()
      ..httpClientAdapter = StubAdapter(failWith(DioExceptionType.cancel))
      ..interceptors.add(
        NetworkHealthInterceptor(
          ({required outcome}) =>
              recorded.add(outcome == RequestOutcome.timedOut),
        ),
      );
    try {
      await dio.get<void>('/x');
    } on DioException {
      // Expected.
    }
    expect(recorded, isEmpty);
  });
}
