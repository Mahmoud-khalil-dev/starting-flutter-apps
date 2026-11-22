/// API paths relative to `Env.baseUrl`. One example stays here; add each
/// endpoint your API has as a constant and list the sign-in paths you hand
/// to `AuthInterceptor`.
abstract final class ApiEndpoints {
  /// An unauthenticated liveness path, the example to copy.
  static const health = '/health';

  /// The kit's auth paths; a project changes them to its API's in this file.
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const verifyCode = '/verify-code';
  static const resendCode = '/resend-code';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  /// Paths where a 401 means wrong credentials, not an ended session: sign
  /// in, sign up, one-time code and password reset. Hand this to
  /// `AuthInterceptor`. A path missing here signs the user out on a wrong
  /// password.
  static const signInPaths = <String>{
    signIn,
    signUp,
    verifyCode,
    resendCode,
    forgotPassword,
    resetPassword,
  };

  /// The signed-in user's profile; `SessionRemoteSource` reads it. Replace
  /// the example with your API's path.
  static const profile = '/profile';

  /// Ends the session on the server; `SessionRemoteSource` posts to it.
  /// Replace the example with your API's path.
  static const logout = '/sign-out';

  /// Replaces the signed-in user's photo (multipart, field `photo`);
  /// `DioAvatarUploader` posts to it. Replace the example with your API's.
  static const avatar = '/profile/avatar';

  /// Every path, for a check against your API spec.
  static const all = <String>[health, profile, avatar, logout, ...signInPaths];
}
