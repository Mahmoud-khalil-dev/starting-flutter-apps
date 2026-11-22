/// Paths of the app's screens. Add one constant per screen, and list it in
/// `RouteGuard.access` (and in [tabs] when it is a shell destination).
abstract final class RouteNames {
  /// The splash that waits for the saved session to settle.
  static const start = '/start';

  /// The sign-in screen; the guard sends a signed-out user here.
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';

  /// Reached with the identifier as `extra`; without it the screen asks for
  /// the identifier again.
  static const resetPassword = '/reset-password';

  /// An active account with no name yet (`RouteGuard.nameMissing`).
  static const completeProfile = '/complete-profile';

  /// The account still has to be verified.
  static const verify = '/verify';

  /// The account is blocked.
  static const blocked = '/blocked';

  /// The user has no role this app knows.
  static const noAccess = '/no-access';

  /// The component gallery. Debug builds only, and only when asked for.
  static const kitGallery = '/kit';

  static const home = '/home';
  static const settings = '/settings';

  /// Shell destinations: openRoute goes to these instead of pushing.
  static const Set<String> tabs = {home, settings};
}
