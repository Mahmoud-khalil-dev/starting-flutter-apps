import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/api_endpoints.dart';

void main() {
  test('KIT-T9: every endpoint is a path under the base URL', () {
    expect(ApiEndpoints.all, contains('/health'));
    for (final path in ApiEndpoints.all) {
      expect(path, startsWith('/'), reason: path);
      expect(Uri.parse(path).hasScheme, isFalse, reason: path);
    }
  });

  test('KIT-T16: every auth path is a sign-in path', () {
    expect(ApiEndpoints.signInPaths, {
      ApiEndpoints.signIn,
      ApiEndpoints.signUp,
      ApiEndpoints.verifyCode,
      ApiEndpoints.resendCode,
      ApiEndpoints.forgotPassword,
      ApiEndpoints.resetPassword,
    });
    expect(ApiEndpoints.all, containsAll(ApiEndpoints.signInPaths));
  });
}
