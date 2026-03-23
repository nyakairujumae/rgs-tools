// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'उपकरण';

  @override
  String get common_cancel => 'रद्द करें';

  @override
  String get common_save => 'सहेजें';

  @override
  String get common_delete => 'हटाएं';

  @override
  String get common_edit => 'संपादित करें';

  @override
  String get common_close => 'बंद करें';

  @override
  String get common_ok => 'ठीक है';

  @override
  String get common_retry => 'पुनः प्रयास करें';

  @override
  String get common_remove => 'निकालें';

  @override
  String get common_view => 'देखें';

  @override
  String get common_back => 'वापस';

  @override
  String get common_search => 'खोजें';

  @override
  String get common_loading => 'लोड हो रहा है...';

  @override
  String get common_error => 'त्रुटि';

  @override
  String get common_success => 'सफलता';

  @override
  String get common_unknown => 'अज्ञात';

  @override
  String get common_notAvailable => 'उपलब्ध नहीं';

  @override
  String get common_required => 'आवश्यक';

  @override
  String get common_optional => 'वैकल्पिक';

  @override
  String get common_all => 'सभी';

  @override
  String get common_none => 'कोई नहीं';

  @override
  String get common_yes => 'हाँ';

  @override
  String get common_no => 'नहीं';

  @override
  String get common_signOut => 'साइन आउट';

  @override
  String get common_logout => 'लॉगआउट';

  @override
  String get common_settings => 'सेटिंग्स';

  @override
  String get common_notifications => 'सूचनाएं';

  @override
  String get common_email => 'Email';

  @override
  String get common_password => 'पासवर्ड';

  @override
  String get common_name => 'नाम';

  @override
  String get common_phone => 'फ़ोन';

  @override
  String get common_status => 'स्थिति';

  @override
  String get common_active => 'सक्रिय';

  @override
  String get common_inactive => 'निष्क्रिय';

  @override
  String get common_camera => 'कैमरा';

  @override
  String get common_gallery => 'गैलरी';

  @override
  String get common_addImage => 'छवि जोड़ें';

  @override
  String get common_selectImageSource => 'छवि स्रोत चुनें';

  @override
  String common_failedToPickImage(String error) {
    return 'छवि चुनने में विफल: $error';
  }

  @override
  String get common_somethingWentWrong =>
      'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get common_offlineBanner => 'ऑफलाइन — कैश डेटा दिखाया जा रहा है';

  @override
  String get common_noImage => 'कोई छवि नहीं';

  @override
  String get status_available => 'उपलब्ध';

  @override
  String get status_assigned => 'असाइन किया गया';

  @override
  String get status_inUse => 'उपयोग में';

  @override
  String get status_maintenance => 'रखरखाव';

  @override
  String get status_retired => 'सेवानिवृत्त';

  @override
  String get status_lost => 'खोया हुआ';

  @override
  String get priority_low => 'कम';

  @override
  String get priority_medium => 'मध्यम';

  @override
  String get priority_high => 'उच्च';

  @override
  String get priority_critical => 'अत्यंत महत्वपूर्ण';

  @override
  String get priority_normal => 'सामान्य';

  @override
  String get priority_urgent => 'अत्यावश्यक';

  @override
  String get validation_required => 'यह फ़ील्ड आवश्यक है';

  @override
  String get validation_emailRequired => 'कृपया अपना Email दर्ज करें';

  @override
  String get validation_emailInvalid => 'कृपया एक मान्य Email पता दर्ज करें';

  @override
  String get validation_passwordRequired => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get validation_passwordMinLength =>
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get validation_passwordMismatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get validation_nameRequired => 'कृपया अपना पूरा नाम दर्ज करें';

  @override
  String get validation_phoneRequired => 'कृपया अपना फ़ोन नंबर दर्ज करें';

  @override
  String get validation_pleaseSelectTool => 'कृपया एक उपकरण चुनें';

  @override
  String get roleSelection_subtitle => 'उपकरण ट्रैकिंग • असाइनमेंट • इन्वेंटरी';

  @override
  String get roleSelection_registerAdmin => 'एडमिन के रूप में पंजीकरण करें';

  @override
  String get roleSelection_continueAdmin => 'एडमिन के रूप में जारी रखें';

  @override
  String get roleSelection_registerTechnician =>
      'तकनीशियन के रूप में पंजीकरण करें';

  @override
  String get roleSelection_continueTechnician =>
      'तकनीशियन के रूप में जारी रखें';

  @override
  String get roleSelection_alreadyHaveAccount => 'पहले से खाता है? ';

  @override
  String get roleSelection_signIn => 'साइन इन करें';

  @override
  String get roleSelection_adminClosedError =>
      'एडमिन पंजीकरण बंद है। कृपया एडमिन आमंत्रण का अनुरोध करें।';

  @override
  String get login_title => 'साइन इन';

  @override
  String get login_emailLabel => 'Email पता';

  @override
  String get login_emailHint => 'अपना Email दर्ज करें';

  @override
  String get login_passwordLabel => 'पासवर्ड';

  @override
  String get login_passwordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get login_signInButton => 'साइन इन';

  @override
  String get login_forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get login_orContinueWith => 'या इससे जारी रखें';

  @override
  String get login_or => 'या';

  @override
  String get login_google => 'Google';

  @override
  String get login_apple => 'Apple';

  @override
  String get login_registerPrompt => 'खाता नहीं है? यहाँ पंजीकरण करें';

  @override
  String get login_registerSubtext => 'एडमिन या तकनीशियन पंजीकरण चुनें';

  @override
  String get login_welcomeBack => 'वापसी पर स्वागत है';

  @override
  String get login_welcomeBackSubtitle => 'अपने खाते में साइन इन करें';

  @override
  String get login_successMessage => 'स्वागत है! सफलतापूर्वक साइन इन किया।';

  @override
  String get login_accessDenied => 'प्रवेश अस्वीकृत: अमान्य एडमिन क्रेडेंशियल';

  @override
  String get login_emailRequiredFirst => 'कृपया पहले अपना Email पता दर्ज करें';

  @override
  String get login_passwordResetSent =>
      'पासवर्ड रीसेट Email भेजा गया! अपना इनबॉक्स देखें।';

  @override
  String get login_appleCancelled => 'Apple साइन-इन रद्द किया गया।';

  @override
  String get login_appleFailed => 'Apple साइन-इन विफल रहा।';

  @override
  String get login_oauthAccountExists =>
      'यह Email पहले से पंजीकृत है। कृपया अपने Email और पासवर्ड से साइन इन करें।';

  @override
  String get login_emailDomainNotAllowed =>
      'Email डोमेन की अनुमति नहीं है। कृपया अनुमोदित Email पते का उपयोग करें।';

  @override
  String get login_resetPasswordDialogTitle => 'पासवर्ड रीसेट करें';

  @override
  String get login_resetPasswordDialogMessage =>
      'अपना Email पता दर्ज करें और हम आपको पासवर्ड रीसेट लिंक भेजेंगे।';

  @override
  String get login_resetPasswordEmailHint => 'your.email@example.com';

  @override
  String get login_resetPasswordSendButton => 'रीसेट लिंक भेजें';

  @override
  String get login_resetPasswordSuccessTitle => 'Email भेजा गया!';

  @override
  String login_resetPasswordSuccessMessage(String email) {
    return 'हमने $email पर पासवर्ड रीसेट लिंक भेजा है। कृपया अपना इनबॉक्स देखें और पासवर्ड रीसेट करने के निर्देशों का पालन करें।';
  }

  @override
  String get register_createAccount => 'शुरू करने के लिए अपना खाता बनाएं।';

  @override
  String get register_fullNameLabel => 'पूरा नाम';

  @override
  String get register_emailLabel => 'Email';

  @override
  String get register_passwordLabel => 'पासवर्ड';

  @override
  String get register_confirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get register_phoneLabel => 'फ़ोन नंबर';

  @override
  String get register_departmentLabel => 'विभाग';

  @override
  String get register_roleLabel => 'भूमिका';

  @override
  String get register_createAccountButton => 'खाता बनाएं';

  @override
  String get register_signInLink => 'पहले से खाता है? साइन इन करें';

  @override
  String get register_backToRoleSelection => 'भूमिका चयन पर वापस जाएं';

  @override
  String get register_checkYourEmail => 'अपना Email देखें';

  @override
  String get register_confirmationEmailSent =>
      'हमने इस पर एक पुष्टिकरण Email भेजा है:';

  @override
  String get register_confirmationInstructions =>
      'कृपया अपना Email देखें और अपने खाते की पुष्टि करने के लिए लिंक पर क्लिक करें। पुष्टि के बाद, आपका खाता एडमिन अनुमोदन के लिए लंबित रहेगा।';

  @override
  String get register_goToLogin => 'लॉगिन पर जाएं';

  @override
  String get register_pendingApproval =>
      'आपका खाता एडमिन अनुमोदन के लिए लंबित है। अनुमोदित होने पर आपको सूचित किया जाएगा।';

  @override
  String get register_emailFormatValidation =>
      'कृपया एक मान्य Email पता दर्ज करें (जैसे, name@example.com)';

  @override
  String get resetPassword_title => 'पासवर्ड रीसेट करें';

  @override
  String get resetPassword_subtitle => 'नीचे अपना नया पासवर्ड दर्ज करें';

  @override
  String get resetPassword_newPasswordLabel => 'नया पासवर्ड';

  @override
  String get resetPassword_confirmLabel => 'नए पासवर्ड की पुष्टि करें';

  @override
  String get resetPassword_button => 'पासवर्ड रीसेट करें';

  @override
  String get resetPassword_backToLogin => 'लॉगिन पर वापस जाएं';

  @override
  String get resetPassword_successMessage =>
      'पासवर्ड सफलतापूर्वक सेट किया गया! रीडायरेक्ट हो रहा है...';

  @override
  String get resetPassword_sessionExpired =>
      'सत्र समाप्त हो गया। कृपया आमंत्रण लिंक फिर से खोलें।';

  @override
  String get adminRegistration_title => 'एडमिन पंजीकरण';

  @override
  String get adminRegistration_subtitle => 'एडमिन के रूप में पंजीकरण करें';

  @override
  String get adminRegistration_fullNameLabel => 'पूरा नाम';

  @override
  String get adminRegistration_fullNameHint => 'पूरा नाम दर्ज करें';

  @override
  String get adminRegistration_emailLabel => 'Email पता';

  @override
  String get adminRegistration_emailHint => 'कंपनी Email दर्ज करें';

  @override
  String get adminRegistration_passwordLabel => 'पासवर्ड';

  @override
  String get adminRegistration_passwordHint => 'न्यूनतम 6 अक्षर';

  @override
  String get adminRegistration_confirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get adminRegistration_confirmPasswordHint =>
      'पासवर्ड दोबारा दर्ज करें';

  @override
  String get adminRegistration_registerButton =>
      'एडमिन के रूप में पंजीकरण करें';

  @override
  String get adminRegistration_alreadyHaveAccount => 'पहले से खाता है?';

  @override
  String get adminRegistration_loadingRole => 'एडमिन भूमिका लोड हो रही है...';

  @override
  String get adminRegistration_positionNotConfigured =>
      'सुपर एडमिन पद कॉन्फ़िगर नहीं है। कृपया एडमिन माइग्रेशन चलाएं।';

  @override
  String get adminRegistration_accountCreated =>
      'एडमिन खाता सफलतापूर्वक बनाया गया! स्वागत है।';

  @override
  String adminRegistration_invalidDomain(String domains) {
    return 'एडमिन पंजीकरण के लिए अमान्य Email डोमेन। $domains का उपयोग करें';
  }

  @override
  String get adminRegistration_checkEmailConfirmation =>
      'कृपया अपना Email देखें और अपने एडमिन खाते की पुष्टि करने के लिए लिंक पर क्लिक करें। लॉगिन करने से पहले Email की पुष्टि अनिवार्य है।';

  @override
  String get adminRegistration_afterConfirmation =>
      'Email की पुष्टि करने के बाद, आप अपने एडमिन क्रेडेंशियल से लॉगिन कर सकते हैं।';

  @override
  String get adminRegistration_connectionError =>
      'कनेक्शन त्रुटि: कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get adminRegistration_emailAlreadyRegistered =>
      'यह Email पहले से पंजीकृत है। कृपया कोई अन्य Email उपयोग करें या लॉगिन करने का प्रयास करें।';

  @override
  String get adminRegistration_invalidEmail =>
      'अमान्य Email पता। कृपया जांचें और पुनः प्रयास करें।';

  @override
  String get adminRegistration_weakPassword =>
      'पासवर्ड बहुत कमज़ोर है। कृपया एक मज़बूत पासवर्ड उपयोग करें।';

  @override
  String get techRegistration_title => 'तकनीशियन पंजीकरण';

  @override
  String get techRegistration_subtitle => 'तकनीशियन के रूप में पंजीकरण करें';

  @override
  String get techRegistration_fullNameLabel => 'पूरा नाम';

  @override
  String get techRegistration_fullNameHint => 'पूरा नाम दर्ज करें';

  @override
  String get techRegistration_emailLabel => 'Email पता';

  @override
  String get techRegistration_emailHint => 'Email पता दर्ज करें';

  @override
  String get techRegistration_phoneLabel => 'फ़ोन नंबर';

  @override
  String get techRegistration_phoneHint => 'फ़ोन नंबर दर्ज करें';

  @override
  String get techRegistration_departmentLabel => 'विभाग';

  @override
  String get techRegistration_departmentHint => 'विभाग चुनें';

  @override
  String get techRegistration_passwordLabel => 'पासवर्ड';

  @override
  String get techRegistration_passwordHint => 'न्यूनतम 6 अक्षर';

  @override
  String get techRegistration_confirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get techRegistration_confirmPasswordHint => 'पासवर्ड दोबारा दर्ज करें';

  @override
  String get techRegistration_registerButton =>
      'तकनीशियन के रूप में पंजीकरण करें';

  @override
  String get techRegistration_alreadyHaveAccount => 'पहले से खाता है?';

  @override
  String get pendingApproval_titlePending => 'खाता अनुमोदन लंबित है';

  @override
  String get pendingApproval_titleRejected => 'खाता अनुमोदन अस्वीकृत';

  @override
  String get pendingApproval_descriptionPending =>
      'आपका तकनीशियन खाता बनाया गया है और एडमिन अनुमोदन के लिए भेजा गया है। अनुमोदित होने और सिस्टम एक्सेस मिलने पर आपको सूचित किया जाएगा।';

  @override
  String get pendingApproval_descriptionRejected =>
      'आपके तकनीशियन खाते का अनुरोध अस्वीकृत कर दिया गया है। कृपया नीचे कारण देखें और यदि आपके कोई प्रश्न हैं तो अपने एडमिन से संपर्क करें।';

  @override
  String get pendingApproval_currentStatus => 'वर्तमान स्थिति';

  @override
  String get pendingApproval_statusPending => 'एडमिन अनुमोदन लंबित';

  @override
  String get pendingApproval_statusRejected => 'अस्वीकृत';

  @override
  String get pendingApproval_rejectionReason => 'अस्वीकृति का कारण:';

  @override
  String pendingApproval_rejectionWarning(int count) {
    return 'चेतावनी: यह अस्वीकृति #$count है। 3 अस्वीकृतियों के बाद, आपका खाता स्थायी रूप से हटा दिया जाएगा।';
  }

  @override
  String get pendingApproval_checkStatus => 'अनुमोदन स्थिति जांचें';

  @override
  String get pendingApproval_checking => 'जांच हो रही है...';

  @override
  String get pendingApproval_autoRefresh =>
      'स्थिति हर 5 सेकंड में स्वचालित रूप से जांची जाती है';

  @override
  String get pendingApproval_contactAdmin =>
      'प्रश्न? अपने एडमिन से संपर्क करें';

  @override
  String get pendingApproval_approved =>
      'आपका खाता अनुमोदित हो गया है! स्वागत है।';

  @override
  String pendingApproval_errorSigningOut(String error) {
    return 'साइन आउट में त्रुटि: $error';
  }

  @override
  String get adminHome_dashboard => 'डैशबोर्ड';

  @override
  String get adminHome_tools => 'उपकरण';

  @override
  String get adminHome_sharedTools => 'साझा उपकरण';

  @override
  String get adminHome_technicians => 'तकनीशियन';

  @override
  String get adminHome_reports => 'रिपोर्ट';

  @override
  String get adminHome_maintenance => 'रखरखाव';

  @override
  String get adminHome_approvals => 'अनुमोदन';

  @override
  String get adminHome_toolIssues => 'उपकरण समस्याएं';

  @override
  String get adminHome_toolHistory => 'उपकरण इतिहास';

  @override
  String get adminHome_notifications => 'सूचनाएं';

  @override
  String get adminHome_myTools => 'मेरे उपकरण';

  @override
  String get adminHome_manageAdmins => 'एडमिन प्रबंधन';

  @override
  String get adminHome_settings => 'सेटिंग्स';

  @override
  String get adminHome_deleteAccount => 'खाता हटाएं';

  @override
  String get adminHome_account => 'खाता';

  @override
  String get adminHome_accountDetails => 'खाता विवरण';

  @override
  String get adminHome_preferences => 'प्राथमिकताएं';

  @override
  String get adminHome_security => 'सुरक्षा';

  @override
  String get adminHome_editName => 'नाम संपादित करें';

  @override
  String get adminHome_fullName => 'पूरा नाम';

  @override
  String get adminHome_enterFullName => 'अपना पूरा नाम दर्ज करें';

  @override
  String get adminHome_nameUpdated => 'नाम सफलतापूर्वक अपडेट किया गया';

  @override
  String get adminHome_failedToUpdateName => 'नाम अपडेट करने में विफल';

  @override
  String get adminHome_memberSince => 'सदस्यता तिथि';

  @override
  String get adminHome_role => 'भूमिका';

  @override
  String get adminHome_adminPanel => 'एडमिन पैनल';

  @override
  String get adminHome_somethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get adminHome_tryLoggingOut => 'कृपया लॉगआउट करके पुनः लॉगिन करें';

  @override
  String get adminHome_logoutAndTryAgain => 'लॉगआउट करें और पुनः प्रयास करें';

  @override
  String get adminDashboard_title => 'डैशबोर्ड';

  @override
  String get adminDashboard_overview =>
      'आपके उपकरणों, तकनीशियनों और अनुमोदनों का अवलोकन।';

  @override
  String get adminDashboard_keyMetrics => 'मुख्य मेट्रिक्स';

  @override
  String get adminDashboard_totalTools => 'कुल उपकरण';

  @override
  String get adminDashboard_technicians => 'तकनीशियन';

  @override
  String get adminDashboard_totalValue => 'कुल मूल्य';

  @override
  String get adminDashboard_maintenance => 'रखरखाव';

  @override
  String get adminDashboard_last30Days => 'पिछले 30 दिन';

  @override
  String get adminDashboard_quickActions => 'त्वरित क्रियाएं';

  @override
  String get adminDashboard_addTool => 'उपकरण जोड़ें';

  @override
  String get adminDashboard_assignTool => 'उपकरण असाइन करें';

  @override
  String get adminDashboard_authorizeUsers => 'उपयोगकर्ता अधिकृत करें';

  @override
  String get adminDashboard_reports => 'रिपोर्ट';

  @override
  String get adminDashboard_toolIssues => 'उपकरण समस्याएं';

  @override
  String get adminDashboard_approvals => 'अनुमोदन';

  @override
  String get adminDashboard_maintenanceSchedule => 'रखरखाव शेड्यूल';

  @override
  String get adminDashboard_toolHistory => 'उपकरण इतिहास';

  @override
  String get adminDashboard_fleetStatus => 'फ्लीट स्थिति';

  @override
  String get adminDashboard_toolStatus => 'उपकरण स्थिति';

  @override
  String get adminDashboard_greetingMorning => 'सुप्रभात';

  @override
  String get adminDashboard_greetingAfternoon => 'नमस्कार';

  @override
  String get adminDashboard_greetingEvening => 'शुभ संध्या';

  @override
  String get adminDashboard_manageTools =>
      'अपने उपकरण और फील्ड टीम प्रबंधित करें';

  @override
  String get adminManagement_title => 'एडमिन';

  @override
  String get adminManagement_loading => 'एडमिन लोड हो रहे हैं...';

  @override
  String get adminManagement_noAdmins => 'अभी कोई एडमिन नहीं';

  @override
  String get adminManagement_tapPlusToAdd => 'एडमिन जोड़ने के लिए + दबाएं';

  @override
  String get adminManagement_removeAdmin => 'एडमिन हटाएं';

  @override
  String adminManagement_removeConfirm(String name) {
    return 'क्या आप वाकई $name को एडमिन एक्सेस से हटाना चाहते हैं?';
  }

  @override
  String get adminManagement_removeNote =>
      'उनका प्रमाणीकरण खाता बना रहेगा लेकिन एडमिन विशेषाधिकार समाप्त हो जाएंगे।';

  @override
  String adminManagement_removed(String name) {
    return '$name को एडमिन एक्सेस से हटा दिया गया है';
  }

  @override
  String get adminManagement_removeFailed => 'एडमिन हटाने में विफल';

  @override
  String get adminManagement_unassigned => 'असाइन नहीं';

  @override
  String get adminNotification_title => 'सूचनाएं';

  @override
  String get adminNotification_markAllRead => 'सभी पढ़ी हुई मार्क करें';

  @override
  String get adminNotification_errorLoading => 'सूचनाएं लोड करने में त्रुटि';

  @override
  String get adminNotification_empty => 'कोई सूचना नहीं';

  @override
  String get adminNotification_emptyHint => 'तकनीशियन अनुरोध यहाँ दिखाई देंगे';

  @override
  String get adminNotification_technicianDetails => 'तकनीशियन विवरण:';

  @override
  String get adminNotification_time => 'समय';

  @override
  String get adminNotification_justNow => 'अभी';

  @override
  String adminNotification_minutesAgo(int count) {
    return '$count मिनट पहले';
  }

  @override
  String adminNotification_hoursAgo(int count) {
    return '$count घंटे पहले';
  }

  @override
  String adminNotification_daysAgo(int count) {
    return '$count दिन पहले';
  }

  @override
  String get adminNotification_markRead => 'पढ़ा हुआ मार्क करें';

  @override
  String get adminNotification_markUnread => 'अपठित मार्क करें';

  @override
  String get tools_title => 'उपकरण';

  @override
  String get tools_searchHint => 'उपकरण खोजें...';

  @override
  String get tools_emptyTitle => 'कोई उपकरण नहीं मिला';

  @override
  String get tools_emptySubtitle => 'शुरू करने के लिए अपना पहला उपकरण जोड़ें';

  @override
  String get tools_addTool => 'उपकरण जोड़ें';

  @override
  String get tools_filterAll => 'सभी';

  @override
  String get tools_filterAvailable => 'उपलब्ध';

  @override
  String get tools_filterAssigned => 'असाइन किया गया';

  @override
  String get tools_filterMaintenance => 'रखरखाव';

  @override
  String get tools_deleteTool => 'उपकरण हटाएं';

  @override
  String get tools_deleteConfirm =>
      'क्या आप वाकई इस उपकरण को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get toolDetail_title => 'उपकरण विवरण';

  @override
  String get toolDetail_brand => 'ब्रांड';

  @override
  String get toolDetail_model => 'मॉडल';

  @override
  String get toolDetail_serialNumber => 'सीरियल नंबर';

  @override
  String get toolDetail_category => 'श्रेणी';

  @override
  String get toolDetail_condition => 'स्थिति';

  @override
  String get toolDetail_location => 'स्थान';

  @override
  String get toolDetail_assignedTo => 'असाइन किया गया';

  @override
  String get toolDetail_purchaseDate => 'खरीद तिथि';

  @override
  String get toolDetail_purchasePrice => 'खरीद मूल्य';

  @override
  String get toolDetail_currentValue => 'वर्तमान मूल्य';

  @override
  String get toolDetail_notes => 'नोट्स';

  @override
  String get toolDetail_status => 'स्थिति';

  @override
  String get toolDetail_toolType => 'उपकरण प्रकार';

  @override
  String get toolDetail_history => 'इतिहास';

  @override
  String get toolDetail_noHistory => 'कोई इतिहास उपलब्ध नहीं';

  @override
  String get toolDetail_unassigned => 'असाइन नहीं';

  @override
  String get toolDetail_returnTool => 'उपकरण वापस करें';

  @override
  String get toolDetail_assignTool => 'उपकरण असाइन करें';

  @override
  String get toolDetail_editTool => 'उपकरण संपादित करें';

  @override
  String get toolDetail_deleteTool => 'उपकरण हटाएं';

  @override
  String get addTool_title => 'उपकरण जोड़ें';

  @override
  String get addTool_nameLabel => 'उपकरण का नाम';

  @override
  String get addTool_nameHint => 'उपकरण का नाम दर्ज करें';

  @override
  String get addTool_nameRequired => 'कृपया उपकरण का नाम दर्ज करें';

  @override
  String get addTool_categoryLabel => 'श्रेणी';

  @override
  String get addTool_categoryHint => 'श्रेणी चुनें';

  @override
  String get addTool_categoryRequired => 'कृपया एक श्रेणी चुनें';

  @override
  String get addTool_brandLabel => 'ब्रांड';

  @override
  String get addTool_brandHint => 'ब्रांड दर्ज करें';

  @override
  String get addTool_modelLabel => 'मॉडल';

  @override
  String get addTool_modelHint => 'मॉडल दर्ज करें';

  @override
  String get addTool_serialNumberLabel => 'सीरियल नंबर';

  @override
  String get addTool_serialNumberHint => 'सीरियल नंबर दर्ज करें';

  @override
  String get addTool_purchaseDateLabel => 'खरीद तिथि';

  @override
  String get addTool_purchasePriceLabel => 'खरीद मूल्य';

  @override
  String get addTool_currentValueLabel => 'वर्तमान मूल्य';

  @override
  String get addTool_conditionLabel => 'स्थिति';

  @override
  String get addTool_conditionHint => 'स्थिति चुनें';

  @override
  String get addTool_locationLabel => 'स्थान';

  @override
  String get addTool_locationHint => 'स्थान दर्ज करें';

  @override
  String get addTool_toolTypeLabel => 'उपकरण प्रकार';

  @override
  String get addTool_notesLabel => 'नोट्स';

  @override
  String get addTool_notesHint => 'नोट्स दर्ज करें (वैकल्पिक)';

  @override
  String get addTool_saveButton => 'उपकरण सहेजें';

  @override
  String get addTool_success => 'उपकरण सफलतापूर्वक जोड़ा गया!';

  @override
  String get addTool_attachPhoto => 'फ़ोटो संलग्न करें (वैकल्पिक)';

  @override
  String get editTool_title => 'उपकरण संपादित करें';

  @override
  String get editTool_saveButton => 'उपकरण अपडेट करें';

  @override
  String get editTool_success => 'उपकरण सफलतापूर्वक अपडेट किया गया!';

  @override
  String get toolHistory_title => 'उपकरण इतिहास';

  @override
  String get toolHistory_noHistory => 'कोई इतिहास रिकॉर्ड नहीं मिला';

  @override
  String get toolHistory_allHistory => 'सभी उपकरण इतिहास';

  @override
  String get toolInstances_title => 'उपकरण इंस्टेंस';

  @override
  String get toolInstances_empty => 'कोई इंस्टेंस नहीं मिला';

  @override
  String get toolIssues_title => 'उपकरण समस्याएं';

  @override
  String get toolIssues_all => 'सभी';

  @override
  String get toolIssues_open => 'खुली';

  @override
  String get toolIssues_inProgress => 'प्रगति में';

  @override
  String get toolIssues_resolved => 'हल की गई';

  @override
  String get toolIssues_closed => 'बंद';

  @override
  String get toolIssues_empty => 'कोई समस्या नहीं मिली';

  @override
  String get toolIssues_emptyHint => 'कोई उपकरण समस्या रिपोर्ट नहीं की गई';

  @override
  String get toolIssues_reportIssue => 'समस्या रिपोर्ट करें';

  @override
  String get addToolIssue_title => 'उपकरण समस्या रिपोर्ट करें';

  @override
  String get addToolIssue_selectTool => 'उपकरण चुनें *';

  @override
  String get addToolIssue_issueDetails => 'समस्या विवरण';

  @override
  String get addToolIssue_issueType => 'समस्या प्रकार';

  @override
  String get addToolIssue_priority => 'प्राथमिकता';

  @override
  String get addToolIssue_description => 'विवरण *';

  @override
  String get addToolIssue_descriptionHint => 'समस्या का विस्तृत विवरण दें';

  @override
  String get addToolIssue_descriptionRequired =>
      'कृपया समस्या का विवरण दर्ज करें';

  @override
  String get addToolIssue_additionalInfo => 'अतिरिक्त जानकारी';

  @override
  String get addToolIssue_location => 'स्थान';

  @override
  String get addToolIssue_locationHint => 'यह कहाँ हुआ? (वैकल्पिक)';

  @override
  String get addToolIssue_estimatedCost => 'अनुमानित लागत';

  @override
  String get addToolIssue_estimatedCostHint =>
      'ठीक करने/बदलने की लागत (वैकल्पिक)';

  @override
  String get addToolIssue_priorityGuidelines => 'प्राथमिकता दिशानिर्देश';

  @override
  String get addToolIssue_criticalGuideline =>
      'सुरक्षा खतरा या उपकरण पूरी तरह खराब';

  @override
  String get addToolIssue_highGuideline =>
      'उपकरण अनुपयोगी लेकिन कोई सुरक्षा खतरा नहीं';

  @override
  String get addToolIssue_mediumGuideline => 'उपकरण आंशिक रूप से कार्यात्मक';

  @override
  String get addToolIssue_lowGuideline =>
      'मामूली समस्या, उपकरण अभी भी उपयोग योग्य';

  @override
  String get addToolIssue_submitButton => 'रिपोर्ट सबमिट करें';

  @override
  String get addToolIssue_success => 'समस्या सफलतापूर्वक रिपोर्ट की गई!';

  @override
  String get addToolIssue_toolNotFound =>
      'चुना गया उपकरण नहीं मिला। कृपया रिफ्रेश करें और पुनः प्रयास करें।';

  @override
  String get addToolIssue_tableNotFound =>
      'उपकरण समस्या तालिका नहीं मिली। कृपया एडमिन से संपर्क करें।';

  @override
  String get addToolIssue_sessionExpired =>
      'सत्र समाप्त हो गया। कृपया पुनः लॉगिन करें।';

  @override
  String get addToolIssue_permissionDenied =>
      'अनुमति अस्वीकृत। आपको समस्या रिपोर्ट करने की अनुमति नहीं हो सकती।';

  @override
  String get addToolIssue_fillRequired => 'कृपया सभी आवश्यक फ़ील्ड भरें।';

  @override
  String get addToolIssue_networkError =>
      'नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get technicians_title => 'तकनीशियन';

  @override
  String get technicians_subtitle =>
      'सक्रिय, निष्क्रिय और असाइन किए गए तकनीशियनों का प्रबंधन करें';

  @override
  String get technicians_searchHint => 'तकनीशियन खोजें...';

  @override
  String get technicians_emptyTitle => 'कोई तकनीशियन नहीं मिला';

  @override
  String get technicians_emptySubtitle =>
      'शुरू करने के लिए अपना पहला तकनीशियन जोड़ें';

  @override
  String get technicians_filterAll => 'सभी';

  @override
  String get technicians_filterActive => 'सक्रिय';

  @override
  String get technicians_filterInactive => 'निष्क्रिय';

  @override
  String get technicians_filterWithTools => 'उपकरण सहित';

  @override
  String get technicians_filterWithoutTools => 'उपकरण रहित';

  @override
  String get technicians_deleteTitle => 'तकनीशियन हटाएं';

  @override
  String technicians_deleteConfirm(String name) {
    return 'क्या आप वाकई $name को हटाना चाहते हैं?';
  }

  @override
  String get technicians_noTools => 'कोई उपकरण नहीं';

  @override
  String get technicians_noDepartment => 'कोई विभाग नहीं';

  @override
  String get technicianDetail_profile => 'प्रोफ़ाइल';

  @override
  String get technicianDetail_tools => 'उपकरण';

  @override
  String get technicianDetail_issues => 'समस्याएं';

  @override
  String get technicianDetail_editTechnician => 'तकनीशियन संपादित करें';

  @override
  String get technicianDetail_deleteTechnician => 'तकनीशियन हटाएं';

  @override
  String get technicianDetail_contactInfo => 'संपर्क जानकारी';

  @override
  String get technicianDetail_employmentDetails => 'रोजगार विवरण';

  @override
  String get technicianDetail_statusInfo => 'स्थिति जानकारी';

  @override
  String get technicianDetail_employeeId => 'कर्मचारी ID';

  @override
  String get technicianDetail_department => 'विभाग';

  @override
  String get technicianDetail_hireDate => 'नियुक्ति तिथि';

  @override
  String get technicianDetail_created => 'बनाया गया';

  @override
  String get technicianDetail_noTools => 'कोई उपकरण असाइन नहीं';

  @override
  String get technicianDetail_noToolsDesc =>
      'इस तकनीशियन को कोई उपकरण असाइन नहीं किया गया है';

  @override
  String get technicianDetail_noIssues => 'कोई समस्या रिपोर्ट नहीं';

  @override
  String get technicianDetail_noIssuesDesc =>
      'इस तकनीशियन ने कोई उपकरण समस्या रिपोर्ट नहीं की है';

  @override
  String get technicianDetail_deleteWarning => 'यह स्थायी रूप से हटाएगा:';

  @override
  String get technicianDetail_deleteLine1 => 'तकनीशियन रिकॉर्ड';

  @override
  String get technicianDetail_deleteLine2 => 'सभी संबंधित डेटा';

  @override
  String get technicianDetail_deleteCannotUndo =>
      'यह क्रिया पूर्ववत नहीं की जा सकती!';

  @override
  String get technicianDetail_deleteHasTools =>
      'असाइन किए गए उपकरणों वाले तकनीशियन को हटाया नहीं जा सकता। पहले उन्हें पुनः असाइन या वापस करें।';

  @override
  String get technicianHome_account => 'खाता';

  @override
  String get technicianHome_accountDetails => 'खाता विवरण';

  @override
  String get technicianHome_preferences => 'प्राथमिकताएं';

  @override
  String get technicianHome_security => 'सुरक्षा';

  @override
  String get technicianHome_editName => 'नाम संपादित करें';

  @override
  String get technicianHome_fullName => 'पूरा नाम';

  @override
  String get technicianHome_enterFullName => 'अपना पूरा नाम दर्ज करें';

  @override
  String get technicianHome_memberSince => 'सदस्यता तिथि';

  @override
  String get technicianHome_role => 'भूमिका';

  @override
  String get technicianHome_administrator => 'एडमिन';

  @override
  String get technicianHome_technician => 'तकनीशियन';

  @override
  String get technicianHome_noNotifications => 'कोई सूचना नहीं';

  @override
  String get technicianHome_notificationsHint =>
      'उपकरण अनुरोध मिलने पर सूचनाएं यहाँ दिखाई देंगी';

  @override
  String get technicianHome_requestAccountDeletion =>
      'खाता हटाने का अनुरोध करें';

  @override
  String get techDashboard_greetingMorning => 'सुप्रभात';

  @override
  String get techDashboard_greetingAfternoon => 'नमस्कार';

  @override
  String get techDashboard_greetingEvening => 'शुभ संध्या';

  @override
  String get techDashboard_welcome =>
      'अपने उपकरण प्रबंधित करें और साझा संसाधन एक्सेस करें';

  @override
  String get techDashboard_sharedTools => 'साझा उपकरण';

  @override
  String get techDashboard_seeAll => 'सभी देखें';

  @override
  String get techDashboard_myTools => 'मेरे उपकरण';

  @override
  String get techDashboard_noTools => 'कोई उपकरण उपलब्ध नहीं';

  @override
  String get techDashboard_noToolsHint =>
      'आपके पास कोई असाइन किया गया उपकरण नहीं है। आप अपना पहला उपकरण जोड़ सकते हैं या उपकरण असाइनमेंट का अनुरोध कर सकते हैं।';

  @override
  String get techDashboard_noSharedTools => 'कोई साझा उपकरण उपलब्ध नहीं';

  @override
  String get techDashboard_noAssignedTools => 'अभी कोई उपकरण असाइन नहीं';

  @override
  String get techDashboard_noAssignedToolsHint =>
      'वर्तमान में आपके पास जो उपकरण हैं, उन्हें जोड़ें या बैज करें और यहाँ देखें।';

  @override
  String get techDashboard_shared => 'साझा';

  @override
  String get techDashboard_request => 'अनुरोध';

  @override
  String get myTools_title => 'मेरे उपकरण';

  @override
  String get myTools_searchHint => 'उपकरण खोजें...';

  @override
  String get myTools_categoryFilter => 'श्रेणी';

  @override
  String get myTools_statusFilter => 'स्थिति';

  @override
  String get myTools_empty => 'कोई उपकरण नहीं मिला';

  @override
  String get myTools_emptyHint => 'शुरू करने के लिए अपना पहला उपकरण जोड़ें';

  @override
  String get myTools_addButton => 'उपकरण जोड़ें';

  @override
  String get addTechnician_addTitle => 'तकनीशियन जोड़ें';

  @override
  String get addTechnician_editTitle => 'तकनीशियन संपादित करें';

  @override
  String get addTechnician_addSubtitle =>
      'तकनीशियन जोड़ें ताकि वे असाइनमेंट और उपकरण एक्सेस प्राप्त कर सकें।';

  @override
  String get addTechnician_editSubtitle =>
      'असाइनमेंट को अद्यतन रखने के लिए तकनीशियन विवरण अपडेट करें।';

  @override
  String get addTechnician_nameLabel => 'पूरा नाम';

  @override
  String get addTechnician_nameHint => 'पूरा नाम दर्ज करें';

  @override
  String get addTechnician_employeeIdLabel => 'कर्मचारी ID';

  @override
  String get addTechnician_employeeIdHint => 'कर्मचारी ID दर्ज करें (वैकल्पिक)';

  @override
  String get addTechnician_phoneLabel => 'फ़ोन नंबर';

  @override
  String get addTechnician_phoneHint => 'फ़ोन नंबर दर्ज करें';

  @override
  String get addTechnician_emailLabel => 'Email पता';

  @override
  String get addTechnician_emailHint => 'Email पता दर्ज करें';

  @override
  String get addTechnician_emailInvalid => 'एक मान्य Email पता दर्ज करें';

  @override
  String get addTechnician_departmentLabel => 'विभाग';

  @override
  String get addTechnician_departmentHint => 'विभाग चुनें';

  @override
  String get addTechnician_statusLabel => 'स्थिति';

  @override
  String get addTechnician_hireDateHint => 'नियुक्ति तिथि चुनें';

  @override
  String get addTechnician_addButton => 'तकनीशियन जोड़ें';

  @override
  String get addTechnician_updateButton => 'तकनीशियन अपडेट करें';

  @override
  String get addTechnician_addSuccess => 'तकनीशियन सफलतापूर्वक जोड़ा गया!';

  @override
  String addTechnician_inviteEmailSent(String email) {
    return '$email पर आमंत्रण Email भेजा गया';
  }

  @override
  String get addTechnician_inviteHint =>
      'तकनीशियन को अपना पासवर्ड सेट करने के लिए आमंत्रण Email का उपयोग करना चाहिए।';

  @override
  String get addTechnician_updateSuccess =>
      'तकनीशियन सफलतापूर्वक अपडेट किया गया!';

  @override
  String get addTechnician_nameRequired => 'कृपया तकनीशियन का नाम दर्ज करें';

  @override
  String get addTechnician_chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get addTechnician_takePhoto => 'फ़ोटो खींचें';

  @override
  String get addTechnician_removePhoto => 'फ़ोटो हटाएं';

  @override
  String get settings_title => 'सेटिंग्स';

  @override
  String get settings_accountSection => 'खाता';

  @override
  String get settings_accountDetailsSection => 'खाता विवरण';

  @override
  String get settings_accountManagementSection => 'खाता प्रबंधन';

  @override
  String get settings_preferencesSection => 'प्राथमिकताएं';

  @override
  String get settings_notificationsSection => 'सूचनाएं';

  @override
  String get settings_dataBackupSection => 'डेटा और बैकअप';

  @override
  String get settings_aboutSection => 'जानकारी';

  @override
  String get settings_languageLabel => 'भाषा';

  @override
  String get settings_currencyLabel => 'मुद्रा';

  @override
  String get settings_pushNotifications => 'पुश सूचनाएं';

  @override
  String get settings_pushNotificationsSubtitle =>
      'रखरखाव रिमाइंडर और अपडेट प्राप्त करें';

  @override
  String get settings_autoBackup => 'स्वतः बैकअप';

  @override
  String get settings_autoBackupSubtitle =>
      'क्लाउड पर डेटा स्वचालित रूप से बैकअप करें';

  @override
  String get settings_exportData => 'डेटा निर्यात करें';

  @override
  String get settings_exportDataSubtitle =>
      'अपना डेटा CSV के रूप में डाउनलोड करें';

  @override
  String get settings_importData => 'डेटा आयात करें';

  @override
  String get settings_importDataSubtitle => 'बैकअप फ़ाइल से पुनर्स्थापित करें';

  @override
  String get settings_importDataMessage =>
      'डेटा आयात करने के लिए कृपया सहायता से संपर्क करें। हम आपको बैकअप फ़ाइल से डेटा पुनर्स्थापित करने में मदद करेंगे।';

  @override
  String get settings_appVersion => 'ऐप संस्करण';

  @override
  String get settings_helpSupport => 'सहायता और समर्थन';

  @override
  String get settings_helpSupportSubtitle =>
      'सहायता प्राप्त करें और समर्थन से संपर्क करें';

  @override
  String get settings_privacyPolicy => 'गोपनीयता नीति';

  @override
  String get settings_privacyPolicySubtitle => 'हमारी गोपनीयता नीति पढ़ें';

  @override
  String get settings_termsOfService => 'सेवा की शर्तें';

  @override
  String get settings_termsOfServiceSubtitle => 'हमारी सेवा की शर्तें पढ़ें';

  @override
  String get settings_selectLanguage => 'भाषा चुनें';

  @override
  String get settings_selectCurrency => 'मुद्रा चुनें';

  @override
  String get settings_deleteAccount => 'खाता हटाएं';

  @override
  String get settings_deleteAccountSubtitle =>
      'अपना खाता और डेटा स्थायी रूप से हटाएं';

  @override
  String get settings_requestAccountDeletion => 'खाता हटाने का अनुरोध करें';

  @override
  String get settings_requestAccountDeletionSubtitle =>
      'अपने एडमिन से खाता हटाने का अनुरोध करें';

  @override
  String get settings_versionInfo => 'संस्करण जानकारी';

  @override
  String get settings_rgsToolsManager => 'Tools Manager';

  @override
  String get settings_couldNotOpenPage => 'सहायता पृष्ठ नहीं खुल सका';

  @override
  String settings_exportSuccess(int count) {
    return 'डेटा सफलतापूर्वक निर्यात किया गया! $count फ़ाइल(ें) बनाई गईं।';
  }

  @override
  String settings_exportError(String error) {
    return 'डेटा निर्यात करने में त्रुटि: $error';
  }

  @override
  String get currency_usd => 'US डॉलर';

  @override
  String get currency_eur => 'यूरो';

  @override
  String get currency_gbp => 'ब्रिटिश पाउंड';

  @override
  String get currency_aed => 'UAE दिरहम';

  @override
  String get reports_title => 'रिपोर्ट';

  @override
  String get reports_toolsOverview => 'उपकरण अवलोकन';

  @override
  String get reports_technicianActivity => 'तकनीशियन गतिविधि';

  @override
  String get reports_maintenanceReport => 'रखरखाव रिपोर्ट';

  @override
  String get reports_exportReport => 'रिपोर्ट निर्यात करें';

  @override
  String get reports_generateReport => 'रिपोर्ट तैयार करें';

  @override
  String get reports_noData => 'इस रिपोर्ट के लिए कोई डेटा उपलब्ध नहीं';

  @override
  String get reports_dateRange => 'दिनांक सीमा';

  @override
  String get reports_last7Days => 'पिछले 7 दिन';

  @override
  String get reports_last30Days => 'पिछले 30 दिन';

  @override
  String get reports_last90Days => 'पिछले 90 दिन';

  @override
  String get reports_custom => 'कस्टम';

  @override
  String get maintenance_title => 'रखरखाव';

  @override
  String get maintenance_schedule => 'रखरखाव शेड्यूल करें';

  @override
  String get maintenance_noScheduled => 'कोई रखरखाव शेड्यूल नहीं';

  @override
  String get maintenance_upcoming => 'आगामी';

  @override
  String get maintenance_overdue => 'अतिदेय';

  @override
  String get maintenance_completed => 'पूर्ण';

  @override
  String get checkin_title => 'चेक इन / चेक आउट';

  @override
  String get checkin_scanBarcode => 'बारकोड स्कैन करें';

  @override
  String get checkin_manualEntry => 'मैन्युअल प्रविष्टि';

  @override
  String get checkin_toolId => 'Tool ID';

  @override
  String get checkin_checkInButton => 'चेक इन';

  @override
  String get checkin_checkOutButton => 'चेक आउट';

  @override
  String get sharedTools_title => 'साझा उपकरण';

  @override
  String get sharedTools_empty => 'कोई साझा उपकरण उपलब्ध नहीं';

  @override
  String get sharedTools_emptyHint =>
      'साझा के रूप में चिह्नित उपकरण यहाँ दिखाई देंगे';

  @override
  String get sharedTools_badgeIn => 'बैज इन';

  @override
  String get sharedTools_badgeOut => 'बैज आउट';

  @override
  String get sharedTools_currentHolder => 'वर्तमान धारक';

  @override
  String get sharedTools_noCurrentHolder => 'कोई वर्तमान धारक नहीं';

  @override
  String get bulkImport_title => 'बल्क आयात';

  @override
  String get bulkImport_selectFile => 'CSV फ़ाइल चुनें';

  @override
  String get bulkImport_importButton => 'आयात करें';

  @override
  String get bulkImport_preview => 'पूर्वावलोकन';

  @override
  String bulkImport_rowsFound(int count) {
    return '$count पंक्तियाँ मिलीं';
  }

  @override
  String bulkImport_success(int count) {
    return '$count उपकरण सफलतापूर्वक आयात किए गए';
  }

  @override
  String bulkImport_error(String error) {
    return 'आयात विफल: $error';
  }

  @override
  String get permanentAssignment_title => 'स्थायी असाइनमेंट';

  @override
  String get permanentAssignment_selectTechnician => 'तकनीशियन चुनें';

  @override
  String get permanentAssignment_selectTools => 'उपकरण चुनें';

  @override
  String get permanentAssignment_assignButton => 'असाइन करें';

  @override
  String get permanentAssignment_success => 'उपकरण सफलतापूर्वक असाइन किए गए';

  @override
  String get reassignTool_title => 'उपकरण पुनः असाइन करें';

  @override
  String get reassignTool_currentTechnician => 'वर्तमान तकनीशियन';

  @override
  String get reassignTool_newTechnician => 'नया तकनीशियन';

  @override
  String get reassignTool_reassignButton => 'पुनः असाइन करें';

  @override
  String get reassignTool_success => 'उपकरण सफलतापूर्वक पुनः असाइन किया गया';

  @override
  String get requestNewTool_title => 'नया अनुरोध';

  @override
  String get requestNewTool_subtitle =>
      'उपकरण, असाइनमेंट, स्थानांतरण या रखरखाव के लिए अनुरोध सबमिट करें';

  @override
  String get requestNewTool_requestType => 'अनुरोध प्रकार';

  @override
  String get requestNewTool_requestInfo => 'अनुरोध जानकारी';

  @override
  String get requestNewTool_titleLabel => 'शीर्षक (वैकल्पिक)';

  @override
  String get requestNewTool_titleHint => 'खाली छोड़ने पर स्वतः उत्पन्न होगा';

  @override
  String get requestNewTool_descriptionLabel => 'विवरण (वैकल्पिक)';

  @override
  String get requestNewTool_descriptionHint =>
      'खाली छोड़ने पर स्वतः उत्पन्न होगा';

  @override
  String get requestNewTool_justification => 'औचित्य / कारण *';

  @override
  String get requestNewTool_neededBy => 'कब तक चाहिए (वैकल्पिक)';

  @override
  String get requestNewTool_selectDate => 'तिथि चुनें';

  @override
  String get requestNewTool_siteLocation => 'साइट / स्थान';

  @override
  String get requestNewTool_siteLocationHint => 'जैसे, भवन A, तल 3';

  @override
  String get requestNewTool_submitButton => 'अनुरोध सबमिट करें';

  @override
  String get requestNewTool_success => 'अनुरोध सफलतापूर्वक सबमिट किया गया!';

  @override
  String get requestNewTool_toolDetails => 'उपकरण विवरण';

  @override
  String get requestNewTool_assignmentDetails => 'असाइनमेंट विवरण';

  @override
  String get requestNewTool_transferDetails => 'स्थानांतरण विवरण';

  @override
  String get requestNewTool_maintenanceDetails => 'रखरखाव विवरण';

  @override
  String get requestNewTool_disposalDetails => 'निपटान विवरण';

  @override
  String get requestNewTool_toolName => 'उपकरण का नाम';

  @override
  String get requestNewTool_toolSerial => 'उपकरण सीरियल नंबर (वैकल्पिक)';

  @override
  String get requestNewTool_quantity => 'मात्रा';

  @override
  String get requestNewTool_unitPrice => 'इकाई मूल्य (AED)';

  @override
  String get requestNewTool_totalCost => 'कुल लागत (AED)';

  @override
  String get requestNewTool_supplier => 'आपूर्तिकर्ता (वैकल्पिक)';

  @override
  String get requestNewTool_assignTo =>
      'किसे असाइन करें (आपका नाम या अन्य तकनीशियन)';

  @override
  String get requestNewTool_project => 'परियोजना/साइट';

  @override
  String get requestNewTool_fromLocation => 'स्रोत स्थान';

  @override
  String get requestNewTool_toLocation => 'गंतव्य स्थान';

  @override
  String get requestNewTool_maintenanceType => 'रखरखाव प्रकार';

  @override
  String get requestNewTool_currentCondition => 'वर्तमान स्थिति';

  @override
  String get requestNewTool_attachPhoto =>
      'फ़ोटो या विशिष्टता संलग्न करें (वैकल्पिक)';

  @override
  String get requestNewTool_enterValidNumber => 'एक मान्य संख्या दर्ज करें';

  @override
  String get requestType_toolPurchase => 'उपकरण खरीद';

  @override
  String get requestType_toolAssignment => 'उपकरण असाइनमेंट';

  @override
  String get requestType_transfer => 'स्थानांतरण';

  @override
  String get requestType_maintenance => 'रखरखाव';

  @override
  String get requestType_toolDisposal => 'उपकरण निपटान';
}
