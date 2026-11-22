import 'package:dio/dio.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/core/utils/code_input_formatter.dart';
import 'package:kit_app/core/utils/string_extensions.dart';

/// Every typed identifier, phone and code goes out with Western digits, and a
/// code with its digits only. Passwords go out exactly as typed, whatever
/// digits they hold: a password is a secret, not a number the API reads, and
/// changing its digits would lock out a user whose stored password has the
/// other kind.
class AuthRemoteSource {
  const AuthRemoteSource(this._dio);

  final Dio _dio;

  Future<Object?> _post(String path, Map<String, Object?> body) async =>
      (await _dio.post<Object?>(
        path,
        data: body,
        options: RequestPolicy.as(RequestClass.auth),
      )).data;

  Future<Object?> signIn({
    required String identifier,
    required String password,
  }) => _post(ApiEndpoints.signIn, {
    'identifier': identifier.westernDigits.trim(),
    'password': password,
  });

  Future<Object?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => _post(ApiEndpoints.signUp, {
    'name': name.trim(),
    'email': email.trim(),
    'phone': phone.westernDigits.trim(),
    'password': password,
  });

  Future<Object?> verifyCode(String code) =>
      _post(ApiEndpoints.verifyCode, {'code': CodeInputFormatter.clean(code)});

  Future<Object?> resendCode() => _post(ApiEndpoints.resendCode, {});

  Future<Object?> requestPasswordReset(String identifier) => _post(
    ApiEndpoints.forgotPassword,
    {'identifier': identifier.westernDigits.trim()},
  );

  Future<Object?> resetPassword({
    required String identifier,
    required String code,
    required String password,
  }) => _post(ApiEndpoints.resetPassword, {
    'identifier': identifier.westernDigits.trim(),
    'code': CodeInputFormatter.clean(code),
    'password': password,
  });

  Future<Object?> completeProfile({required String name}) async =>
      (await _dio.patch<Object?>(
        ApiEndpoints.profile,
        data: {'name': name.trim()},
        options: RequestPolicy.as(RequestClass.mutation),
      )).data;
}
