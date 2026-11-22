// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get errorNoConnection =>
      'يبدو أنك غير متصل بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';

  @override
  String get errorTimeout =>
      'يستغرق الاتصال وقتاً أطول من المعتاد. يرجى المحاولة مرة أخرى.';

  @override
  String get errorOutcomeUnknown =>
      'لم نتمكن من التأكد من إتمام طلبك. يرجى التحقق قبل المحاولة مرة أخرى.';

  @override
  String get errorServer =>
      'حدث خطأ من جهتنا. يرجى المحاولة مرة أخرى بعد قليل.';

  @override
  String get errorSessionEnded => 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errorForbidden => 'هذه الصفحة غير متاحة لحسابك.';

  @override
  String get errorNotFound => 'لم نتمكن من العثور على ما تبحث عنه.';

  @override
  String get errorConflict =>
      'تم تغيير هذا للتو. يرجى مراجعته والمحاولة مرة أخرى.';

  @override
  String get errorUnknown => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get bootFailureTitle => 'تعذّر تشغيل التطبيق';

  @override
  String get bootFailureBody =>
      'حدث خطأ أثناء فتح التطبيق. يُرجى المحاولة مرة أخرى بعد قليل.';

  @override
  String get bootFailureRetry => 'حاول مرة أخرى';

  @override
  String get kitEmptyTitle => 'لا يوجد شيء هنا بعد';

  @override
  String get kitErrorTitle => 'تعذّر تحميل هذه الصفحة';

  @override
  String get kitOfflineTitle => 'أنت غير متصل';

  @override
  String get kitRetry => 'حاول مرة أخرى';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navExpand => 'توسيع الشريط الجانبي';

  @override
  String get navCollapse => 'طيّ الشريط الجانبي';

  @override
  String navActionRequired(String label) {
    return '$label، يتطلب إجراءً';
  }

  @override
  String get startupRetryAction => 'حاول مرة أخرى';

  @override
  String get startupRetryBody => 'ما زلنا نفتح جلستك المحفوظة.';

  @override
  String get appName => 'Kit App';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get homeEmptyTitle => 'يبدأ تطبيقك من هنا';

  @override
  String get homeEmptyBody => 'ستظهر شاشتك الأولى هنا عندما تكون جاهزة.';

  @override
  String get loaderLabel => 'جارٍ التحميل';

  @override
  String get kitDone => 'تم';

  @override
  String get kitDestructiveHint => 'لا يمكن التراجع عنه';

  @override
  String get kitPastTime => 'يُرجى اختيار وقت بعد الوقت الحالي.';

  @override
  String get kitUpdateTitle => 'التحديث جاهز';

  @override
  String get kitUpdateBody => 'أعد التشغيل لإكماله. يستغرق ذلك بضع ثوانٍ.';

  @override
  String get kitUpdateRestart => 'إعادة التشغيل';

  @override
  String get kitUpdateLater => 'لاحقًا';

  @override
  String get kitOffline => 'لا يوجد اتصال بالإنترنت';

  @override
  String get kitBackOnline => 'عاد الاتصال';

  @override
  String get kitSlowConnection => 'الاتصال بطيء';

  @override
  String get loaderLongWait => 'ما زلنا نجهّز ذلك. شكرًا لانتظارك.';

  @override
  String get kitNotNow => 'ليس الآن';

  @override
  String get settingsAppearanceTitle => 'المظهر';

  @override
  String get settingsThemeSystem => 'تلقائي';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsLanguageTitle => 'اللغة';

  @override
  String get settingsLanguageSystem => 'الجهاز';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsTextSizeTitle => 'حجم النص';

  @override
  String settingsTextSizeValue(String percent) {
    return '$percent٪';
  }

  @override
  String get validationRequired => 'يُرجى تعبئة هذا الحقل.';

  @override
  String get validationEmail => 'يُرجى إدخال بريد إلكتروني صحيح.';

  @override
  String get validationPhone => 'يُرجى إدخال رقم هاتف صحيح.';

  @override
  String validationPassword(int count, String shown) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يُرجى استخدام $shown حرف على الأقل، تتضمن حرفًا ورقمًا.',
      many: 'يُرجى استخدام $shown حرفًا على الأقل، تتضمن حرفًا ورقمًا.',
      few: 'يُرجى استخدام $shown أحرف على الأقل، تتضمن حرفًا ورقمًا.',
      two: 'يُرجى استخدام حرفين على الأقل، يتضمنان حرفًا ورقمًا.',
      one: 'يُرجى استخدام حرف واحد على الأقل، يتضمن حرفًا ورقمًا.',
      zero: 'يُرجى إدخال كلمة مرور.',
    );
    return '$_temp0';
  }

  @override
  String validationTooShort(int count, String shown) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يُرجى استخدام $shown حرف على الأقل.',
      many: 'يُرجى استخدام $shown حرفًا على الأقل.',
      few: 'يُرجى استخدام $shown أحرف على الأقل.',
      two: 'يُرجى استخدام حرفين على الأقل.',
      one: 'يُرجى استخدام حرف واحد على الأقل.',
      zero: 'يُرجى إدخال نص.',
    );
    return '$_temp0';
  }

  @override
  String validationTooLong(int count, String shown) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يُرجى ألا يتجاوز النص $shown حرف.',
      many: 'يُرجى ألا يتجاوز النص $shown حرفًا.',
      few: 'يُرجى ألا يتجاوز النص $shown أحرف.',
      two: 'يُرجى ألا يتجاوز النص حرفين.',
      one: 'يُرجى ألا يتجاوز النص حرفًا واحدًا.',
      zero: 'يُرجى ترك هذا الحقل فارغًا.',
    );
    return '$_temp0';
  }

  @override
  String get validationMismatch => 'القيمتان غير متطابقتين.';

  @override
  String get authSignInTitle => 'مرحبًا بعودتك';

  @override
  String get authSignInBody => 'سجّل الدخول للمتابعة.';

  @override
  String get authIdentifierLabel => 'البريد الإلكتروني أو رقم الهاتف';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authSignInAction => 'تسجيل الدخول';

  @override
  String get authForgotLink => 'نسيت كلمة المرور؟';

  @override
  String get authNoAccountLink => 'جديد هنا؟ أنشئ حسابًا';

  @override
  String get authSignUpTitle => 'أنشئ حسابك';

  @override
  String get authSignUpBody => 'لن يستغرق ذلك سوى لحظة.';

  @override
  String get authNameLabel => 'الاسم الكامل';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authPhoneLabel => 'رقم الهاتف';

  @override
  String get authConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get authSignUpAction => 'إنشاء الحساب';

  @override
  String get authHaveAccountLink => 'لديك حساب؟ سجّل الدخول';

  @override
  String get authVerifyTitle => 'أكّد الرمز';

  @override
  String get authVerifyBody => 'يُرجى إدخال الرمز الذي أرسلناه إليك.';

  @override
  String get authCodeLabel => 'الرمز';

  @override
  String get authVerifyAction => 'تأكيد';

  @override
  String get authResendAction => 'إرسال رمز جديد';

  @override
  String authResendIn(String time) {
    return 'يمكنك طلب رمز جديد بعد $time.';
  }

  @override
  String get authCodeSent => 'رمز جديد في الطريق إليك.';

  @override
  String get authForgotTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get authForgotBody =>
      'أدخل بريدك الإلكتروني أو رقم هاتفك وسنرسل إليك رمزًا.';

  @override
  String get authSendCodeAction => 'إرسال الرمز';

  @override
  String get authResetTitle => 'اختر كلمة مرور جديدة';

  @override
  String get authResetBody => 'يُرجى إدخال الرمز وكلمة المرور الجديدة.';

  @override
  String get authNewPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get authResetAction => 'حفظ كلمة المرور';

  @override
  String get authPasswordSaved => 'حُفظت كلمة المرور. يُرجى تسجيل الدخول.';

  @override
  String get authCompleteTitle => 'تفصيل أخير';

  @override
  String get authCompleteBody => 'يُرجى إخبارنا باسمك لإكمال التسجيل.';

  @override
  String get authCompleteAction => 'متابعة';

  @override
  String get authSignOutAction => 'تسجيل الخروج';

  @override
  String get authBlockedTitle => 'حسابك موقوف مؤقتًا';

  @override
  String get authBlockedBody => 'يُرجى التواصل مع الدعم لاستعادة الوصول.';

  @override
  String get authNoAccessTitle => 'لا يملك هذا الحساب صلاحية الوصول هنا';

  @override
  String get authNoAccessBody => 'يُرجى تسجيل الدخول بحساب آخر.';

  @override
  String get authInvalidCredentials =>
      'البريد الإلكتروني أو رقم الهاتف أو كلمة المرور غير مطابقة لسجلاتنا.';

  @override
  String get errorTooManyRequests =>
      'حاولت عدة مرات. يُرجى الانتظار قليلًا ثم إعادة المحاولة.';

  @override
  String errorTooManyRequestsIn(String time) {
    return 'حاولت عدة مرات. يُرجى المحاولة مجددًا بعد $time.';
  }

  @override
  String get errorCodeExpired => 'انتهت صلاحية هذا الرمز. يُرجى طلب رمز جديد.';

  @override
  String get authBackToSignInLink => 'تذكّرتها؟ العودة إلى تسجيل الدخول';

  @override
  String get permissionNotificationsTitle => 'ابقَ على اطّلاع';

  @override
  String get permissionNotificationsBody =>
      'اسمح بالإشعارات لنُعلمك حين يحتاج أمر ما إلى انتباهك.';

  @override
  String get permissionCameraTitle => 'استخدام الكاميرا';

  @override
  String get permissionCameraBody =>
      'اسمح بالوصول إلى الكاميرا لالتقاط صورتك الشخصية.';

  @override
  String get permissionPhotosTitle => 'الاختيار من صورك';

  @override
  String get permissionPhotosBody =>
      'اسمح بالوصول إلى الصور لاختيار صورتك الشخصية.';

  @override
  String get permissionAllow => 'السماح';

  @override
  String get permissionOpenSettings => 'فتح الإعدادات';

  @override
  String get permissionDeniedBody => 'الوصول متوقف. يمكنك تفعيله من الإعدادات.';

  @override
  String get permissionRevokedBody =>
      'أُوقف الوصول من الإعدادات. يمكنك تفعيله مجددًا من هناك.';

  @override
  String get permissionLimitedBody =>
      'شاركت بعض صورك. يمكنك مشاركة المزيد من الإعدادات.';

  @override
  String get permissionGranted => 'الوصول مفعّل.';

  @override
  String get permissionUnavailable => 'هذه الميزة غير متاحة على هذا الجهاز.';

  @override
  String get notificationChannelGeneral => 'عام';

  @override
  String get permissionBrowserBody =>
      'الوصول متوقف. يمكنك السماح به من إعدادات الموقع في المتصفح.';

  @override
  String get mediaTakePhoto => 'التقاط صورة';

  @override
  String get mediaChoosePhoto => 'الاختيار من صورك';

  @override
  String get mediaChangePhoto => 'تغيير صورتك';

  @override
  String get mediaProfilePhoto => 'الصورة الشخصية';

  @override
  String mediaUploading(String percent) {
    return 'جارٍ الرفع، $percent';
  }

  @override
  String get mediaUploadFailed => 'تعذّر رفع صورتك.';

  @override
  String get mediaImageUnavailable => 'الصورة غير متاحة';
}
