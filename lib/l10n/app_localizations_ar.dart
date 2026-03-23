// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'الأدوات';

  @override
  String get common_cancel => 'إلغاء';

  @override
  String get common_save => 'حفظ';

  @override
  String get common_delete => 'حذف';

  @override
  String get common_edit => 'تعديل';

  @override
  String get common_close => 'إغلاق';

  @override
  String get common_ok => 'موافق';

  @override
  String get common_retry => 'إعادة المحاولة';

  @override
  String get common_remove => 'إزالة';

  @override
  String get common_view => 'عرض';

  @override
  String get common_back => 'رجوع';

  @override
  String get common_search => 'بحث';

  @override
  String get common_loading => 'جارٍ التحميل...';

  @override
  String get common_error => 'خطأ';

  @override
  String get common_success => 'نجاح';

  @override
  String get common_unknown => 'غير معروف';

  @override
  String get common_notAvailable => 'غير متاح';

  @override
  String get common_required => 'مطلوب';

  @override
  String get common_optional => 'اختياري';

  @override
  String get common_all => 'الكل';

  @override
  String get common_none => 'لا شيء';

  @override
  String get common_yes => 'نعم';

  @override
  String get common_no => 'لا';

  @override
  String get common_signOut => 'تسجيل الخروج';

  @override
  String get common_logout => 'تسجيل الخروج';

  @override
  String get common_settings => 'الإعدادات';

  @override
  String get common_notifications => 'الإشعارات';

  @override
  String get common_email => 'البريد الإلكتروني';

  @override
  String get common_password => 'كلمة المرور';

  @override
  String get common_name => 'الاسم';

  @override
  String get common_phone => 'الهاتف';

  @override
  String get common_status => 'الحالة';

  @override
  String get common_active => 'نشط';

  @override
  String get common_inactive => 'غير نشط';

  @override
  String get common_camera => 'الكاميرا';

  @override
  String get common_gallery => 'المعرض';

  @override
  String get common_addImage => 'إضافة صورة';

  @override
  String get common_selectImageSource => 'اختر مصدر الصورة';

  @override
  String common_failedToPickImage(String error) {
    return 'فشل في اختيار الصورة: $error';
  }

  @override
  String get common_somethingWentWrong =>
      'عذراً! حدث خطأ ما. يرجى المحاولة مجدداً.';

  @override
  String get common_offlineBanner => 'غير متصل — عرض البيانات المخزنة';

  @override
  String get common_noImage => 'لا توجد صورة';

  @override
  String get status_available => 'متاح';

  @override
  String get status_assigned => 'مُسنَد';

  @override
  String get status_inUse => 'قيد الاستخدام';

  @override
  String get status_maintenance => 'صيانة';

  @override
  String get status_retired => 'مُستبعَد';

  @override
  String get status_lost => 'مفقود';

  @override
  String get priority_low => 'منخفض';

  @override
  String get priority_medium => 'متوسط';

  @override
  String get priority_high => 'عالٍ';

  @override
  String get priority_critical => 'حرج';

  @override
  String get priority_normal => 'عادي';

  @override
  String get priority_urgent => 'عاجل';

  @override
  String get validation_required => 'هذا الحقل مطلوب';

  @override
  String get validation_emailRequired => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get validation_emailInvalid => 'يرجى إدخال عنوان بريد إلكتروني صحيح';

  @override
  String get validation_passwordRequired => 'يرجى إدخال كلمة المرور';

  @override
  String get validation_passwordMinLength =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get validation_passwordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get validation_nameRequired => 'يرجى إدخال اسمك الكامل';

  @override
  String get validation_phoneRequired => 'يرجى إدخال رقم هاتفك';

  @override
  String get validation_pleaseSelectTool => 'يرجى اختيار أداة';

  @override
  String get roleSelection_subtitle => 'تتبع الأدوات • الإسنادات • المخزون';

  @override
  String get roleSelection_registerAdmin => 'التسجيل كمسؤول';

  @override
  String get roleSelection_continueAdmin => 'المتابعة كمسؤول';

  @override
  String get roleSelection_registerTechnician => 'التسجيل كفني';

  @override
  String get roleSelection_continueTechnician => 'المتابعة كفني';

  @override
  String get roleSelection_alreadyHaveAccount => 'هل لديك حساب بالفعل؟ ';

  @override
  String get roleSelection_signIn => 'تسجيل الدخول';

  @override
  String get roleSelection_adminClosedError =>
      'تسجيل المسؤولين مغلق. يرجى طلب دعوة من المسؤول.';

  @override
  String get login_title => 'تسجيل الدخول';

  @override
  String get login_emailLabel => 'عنوان البريد الإلكتروني';

  @override
  String get login_emailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get login_passwordLabel => 'كلمة المرور';

  @override
  String get login_passwordHint => 'أدخل كلمة المرور';

  @override
  String get login_signInButton => 'تسجيل الدخول';

  @override
  String get login_forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get login_orContinueWith => 'أو المتابعة باستخدام';

  @override
  String get login_or => 'أو';

  @override
  String get login_google => 'Google';

  @override
  String get login_apple => 'Apple';

  @override
  String get login_registerPrompt => 'ليس لديك حساب؟ سجّل هنا';

  @override
  String get login_registerSubtext => 'اختر تسجيل مسؤول أو فني';

  @override
  String get login_welcomeBack => 'مرحباً بعودتك';

  @override
  String get login_welcomeBackSubtitle => 'سجّل دخولك إلى حسابك';

  @override
  String get login_successMessage => 'مرحباً بعودتك! تم تسجيل الدخول بنجاح.';

  @override
  String get login_accessDenied =>
      'تم رفض الوصول: بيانات اعتماد المسؤول غير صحيحة';

  @override
  String get login_emailRequiredFirst =>
      'يرجى إدخال عنوان بريدك الإلكتروني أولاً';

  @override
  String get login_passwordResetSent =>
      'تم إرسال رسالة إعادة تعيين كلمة المرور! تحقق من بريدك الوارد.';

  @override
  String get login_appleCancelled => 'تم إلغاء تسجيل الدخول عبر Apple.';

  @override
  String get login_appleFailed => 'فشل تسجيل الدخول عبر Apple.';

  @override
  String get login_oauthAccountExists =>
      'هذا البريد الإلكتروني مسجّل بالفعل. يرجى تسجيل الدخول باستخدام بريدك الإلكتروني وكلمة المرور.';

  @override
  String get login_emailDomainNotAllowed =>
      'نطاق البريد الإلكتروني غير مسموح به. يرجى استخدام عنوان بريد إلكتروني معتمد.';

  @override
  String get login_resetPasswordDialogTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get login_resetPasswordDialogMessage =>
      'أدخل عنوان بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.';

  @override
  String get login_resetPasswordEmailHint => 'your.email@example.com';

  @override
  String get login_resetPasswordSendButton => 'إرسال رابط الإعادة';

  @override
  String get login_resetPasswordSuccessTitle => 'تم الإرسال!';

  @override
  String login_resetPasswordSuccessMessage(String email) {
    return 'لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى $email. يرجى التحقق من بريدك الوارد واتباع التعليمات لإعادة تعيين كلمة المرور.';
  }

  @override
  String get register_createAccount => 'أنشئ حسابك للبدء.';

  @override
  String get register_fullNameLabel => 'الاسم الكامل';

  @override
  String get register_emailLabel => 'البريد الإلكتروني';

  @override
  String get register_passwordLabel => 'كلمة المرور';

  @override
  String get register_confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get register_phoneLabel => 'رقم الهاتف';

  @override
  String get register_departmentLabel => 'القسم';

  @override
  String get register_roleLabel => 'الدور الوظيفي';

  @override
  String get register_createAccountButton => 'إنشاء حساب';

  @override
  String get register_signInLink => 'هل لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get register_backToRoleSelection => 'العودة إلى اختيار الدور';

  @override
  String get register_checkYourEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String get register_confirmationEmailSent => 'لقد أرسلنا رسالة تأكيد إلى:';

  @override
  String get register_confirmationInstructions =>
      'يرجى التحقق من بريدك الإلكتروني والنقر على رابط التأكيد للتحقق من حسابك. بعد التحقق، سيكون حسابك في انتظار موافقة المسؤول.';

  @override
  String get register_goToLogin => 'الانتقال إلى تسجيل الدخول';

  @override
  String get register_pendingApproval =>
      'حسابك في انتظار موافقة المسؤول. ستتلقى إشعاراً عند الموافقة.';

  @override
  String get register_emailFormatValidation =>
      'يرجى إدخال عنوان بريد إلكتروني صحيح (مثال: name@example.com)';

  @override
  String get resetPassword_title => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPassword_subtitle => 'أدخل كلمة مرورك الجديدة أدناه';

  @override
  String get resetPassword_newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get resetPassword_confirmLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get resetPassword_button => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPassword_backToLogin => 'العودة إلى تسجيل الدخول';

  @override
  String get resetPassword_successMessage =>
      'تم تعيين كلمة المرور بنجاح! جارٍ إعادة التوجيه...';

  @override
  String get resetPassword_sessionExpired =>
      'انتهت صلاحية الجلسة. يرجى فتح رابط الدعوة مجدداً.';

  @override
  String get adminRegistration_title => 'تسجيل المسؤول';

  @override
  String get adminRegistration_subtitle => 'التسجيل كمسؤول نظام';

  @override
  String get adminRegistration_fullNameLabel => 'الاسم الكامل';

  @override
  String get adminRegistration_fullNameHint => 'أدخل الاسم الكامل';

  @override
  String get adminRegistration_emailLabel => 'عنوان البريد الإلكتروني';

  @override
  String get adminRegistration_emailHint => 'أدخل البريد الإلكتروني للشركة';

  @override
  String get adminRegistration_passwordLabel => 'كلمة المرور';

  @override
  String get adminRegistration_passwordHint => '6 أحرف كحد أدنى';

  @override
  String get adminRegistration_confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get adminRegistration_confirmPasswordHint => 'أعد إدخال كلمة المرور';

  @override
  String get adminRegistration_registerButton => 'التسجيل كمسؤول';

  @override
  String get adminRegistration_alreadyHaveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get adminRegistration_loadingRole => 'جارٍ تحميل صلاحيات المسؤول...';

  @override
  String get adminRegistration_positionNotConfigured =>
      'منصب المسؤول الرئيسي غير مُهيَّأ. يرجى تشغيل ترحيل مناصب المسؤولين.';

  @override
  String get adminRegistration_accountCreated =>
      'تم إنشاء حساب المسؤول بنجاح! مرحباً بك.';

  @override
  String adminRegistration_invalidDomain(String domains) {
    return 'نطاق البريد الإلكتروني غير صالح لتسجيل المسؤول. استخدم $domains';
  }

  @override
  String get adminRegistration_checkEmailConfirmation =>
      'يرجى التحقق من بريدك الإلكتروني والنقر على رابط التأكيد للتحقق من حساب المسؤول. يجب تأكيد بريدك الإلكتروني قبل تسجيل الدخول.';

  @override
  String get adminRegistration_afterConfirmation =>
      'بعد تأكيد بريدك الإلكتروني، يمكنك تسجيل الدخول ببيانات اعتماد المسؤول.';

  @override
  String get adminRegistration_connectionError =>
      'خطأ في الاتصال: يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.';

  @override
  String get adminRegistration_emailAlreadyRegistered =>
      'هذا البريد الإلكتروني مسجّل بالفعل. يرجى استخدام بريد إلكتروني مختلف أو محاولة تسجيل الدخول.';

  @override
  String get adminRegistration_invalidEmail =>
      'عنوان البريد الإلكتروني غير صالح. يرجى المراجعة والمحاولة مجدداً.';

  @override
  String get adminRegistration_weakPassword =>
      'كلمة المرور ضعيفة جداً. يرجى استخدام كلمة مرور أقوى.';

  @override
  String get techRegistration_title => 'تسجيل الفني';

  @override
  String get techRegistration_subtitle => 'التسجيل كفني';

  @override
  String get techRegistration_fullNameLabel => 'الاسم الكامل';

  @override
  String get techRegistration_fullNameHint => 'أدخل الاسم الكامل';

  @override
  String get techRegistration_emailLabel => 'عنوان البريد الإلكتروني';

  @override
  String get techRegistration_emailHint => 'أدخل عنوان البريد الإلكتروني';

  @override
  String get techRegistration_phoneLabel => 'رقم الهاتف';

  @override
  String get techRegistration_phoneHint => 'أدخل رقم الهاتف';

  @override
  String get techRegistration_departmentLabel => 'القسم';

  @override
  String get techRegistration_departmentHint => 'اختر القسم';

  @override
  String get techRegistration_passwordLabel => 'كلمة المرور';

  @override
  String get techRegistration_passwordHint => '6 أحرف كحد أدنى';

  @override
  String get techRegistration_confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get techRegistration_confirmPasswordHint => 'أعد إدخال كلمة المرور';

  @override
  String get techRegistration_registerButton => 'التسجيل كفني';

  @override
  String get techRegistration_alreadyHaveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get pendingApproval_titlePending => 'الحساب في انتظار الموافقة';

  @override
  String get pendingApproval_titleRejected => 'تم رفض الموافقة على الحساب';

  @override
  String get pendingApproval_descriptionPending =>
      'تم إنشاء حساب الفني الخاص بك وتقديمه للموافقة من قِبل المسؤول. ستتلقى إشعاراً عند الموافقة على حسابك وتمكينك من الوصول إلى النظام.';

  @override
  String get pendingApproval_descriptionRejected =>
      'تم رفض طلب حساب الفني الخاص بك. يرجى مراجعة سبب الرفض أدناه والتواصل مع المسؤول إذا كان لديك استفسارات.';

  @override
  String get pendingApproval_currentStatus => 'الحالة الحالية';

  @override
  String get pendingApproval_statusPending => 'في انتظار موافقة المسؤول';

  @override
  String get pendingApproval_statusRejected => 'مرفوض';

  @override
  String get pendingApproval_rejectionReason => 'سبب الرفض:';

  @override
  String pendingApproval_rejectionWarning(int count) {
    return 'تحذير: هذا هو الرفض رقم $count. بعد 3 رفضات، سيُحذف حسابك نهائياً.';
  }

  @override
  String get pendingApproval_checkStatus => 'التحقق من حالة الموافقة';

  @override
  String get pendingApproval_checking => 'جارٍ التحقق...';

  @override
  String get pendingApproval_autoRefresh =>
      'يتم التحقق من الحالة تلقائياً كل 5 ثوانٍ';

  @override
  String get pendingApproval_contactAdmin =>
      'هل لديك استفسارات؟ تواصل مع المسؤول';

  @override
  String get pendingApproval_approved => 'تمت الموافقة على حسابك! مرحباً بك.';

  @override
  String pendingApproval_errorSigningOut(String error) {
    return 'خطأ في تسجيل الخروج: $error';
  }

  @override
  String get adminHome_dashboard => 'لوحة التحكم';

  @override
  String get adminHome_tools => 'الأدوات';

  @override
  String get adminHome_sharedTools => 'الأدوات المشتركة';

  @override
  String get adminHome_technicians => 'الفنيون';

  @override
  String get adminHome_reports => 'التقارير';

  @override
  String get adminHome_maintenance => 'الصيانة';

  @override
  String get adminHome_approvals => 'الموافقات';

  @override
  String get adminHome_toolIssues => 'مشاكل الأدوات';

  @override
  String get adminHome_toolHistory => 'سجل الأدوات';

  @override
  String get adminHome_notifications => 'الإشعارات';

  @override
  String get adminHome_myTools => 'أدواتي';

  @override
  String get adminHome_manageAdmins => 'إدارة المسؤولين';

  @override
  String get adminHome_settings => 'الإعدادات';

  @override
  String get adminHome_deleteAccount => 'حذف الحساب';

  @override
  String get adminHome_account => 'الحساب';

  @override
  String get adminHome_accountDetails => 'تفاصيل الحساب';

  @override
  String get adminHome_preferences => 'التفضيلات';

  @override
  String get adminHome_security => 'الأمان';

  @override
  String get adminHome_editName => 'تعديل الاسم';

  @override
  String get adminHome_fullName => 'الاسم الكامل';

  @override
  String get adminHome_enterFullName => 'أدخل اسمك الكامل';

  @override
  String get adminHome_nameUpdated => 'تم تحديث الاسم بنجاح';

  @override
  String get adminHome_failedToUpdateName => 'فشل في تحديث الاسم';

  @override
  String get adminHome_memberSince => 'عضو منذ';

  @override
  String get adminHome_role => 'الدور الوظيفي';

  @override
  String get adminHome_adminPanel => 'لوحة المسؤول';

  @override
  String get adminHome_somethingWentWrong => 'حدث خطأ ما';

  @override
  String get adminHome_tryLoggingOut => 'يرجى تسجيل الخروج والدخول مجدداً';

  @override
  String get adminHome_logoutAndTryAgain => 'تسجيل الخروج والمحاولة مجدداً';

  @override
  String get adminDashboard_title => 'لوحة التحكم';

  @override
  String get adminDashboard_overview =>
      'نظرة عامة على أدواتك وفنييك وموافقاتك.';

  @override
  String get adminDashboard_keyMetrics => 'المقاييس الرئيسية';

  @override
  String get adminDashboard_totalTools => 'إجمالي الأدوات';

  @override
  String get adminDashboard_technicians => 'الفنيون';

  @override
  String get adminDashboard_totalValue => 'القيمة الإجمالية';

  @override
  String get adminDashboard_maintenance => 'الصيانة';

  @override
  String get adminDashboard_last30Days => 'آخر 30 يوماً';

  @override
  String get adminDashboard_quickActions => 'الإجراءات السريعة';

  @override
  String get adminDashboard_addTool => 'إضافة أداة';

  @override
  String get adminDashboard_assignTool => 'إسناد أداة';

  @override
  String get adminDashboard_authorizeUsers => 'تفويض المستخدمين';

  @override
  String get adminDashboard_reports => 'التقارير';

  @override
  String get adminDashboard_toolIssues => 'مشاكل الأدوات';

  @override
  String get adminDashboard_approvals => 'الموافقات';

  @override
  String get adminDashboard_maintenanceSchedule => 'جدول الصيانة';

  @override
  String get adminDashboard_toolHistory => 'سجل الأدوات';

  @override
  String get adminDashboard_fleetStatus => 'حالة الأسطول';

  @override
  String get adminDashboard_toolStatus => 'حالة الأداة';

  @override
  String get adminDashboard_greetingMorning => 'صباح الخير';

  @override
  String get adminDashboard_greetingAfternoon => 'مساء الخير';

  @override
  String get adminDashboard_greetingEvening => 'مساء النور';

  @override
  String get adminDashboard_manageTools => 'إدارة أدواتك وفريقك الميداني';

  @override
  String get adminManagement_title => 'المسؤولون';

  @override
  String get adminManagement_loading => 'جارٍ تحميل المسؤولين...';

  @override
  String get adminManagement_noAdmins => 'لا يوجد مسؤولون بعد';

  @override
  String get adminManagement_tapPlusToAdd => 'انقر + لإضافة مسؤول';

  @override
  String get adminManagement_removeAdmin => 'إزالة المسؤول';

  @override
  String adminManagement_removeConfirm(String name) {
    return 'هل أنت متأكد من رغبتك في إزالة $name من صلاحيات المسؤول؟';
  }

  @override
  String get adminManagement_removeNote =>
      'سيظل حساب المصادقة الخاص به قائماً لكنه سيفقد امتيازات المسؤول.';

  @override
  String adminManagement_removed(String name) {
    return 'تمت إزالة $name من صلاحيات المسؤول';
  }

  @override
  String get adminManagement_removeFailed => 'فشل في إزالة المسؤول';

  @override
  String get adminManagement_unassigned => 'غير مُسنَد';

  @override
  String get adminNotification_title => 'الإشعارات';

  @override
  String get adminNotification_markAllRead => 'تحديد الكل كمقروء';

  @override
  String get adminNotification_errorLoading => 'خطأ في تحميل الإشعارات';

  @override
  String get adminNotification_empty => 'لا توجد إشعارات';

  @override
  String get adminNotification_emptyHint => 'ستظهر هنا طلبات الفنيين';

  @override
  String get adminNotification_technicianDetails => 'تفاصيل الفني:';

  @override
  String get adminNotification_time => 'الوقت';

  @override
  String get adminNotification_justNow => 'الآن';

  @override
  String adminNotification_minutesAgo(int count) {
    return 'منذ $count د';
  }

  @override
  String adminNotification_hoursAgo(int count) {
    return 'منذ $count س';
  }

  @override
  String adminNotification_daysAgo(int count) {
    return 'منذ $count ي';
  }

  @override
  String get adminNotification_markRead => 'تحديد كمقروء';

  @override
  String get adminNotification_markUnread => 'تحديد كغير مقروء';

  @override
  String get tools_title => 'الأدوات';

  @override
  String get tools_searchHint => 'البحث في الأدوات...';

  @override
  String get tools_emptyTitle => 'لم يتم العثور على أدوات';

  @override
  String get tools_emptySubtitle => 'أضف أول أداة للبدء';

  @override
  String get tools_addTool => 'إضافة أداة';

  @override
  String get tools_filterAll => 'الكل';

  @override
  String get tools_filterAvailable => 'متاح';

  @override
  String get tools_filterAssigned => 'مُسنَد';

  @override
  String get tools_filterMaintenance => 'صيانة';

  @override
  String get tools_deleteTool => 'حذف الأداة';

  @override
  String get tools_deleteConfirm =>
      'هل أنت متأكد من رغبتك في حذف هذه الأداة؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get toolDetail_title => 'تفاصيل الأداة';

  @override
  String get toolDetail_brand => 'العلامة التجارية';

  @override
  String get toolDetail_model => 'الطراز';

  @override
  String get toolDetail_serialNumber => 'الرقم التسلسلي';

  @override
  String get toolDetail_category => 'الفئة';

  @override
  String get toolDetail_condition => 'الحالة';

  @override
  String get toolDetail_location => 'الموقع';

  @override
  String get toolDetail_assignedTo => 'مُسنَدة إلى';

  @override
  String get toolDetail_purchaseDate => 'تاريخ الشراء';

  @override
  String get toolDetail_purchasePrice => 'سعر الشراء';

  @override
  String get toolDetail_currentValue => 'القيمة الحالية';

  @override
  String get toolDetail_notes => 'ملاحظات';

  @override
  String get toolDetail_status => 'الحالة';

  @override
  String get toolDetail_toolType => 'نوع الأداة';

  @override
  String get toolDetail_history => 'السجل';

  @override
  String get toolDetail_noHistory => 'لا يوجد سجل متاح';

  @override
  String get toolDetail_unassigned => 'غير مُسنَدة';

  @override
  String get toolDetail_returnTool => 'إعادة الأداة';

  @override
  String get toolDetail_assignTool => 'إسناد الأداة';

  @override
  String get toolDetail_editTool => 'تعديل الأداة';

  @override
  String get toolDetail_deleteTool => 'حذف الأداة';

  @override
  String get addTool_title => 'إضافة أداة';

  @override
  String get addTool_nameLabel => 'اسم الأداة';

  @override
  String get addTool_nameHint => 'أدخل اسم الأداة';

  @override
  String get addTool_nameRequired => 'يرجى إدخال اسم الأداة';

  @override
  String get addTool_categoryLabel => 'الفئة';

  @override
  String get addTool_categoryHint => 'اختر الفئة';

  @override
  String get addTool_categoryRequired => 'يرجى اختيار فئة';

  @override
  String get addTool_brandLabel => 'العلامة التجارية';

  @override
  String get addTool_brandHint => 'أدخل العلامة التجارية';

  @override
  String get addTool_modelLabel => 'الطراز';

  @override
  String get addTool_modelHint => 'أدخل الطراز';

  @override
  String get addTool_serialNumberLabel => 'الرقم التسلسلي';

  @override
  String get addTool_serialNumberHint => 'أدخل الرقم التسلسلي';

  @override
  String get addTool_purchaseDateLabel => 'تاريخ الشراء';

  @override
  String get addTool_purchasePriceLabel => 'سعر الشراء';

  @override
  String get addTool_currentValueLabel => 'القيمة الحالية';

  @override
  String get addTool_conditionLabel => 'الحالة';

  @override
  String get addTool_conditionHint => 'اختر الحالة';

  @override
  String get addTool_locationLabel => 'الموقع';

  @override
  String get addTool_locationHint => 'أدخل الموقع';

  @override
  String get addTool_toolTypeLabel => 'نوع الأداة';

  @override
  String get addTool_notesLabel => 'ملاحظات';

  @override
  String get addTool_notesHint => 'أدخل الملاحظات (اختياري)';

  @override
  String get addTool_saveButton => 'حفظ الأداة';

  @override
  String get addTool_success => 'تمت إضافة الأداة بنجاح!';

  @override
  String get addTool_attachPhoto => 'إرفاق صورة (اختياري)';

  @override
  String get editTool_title => 'تعديل الأداة';

  @override
  String get editTool_saveButton => 'تحديث الأداة';

  @override
  String get editTool_success => 'تم تحديث الأداة بنجاح!';

  @override
  String get toolHistory_title => 'سجل الأدوات';

  @override
  String get toolHistory_noHistory => 'لم يتم العثور على سجلات';

  @override
  String get toolHistory_allHistory => 'سجل جميع الأدوات';

  @override
  String get toolInstances_title => 'نسخ الأداة';

  @override
  String get toolInstances_empty => 'لم يتم العثور على نسخ';

  @override
  String get toolIssues_title => 'مشاكل الأدوات';

  @override
  String get toolIssues_all => 'الكل';

  @override
  String get toolIssues_open => 'مفتوح';

  @override
  String get toolIssues_inProgress => 'قيد التنفيذ';

  @override
  String get toolIssues_resolved => 'محلول';

  @override
  String get toolIssues_closed => 'مغلق';

  @override
  String get toolIssues_empty => 'لم يتم العثور على مشاكل';

  @override
  String get toolIssues_emptyHint => 'لم يتم الإبلاغ عن أي مشاكل في الأدوات';

  @override
  String get toolIssues_reportIssue => 'الإبلاغ عن مشكلة';

  @override
  String get addToolIssue_title => 'الإبلاغ عن مشكلة في أداة';

  @override
  String get addToolIssue_selectTool => 'اختر الأداة *';

  @override
  String get addToolIssue_issueDetails => 'تفاصيل المشكلة';

  @override
  String get addToolIssue_issueType => 'نوع المشكلة';

  @override
  String get addToolIssue_priority => 'الأولوية';

  @override
  String get addToolIssue_description => 'الوصف *';

  @override
  String get addToolIssue_descriptionHint => 'صف المشكلة بالتفصيل';

  @override
  String get addToolIssue_descriptionRequired => 'يرجى تقديم وصف للمشكلة';

  @override
  String get addToolIssue_additionalInfo => 'معلومات إضافية';

  @override
  String get addToolIssue_location => 'الموقع';

  @override
  String get addToolIssue_locationHint => 'أين حدثت المشكلة؟ (اختياري)';

  @override
  String get addToolIssue_estimatedCost => 'التكلفة التقديرية';

  @override
  String get addToolIssue_estimatedCostHint =>
      'تكلفة الإصلاح/الاستبدال (اختياري)';

  @override
  String get addToolIssue_priorityGuidelines => 'إرشادات الأولوية';

  @override
  String get addToolIssue_criticalGuideline =>
      'خطر على السلامة أو تعطل كامل للأداة';

  @override
  String get addToolIssue_highGuideline =>
      'الأداة غير قابلة للاستخدام دون خطر على السلامة';

  @override
  String get addToolIssue_mediumGuideline => 'الأداة تعمل جزئياً';

  @override
  String get addToolIssue_lowGuideline =>
      'مشكلة طفيفة والأداة لا تزال قابلة للاستخدام';

  @override
  String get addToolIssue_submitButton => 'إرسال التقرير';

  @override
  String get addToolIssue_success => 'تم الإبلاغ عن المشكلة بنجاح!';

  @override
  String get addToolIssue_toolNotFound =>
      'الأداة المختارة غير موجودة. يرجى التحديث والمحاولة مجدداً.';

  @override
  String get addToolIssue_tableNotFound =>
      'جدول مشاكل الأدوات غير موجود. يرجى التواصل مع المسؤول.';

  @override
  String get addToolIssue_sessionExpired =>
      'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.';

  @override
  String get addToolIssue_permissionDenied =>
      'تم رفض الإذن. قد لا تملك صلاحية الإبلاغ عن المشاكل.';

  @override
  String get addToolIssue_fillRequired => 'يرجى تعبئة جميع الحقول المطلوبة.';

  @override
  String get addToolIssue_networkError =>
      'خطأ في الشبكة. يرجى التحقق من اتصالك والمحاولة مجدداً.';

  @override
  String get technicians_title => 'الفنيون';

  @override
  String get technicians_subtitle =>
      'إدارة الفنيين النشطين وغير النشطين والمُسنَدة إليهم أدوات';

  @override
  String get technicians_searchHint => 'البحث في الفنيين...';

  @override
  String get technicians_emptyTitle => 'لم يتم العثور على فنيين';

  @override
  String get technicians_emptySubtitle => 'أضف أول فني للبدء';

  @override
  String get technicians_filterAll => 'الكل';

  @override
  String get technicians_filterActive => 'نشط';

  @override
  String get technicians_filterInactive => 'غير نشط';

  @override
  String get technicians_filterWithTools => 'لديهم أدوات';

  @override
  String get technicians_filterWithoutTools => 'بدون أدوات';

  @override
  String get technicians_deleteTitle => 'حذف الفني';

  @override
  String technicians_deleteConfirm(String name) {
    return 'هل أنت متأكد من رغبتك في حذف $name؟';
  }

  @override
  String get technicians_noTools => 'لا توجد أدوات';

  @override
  String get technicians_noDepartment => 'لا يوجد قسم';

  @override
  String get technicianDetail_profile => 'الملف الشخصي';

  @override
  String get technicianDetail_tools => 'الأدوات';

  @override
  String get technicianDetail_issues => 'المشاكل';

  @override
  String get technicianDetail_editTechnician => 'تعديل الفني';

  @override
  String get technicianDetail_deleteTechnician => 'حذف الفني';

  @override
  String get technicianDetail_contactInfo => 'معلومات التواصل';

  @override
  String get technicianDetail_employmentDetails => 'تفاصيل التوظيف';

  @override
  String get technicianDetail_statusInfo => 'معلومات الحالة';

  @override
  String get technicianDetail_employeeId => 'رقم الموظف';

  @override
  String get technicianDetail_department => 'القسم';

  @override
  String get technicianDetail_hireDate => 'تاريخ التعيين';

  @override
  String get technicianDetail_created => 'تاريخ الإنشاء';

  @override
  String get technicianDetail_noTools => 'لا توجد أدوات مُسنَدة';

  @override
  String get technicianDetail_noToolsDesc => 'لم يتم إسناد أي أدوات لهذا الفني';

  @override
  String get technicianDetail_noIssues => 'لا توجد مشاكل مُبلَّغ عنها';

  @override
  String get technicianDetail_noIssuesDesc =>
      'لم يُبلَّغ عن أي مشاكل في الأدوات لهذا الفني';

  @override
  String get technicianDetail_deleteWarning => 'سيتم حذف ما يلي نهائياً:';

  @override
  String get technicianDetail_deleteLine1 => 'سجل الفني';

  @override
  String get technicianDetail_deleteLine2 => 'جميع البيانات المرتبطة';

  @override
  String get technicianDetail_deleteCannotUndo =>
      'لا يمكن التراجع عن هذا الإجراء!';

  @override
  String get technicianDetail_deleteHasTools =>
      'لا يمكن حذف فني لديه أدوات مُسنَدة. يرجى إعادة إسناد الأدوات أو استردادها أولاً.';

  @override
  String get technicianHome_account => 'الحساب';

  @override
  String get technicianHome_accountDetails => 'تفاصيل الحساب';

  @override
  String get technicianHome_preferences => 'التفضيلات';

  @override
  String get technicianHome_security => 'الأمان';

  @override
  String get technicianHome_editName => 'تعديل الاسم';

  @override
  String get technicianHome_fullName => 'الاسم الكامل';

  @override
  String get technicianHome_enterFullName => 'أدخل اسمك الكامل';

  @override
  String get technicianHome_memberSince => 'عضو منذ';

  @override
  String get technicianHome_role => 'الدور الوظيفي';

  @override
  String get technicianHome_administrator => 'مسؤول';

  @override
  String get technicianHome_technician => 'فني';

  @override
  String get technicianHome_noNotifications => 'لا توجد إشعارات';

  @override
  String get technicianHome_notificationsHint =>
      'ستظهر هنا الإشعارات عند استلام طلبات الأدوات';

  @override
  String get technicianHome_requestAccountDeletion => 'طلب حذف الحساب';

  @override
  String get techDashboard_greetingMorning => 'صباح الخير';

  @override
  String get techDashboard_greetingAfternoon => 'مساء الخير';

  @override
  String get techDashboard_greetingEvening => 'مساء النور';

  @override
  String get techDashboard_welcome =>
      'إدارة أدواتك والوصول إلى الموارد المشتركة';

  @override
  String get techDashboard_sharedTools => 'الأدوات المشتركة';

  @override
  String get techDashboard_seeAll => 'عرض الكل';

  @override
  String get techDashboard_myTools => 'أدواتي';

  @override
  String get techDashboard_noTools => 'لا توجد أدوات متاحة';

  @override
  String get techDashboard_noToolsHint =>
      'ليس لديك أدوات مُسنَدة. يمكنك إضافة أول أداة أو طلب إسناد أداة.';

  @override
  String get techDashboard_noSharedTools => 'لا توجد أدوات مشتركة متاحة';

  @override
  String get techDashboard_noAssignedTools => 'لم يتم إسناد أي أدوات بعد';

  @override
  String get techDashboard_noAssignedToolsHint =>
      'أضف أو سجّل الأدوات التي بحوزتك لتظهر هنا.';

  @override
  String get techDashboard_shared => 'مشترك';

  @override
  String get techDashboard_request => 'طلب';

  @override
  String get myTools_title => 'أدواتي';

  @override
  String get myTools_searchHint => 'البحث في الأدوات...';

  @override
  String get myTools_categoryFilter => 'الفئة';

  @override
  String get myTools_statusFilter => 'الحالة';

  @override
  String get myTools_empty => 'لم يتم العثور على أدوات';

  @override
  String get myTools_emptyHint => 'أضف أول أداة للبدء';

  @override
  String get myTools_addButton => 'إضافة أداة';

  @override
  String get addTechnician_addTitle => 'إضافة فني';

  @override
  String get addTechnician_editTitle => 'تعديل الفني';

  @override
  String get addTechnician_addSubtitle =>
      'أضف الفنيين ليتمكنوا من استلام الإسنادات والوصول إلى الأدوات.';

  @override
  String get addTechnician_editSubtitle =>
      'حدّث بيانات الفني للحفاظ على دقة الإسنادات.';

  @override
  String get addTechnician_nameLabel => 'الاسم الكامل';

  @override
  String get addTechnician_nameHint => 'أدخل الاسم الكامل';

  @override
  String get addTechnician_employeeIdLabel => 'رقم الموظف';

  @override
  String get addTechnician_employeeIdHint => 'أدخل رقم الموظف (اختياري)';

  @override
  String get addTechnician_phoneLabel => 'رقم الهاتف';

  @override
  String get addTechnician_phoneHint => 'أدخل رقم الهاتف';

  @override
  String get addTechnician_emailLabel => 'عنوان البريد الإلكتروني';

  @override
  String get addTechnician_emailHint => 'أدخل عنوان البريد الإلكتروني';

  @override
  String get addTechnician_emailInvalid => 'أدخل عنوان بريد إلكتروني صحيح';

  @override
  String get addTechnician_departmentLabel => 'القسم';

  @override
  String get addTechnician_departmentHint => 'اختر القسم';

  @override
  String get addTechnician_statusLabel => 'الحالة';

  @override
  String get addTechnician_hireDateHint => 'اختر تاريخ التعيين';

  @override
  String get addTechnician_addButton => 'إضافة فني';

  @override
  String get addTechnician_updateButton => 'تحديث الفني';

  @override
  String get addTechnician_addSuccess => 'تمت إضافة الفني بنجاح!';

  @override
  String addTechnician_inviteEmailSent(String email) {
    return 'تم إرسال بريد الدعوة إلى $email';
  }

  @override
  String get addTechnician_inviteHint =>
      'يجب على الفني استخدام بريد الدعوة لتعيين كلمة المرور.';

  @override
  String get addTechnician_updateSuccess => 'تم تحديث الفني بنجاح!';

  @override
  String get addTechnician_nameRequired => 'يرجى إدخال اسم الفني';

  @override
  String get addTechnician_chooseFromGallery => 'الاختيار من المعرض';

  @override
  String get addTechnician_takePhoto => 'التقاط صورة';

  @override
  String get addTechnician_removePhoto => 'إزالة الصورة';

  @override
  String get settings_title => 'الإعدادات';

  @override
  String get settings_accountSection => 'الحساب';

  @override
  String get settings_accountDetailsSection => 'تفاصيل الحساب';

  @override
  String get settings_accountManagementSection => 'إدارة الحساب';

  @override
  String get settings_preferencesSection => 'التفضيلات';

  @override
  String get settings_notificationsSection => 'الإشعارات';

  @override
  String get settings_dataBackupSection => 'البيانات والنسخ الاحتياطي';

  @override
  String get settings_aboutSection => 'حول التطبيق';

  @override
  String get settings_languageLabel => 'اللغة';

  @override
  String get settings_currencyLabel => 'العملة';

  @override
  String get settings_pushNotifications => 'إشعارات الدفع';

  @override
  String get settings_pushNotificationsSubtitle =>
      'استلام تذكيرات الصيانة والتحديثات';

  @override
  String get settings_autoBackup => 'النسخ الاحتياطي التلقائي';

  @override
  String get settings_autoBackupSubtitle =>
      'نسخ البيانات احتياطياً تلقائياً إلى السحابة';

  @override
  String get settings_exportData => 'تصدير البيانات';

  @override
  String get settings_exportDataSubtitle => 'تنزيل بياناتك بصيغة CSV';

  @override
  String get settings_importData => 'استيراد البيانات';

  @override
  String get settings_importDataSubtitle => 'الاستعادة من ملف النسخ الاحتياطي';

  @override
  String get settings_importDataMessage =>
      'لاستيراد البيانات، يرجى التواصل مع الدعم الفني. سنساعدك في استعادة بياناتك من ملف النسخ الاحتياطي.';

  @override
  String get settings_appVersion => 'إصدار التطبيق';

  @override
  String get settings_helpSupport => 'المساعدة والدعم';

  @override
  String get settings_helpSupportSubtitle =>
      'الحصول على المساعدة والتواصل مع الدعم';

  @override
  String get settings_privacyPolicy => 'سياسة الخصوصية';

  @override
  String get settings_privacyPolicySubtitle => 'قراءة سياسة الخصوصية';

  @override
  String get settings_termsOfService => 'شروط الخدمة';

  @override
  String get settings_termsOfServiceSubtitle => 'قراءة شروط الخدمة';

  @override
  String get settings_selectLanguage => 'اختر اللغة';

  @override
  String get settings_selectCurrency => 'اختر العملة';

  @override
  String get settings_deleteAccount => 'حذف الحساب';

  @override
  String get settings_deleteAccountSubtitle => 'حذف حسابك وبياناتك نهائياً';

  @override
  String get settings_requestAccountDeletion => 'طلب حذف الحساب';

  @override
  String get settings_requestAccountDeletionSubtitle =>
      'اطلب من مسؤولك حذف حسابك';

  @override
  String get settings_versionInfo => 'معلومات الإصدار';

  @override
  String get settings_rgsToolsManager => 'مدير الأدوات';

  @override
  String get settings_couldNotOpenPage => 'تعذّر فتح صفحة الدعم';

  @override
  String settings_exportSuccess(int count) {
    return 'تم تصدير البيانات بنجاح! تم إنشاء $count ملف/ملفات.';
  }

  @override
  String settings_exportError(String error) {
    return 'خطأ في تصدير البيانات: $error';
  }

  @override
  String get currency_usd => 'الدولار الأمريكي';

  @override
  String get currency_eur => 'اليورو';

  @override
  String get currency_gbp => 'الجنيه الإسترليني';

  @override
  String get currency_aed => 'الدرهم الإماراتي';

  @override
  String get reports_title => 'التقارير';

  @override
  String get reports_toolsOverview => 'نظرة عامة على الأدوات';

  @override
  String get reports_technicianActivity => 'نشاط الفنيين';

  @override
  String get reports_maintenanceReport => 'تقرير الصيانة';

  @override
  String get reports_exportReport => 'تصدير التقرير';

  @override
  String get reports_generateReport => 'إنشاء تقرير';

  @override
  String get reports_noData => 'لا تتوفر بيانات لهذا التقرير';

  @override
  String get reports_dateRange => 'نطاق التاريخ';

  @override
  String get reports_last7Days => 'آخر 7 أيام';

  @override
  String get reports_last30Days => 'آخر 30 يوماً';

  @override
  String get reports_last90Days => 'آخر 90 يوماً';

  @override
  String get reports_custom => 'مخصص';

  @override
  String get maintenance_title => 'الصيانة';

  @override
  String get maintenance_schedule => 'جدولة الصيانة';

  @override
  String get maintenance_noScheduled => 'لا توجد صيانة مجدولة';

  @override
  String get maintenance_upcoming => 'قادمة';

  @override
  String get maintenance_overdue => 'متأخرة';

  @override
  String get maintenance_completed => 'مكتملة';

  @override
  String get checkin_title => 'تسجيل الدخول / الخروج';

  @override
  String get checkin_scanBarcode => 'مسح الباركود';

  @override
  String get checkin_manualEntry => 'إدخال يدوي';

  @override
  String get checkin_toolId => 'ID الأداة';

  @override
  String get checkin_checkInButton => 'تسجيل الدخول';

  @override
  String get checkin_checkOutButton => 'تسجيل الخروج';

  @override
  String get sharedTools_title => 'الأدوات المشتركة';

  @override
  String get sharedTools_empty => 'لا توجد أدوات مشتركة متاحة';

  @override
  String get sharedTools_emptyHint => 'الأدوات المحددة كمشتركة ستظهر هنا';

  @override
  String get sharedTools_badgeIn => 'تسجيل الاستلام';

  @override
  String get sharedTools_badgeOut => 'تسجيل الإرجاع';

  @override
  String get sharedTools_currentHolder => 'الحائز الحالي';

  @override
  String get sharedTools_noCurrentHolder => 'لا يوجد حائز حالي';

  @override
  String get bulkImport_title => 'الاستيراد الجماعي';

  @override
  String get bulkImport_selectFile => 'اختر ملف CSV';

  @override
  String get bulkImport_importButton => 'استيراد';

  @override
  String get bulkImport_preview => 'معاينة';

  @override
  String bulkImport_rowsFound(int count) {
    return 'تم العثور على $count صفوف';
  }

  @override
  String bulkImport_success(int count) {
    return 'تم استيراد $count أداة بنجاح';
  }

  @override
  String bulkImport_error(String error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String get permanentAssignment_title => 'الإسناد الدائم';

  @override
  String get permanentAssignment_selectTechnician => 'اختر الفني';

  @override
  String get permanentAssignment_selectTools => 'اختر الأدوات';

  @override
  String get permanentAssignment_assignButton => 'إسناد';

  @override
  String get permanentAssignment_success => 'تم إسناد الأدوات بنجاح';

  @override
  String get reassignTool_title => 'إعادة إسناد الأداة';

  @override
  String get reassignTool_currentTechnician => 'الفني الحالي';

  @override
  String get reassignTool_newTechnician => 'الفني الجديد';

  @override
  String get reassignTool_reassignButton => 'إعادة الإسناد';

  @override
  String get reassignTool_success => 'تمت إعادة إسناد الأداة بنجاح';

  @override
  String get requestNewTool_title => 'طلب جديد';

  @override
  String get requestNewTool_subtitle =>
      'قدّم طلباً للأدوات أو الإسنادات أو النقل أو الصيانة';

  @override
  String get requestNewTool_requestType => 'نوع الطلب';

  @override
  String get requestNewTool_requestInfo => 'معلومات الطلب';

  @override
  String get requestNewTool_titleLabel => 'العنوان (اختياري)';

  @override
  String get requestNewTool_titleHint => 'يتم إنشاؤه تلقائياً إذا تُرك فارغاً';

  @override
  String get requestNewTool_descriptionLabel => 'الوصف (اختياري)';

  @override
  String get requestNewTool_descriptionHint =>
      'يتم إنشاؤه تلقائياً إذا تُرك فارغاً';

  @override
  String get requestNewTool_justification => 'المبرر / السبب *';

  @override
  String get requestNewTool_neededBy => 'مطلوب بحلول (اختياري)';

  @override
  String get requestNewTool_selectDate => 'اختر التاريخ';

  @override
  String get requestNewTool_siteLocation => 'الموقع / المنشأة';

  @override
  String get requestNewTool_siteLocationHint => 'مثال: المبنى أ، الطابق 3';

  @override
  String get requestNewTool_submitButton => 'إرسال الطلب';

  @override
  String get requestNewTool_success => 'تم إرسال الطلب بنجاح!';

  @override
  String get requestNewTool_toolDetails => 'تفاصيل الأداة';

  @override
  String get requestNewTool_assignmentDetails => 'تفاصيل الإسناد';

  @override
  String get requestNewTool_transferDetails => 'تفاصيل النقل';

  @override
  String get requestNewTool_maintenanceDetails => 'تفاصيل الصيانة';

  @override
  String get requestNewTool_disposalDetails => 'تفاصيل الإتلاف';

  @override
  String get requestNewTool_toolName => 'اسم الأداة';

  @override
  String get requestNewTool_toolSerial => 'الرقم التسلسلي للأداة (اختياري)';

  @override
  String get requestNewTool_quantity => 'الكمية';

  @override
  String get requestNewTool_unitPrice => 'سعر الوحدة (AED)';

  @override
  String get requestNewTool_totalCost => 'التكلفة الإجمالية (AED)';

  @override
  String get requestNewTool_supplier => 'المورّد (اختياري)';

  @override
  String get requestNewTool_assignTo => 'إسناد إلى (اسمك أو اسم فني آخر)';

  @override
  String get requestNewTool_project => 'المشروع / الموقع';

  @override
  String get requestNewTool_fromLocation => 'من الموقع';

  @override
  String get requestNewTool_toLocation => 'إلى الموقع';

  @override
  String get requestNewTool_maintenanceType => 'نوع الصيانة';

  @override
  String get requestNewTool_currentCondition => 'الحالة الراهنة';

  @override
  String get requestNewTool_attachPhoto => 'إرفاق صورة أو مواصفات (اختياري)';

  @override
  String get requestNewTool_enterValidNumber => 'أدخل رقماً صحيحاً';

  @override
  String get requestType_toolPurchase => 'شراء أداة';

  @override
  String get requestType_toolAssignment => 'إسناد أداة';

  @override
  String get requestType_transfer => 'نقل';

  @override
  String get requestType_maintenance => 'صيانة';

  @override
  String get requestType_toolDisposal => 'إتلاف أداة';
}
