import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/features/auth/data/sources/auth_remote_source.dart';

import '../../../helpers/stub_adapter.dart';

void main() {
  late StubAdapter adapter;
  late AuthRemoteSource source;

  setUp(() {
    adapter = StubAdapter((_) async => jsonBody({'data': <String, Object?>{}}));
    source = AuthRemoteSource(
      Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter,
    );
  });

  test('KIT-T16: sign-in sends Western digits as an auth request', () async {
    await source.signIn(identifier: ' ٠٥٠١٢٣٤٥٦٧ ', password: 'pass١word');
    final request = adapter.requests.single;
    expect(request.path, ApiEndpoints.signIn);
    expect(request.method, 'POST');
    expect(request.data, {'identifier': '0501234567', 'password': 'pass١word'});
    expect(request.extra[RequestPolicy.extraKey], RequestClass.auth);
  });

  test('KIT-T16: the code goes out in Western digits', () async {
    await source.verifyCode('١٢٣٤');
    expect(adapter.requests.single.data, {'code': '1234'});
  });

  test('KIT-T16: sign-up trims and sends a Western phone', () async {
    await source.signUp(
      name: ' Sara Ali ',
      email: ' sara@example.com ',
      phone: '٠٥٠١٢٣٤٥٦٧',
      password: 'secret1a',
    );
    final request = adapter.requests.single;
    expect(request.path, ApiEndpoints.signUp);
    expect(request.data, {
      'name': 'Sara Ali',
      'email': 'sara@example.com',
      'phone': '0501234567',
      'password': 'secret1a',
    });
  });

  test('KIT-T16: resend, forgot and reset use their own paths', () async {
    await source.resendCode();
    await source.requestPasswordReset('٠٥٠١٢٣٤٥٦٧');
    await source.resetPassword(
      identifier: 'a@b.co',
      code: '٤٥٦٧',
      password: 'new١pass',
    );
    final sent = adapter.requests;
    expect(sent.map((r) => r.path), [
      ApiEndpoints.resendCode,
      ApiEndpoints.forgotPassword,
      ApiEndpoints.resetPassword,
    ]);
    expect(sent[1].data, {'identifier': '0501234567'});
    expect(sent[2].data, {
      'identifier': 'a@b.co',
      'code': '4567',
      'password': 'new١pass',
    });
    expect(
      sent.every((r) => r.extra[RequestPolicy.extraKey] == RequestClass.auth),
      isTrue,
    );
  });

  test('KIT-T16: completing the profile patches the profile', () async {
    await source.completeProfile(name: '  Sara Ali ');
    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, ApiEndpoints.profile);
    expect(request.data, {'name': 'Sara Ali'});
    expect(request.extra[RequestPolicy.extraKey], RequestClass.mutation);
  });

  test(
    'KIT-T16: a pasted code loses spaces, dashes and Arabic-Indic digits',
    () async {
      await source.verifyCode(' 123 456 ');
      await source.verifyCode('١٢٣-٤٥٦');
      await source.resetPassword(
        identifier: 'a@b.co',
        code: '١٢٣ ٤٥٦',
        password: 'secret1a',
      );
      final sent = adapter.requests;
      expect(sent[0].data, {'code': '123456'});
      expect(sent[1].data, {'code': '123456'});
      expect((sent[2].data as Map)['code'], '123456');
    },
  );

  test('KIT-T16: every password goes out exactly as typed', () async {
    const typed = ' pass١٢٣ word ';
    await source.signIn(identifier: 'a@b.co', password: typed);
    await source.signUp(
      name: 'Sara',
      email: 'a@b.co',
      phone: '0501234567',
      password: typed,
    );
    await source.resetPassword(
      identifier: 'a@b.co',
      code: '1234',
      password: typed,
    );
    for (final request in adapter.requests) {
      expect((request.data as Map)['password'], typed);
    }
  });
}
