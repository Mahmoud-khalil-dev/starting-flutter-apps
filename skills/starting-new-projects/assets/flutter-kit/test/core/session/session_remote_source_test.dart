import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/core/network/status_interceptor.dart';
import 'package:kit_app/core/session/session_remote_source.dart';

import '../../helpers/stub_adapter.dart';

void main() {
  test(
    'KIT-T10: logout sends the captured token, in the background class',
    () async {
      final adapter = StubAdapter(
        (_) async => jsonBody({'data': <String, Object?>{}}),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
      await SessionRemoteSource(dio).logout('test-token');
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, ApiEndpoints.logout);
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(request.extra[RequestPolicy.extraKey], RequestClass.background);
      expect(request.extra[StatusInterceptor.quietKey], isTrue);
    },
  );

  test('KIT-T10: the profile is a read', () async {
    final adapter = StubAdapter(
      (_) async => jsonBody({
        'data': {'id': 1},
      }),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    expect(await SessionRemoteSource(dio).fetchProfile(), {
      'data': {'id': 1},
    });
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, ApiEndpoints.profile);
  });
}
