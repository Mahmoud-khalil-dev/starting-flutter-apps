// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get errorNoConnection =>
      'You appear to be offline. Please check your connection and try again.';

  @override
  String get errorTimeout =>
      'The connection is taking longer than usual. Please try again.';

  @override
  String get errorOutcomeUnknown =>
      'We could not confirm whether your request went through. Please check before you try again.';

  @override
  String get errorServer =>
      'Something went wrong on our side. Please try again in a moment.';

  @override
  String get errorSessionEnded =>
      'Your session has ended. Please sign in again.';

  @override
  String get errorForbidden => 'This page is not available for your account.';

  @override
  String get errorNotFound => 'We could not find what you were looking for.';

  @override
  String get errorConflict =>
      'This has just been changed. Please review it and try again.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get bootFailureTitle => 'We could not start the app';

  @override
  String get bootFailureBody =>
      'Something went wrong while opening the app. Please try again in a moment.';

  @override
  String get bootFailureRetry => 'Try again';

  @override
  String get kitEmptyTitle => 'Nothing here yet';

  @override
  String get kitErrorTitle => 'This could not be loaded';

  @override
  String get kitOfflineTitle => 'You are offline';

  @override
  String get kitRetry => 'Try again';

  @override
  String get navHome => 'Home';

  @override
  String get navExpand => 'Expand the sidebar';

  @override
  String get navCollapse => 'Collapse the sidebar';

  @override
  String navActionRequired(String label) {
    return '$label, action required';
  }

  @override
  String get startupRetryAction => 'Try again';

  @override
  String get startupRetryBody => 'We are still opening your saved session.';

  @override
  String get appName => 'Kit App';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeEmptyTitle => 'Your app starts here';

  @override
  String get homeEmptyBody =>
      'Your first screen will appear here once it is ready.';

  @override
  String get loaderLabel => 'Loading';

  @override
  String get kitDone => 'Done';

  @override
  String get kitDestructiveHint => 'Cannot be undone';

  @override
  String get kitPastTime => 'Please choose a time later than now.';

  @override
  String get kitUpdateTitle => 'An update is ready';

  @override
  String get kitUpdateBody => 'Restart to finish it. It takes a few seconds.';

  @override
  String get kitUpdateRestart => 'Restart';

  @override
  String get kitUpdateLater => 'Later';

  @override
  String get kitOffline => 'No internet connection';

  @override
  String get kitBackOnline => 'Back online';

  @override
  String get kitSlowConnection => 'The connection is slow';

  @override
  String get loaderLongWait => 'Still preparing this. Thank you for waiting.';

  @override
  String get kitNotNow => 'Not now';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsThemeSystem => 'Automatic';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSystem => 'Device';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsTextSizeTitle => 'Text size';

  @override
  String settingsTextSizeValue(String percent) {
    return '$percent%';
  }

  @override
  String get validationRequired => 'Please fill this in.';

  @override
  String get validationEmail => 'Please enter a valid email address.';

  @override
  String get validationPhone => 'Please enter a valid phone number.';

  @override
  String validationPassword(int count, String shown) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Please use at least $shown characters, with a letter and a number.',
      one: 'Please use at least $shown character, with a letter and a number.',
    );
    return '$_temp0';
  }

  @override
  String validationTooShort(int count, String shown) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Please use at least $shown characters.',
      one: 'Please use at least $shown character.',
    );
    return '$_temp0';
  }

  @override
  String validationTooLong(int count, String shown) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Please keep this to $shown characters or fewer.',
      one: 'Please keep this to $shown character or fewer.',
    );
    return '$_temp0';
  }

  @override
  String get validationMismatch => 'These entries do not match.';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignInBody => 'Sign in to continue.';

  @override
  String get authIdentifierLabel => 'Email or phone';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authSignInAction => 'Sign in';

  @override
  String get authForgotLink => 'Forgot your password?';

  @override
  String get authNoAccountLink => 'New here? Create an account';

  @override
  String get authSignUpTitle => 'Create your account';

  @override
  String get authSignUpBody => 'It only takes a moment.';

  @override
  String get authNameLabel => 'Full name';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPhoneLabel => 'Phone number';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authSignUpAction => 'Create account';

  @override
  String get authHaveAccountLink => 'Already have an account? Sign in';

  @override
  String get authVerifyTitle => 'Confirm your code';

  @override
  String get authVerifyBody => 'Please enter the code we sent you.';

  @override
  String get authCodeLabel => 'Code';

  @override
  String get authVerifyAction => 'Confirm';

  @override
  String get authResendAction => 'Send a new code';

  @override
  String authResendIn(String time) {
    return 'You can ask for a new code in $time.';
  }

  @override
  String get authCodeSent => 'A new code is on its way.';

  @override
  String get authForgotTitle => 'Reset your password';

  @override
  String get authForgotBody =>
      'Enter your email or phone and we will send you a code.';

  @override
  String get authSendCodeAction => 'Send code';

  @override
  String get authResetTitle => 'Choose a new password';

  @override
  String get authResetBody => 'Please enter the code and your new password.';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authResetAction => 'Save password';

  @override
  String get authPasswordSaved => 'Your password is saved. Please sign in.';

  @override
  String get authCompleteTitle => 'One last detail';

  @override
  String get authCompleteBody => 'Please tell us your name to finish.';

  @override
  String get authCompleteAction => 'Continue';

  @override
  String get authSignOutAction => 'Sign out';

  @override
  String get authBlockedTitle => 'Your account is paused';

  @override
  String get authBlockedBody => 'Please contact support to restore access.';

  @override
  String get authNoAccessTitle => 'This account has no access here';

  @override
  String get authNoAccessBody => 'Please sign in with another account.';

  @override
  String get authInvalidCredentials =>
      'That email, phone or password does not match our records.';

  @override
  String get errorTooManyRequests =>
      'You have tried a few times. Please wait a moment and try again.';

  @override
  String errorTooManyRequestsIn(String time) {
    return 'You have tried a few times. Please try again in $time.';
  }

  @override
  String get errorCodeExpired =>
      'That code has expired. Please ask for a new one.';

  @override
  String get authBackToSignInLink => 'Remembered it? Back to sign in';

  @override
  String get permissionNotificationsTitle => 'Stay informed';

  @override
  String get permissionNotificationsBody =>
      'Allow notifications so we can let you know when something needs your attention.';

  @override
  String get permissionCameraTitle => 'Use your camera';

  @override
  String get permissionCameraBody =>
      'Allow camera access to take your profile photo.';

  @override
  String get permissionPhotosTitle => 'Choose from your photos';

  @override
  String get permissionPhotosBody =>
      'Allow photo access to choose your profile photo.';

  @override
  String get permissionAllow => 'Allow';

  @override
  String get permissionOpenSettings => 'Open Settings';

  @override
  String get permissionDeniedBody =>
      'Access is turned off. You can turn it on in Settings.';

  @override
  String get permissionRevokedBody =>
      'Access was turned off in Settings. You can turn it on again there.';

  @override
  String get permissionLimitedBody =>
      'You have shared some of your photos. You can share more in Settings.';

  @override
  String get permissionGranted => 'Access is on.';

  @override
  String get permissionUnavailable => 'This is not available on this device.';

  @override
  String get notificationChannelGeneral => 'General';

  @override
  String get permissionBrowserBody =>
      'Access is turned off. You can allow it in your browser\'s site settings.';

  @override
  String get mediaTakePhoto => 'Take a photo';

  @override
  String get mediaChoosePhoto => 'Choose from your photos';

  @override
  String get mediaChangePhoto => 'Change your photo';

  @override
  String get mediaProfilePhoto => 'Profile photo';

  @override
  String mediaUploading(String percent) {
    return 'Uploading, $percent';
  }

  @override
  String get mediaUploadFailed => 'Your photo could not be uploaded.';

  @override
  String get mediaImageUnavailable => 'Image unavailable';
}
