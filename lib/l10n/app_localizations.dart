import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'RGS HVAC Tools'**
  String get appTitle;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get common_remove;

  /// No description provided for @common_view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get common_view;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// No description provided for @common_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get common_unknown;

  /// No description provided for @common_notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get common_notAvailable;

  /// No description provided for @common_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get common_required;

  /// No description provided for @common_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get common_optional;

  /// No description provided for @common_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// No description provided for @common_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get common_none;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get common_signOut;

  /// No description provided for @common_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get common_logout;

  /// No description provided for @common_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get common_settings;

  /// No description provided for @common_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get common_notifications;

  /// No description provided for @common_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get common_email;

  /// No description provided for @common_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get common_password;

  /// No description provided for @common_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get common_name;

  /// No description provided for @common_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get common_phone;

  /// No description provided for @common_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get common_status;

  /// No description provided for @common_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get common_active;

  /// No description provided for @common_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get common_inactive;

  /// No description provided for @common_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get common_camera;

  /// No description provided for @common_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get common_gallery;

  /// No description provided for @common_addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get common_addImage;

  /// No description provided for @common_selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get common_selectImageSource;

  /// No description provided for @common_failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String common_failedToPickImage(String error);

  /// No description provided for @common_somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong. Please try again.'**
  String get common_somethingWentWrong;

  /// No description provided for @common_offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing cached data'**
  String get common_offlineBanner;

  /// No description provided for @common_noImage.
  ///
  /// In en, this message translates to:
  /// **'No Image'**
  String get common_noImage;

  /// No description provided for @status_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get status_available;

  /// No description provided for @status_assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get status_assigned;

  /// No description provided for @status_inUse.
  ///
  /// In en, this message translates to:
  /// **'In Use'**
  String get status_inUse;

  /// No description provided for @status_maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get status_maintenance;

  /// No description provided for @status_retired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get status_retired;

  /// No description provided for @status_lost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get status_lost;

  /// No description provided for @priority_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priority_low;

  /// No description provided for @priority_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priority_medium;

  /// No description provided for @priority_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priority_high;

  /// No description provided for @priority_critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get priority_critical;

  /// No description provided for @priority_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get priority_normal;

  /// No description provided for @priority_urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priority_urgent;

  /// No description provided for @validation_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validation_required;

  /// No description provided for @validation_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get validation_emailRequired;

  /// No description provided for @validation_emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validation_emailInvalid;

  /// No description provided for @validation_passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get validation_passwordRequired;

  /// No description provided for @validation_passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validation_passwordMinLength;

  /// No description provided for @validation_passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validation_passwordMismatch;

  /// No description provided for @validation_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get validation_nameRequired;

  /// No description provided for @validation_phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get validation_phoneRequired;

  /// No description provided for @validation_pleaseSelectTool.
  ///
  /// In en, this message translates to:
  /// **'Please select a tool'**
  String get validation_pleaseSelectTool;

  /// No description provided for @roleSelection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tool Tracking • Assignments • Inventory'**
  String get roleSelection_subtitle;

  /// No description provided for @roleSelection_registerAdmin.
  ///
  /// In en, this message translates to:
  /// **'Register as Admin'**
  String get roleSelection_registerAdmin;

  /// No description provided for @roleSelection_continueAdmin.
  ///
  /// In en, this message translates to:
  /// **'Continue as Admin'**
  String get roleSelection_continueAdmin;

  /// No description provided for @roleSelection_registerTechnician.
  ///
  /// In en, this message translates to:
  /// **'Register as Technician'**
  String get roleSelection_registerTechnician;

  /// No description provided for @roleSelection_continueTechnician.
  ///
  /// In en, this message translates to:
  /// **'Continue as Technician'**
  String get roleSelection_continueTechnician;

  /// No description provided for @roleSelection_alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get roleSelection_alreadyHaveAccount;

  /// No description provided for @roleSelection_signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get roleSelection_signIn;

  /// No description provided for @roleSelection_adminClosedError.
  ///
  /// In en, this message translates to:
  /// **'Admin registration is closed. Please request an admin invite.'**
  String get roleSelection_adminClosedError;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login_title;

  /// No description provided for @login_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get login_emailLabel;

  /// No description provided for @login_emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get login_emailHint;

  /// No description provided for @login_passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get login_passwordLabel;

  /// No description provided for @login_passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get login_passwordHint;

  /// No description provided for @login_signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login_signInButton;

  /// No description provided for @login_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get login_forgotPassword;

  /// No description provided for @login_orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get login_orContinueWith;

  /// No description provided for @login_or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get login_or;

  /// No description provided for @login_google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get login_google;

  /// No description provided for @login_apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get login_apple;

  /// No description provided for @login_registerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register Here'**
  String get login_registerPrompt;

  /// No description provided for @login_registerSubtext.
  ///
  /// In en, this message translates to:
  /// **'Choose Admin or Technician registration'**
  String get login_registerSubtext;

  /// No description provided for @login_welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get login_welcomeBack;

  /// No description provided for @login_welcomeBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your RGS HVAC Services account'**
  String get login_welcomeBackSubtitle;

  /// No description provided for @login_successMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Successfully signed in.'**
  String get login_successMessage;

  /// No description provided for @login_accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied: Invalid admin credentials'**
  String get login_accessDenied;

  /// No description provided for @login_emailRequiredFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address first'**
  String get login_emailRequiredFirst;

  /// No description provided for @login_passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox.'**
  String get login_passwordResetSent;

  /// No description provided for @login_appleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in was cancelled.'**
  String get login_appleCancelled;

  /// No description provided for @login_appleFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed.'**
  String get login_appleFailed;

  /// No description provided for @login_oauthAccountExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please sign in with your email and password.'**
  String get login_oauthAccountExists;

  /// No description provided for @login_emailDomainNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Email domain not allowed. Use @mekar.ae or other approved domains'**
  String get login_emailDomainNotAllowed;

  /// No description provided for @login_resetPasswordDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get login_resetPasswordDialogTitle;

  /// No description provided for @login_resetPasswordDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get login_resetPasswordDialogMessage;

  /// No description provided for @login_resetPasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your.email@example.com'**
  String get login_resetPasswordEmailHint;

  /// No description provided for @login_resetPasswordSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get login_resetPasswordSendButton;

  /// No description provided for @login_resetPasswordSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Sent!'**
  String get login_resetPasswordSuccessTitle;

  /// No description provided for @login_resetPasswordSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to {email}. Please check your inbox and follow the instructions to reset your password.'**
  String login_resetPasswordSuccessMessage(String email);

  /// No description provided for @register_createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account to get started.'**
  String get register_createAccount;

  /// No description provided for @register_fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get register_fullNameLabel;

  /// No description provided for @register_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get register_emailLabel;

  /// No description provided for @register_passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get register_passwordLabel;

  /// No description provided for @register_confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get register_confirmPasswordLabel;

  /// No description provided for @register_phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get register_phoneLabel;

  /// No description provided for @register_departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get register_departmentLabel;

  /// No description provided for @register_roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get register_roleLabel;

  /// No description provided for @register_createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get register_createAccountButton;

  /// No description provided for @register_signInLink.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get register_signInLink;

  /// No description provided for @register_backToRoleSelection.
  ///
  /// In en, this message translates to:
  /// **'Back to Role Selection'**
  String get register_backToRoleSelection;

  /// No description provided for @register_checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get register_checkYourEmail;

  /// No description provided for @register_confirmationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a confirmation email to:'**
  String get register_confirmationEmailSent;

  /// No description provided for @register_confirmationInstructions.
  ///
  /// In en, this message translates to:
  /// **'Please check your email and click the confirmation link to verify your account. After verification, your account will be pending admin approval.'**
  String get register_confirmationInstructions;

  /// No description provided for @register_goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get register_goToLogin;

  /// No description provided for @register_pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Your account is pending admin approval. You will be notified once approved.'**
  String get register_pendingApproval;

  /// No description provided for @register_emailFormatValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address (e.g., name@example.com)'**
  String get register_emailFormatValidation;

  /// No description provided for @resetPassword_title.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword_title;

  /// No description provided for @resetPassword_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password below'**
  String get resetPassword_subtitle;

  /// No description provided for @resetPassword_newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get resetPassword_newPasswordLabel;

  /// No description provided for @resetPassword_confirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get resetPassword_confirmLabel;

  /// No description provided for @resetPassword_button.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword_button;

  /// No description provided for @resetPassword_backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get resetPassword_backToLogin;

  /// No description provided for @resetPassword_successMessage.
  ///
  /// In en, this message translates to:
  /// **'Password set successfully! Redirecting...'**
  String get resetPassword_successMessage;

  /// No description provided for @resetPassword_sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please open the invite link again.'**
  String get resetPassword_sessionExpired;

  /// No description provided for @adminRegistration_title.
  ///
  /// In en, this message translates to:
  /// **'Admin Registration'**
  String get adminRegistration_title;

  /// No description provided for @adminRegistration_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Register as an administrator for RGS HVAC Services'**
  String get adminRegistration_subtitle;

  /// No description provided for @adminRegistration_fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get adminRegistration_fullNameLabel;

  /// No description provided for @adminRegistration_fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get adminRegistration_fullNameHint;

  /// No description provided for @adminRegistration_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get adminRegistration_emailLabel;

  /// No description provided for @adminRegistration_emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter company email'**
  String get adminRegistration_emailHint;

  /// No description provided for @adminRegistration_passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get adminRegistration_passwordLabel;

  /// No description provided for @adminRegistration_passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get adminRegistration_passwordHint;

  /// No description provided for @adminRegistration_confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get adminRegistration_confirmPasswordLabel;

  /// No description provided for @adminRegistration_confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get adminRegistration_confirmPasswordHint;

  /// No description provided for @adminRegistration_registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register as Admin'**
  String get adminRegistration_registerButton;

  /// No description provided for @adminRegistration_alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get adminRegistration_alreadyHaveAccount;

  /// No description provided for @adminRegistration_loadingRole.
  ///
  /// In en, this message translates to:
  /// **'Loading admin role...'**
  String get adminRegistration_loadingRole;

  /// No description provided for @adminRegistration_positionNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Super Admin position not configured. Please run the admin positions migration.'**
  String get adminRegistration_positionNotConfigured;

  /// No description provided for @adminRegistration_accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Admin account created successfully! Welcome to RGS HVAC Services.'**
  String get adminRegistration_accountCreated;

  /// No description provided for @adminRegistration_invalidDomain.
  ///
  /// In en, this message translates to:
  /// **'Invalid email domain for admin registration. Use {domains}'**
  String adminRegistration_invalidDomain(String domains);

  /// No description provided for @adminRegistration_checkEmailConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Please check your email and click the confirmation link to verify your admin account. You must confirm your email before you can log in.'**
  String get adminRegistration_checkEmailConfirmation;

  /// No description provided for @adminRegistration_afterConfirmation.
  ///
  /// In en, this message translates to:
  /// **'After confirming your email, you can log in with your admin credentials.'**
  String get adminRegistration_afterConfirmation;

  /// No description provided for @adminRegistration_connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error: Please check your internet connection and try again.'**
  String get adminRegistration_connectionError;

  /// No description provided for @adminRegistration_emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please use a different email or try logging in.'**
  String get adminRegistration_emailAlreadyRegistered;

  /// No description provided for @adminRegistration_invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address. Please check and try again.'**
  String get adminRegistration_invalidEmail;

  /// No description provided for @adminRegistration_weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please use a stronger password.'**
  String get adminRegistration_weakPassword;

  /// No description provided for @techRegistration_title.
  ///
  /// In en, this message translates to:
  /// **'Technician Registration'**
  String get techRegistration_title;

  /// No description provided for @techRegistration_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Register as a technician for RGS HVAC Services'**
  String get techRegistration_subtitle;

  /// No description provided for @techRegistration_fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get techRegistration_fullNameLabel;

  /// No description provided for @techRegistration_fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get techRegistration_fullNameHint;

  /// No description provided for @techRegistration_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get techRegistration_emailLabel;

  /// No description provided for @techRegistration_emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get techRegistration_emailHint;

  /// No description provided for @techRegistration_phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get techRegistration_phoneLabel;

  /// No description provided for @techRegistration_phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get techRegistration_phoneHint;

  /// No description provided for @techRegistration_departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get techRegistration_departmentLabel;

  /// No description provided for @techRegistration_departmentHint.
  ///
  /// In en, this message translates to:
  /// **'Select department'**
  String get techRegistration_departmentHint;

  /// No description provided for @techRegistration_passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get techRegistration_passwordLabel;

  /// No description provided for @techRegistration_passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get techRegistration_passwordHint;

  /// No description provided for @techRegistration_confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get techRegistration_confirmPasswordLabel;

  /// No description provided for @techRegistration_confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get techRegistration_confirmPasswordHint;

  /// No description provided for @techRegistration_registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register as Technician'**
  String get techRegistration_registerButton;

  /// No description provided for @techRegistration_alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get techRegistration_alreadyHaveAccount;

  /// No description provided for @pendingApproval_titlePending.
  ///
  /// In en, this message translates to:
  /// **'Account Pending Approval'**
  String get pendingApproval_titlePending;

  /// No description provided for @pendingApproval_titleRejected.
  ///
  /// In en, this message translates to:
  /// **'Account Approval Rejected'**
  String get pendingApproval_titleRejected;

  /// No description provided for @pendingApproval_descriptionPending.
  ///
  /// In en, this message translates to:
  /// **'Your technician account has been created and submitted for admin approval. You will be notified once your account is approved and you can access the system.'**
  String get pendingApproval_descriptionPending;

  /// No description provided for @pendingApproval_descriptionRejected.
  ///
  /// In en, this message translates to:
  /// **'Your technician account request has been rejected. Please review the reason below and contact your administrator if you have questions.'**
  String get pendingApproval_descriptionRejected;

  /// No description provided for @pendingApproval_currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get pendingApproval_currentStatus;

  /// No description provided for @pendingApproval_statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Admin Approval'**
  String get pendingApproval_statusPending;

  /// No description provided for @pendingApproval_statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get pendingApproval_statusRejected;

  /// No description provided for @pendingApproval_rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason:'**
  String get pendingApproval_rejectionReason;

  /// No description provided for @pendingApproval_rejectionWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: This is rejection #{count}. After 3 rejections, your account will be permanently deleted.'**
  String pendingApproval_rejectionWarning(int count);

  /// No description provided for @pendingApproval_checkStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Approval Status'**
  String get pendingApproval_checkStatus;

  /// No description provided for @pendingApproval_checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get pendingApproval_checking;

  /// No description provided for @pendingApproval_autoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Status is checked automatically every 5 seconds'**
  String get pendingApproval_autoRefresh;

  /// No description provided for @pendingApproval_contactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Questions? Contact your administrator'**
  String get pendingApproval_contactAdmin;

  /// No description provided for @pendingApproval_approved.
  ///
  /// In en, this message translates to:
  /// **'Your account has been approved! Welcome to RGS HVAC Services.'**
  String get pendingApproval_approved;

  /// No description provided for @pendingApproval_errorSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Error signing out: {error}'**
  String pendingApproval_errorSigningOut(String error);

  /// No description provided for @adminHome_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminHome_dashboard;

  /// No description provided for @adminHome_tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get adminHome_tools;

  /// No description provided for @adminHome_sharedTools.
  ///
  /// In en, this message translates to:
  /// **'Shared Tools'**
  String get adminHome_sharedTools;

  /// No description provided for @adminHome_technicians.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get adminHome_technicians;

  /// No description provided for @adminHome_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminHome_reports;

  /// No description provided for @adminHome_maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get adminHome_maintenance;

  /// No description provided for @adminHome_approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get adminHome_approvals;

  /// No description provided for @adminHome_toolIssues.
  ///
  /// In en, this message translates to:
  /// **'Tool Issues'**
  String get adminHome_toolIssues;

  /// No description provided for @adminHome_toolHistory.
  ///
  /// In en, this message translates to:
  /// **'Tool History'**
  String get adminHome_toolHistory;

  /// No description provided for @adminHome_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get adminHome_notifications;

  /// No description provided for @adminHome_myTools.
  ///
  /// In en, this message translates to:
  /// **'My Tools'**
  String get adminHome_myTools;

  /// No description provided for @adminHome_manageAdmins.
  ///
  /// In en, this message translates to:
  /// **'Manage Admins'**
  String get adminHome_manageAdmins;

  /// No description provided for @adminHome_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminHome_settings;

  /// No description provided for @adminHome_deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get adminHome_deleteAccount;

  /// No description provided for @adminHome_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get adminHome_account;

  /// No description provided for @adminHome_accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get adminHome_accountDetails;

  /// No description provided for @adminHome_preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get adminHome_preferences;

  /// No description provided for @adminHome_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get adminHome_security;

  /// No description provided for @adminHome_editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get adminHome_editName;

  /// No description provided for @adminHome_fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get adminHome_fullName;

  /// No description provided for @adminHome_enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get adminHome_enterFullName;

  /// No description provided for @adminHome_nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated successfully'**
  String get adminHome_nameUpdated;

  /// No description provided for @adminHome_failedToUpdateName.
  ///
  /// In en, this message translates to:
  /// **'Failed to update name'**
  String get adminHome_failedToUpdateName;

  /// No description provided for @adminHome_memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get adminHome_memberSince;

  /// No description provided for @adminHome_role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get adminHome_role;

  /// No description provided for @adminHome_adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminHome_adminPanel;

  /// No description provided for @adminHome_somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get adminHome_somethingWentWrong;

  /// No description provided for @adminHome_tryLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Please try logging out and back in'**
  String get adminHome_tryLoggingOut;

  /// No description provided for @adminHome_logoutAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Logout & Try Again'**
  String get adminHome_logoutAndTryAgain;

  /// No description provided for @adminDashboard_title.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashboard_title;

  /// No description provided for @adminDashboard_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview of your tools, technicians, and approvals.'**
  String get adminDashboard_overview;

  /// No description provided for @adminDashboard_keyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Key Metrics'**
  String get adminDashboard_keyMetrics;

  /// No description provided for @adminDashboard_totalTools.
  ///
  /// In en, this message translates to:
  /// **'Total Tools'**
  String get adminDashboard_totalTools;

  /// No description provided for @adminDashboard_technicians.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get adminDashboard_technicians;

  /// No description provided for @adminDashboard_totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get adminDashboard_totalValue;

  /// No description provided for @adminDashboard_maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get adminDashboard_maintenance;

  /// No description provided for @adminDashboard_last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get adminDashboard_last30Days;

  /// No description provided for @adminDashboard_quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get adminDashboard_quickActions;

  /// No description provided for @adminDashboard_addTool.
  ///
  /// In en, this message translates to:
  /// **'Add Tool'**
  String get adminDashboard_addTool;

  /// No description provided for @adminDashboard_assignTool.
  ///
  /// In en, this message translates to:
  /// **'Assign Tool'**
  String get adminDashboard_assignTool;

  /// No description provided for @adminDashboard_authorizeUsers.
  ///
  /// In en, this message translates to:
  /// **'Authorize Users'**
  String get adminDashboard_authorizeUsers;

  /// No description provided for @adminDashboard_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminDashboard_reports;

  /// No description provided for @adminDashboard_toolIssues.
  ///
  /// In en, this message translates to:
  /// **'Tool Issues'**
  String get adminDashboard_toolIssues;

  /// No description provided for @adminDashboard_approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get adminDashboard_approvals;

  /// No description provided for @adminDashboard_maintenanceSchedule.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Schedule'**
  String get adminDashboard_maintenanceSchedule;

  /// No description provided for @adminDashboard_toolHistory.
  ///
  /// In en, this message translates to:
  /// **'Tool History'**
  String get adminDashboard_toolHistory;

  /// No description provided for @adminDashboard_fleetStatus.
  ///
  /// In en, this message translates to:
  /// **'Fleet status'**
  String get adminDashboard_fleetStatus;

  /// No description provided for @adminDashboard_toolStatus.
  ///
  /// In en, this message translates to:
  /// **'Tool Status'**
  String get adminDashboard_toolStatus;

  /// No description provided for @adminDashboard_greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get adminDashboard_greetingMorning;

  /// No description provided for @adminDashboard_greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get adminDashboard_greetingAfternoon;

  /// No description provided for @adminDashboard_greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get adminDashboard_greetingEvening;

  /// No description provided for @adminDashboard_manageTools.
  ///
  /// In en, this message translates to:
  /// **'Manage your HVAC tools and technicians'**
  String get adminDashboard_manageTools;

  /// No description provided for @adminManagement_title.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminManagement_title;

  /// No description provided for @adminManagement_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading admins...'**
  String get adminManagement_loading;

  /// No description provided for @adminManagement_noAdmins.
  ///
  /// In en, this message translates to:
  /// **'No admins yet'**
  String get adminManagement_noAdmins;

  /// No description provided for @adminManagement_tapPlusToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add an admin'**
  String get adminManagement_tapPlusToAdd;

  /// No description provided for @adminManagement_removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove Admin'**
  String get adminManagement_removeAdmin;

  /// No description provided for @adminManagement_removeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from admin access?'**
  String adminManagement_removeConfirm(String name);

  /// No description provided for @adminManagement_removeNote.
  ///
  /// In en, this message translates to:
  /// **'Their authentication account will remain but they will lose admin privileges.'**
  String get adminManagement_removeNote;

  /// No description provided for @adminManagement_removed.
  ///
  /// In en, this message translates to:
  /// **'{name} has been removed from admin access'**
  String adminManagement_removed(String name);

  /// No description provided for @adminManagement_removeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove admin'**
  String get adminManagement_removeFailed;

  /// No description provided for @adminManagement_unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get adminManagement_unassigned;

  /// No description provided for @adminNotification_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get adminNotification_title;

  /// No description provided for @adminNotification_markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get adminNotification_markAllRead;

  /// No description provided for @adminNotification_errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get adminNotification_errorLoading;

  /// No description provided for @adminNotification_empty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get adminNotification_empty;

  /// No description provided for @adminNotification_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see technician requests here'**
  String get adminNotification_emptyHint;

  /// No description provided for @adminNotification_technicianDetails.
  ///
  /// In en, this message translates to:
  /// **'Technician Details:'**
  String get adminNotification_technicianDetails;

  /// No description provided for @adminNotification_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get adminNotification_time;

  /// No description provided for @adminNotification_justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get adminNotification_justNow;

  /// No description provided for @adminNotification_minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String adminNotification_minutesAgo(int count);

  /// No description provided for @adminNotification_hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String adminNotification_hoursAgo(int count);

  /// No description provided for @adminNotification_daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String adminNotification_daysAgo(int count);

  /// No description provided for @adminNotification_markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark Read'**
  String get adminNotification_markRead;

  /// No description provided for @adminNotification_markUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark Unread'**
  String get adminNotification_markUnread;

  /// No description provided for @tools_title.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools_title;

  /// No description provided for @tools_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tools...'**
  String get tools_searchHint;

  /// No description provided for @tools_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tools found'**
  String get tools_emptyTitle;

  /// No description provided for @tools_emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first tool to get started'**
  String get tools_emptySubtitle;

  /// No description provided for @tools_addTool.
  ///
  /// In en, this message translates to:
  /// **'Add Tool'**
  String get tools_addTool;

  /// No description provided for @tools_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tools_filterAll;

  /// No description provided for @tools_filterAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get tools_filterAvailable;

  /// No description provided for @tools_filterAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get tools_filterAssigned;

  /// No description provided for @tools_filterMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get tools_filterMaintenance;

  /// No description provided for @tools_deleteTool.
  ///
  /// In en, this message translates to:
  /// **'Delete Tool'**
  String get tools_deleteTool;

  /// No description provided for @tools_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this tool? This action cannot be undone.'**
  String get tools_deleteConfirm;

  /// No description provided for @toolDetail_title.
  ///
  /// In en, this message translates to:
  /// **'Tool Details'**
  String get toolDetail_title;

  /// No description provided for @toolDetail_brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get toolDetail_brand;

  /// No description provided for @toolDetail_model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get toolDetail_model;

  /// No description provided for @toolDetail_serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get toolDetail_serialNumber;

  /// No description provided for @toolDetail_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get toolDetail_category;

  /// No description provided for @toolDetail_condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get toolDetail_condition;

  /// No description provided for @toolDetail_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get toolDetail_location;

  /// No description provided for @toolDetail_assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned To'**
  String get toolDetail_assignedTo;

  /// No description provided for @toolDetail_purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get toolDetail_purchaseDate;

  /// No description provided for @toolDetail_purchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get toolDetail_purchasePrice;

  /// No description provided for @toolDetail_currentValue.
  ///
  /// In en, this message translates to:
  /// **'Current Value'**
  String get toolDetail_currentValue;

  /// No description provided for @toolDetail_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get toolDetail_notes;

  /// No description provided for @toolDetail_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get toolDetail_status;

  /// No description provided for @toolDetail_toolType.
  ///
  /// In en, this message translates to:
  /// **'Tool Type'**
  String get toolDetail_toolType;

  /// No description provided for @toolDetail_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get toolDetail_history;

  /// No description provided for @toolDetail_noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history available'**
  String get toolDetail_noHistory;

  /// No description provided for @toolDetail_unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get toolDetail_unassigned;

  /// No description provided for @toolDetail_returnTool.
  ///
  /// In en, this message translates to:
  /// **'Return Tool'**
  String get toolDetail_returnTool;

  /// No description provided for @toolDetail_assignTool.
  ///
  /// In en, this message translates to:
  /// **'Assign Tool'**
  String get toolDetail_assignTool;

  /// No description provided for @toolDetail_editTool.
  ///
  /// In en, this message translates to:
  /// **'Edit Tool'**
  String get toolDetail_editTool;

  /// No description provided for @toolDetail_deleteTool.
  ///
  /// In en, this message translates to:
  /// **'Delete Tool'**
  String get toolDetail_deleteTool;

  /// No description provided for @addTool_title.
  ///
  /// In en, this message translates to:
  /// **'Add Tool'**
  String get addTool_title;

  /// No description provided for @addTool_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Tool Name'**
  String get addTool_nameLabel;

  /// No description provided for @addTool_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tool name'**
  String get addTool_nameHint;

  /// No description provided for @addTool_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a tool name'**
  String get addTool_nameRequired;

  /// No description provided for @addTool_categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get addTool_categoryLabel;

  /// No description provided for @addTool_categoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get addTool_categoryHint;

  /// No description provided for @addTool_categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get addTool_categoryRequired;

  /// No description provided for @addTool_brandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get addTool_brandLabel;

  /// No description provided for @addTool_brandHint.
  ///
  /// In en, this message translates to:
  /// **'Enter brand'**
  String get addTool_brandHint;

  /// No description provided for @addTool_modelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get addTool_modelLabel;

  /// No description provided for @addTool_modelHint.
  ///
  /// In en, this message translates to:
  /// **'Enter model'**
  String get addTool_modelHint;

  /// No description provided for @addTool_serialNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get addTool_serialNumberLabel;

  /// No description provided for @addTool_serialNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter serial number'**
  String get addTool_serialNumberHint;

  /// No description provided for @addTool_purchaseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get addTool_purchaseDateLabel;

  /// No description provided for @addTool_purchasePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get addTool_purchasePriceLabel;

  /// No description provided for @addTool_currentValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Value'**
  String get addTool_currentValueLabel;

  /// No description provided for @addTool_conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get addTool_conditionLabel;

  /// No description provided for @addTool_conditionHint.
  ///
  /// In en, this message translates to:
  /// **'Select condition'**
  String get addTool_conditionHint;

  /// No description provided for @addTool_locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get addTool_locationLabel;

  /// No description provided for @addTool_locationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter location'**
  String get addTool_locationHint;

  /// No description provided for @addTool_toolTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Tool Type'**
  String get addTool_toolTypeLabel;

  /// No description provided for @addTool_notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get addTool_notesLabel;

  /// No description provided for @addTool_notesHint.
  ///
  /// In en, this message translates to:
  /// **'Enter notes (optional)'**
  String get addTool_notesHint;

  /// No description provided for @addTool_saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Tool'**
  String get addTool_saveButton;

  /// No description provided for @addTool_success.
  ///
  /// In en, this message translates to:
  /// **'Tool added successfully!'**
  String get addTool_success;

  /// No description provided for @addTool_attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo (optional)'**
  String get addTool_attachPhoto;

  /// No description provided for @editTool_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Tool'**
  String get editTool_title;

  /// No description provided for @editTool_saveButton.
  ///
  /// In en, this message translates to:
  /// **'Update Tool'**
  String get editTool_saveButton;

  /// No description provided for @editTool_success.
  ///
  /// In en, this message translates to:
  /// **'Tool updated successfully!'**
  String get editTool_success;

  /// No description provided for @toolHistory_title.
  ///
  /// In en, this message translates to:
  /// **'Tool History'**
  String get toolHistory_title;

  /// No description provided for @toolHistory_noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history records found'**
  String get toolHistory_noHistory;

  /// No description provided for @toolHistory_allHistory.
  ///
  /// In en, this message translates to:
  /// **'All Tool History'**
  String get toolHistory_allHistory;

  /// No description provided for @toolInstances_title.
  ///
  /// In en, this message translates to:
  /// **'Tool Instances'**
  String get toolInstances_title;

  /// No description provided for @toolInstances_empty.
  ///
  /// In en, this message translates to:
  /// **'No instances found'**
  String get toolInstances_empty;

  /// No description provided for @toolIssues_title.
  ///
  /// In en, this message translates to:
  /// **'Tool Issues'**
  String get toolIssues_title;

  /// No description provided for @toolIssues_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get toolIssues_all;

  /// No description provided for @toolIssues_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get toolIssues_open;

  /// No description provided for @toolIssues_inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get toolIssues_inProgress;

  /// No description provided for @toolIssues_resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get toolIssues_resolved;

  /// No description provided for @toolIssues_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get toolIssues_closed;

  /// No description provided for @toolIssues_empty.
  ///
  /// In en, this message translates to:
  /// **'No issues found'**
  String get toolIssues_empty;

  /// No description provided for @toolIssues_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'No tool issues have been reported'**
  String get toolIssues_emptyHint;

  /// No description provided for @toolIssues_reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get toolIssues_reportIssue;

  /// No description provided for @addToolIssue_title.
  ///
  /// In en, this message translates to:
  /// **'Report Tool Issue'**
  String get addToolIssue_title;

  /// No description provided for @addToolIssue_selectTool.
  ///
  /// In en, this message translates to:
  /// **'Select Tool *'**
  String get addToolIssue_selectTool;

  /// No description provided for @addToolIssue_issueDetails.
  ///
  /// In en, this message translates to:
  /// **'Issue Details'**
  String get addToolIssue_issueDetails;

  /// No description provided for @addToolIssue_issueType.
  ///
  /// In en, this message translates to:
  /// **'Issue Type'**
  String get addToolIssue_issueType;

  /// No description provided for @addToolIssue_priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get addToolIssue_priority;

  /// No description provided for @addToolIssue_description.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get addToolIssue_description;

  /// No description provided for @addToolIssue_descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in detail'**
  String get addToolIssue_descriptionHint;

  /// No description provided for @addToolIssue_descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide a description of the issue'**
  String get addToolIssue_descriptionRequired;

  /// No description provided for @addToolIssue_additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get addToolIssue_additionalInfo;

  /// No description provided for @addToolIssue_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get addToolIssue_location;

  /// No description provided for @addToolIssue_locationHint.
  ///
  /// In en, this message translates to:
  /// **'Where did this occur? (optional)'**
  String get addToolIssue_locationHint;

  /// No description provided for @addToolIssue_estimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost'**
  String get addToolIssue_estimatedCost;

  /// No description provided for @addToolIssue_estimatedCostHint.
  ///
  /// In en, this message translates to:
  /// **'Cost to fix/replace (optional)'**
  String get addToolIssue_estimatedCostHint;

  /// No description provided for @addToolIssue_priorityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Priority Guidelines'**
  String get addToolIssue_priorityGuidelines;

  /// No description provided for @addToolIssue_criticalGuideline.
  ///
  /// In en, this message translates to:
  /// **'Safety hazard or complete tool failure'**
  String get addToolIssue_criticalGuideline;

  /// No description provided for @addToolIssue_highGuideline.
  ///
  /// In en, this message translates to:
  /// **'Tool unusable but no safety risk'**
  String get addToolIssue_highGuideline;

  /// No description provided for @addToolIssue_mediumGuideline.
  ///
  /// In en, this message translates to:
  /// **'Tool partially functional'**
  String get addToolIssue_mediumGuideline;

  /// No description provided for @addToolIssue_lowGuideline.
  ///
  /// In en, this message translates to:
  /// **'Minor issue, tool still usable'**
  String get addToolIssue_lowGuideline;

  /// No description provided for @addToolIssue_submitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get addToolIssue_submitButton;

  /// No description provided for @addToolIssue_success.
  ///
  /// In en, this message translates to:
  /// **'Issue reported successfully!'**
  String get addToolIssue_success;

  /// No description provided for @addToolIssue_toolNotFound.
  ///
  /// In en, this message translates to:
  /// **'Selected tool not found. Please refresh and try again.'**
  String get addToolIssue_toolNotFound;

  /// No description provided for @addToolIssue_tableNotFound.
  ///
  /// In en, this message translates to:
  /// **'Tool issues table not found. Please contact administrator.'**
  String get addToolIssue_tableNotFound;

  /// No description provided for @addToolIssue_sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get addToolIssue_sessionExpired;

  /// No description provided for @addToolIssue_permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. You may not have permission to report issues.'**
  String get addToolIssue_permissionDenied;

  /// No description provided for @addToolIssue_fillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get addToolIssue_fillRequired;

  /// No description provided for @addToolIssue_networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection and try again.'**
  String get addToolIssue_networkError;

  /// No description provided for @technicians_title.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get technicians_title;

  /// No description provided for @technicians_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage active, inactive, and assigned technicians'**
  String get technicians_subtitle;

  /// No description provided for @technicians_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search technicians...'**
  String get technicians_searchHint;

  /// No description provided for @technicians_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No technicians found'**
  String get technicians_emptyTitle;

  /// No description provided for @technicians_emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first technician to get started'**
  String get technicians_emptySubtitle;

  /// No description provided for @technicians_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get technicians_filterAll;

  /// No description provided for @technicians_filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get technicians_filterActive;

  /// No description provided for @technicians_filterInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get technicians_filterInactive;

  /// No description provided for @technicians_filterWithTools.
  ///
  /// In en, this message translates to:
  /// **'With Tools'**
  String get technicians_filterWithTools;

  /// No description provided for @technicians_filterWithoutTools.
  ///
  /// In en, this message translates to:
  /// **'Without Tools'**
  String get technicians_filterWithoutTools;

  /// No description provided for @technicians_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Technician'**
  String get technicians_deleteTitle;

  /// No description provided for @technicians_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String technicians_deleteConfirm(String name);

  /// No description provided for @technicians_noTools.
  ///
  /// In en, this message translates to:
  /// **'No tools'**
  String get technicians_noTools;

  /// No description provided for @technicians_noDepartment.
  ///
  /// In en, this message translates to:
  /// **'No department'**
  String get technicians_noDepartment;

  /// No description provided for @technicianDetail_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get technicianDetail_profile;

  /// No description provided for @technicianDetail_tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get technicianDetail_tools;

  /// No description provided for @technicianDetail_issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get technicianDetail_issues;

  /// No description provided for @technicianDetail_editTechnician.
  ///
  /// In en, this message translates to:
  /// **'Edit Technician'**
  String get technicianDetail_editTechnician;

  /// No description provided for @technicianDetail_deleteTechnician.
  ///
  /// In en, this message translates to:
  /// **'Delete Technician'**
  String get technicianDetail_deleteTechnician;

  /// No description provided for @technicianDetail_contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get technicianDetail_contactInfo;

  /// No description provided for @technicianDetail_employmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Employment Details'**
  String get technicianDetail_employmentDetails;

  /// No description provided for @technicianDetail_statusInfo.
  ///
  /// In en, this message translates to:
  /// **'Status Information'**
  String get technicianDetail_statusInfo;

  /// No description provided for @technicianDetail_employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get technicianDetail_employeeId;

  /// No description provided for @technicianDetail_department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get technicianDetail_department;

  /// No description provided for @technicianDetail_hireDate.
  ///
  /// In en, this message translates to:
  /// **'Hire Date'**
  String get technicianDetail_hireDate;

  /// No description provided for @technicianDetail_created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get technicianDetail_created;

  /// No description provided for @technicianDetail_noTools.
  ///
  /// In en, this message translates to:
  /// **'No tools assigned'**
  String get technicianDetail_noTools;

  /// No description provided for @technicianDetail_noToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'This technician has no tools assigned to them'**
  String get technicianDetail_noToolsDesc;

  /// No description provided for @technicianDetail_noIssues.
  ///
  /// In en, this message translates to:
  /// **'No issues reported'**
  String get technicianDetail_noIssues;

  /// No description provided for @technicianDetail_noIssuesDesc.
  ///
  /// In en, this message translates to:
  /// **'This technician has not reported any tool issues'**
  String get technicianDetail_noIssuesDesc;

  /// No description provided for @technicianDetail_deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete:'**
  String get technicianDetail_deleteWarning;

  /// No description provided for @technicianDetail_deleteLine1.
  ///
  /// In en, this message translates to:
  /// **'The technician record'**
  String get technicianDetail_deleteLine1;

  /// No description provided for @technicianDetail_deleteLine2.
  ///
  /// In en, this message translates to:
  /// **'All associated data'**
  String get technicianDetail_deleteLine2;

  /// No description provided for @technicianDetail_deleteCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone!'**
  String get technicianDetail_deleteCannotUndo;

  /// No description provided for @technicianDetail_deleteHasTools.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete technician with assigned tools. Please reassign or return them first.'**
  String get technicianDetail_deleteHasTools;

  /// No description provided for @technicianHome_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get technicianHome_account;

  /// No description provided for @technicianHome_accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get technicianHome_accountDetails;

  /// No description provided for @technicianHome_preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get technicianHome_preferences;

  /// No description provided for @technicianHome_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get technicianHome_security;

  /// No description provided for @technicianHome_editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get technicianHome_editName;

  /// No description provided for @technicianHome_fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get technicianHome_fullName;

  /// No description provided for @technicianHome_enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get technicianHome_enterFullName;

  /// No description provided for @technicianHome_memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get technicianHome_memberSince;

  /// No description provided for @technicianHome_role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get technicianHome_role;

  /// No description provided for @technicianHome_administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get technicianHome_administrator;

  /// No description provided for @technicianHome_technician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technicianHome_technician;

  /// No description provided for @technicianHome_noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get technicianHome_noNotifications;

  /// No description provided for @technicianHome_notificationsHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see notifications here when you receive tool requests'**
  String get technicianHome_notificationsHint;

  /// No description provided for @technicianHome_requestAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Request Account Deletion'**
  String get technicianHome_requestAccountDeletion;

  /// No description provided for @techDashboard_greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get techDashboard_greetingMorning;

  /// No description provided for @techDashboard_greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get techDashboard_greetingAfternoon;

  /// No description provided for @techDashboard_greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get techDashboard_greetingEvening;

  /// No description provided for @techDashboard_welcome.
  ///
  /// In en, this message translates to:
  /// **'Manage your tools and access shared resources'**
  String get techDashboard_welcome;

  /// No description provided for @techDashboard_sharedTools.
  ///
  /// In en, this message translates to:
  /// **'Shared Tools'**
  String get techDashboard_sharedTools;

  /// No description provided for @techDashboard_seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get techDashboard_seeAll;

  /// No description provided for @techDashboard_myTools.
  ///
  /// In en, this message translates to:
  /// **'My Tools'**
  String get techDashboard_myTools;

  /// No description provided for @techDashboard_noTools.
  ///
  /// In en, this message translates to:
  /// **'No tools available'**
  String get techDashboard_noTools;

  /// No description provided for @techDashboard_noToolsHint.
  ///
  /// In en, this message translates to:
  /// **'You have no assigned tools. You can add your first tool or request tool assignment.'**
  String get techDashboard_noToolsHint;

  /// No description provided for @techDashboard_noSharedTools.
  ///
  /// In en, this message translates to:
  /// **'No shared tools available'**
  String get techDashboard_noSharedTools;

  /// No description provided for @techDashboard_noAssignedTools.
  ///
  /// In en, this message translates to:
  /// **'No tools assigned yet'**
  String get techDashboard_noAssignedTools;

  /// No description provided for @techDashboard_noAssignedToolsHint.
  ///
  /// In en, this message translates to:
  /// **'Add or badge tools you currently have to see them here.'**
  String get techDashboard_noAssignedToolsHint;

  /// No description provided for @techDashboard_shared.
  ///
  /// In en, this message translates to:
  /// **'SHARED'**
  String get techDashboard_shared;

  /// No description provided for @techDashboard_request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get techDashboard_request;

  /// No description provided for @myTools_title.
  ///
  /// In en, this message translates to:
  /// **'My Tools'**
  String get myTools_title;

  /// No description provided for @myTools_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tools...'**
  String get myTools_searchHint;

  /// No description provided for @myTools_categoryFilter.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get myTools_categoryFilter;

  /// No description provided for @myTools_statusFilter.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get myTools_statusFilter;

  /// No description provided for @myTools_empty.
  ///
  /// In en, this message translates to:
  /// **'No tools found'**
  String get myTools_empty;

  /// No description provided for @myTools_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first tool to get started'**
  String get myTools_emptyHint;

  /// No description provided for @myTools_addButton.
  ///
  /// In en, this message translates to:
  /// **'Add Tool'**
  String get myTools_addButton;

  /// No description provided for @addTechnician_addTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Technician'**
  String get addTechnician_addTitle;

  /// No description provided for @addTechnician_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Technician'**
  String get addTechnician_editTitle;

  /// No description provided for @addTechnician_addSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add technicians so they can receive assignments and tool access.'**
  String get addTechnician_addSubtitle;

  /// No description provided for @addTechnician_editSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update technician details to keep assignments current.'**
  String get addTechnician_editSubtitle;

  /// No description provided for @addTechnician_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get addTechnician_nameLabel;

  /// No description provided for @addTechnician_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get addTechnician_nameHint;

  /// No description provided for @addTechnician_employeeIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get addTechnician_employeeIdLabel;

  /// No description provided for @addTechnician_employeeIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter employee ID (optional)'**
  String get addTechnician_employeeIdHint;

  /// No description provided for @addTechnician_phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get addTechnician_phoneLabel;

  /// No description provided for @addTechnician_phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get addTechnician_phoneHint;

  /// No description provided for @addTechnician_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get addTechnician_emailLabel;

  /// No description provided for @addTechnician_emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get addTechnician_emailHint;

  /// No description provided for @addTechnician_emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get addTechnician_emailInvalid;

  /// No description provided for @addTechnician_departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get addTechnician_departmentLabel;

  /// No description provided for @addTechnician_departmentHint.
  ///
  /// In en, this message translates to:
  /// **'Select department'**
  String get addTechnician_departmentHint;

  /// No description provided for @addTechnician_statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get addTechnician_statusLabel;

  /// No description provided for @addTechnician_hireDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select hire date'**
  String get addTechnician_hireDateHint;

  /// No description provided for @addTechnician_addButton.
  ///
  /// In en, this message translates to:
  /// **'Add Technician'**
  String get addTechnician_addButton;

  /// No description provided for @addTechnician_updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Technician'**
  String get addTechnician_updateButton;

  /// No description provided for @addTechnician_addSuccess.
  ///
  /// In en, this message translates to:
  /// **'Technician added successfully!'**
  String get addTechnician_addSuccess;

  /// No description provided for @addTechnician_inviteEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Invite email sent to {email}'**
  String addTechnician_inviteEmailSent(String email);

  /// No description provided for @addTechnician_inviteHint.
  ///
  /// In en, this message translates to:
  /// **'Technician should use the invite email to set their password.'**
  String get addTechnician_inviteHint;

  /// No description provided for @addTechnician_updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Technician updated successfully!'**
  String get addTechnician_updateSuccess;

  /// No description provided for @addTechnician_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter technician\'s name'**
  String get addTechnician_nameRequired;

  /// No description provided for @addTechnician_chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get addTechnician_chooseFromGallery;

  /// No description provided for @addTechnician_takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get addTechnician_takePhoto;

  /// No description provided for @addTechnician_removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get addTechnician_removePhoto;

  /// No description provided for @department_repairing.
  ///
  /// In en, this message translates to:
  /// **'Repairing'**
  String get department_repairing;

  /// No description provided for @department_maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get department_maintenance;

  /// No description provided for @department_retrofit.
  ///
  /// In en, this message translates to:
  /// **'Retrofit'**
  String get department_retrofit;

  /// No description provided for @department_installation.
  ///
  /// In en, this message translates to:
  /// **'Installation'**
  String get department_installation;

  /// No description provided for @department_factory.
  ///
  /// In en, this message translates to:
  /// **'Factory'**
  String get department_factory;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_accountSection;

  /// No description provided for @settings_accountDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get settings_accountDetailsSection;

  /// No description provided for @settings_accountManagementSection.
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get settings_accountManagementSection;

  /// No description provided for @settings_preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settings_preferencesSection;

  /// No description provided for @settings_notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notificationsSection;

  /// No description provided for @settings_dataBackupSection.
  ///
  /// In en, this message translates to:
  /// **'Data & Backup'**
  String get settings_dataBackupSection;

  /// No description provided for @settings_aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_aboutSection;

  /// No description provided for @settings_languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_languageLabel;

  /// No description provided for @settings_currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settings_currencyLabel;

  /// No description provided for @settings_pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settings_pushNotifications;

  /// No description provided for @settings_pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive maintenance reminders and updates'**
  String get settings_pushNotificationsSubtitle;

  /// No description provided for @settings_autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get settings_autoBackup;

  /// No description provided for @settings_autoBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically backup data to cloud'**
  String get settings_autoBackupSubtitle;

  /// No description provided for @settings_exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get settings_exportData;

  /// No description provided for @settings_exportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download your data as CSV'**
  String get settings_exportDataSubtitle;

  /// No description provided for @settings_importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get settings_importData;

  /// No description provided for @settings_importDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup file'**
  String get settings_importDataSubtitle;

  /// No description provided for @settings_importDataMessage.
  ///
  /// In en, this message translates to:
  /// **'To import data, please contact support at support@rgstools.app. We will help you restore your data from a backup file.'**
  String get settings_importDataMessage;

  /// No description provided for @settings_appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settings_appVersion;

  /// No description provided for @settings_helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settings_helpSupport;

  /// No description provided for @settings_helpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help and contact support'**
  String get settings_helpSupportSubtitle;

  /// No description provided for @settings_privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settings_privacyPolicy;

  /// No description provided for @settings_privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get settings_privacyPolicySubtitle;

  /// No description provided for @settings_termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settings_termsOfService;

  /// No description provided for @settings_termsOfServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our terms of service'**
  String get settings_termsOfServiceSubtitle;

  /// No description provided for @settings_selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settings_selectLanguage;

  /// No description provided for @settings_selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get settings_selectCurrency;

  /// No description provided for @settings_deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settings_deleteAccount;

  /// No description provided for @settings_deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and data'**
  String get settings_deleteAccountSubtitle;

  /// No description provided for @settings_requestAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Request Account Deletion'**
  String get settings_requestAccountDeletion;

  /// No description provided for @settings_requestAccountDeletionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask your administrator to delete your account'**
  String get settings_requestAccountDeletionSubtitle;

  /// No description provided for @settings_versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version Information'**
  String get settings_versionInfo;

  /// No description provided for @settings_rgsToolsManager.
  ///
  /// In en, this message translates to:
  /// **'RGS Tools Manager'**
  String get settings_rgsToolsManager;

  /// No description provided for @settings_couldNotOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Could not open support page'**
  String get settings_couldNotOpenPage;

  /// No description provided for @settings_exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully! {count} file(s) created.'**
  String settings_exportSuccess(int count);

  /// No description provided for @settings_exportError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting data: {error}'**
  String settings_exportError(String error);

  /// No description provided for @currency_usd.
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get currency_usd;

  /// No description provided for @currency_eur.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get currency_eur;

  /// No description provided for @currency_gbp.
  ///
  /// In en, this message translates to:
  /// **'British Pound'**
  String get currency_gbp;

  /// No description provided for @currency_aed.
  ///
  /// In en, this message translates to:
  /// **'UAE Dirham'**
  String get currency_aed;

  /// No description provided for @reports_title.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports_title;

  /// No description provided for @reports_toolsOverview.
  ///
  /// In en, this message translates to:
  /// **'Tools Overview'**
  String get reports_toolsOverview;

  /// No description provided for @reports_technicianActivity.
  ///
  /// In en, this message translates to:
  /// **'Technician Activity'**
  String get reports_technicianActivity;

  /// No description provided for @reports_maintenanceReport.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Report'**
  String get reports_maintenanceReport;

  /// No description provided for @reports_exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get reports_exportReport;

  /// No description provided for @reports_generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get reports_generateReport;

  /// No description provided for @reports_noData.
  ///
  /// In en, this message translates to:
  /// **'No data available for this report'**
  String get reports_noData;

  /// No description provided for @reports_dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get reports_dateRange;

  /// No description provided for @reports_last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get reports_last7Days;

  /// No description provided for @reports_last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get reports_last30Days;

  /// No description provided for @reports_last90Days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get reports_last90Days;

  /// No description provided for @reports_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reports_custom;

  /// No description provided for @maintenance_title.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance_title;

  /// No description provided for @maintenance_schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule Maintenance'**
  String get maintenance_schedule;

  /// No description provided for @maintenance_noScheduled.
  ///
  /// In en, this message translates to:
  /// **'No maintenance scheduled'**
  String get maintenance_noScheduled;

  /// No description provided for @maintenance_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get maintenance_upcoming;

  /// No description provided for @maintenance_overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get maintenance_overdue;

  /// No description provided for @maintenance_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get maintenance_completed;

  /// No description provided for @checkin_title.
  ///
  /// In en, this message translates to:
  /// **'Check In / Check Out'**
  String get checkin_title;

  /// No description provided for @checkin_scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get checkin_scanBarcode;

  /// No description provided for @checkin_manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get checkin_manualEntry;

  /// No description provided for @checkin_toolId.
  ///
  /// In en, this message translates to:
  /// **'Tool ID'**
  String get checkin_toolId;

  /// No description provided for @checkin_checkInButton.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkin_checkInButton;

  /// No description provided for @checkin_checkOutButton.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkin_checkOutButton;

  /// No description provided for @sharedTools_title.
  ///
  /// In en, this message translates to:
  /// **'Shared Tools'**
  String get sharedTools_title;

  /// No description provided for @sharedTools_empty.
  ///
  /// In en, this message translates to:
  /// **'No shared tools available'**
  String get sharedTools_empty;

  /// No description provided for @sharedTools_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tools marked as shared will appear here'**
  String get sharedTools_emptyHint;

  /// No description provided for @sharedTools_badgeIn.
  ///
  /// In en, this message translates to:
  /// **'Badge In'**
  String get sharedTools_badgeIn;

  /// No description provided for @sharedTools_badgeOut.
  ///
  /// In en, this message translates to:
  /// **'Badge Out'**
  String get sharedTools_badgeOut;

  /// No description provided for @sharedTools_currentHolder.
  ///
  /// In en, this message translates to:
  /// **'Current Holder'**
  String get sharedTools_currentHolder;

  /// No description provided for @sharedTools_noCurrentHolder.
  ///
  /// In en, this message translates to:
  /// **'No current holder'**
  String get sharedTools_noCurrentHolder;

  /// No description provided for @bulkImport_title.
  ///
  /// In en, this message translates to:
  /// **'Bulk Import'**
  String get bulkImport_title;

  /// No description provided for @bulkImport_selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select CSV File'**
  String get bulkImport_selectFile;

  /// No description provided for @bulkImport_importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get bulkImport_importButton;

  /// No description provided for @bulkImport_preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get bulkImport_preview;

  /// No description provided for @bulkImport_rowsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} rows found'**
  String bulkImport_rowsFound(int count);

  /// No description provided for @bulkImport_success.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} tools'**
  String bulkImport_success(int count);

  /// No description provided for @bulkImport_error.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String bulkImport_error(String error);

  /// No description provided for @permanentAssignment_title.
  ///
  /// In en, this message translates to:
  /// **'Permanent Assignment'**
  String get permanentAssignment_title;

  /// No description provided for @permanentAssignment_selectTechnician.
  ///
  /// In en, this message translates to:
  /// **'Select Technician'**
  String get permanentAssignment_selectTechnician;

  /// No description provided for @permanentAssignment_selectTools.
  ///
  /// In en, this message translates to:
  /// **'Select Tools'**
  String get permanentAssignment_selectTools;

  /// No description provided for @permanentAssignment_assignButton.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get permanentAssignment_assignButton;

  /// No description provided for @permanentAssignment_success.
  ///
  /// In en, this message translates to:
  /// **'Tools assigned successfully'**
  String get permanentAssignment_success;

  /// No description provided for @reassignTool_title.
  ///
  /// In en, this message translates to:
  /// **'Reassign Tool'**
  String get reassignTool_title;

  /// No description provided for @reassignTool_currentTechnician.
  ///
  /// In en, this message translates to:
  /// **'Current Technician'**
  String get reassignTool_currentTechnician;

  /// No description provided for @reassignTool_newTechnician.
  ///
  /// In en, this message translates to:
  /// **'New Technician'**
  String get reassignTool_newTechnician;

  /// No description provided for @reassignTool_reassignButton.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassignTool_reassignButton;

  /// No description provided for @reassignTool_success.
  ///
  /// In en, this message translates to:
  /// **'Tool reassigned successfully'**
  String get reassignTool_success;

  /// No description provided for @requestNewTool_title.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get requestNewTool_title;

  /// No description provided for @requestNewTool_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit a request for tools, assignments, transfers, or maintenance'**
  String get requestNewTool_subtitle;

  /// No description provided for @requestNewTool_requestType.
  ///
  /// In en, this message translates to:
  /// **'Request Type'**
  String get requestNewTool_requestType;

  /// No description provided for @requestNewTool_requestInfo.
  ///
  /// In en, this message translates to:
  /// **'Request Information'**
  String get requestNewTool_requestInfo;

  /// No description provided for @requestNewTool_titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title (Optional)'**
  String get requestNewTool_titleLabel;

  /// No description provided for @requestNewTool_titleHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated if left blank'**
  String get requestNewTool_titleHint;

  /// No description provided for @requestNewTool_descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get requestNewTool_descriptionLabel;

  /// No description provided for @requestNewTool_descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated if left blank'**
  String get requestNewTool_descriptionHint;

  /// No description provided for @requestNewTool_justification.
  ///
  /// In en, this message translates to:
  /// **'Justification / Reason *'**
  String get requestNewTool_justification;

  /// No description provided for @requestNewTool_neededBy.
  ///
  /// In en, this message translates to:
  /// **'Needed By (Optional)'**
  String get requestNewTool_neededBy;

  /// No description provided for @requestNewTool_selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get requestNewTool_selectDate;

  /// No description provided for @requestNewTool_siteLocation.
  ///
  /// In en, this message translates to:
  /// **'Site / Location'**
  String get requestNewTool_siteLocation;

  /// No description provided for @requestNewTool_siteLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Building A, Floor 3'**
  String get requestNewTool_siteLocationHint;

  /// No description provided for @requestNewTool_submitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get requestNewTool_submitButton;

  /// No description provided for @requestNewTool_success.
  ///
  /// In en, this message translates to:
  /// **'Request submitted successfully!'**
  String get requestNewTool_success;

  /// No description provided for @requestNewTool_toolDetails.
  ///
  /// In en, this message translates to:
  /// **'Tool Details'**
  String get requestNewTool_toolDetails;

  /// No description provided for @requestNewTool_assignmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Assignment Details'**
  String get requestNewTool_assignmentDetails;

  /// No description provided for @requestNewTool_transferDetails.
  ///
  /// In en, this message translates to:
  /// **'Transfer Details'**
  String get requestNewTool_transferDetails;

  /// No description provided for @requestNewTool_maintenanceDetails.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Details'**
  String get requestNewTool_maintenanceDetails;

  /// No description provided for @requestNewTool_disposalDetails.
  ///
  /// In en, this message translates to:
  /// **'Disposal Details'**
  String get requestNewTool_disposalDetails;

  /// No description provided for @requestNewTool_toolName.
  ///
  /// In en, this message translates to:
  /// **'Tool Name'**
  String get requestNewTool_toolName;

  /// No description provided for @requestNewTool_toolSerial.
  ///
  /// In en, this message translates to:
  /// **'Tool Serial Number (Optional)'**
  String get requestNewTool_toolSerial;

  /// No description provided for @requestNewTool_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get requestNewTool_quantity;

  /// No description provided for @requestNewTool_unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price (AED)'**
  String get requestNewTool_unitPrice;

  /// No description provided for @requestNewTool_totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost (AED)'**
  String get requestNewTool_totalCost;

  /// No description provided for @requestNewTool_supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier (Optional)'**
  String get requestNewTool_supplier;

  /// No description provided for @requestNewTool_assignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign To (Your Name or Another Technician)'**
  String get requestNewTool_assignTo;

  /// No description provided for @requestNewTool_project.
  ///
  /// In en, this message translates to:
  /// **'Project/Site'**
  String get requestNewTool_project;

  /// No description provided for @requestNewTool_fromLocation.
  ///
  /// In en, this message translates to:
  /// **'From Location'**
  String get requestNewTool_fromLocation;

  /// No description provided for @requestNewTool_toLocation.
  ///
  /// In en, this message translates to:
  /// **'To Location'**
  String get requestNewTool_toLocation;

  /// No description provided for @requestNewTool_maintenanceType.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Type'**
  String get requestNewTool_maintenanceType;

  /// No description provided for @requestNewTool_currentCondition.
  ///
  /// In en, this message translates to:
  /// **'Current Condition'**
  String get requestNewTool_currentCondition;

  /// No description provided for @requestNewTool_attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo or spec (optional)'**
  String get requestNewTool_attachPhoto;

  /// No description provided for @requestNewTool_enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get requestNewTool_enterValidNumber;

  /// No description provided for @requestType_toolPurchase.
  ///
  /// In en, this message translates to:
  /// **'Tool Purchase'**
  String get requestType_toolPurchase;

  /// No description provided for @requestType_toolAssignment.
  ///
  /// In en, this message translates to:
  /// **'Tool Assignment'**
  String get requestType_toolAssignment;

  /// No description provided for @requestType_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get requestType_transfer;

  /// No description provided for @requestType_maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get requestType_maintenance;

  /// No description provided for @requestType_toolDisposal.
  ///
  /// In en, this message translates to:
  /// **'Tool Disposal'**
  String get requestType_toolDisposal;
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
      <String>['ar', 'en', 'es', 'fr'].contains(locale.languageCode);

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
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
