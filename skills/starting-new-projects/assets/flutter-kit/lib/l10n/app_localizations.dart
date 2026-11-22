import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No connection before a request was sent
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Please check your connection and try again.'**
  String get errorNoConnection;

  /// Connect timeout, nothing reached the server
  ///
  /// In en, this message translates to:
  /// **'The connection is taking longer than usual. Please try again.'**
  String get errorTimeout;

  /// Send or receive timeout, outcome unknown
  ///
  /// In en, this message translates to:
  /// **'We could not confirm whether your request went through. Please check before you try again.'**
  String get errorOutcomeUnknown;

  /// Server error 5xx
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again in a moment.'**
  String get errorServer;

  /// 401
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get errorSessionEnded;

  /// 403
  ///
  /// In en, this message translates to:
  /// **'This page is not available for your account.'**
  String get errorForbidden;

  /// 404
  ///
  /// In en, this message translates to:
  /// **'We could not find what you were looking for.'**
  String get errorNotFound;

  /// 409 without a backend message
  ///
  /// In en, this message translates to:
  /// **'This has just been changed. Please review it and try again.'**
  String get errorConflict;

  /// Any other failure
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// Title of the screen shown when the app cannot finish starting
  ///
  /// In en, this message translates to:
  /// **'We could not start the app'**
  String get bootFailureTitle;

  /// Body of the start-up failure screen
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while opening the app. Please try again in a moment.'**
  String get bootFailureBody;

  /// Retry button of the start-up failure screen
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get bootFailureRetry;

  /// Default title of an empty view
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get kitEmptyTitle;

  /// Title of the error view
  ///
  /// In en, this message translates to:
  /// **'This could not be loaded'**
  String get kitErrorTitle;

  /// Title of the offline view
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get kitOfflineTitle;

  /// Retry action on an error view
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get kitRetry;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Web sidebar toggle
  ///
  /// In en, this message translates to:
  /// **'Expand the sidebar'**
  String get navExpand;

  /// Web sidebar toggle
  ///
  /// In en, this message translates to:
  /// **'Collapse the sidebar'**
  String get navCollapse;

  /// Screen-reader label of a tab with a badge
  ///
  /// In en, this message translates to:
  /// **'{label}, action required'**
  String navActionRequired(String label);

  /// Splash retry button
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get startupRetryAction;

  /// Splash, when the saved session cannot be read yet
  ///
  /// In en, this message translates to:
  /// **'We are still opening your saved session.'**
  String get startupRetryBody;

  /// The app's name, shown at the top of the sidebar
  ///
  /// In en, this message translates to:
  /// **'Kit App'**
  String get appName;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Title of the empty Home screen
  ///
  /// In en, this message translates to:
  /// **'Your app starts here'**
  String get homeEmptyTitle;

  /// Body of the empty Home screen
  ///
  /// In en, this message translates to:
  /// **'Your first screen will appear here once it is ready.'**
  String get homeEmptyBody;

  /// Screen-reader label of a loading indicator
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loaderLabel;

  /// Confirms a wheel picker
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get kitDone;

  /// Screen-reader hint on a destructive dialog action
  ///
  /// In en, this message translates to:
  /// **'Cannot be undone'**
  String get kitDestructiveHint;

  /// Time picker error when a past time is picked for today
  ///
  /// In en, this message translates to:
  /// **'Please choose a time later than now.'**
  String get kitPastTime;

  /// Update banner title
  ///
  /// In en, this message translates to:
  /// **'An update is ready'**
  String get kitUpdateTitle;

  /// Update banner body
  ///
  /// In en, this message translates to:
  /// **'Restart to finish it. It takes a few seconds.'**
  String get kitUpdateBody;

  /// Update banner action
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get kitUpdateRestart;

  /// Update banner action
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get kitUpdateLater;

  /// Connection banner while offline
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get kitOffline;

  /// Connection banner for 2 seconds after reconnecting
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get kitBackOnline;

  /// Connection banner when requests time out; also the title of the retry dialog
  ///
  /// In en, this message translates to:
  /// **'The connection is slow'**
  String get kitSlowConnection;

  /// Shown under the logo loader after a long wait; quiet and courteous
  ///
  /// In en, this message translates to:
  /// **'Still preparing this. Thank you for waiting.'**
  String get loaderLongWait;

  /// Declines a prompt without consequence, such as the retry dialog
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get kitNotNow;

  /// Title of the theme group and its section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// Theme choice: follow the device
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsThemeSystem;

  /// Theme choice
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme choice
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Title of the language group and its section
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Language choice: follow the device language
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get settingsLanguageSystem;

  /// Language choice, always written in its own language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Language choice, always written in its own language
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get settingsLanguageArabic;

  /// Title of the text size group and its section
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSizeTitle;

  /// The text size as a percentage
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String settingsTextSizeValue(String percent);

  /// Form error: a required field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please fill this in.'**
  String get validationRequired;

  /// Form error: the email is not valid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get validationEmail;

  /// Form error: the phone number is not valid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get validationPhone;

  /// Form error: the password is too weak. count picks the plural form; shown is the same number, already localized.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Please use at least {shown} character, with a letter and a number.} other{Please use at least {shown} characters, with a letter and a number.}}'**
  String validationPassword(int count, String shown);

  /// Form error: the text is too short. count picks the plural form; shown is the same number, already localized.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Please use at least {shown} character.} other{Please use at least {shown} characters.}}'**
  String validationTooShort(int count, String shown);

  /// Form error: the text is too long. count picks the plural form; shown is the same number, already localized.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Please keep this to {shown} character or fewer.} other{Please keep this to {shown} characters or fewer.}}'**
  String validationTooLong(int count, String shown);

  /// Form error: a confirmation field differs from the first.
  ///
  /// In en, this message translates to:
  /// **'These entries do not match.'**
  String get validationMismatch;

  /// Sign-in screen: the title.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInTitle;

  /// Sign-in screen: the line under the title.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue.'**
  String get authSignInBody;

  /// Label of the field that takes an email or a phone number (sign-in, forgot password).
  ///
  /// In en, this message translates to:
  /// **'Email or phone'**
  String get authIdentifierLabel;

  /// Label of a password field (sign-in, sign-up).
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Tooltip of the button that reveals a password field.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// Tooltip of the button that hides a password field.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// Sign-in screen: the main button.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInAction;

  /// Sign-in screen: link to the forgot-password screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authForgotLink;

  /// Sign-in screen: link to the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authNoAccountLink;

  /// Sign-up screen: the title.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authSignUpTitle;

  /// Sign-up screen: the line under the title.
  ///
  /// In en, this message translates to:
  /// **'It only takes a moment.'**
  String get authSignUpBody;

  /// Label of the name field (sign-up, complete profile).
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authNameLabel;

  /// Sign-up screen: label of the email field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Sign-up screen: label of the phone field.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authPhoneLabel;

  /// Label of the field that repeats the new password.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// Sign-up screen: the main button.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpAction;

  /// Link back to the sign-in screen (sign-up, forgot password).
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccountLink;

  /// Verify screen: the title.
  ///
  /// In en, this message translates to:
  /// **'Confirm your code'**
  String get authVerifyTitle;

  /// Verify screen: the line under the title.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code we sent you.'**
  String get authVerifyBody;

  /// Label of the one-time code field (verify, reset password).
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get authCodeLabel;

  /// Verify screen: the main button.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get authVerifyAction;

  /// Verify screen: the button that asks for another code.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get authResendAction;

  /// Under the code field while the resend button waits. time is a localized mm:ss countdown from AppFormats.formatDuration.
  ///
  /// In en, this message translates to:
  /// **'You can ask for a new code in {time}.'**
  String authResendIn(String time);

  /// Verify screen: the snackbar after a new code is sent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way.'**
  String get authCodeSent;

  /// Forgot-password screen: the title.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authForgotTitle;

  /// Forgot-password screen: the line under the title.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone and we will send you a code.'**
  String get authForgotBody;

  /// Forgot-password screen: the main button.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCodeAction;

  /// Reset-password screen: the title.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get authResetTitle;

  /// Reset-password screen: the line under the title.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code and your new password.'**
  String get authResetBody;

  /// Reset-password screen: label of the new password field.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordLabel;

  /// Reset-password screen: the main button.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get authResetAction;

  /// Snackbar after a password reset, on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Your password is saved. Please sign in.'**
  String get authPasswordSaved;

  /// Complete-profile screen: the title.
  ///
  /// In en, this message translates to:
  /// **'One last detail'**
  String get authCompleteTitle;

  /// Complete-profile screen: the line under the title.
  ///
  /// In en, this message translates to:
  /// **'Please tell us your name to finish.'**
  String get authCompleteBody;

  /// Complete-profile screen: the main button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authCompleteAction;

  /// Quiet button to leave an account (Settings, verify, complete profile, status screens).
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOutAction;

  /// Status screen for a blocked account: the title.
  ///
  /// In en, this message translates to:
  /// **'Your account is paused'**
  String get authBlockedTitle;

  /// Status screen for a blocked account: the line under the title.
  ///
  /// In en, this message translates to:
  /// **'Please contact support to restore access.'**
  String get authBlockedBody;

  /// Status screen for an account with no role in this app: the title.
  ///
  /// In en, this message translates to:
  /// **'This account has no access here'**
  String get authNoAccessTitle;

  /// Status screen for an account with no role in this app: the line under the title.
  ///
  /// In en, this message translates to:
  /// **'Please sign in with another account.'**
  String get authNoAccessBody;

  /// Sign-in screen: shown under the form when the details are wrong.
  ///
  /// In en, this message translates to:
  /// **'That email, phone or password does not match our records.'**
  String get authInvalidCredentials;

  /// 429 without a wait time (a failure shown under a form).
  ///
  /// In en, this message translates to:
  /// **'You have tried a few times. Please wait a moment and try again.'**
  String get errorTooManyRequests;

  /// 429 with the wait the server asked for. time is a localized mm:ss from AppFormats.formatDuration.
  ///
  /// In en, this message translates to:
  /// **'You have tried a few times. Please try again in {time}.'**
  String errorTooManyRequestsIn(String time);

  /// 410: the one-time code has expired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Please ask for a new one.'**
  String get errorCodeExpired;

  /// Link back to the sign-in screen on forgot-password and reset-password.
  ///
  /// In en, this message translates to:
  /// **'Remembered it? Back to sign in'**
  String get authBackToSignInLink;

  /// Permission prompt: title for notifications.
  ///
  /// In en, this message translates to:
  /// **'Stay informed'**
  String get permissionNotificationsTitle;

  /// Permission prompt: why the app asks for notifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so we can let you know when something needs your attention.'**
  String get permissionNotificationsBody;

  /// Permission prompt: title for the camera.
  ///
  /// In en, this message translates to:
  /// **'Use your camera'**
  String get permissionCameraTitle;

  /// Permission prompt: why the app asks for the camera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access to take your profile photo.'**
  String get permissionCameraBody;

  /// Permission prompt: title for the photo library.
  ///
  /// In en, this message translates to:
  /// **'Choose from your photos'**
  String get permissionPhotosTitle;

  /// Permission prompt: why the app asks for the photo library.
  ///
  /// In en, this message translates to:
  /// **'Allow photo access to choose your profile photo.'**
  String get permissionPhotosBody;

  /// Permission prompt: the button that shows the system dialog.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get permissionAllow;

  /// Permission prompt: the button that opens the system settings for the app.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get permissionOpenSettings;

  /// Permission prompt: the line when the permission was refused.
  ///
  /// In en, this message translates to:
  /// **'Access is turned off. You can turn it on in Settings.'**
  String get permissionDeniedBody;

  /// Permission prompt: the line when a permission once granted was turned off in Settings.
  ///
  /// In en, this message translates to:
  /// **'Access was turned off in Settings. You can turn it on again there.'**
  String get permissionRevokedBody;

  /// Permission prompt: the line when only some photos are shared.
  ///
  /// In en, this message translates to:
  /// **'You have shared some of your photos. You can share more in Settings.'**
  String get permissionLimitedBody;

  /// Permission prompt: the line when the permission is granted.
  ///
  /// In en, this message translates to:
  /// **'Access is on.'**
  String get permissionGranted;

  /// Permission prompt: the line when the device or browser cannot offer it.
  ///
  /// In en, this message translates to:
  /// **'This is not available on this device.'**
  String get permissionUnavailable;

  /// Android notification channel: the visible name of the general channel.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notificationChannelGeneral;

  /// Permission prompt on the web: the line when the browser refused; no button, the user changes it in the browser's site settings.
  ///
  /// In en, this message translates to:
  /// **'Access is turned off. You can allow it in your browser\'s site settings.'**
  String get permissionBrowserBody;

  /// Photo sheet: the row that opens the camera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get mediaTakePhoto;

  /// Photo sheet: the row that opens the photo picker.
  ///
  /// In en, this message translates to:
  /// **'Choose from your photos'**
  String get mediaChoosePhoto;

  /// The profile photo's button label and the photo sheet's title.
  ///
  /// In en, this message translates to:
  /// **'Change your photo'**
  String get mediaChangePhoto;

  /// The accessible name of a profile photo.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get mediaProfilePhoto;

  /// Shown under the photo while it uploads; the percent is already formatted, with the screen's digits.
  ///
  /// In en, this message translates to:
  /// **'Uploading, {percent}'**
  String mediaUploading(String percent);

  /// The line shown when a photo upload failed.
  ///
  /// In en, this message translates to:
  /// **'Your photo could not be uploaded.'**
  String get mediaUploadFailed;

  /// The accessible name of the icon shown where an image could not load.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get mediaImageUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
