// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'RGS Outils CVC';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_close => 'Fermer';

  @override
  String get common_ok => 'OK';

  @override
  String get common_retry => 'Réessayer';

  @override
  String get common_remove => 'Retirer';

  @override
  String get common_view => 'Voir';

  @override
  String get common_back => 'Retour';

  @override
  String get common_search => 'Rechercher';

  @override
  String get common_loading => 'Chargement...';

  @override
  String get common_error => 'Erreur';

  @override
  String get common_success => 'Succès';

  @override
  String get common_unknown => 'Inconnu';

  @override
  String get common_notAvailable => 'Non disponible';

  @override
  String get common_required => 'Required';

  @override
  String get common_optional => 'Optional';

  @override
  String get common_all => 'All';

  @override
  String get common_none => 'None';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_signOut => 'Déconnexion';

  @override
  String get common_logout => 'Déconnexion';

  @override
  String get common_settings => 'Paramètres';

  @override
  String get common_notifications => 'Notifications';

  @override
  String get common_email => 'E-mail';

  @override
  String get common_password => 'Mot de passe';

  @override
  String get common_name => 'Nom';

  @override
  String get common_phone => 'Phone';

  @override
  String get common_status => 'Statut';

  @override
  String get common_active => 'Actif';

  @override
  String get common_inactive => 'Inactif';

  @override
  String get common_camera => 'Camera';

  @override
  String get common_gallery => 'Gallery';

  @override
  String get common_addImage => 'Add Image';

  @override
  String get common_selectImageSource => 'Select Image Source';

  @override
  String common_failedToPickImage(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get common_somethingWentWrong =>
      'Oops! Something went wrong. Please try again.';

  @override
  String get common_offlineBanner =>
      'Hors ligne — affichage des données en cache';

  @override
  String get common_noImage => 'No Image';

  @override
  String get status_available => 'Available';

  @override
  String get status_assigned => 'Assigned';

  @override
  String get status_inUse => 'In Use';

  @override
  String get status_maintenance => 'Maintenance';

  @override
  String get status_retired => 'Retired';

  @override
  String get status_lost => 'Lost';

  @override
  String get priority_low => 'Low';

  @override
  String get priority_medium => 'Medium';

  @override
  String get priority_high => 'High';

  @override
  String get priority_critical => 'Critical';

  @override
  String get priority_normal => 'Normal';

  @override
  String get priority_urgent => 'Urgent';

  @override
  String get validation_required => 'This field is required';

  @override
  String get validation_emailRequired => 'Please enter your email';

  @override
  String get validation_emailInvalid => 'Please enter a valid email address';

  @override
  String get validation_passwordRequired => 'Please enter your password';

  @override
  String get validation_passwordMinLength =>
      'Password must be at least 6 characters';

  @override
  String get validation_passwordMismatch => 'Passwords do not match';

  @override
  String get validation_nameRequired => 'Please enter your full name';

  @override
  String get validation_phoneRequired => 'Please enter your phone number';

  @override
  String get validation_pleaseSelectTool => 'Please select a tool';

  @override
  String get roleSelection_subtitle =>
      'Tool Tracking • Assignments • Inventory';

  @override
  String get roleSelection_registerAdmin => 'Register as Admin';

  @override
  String get roleSelection_continueAdmin => 'Continue as Admin';

  @override
  String get roleSelection_registerTechnician => 'Register as Technician';

  @override
  String get roleSelection_continueTechnician => 'Continue as Technician';

  @override
  String get roleSelection_alreadyHaveAccount => 'Already have an account? ';

  @override
  String get roleSelection_signIn => 'Sign in';

  @override
  String get roleSelection_adminClosedError =>
      'Admin registration is closed. Please request an admin invite.';

  @override
  String get login_title => 'Sign In';

  @override
  String get login_emailLabel => 'Email Address';

  @override
  String get login_emailHint => 'Enter your email';

  @override
  String get login_passwordLabel => 'Password';

  @override
  String get login_passwordHint => 'Enter your password';

  @override
  String get login_signInButton => 'Sign In';

  @override
  String get login_forgotPassword => 'Forgot Password?';

  @override
  String get login_orContinueWith => 'Or continue with';

  @override
  String get login_or => 'OR';

  @override
  String get login_google => 'Google';

  @override
  String get login_apple => 'Apple';

  @override
  String get login_registerPrompt => 'Don\'t have an account? Register Here';

  @override
  String get login_registerSubtext => 'Choose Admin or Technician registration';

  @override
  String get login_welcomeBack => 'Welcome Back';

  @override
  String get login_welcomeBackSubtitle =>
      'Sign in to your RGS HVAC Services account';

  @override
  String get login_successMessage => 'Welcome back! Successfully signed in.';

  @override
  String get login_accessDenied => 'Access denied: Invalid admin credentials';

  @override
  String get login_emailRequiredFirst =>
      'Please enter your email address first';

  @override
  String get login_passwordResetSent =>
      'Password reset email sent! Check your inbox.';

  @override
  String get login_appleCancelled => 'Apple sign-in was cancelled.';

  @override
  String get login_appleFailed => 'Apple sign-in failed.';

  @override
  String get login_oauthAccountExists =>
      'This email is already registered. Please sign in with your email and password.';

  @override
  String get login_emailDomainNotAllowed =>
      'Email domain not allowed. Use @mekar.ae or other approved domains';

  @override
  String get login_resetPasswordDialogTitle => 'Reset Password';

  @override
  String get login_resetPasswordDialogMessage =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get login_resetPasswordEmailHint => 'your.email@example.com';

  @override
  String get login_resetPasswordSendButton => 'Send Reset Link';

  @override
  String get login_resetPasswordSuccessTitle => 'Email Sent!';

  @override
  String login_resetPasswordSuccessMessage(String email) {
    return 'We\'ve sent a password reset link to $email. Please check your inbox and follow the instructions to reset your password.';
  }

  @override
  String get register_createAccount => 'Create your account to get started.';

  @override
  String get register_fullNameLabel => 'Full Name';

  @override
  String get register_emailLabel => 'Email';

  @override
  String get register_passwordLabel => 'Password';

  @override
  String get register_confirmPasswordLabel => 'Confirm Password';

  @override
  String get register_phoneLabel => 'Phone Number';

  @override
  String get register_departmentLabel => 'Department';

  @override
  String get register_roleLabel => 'Role';

  @override
  String get register_createAccountButton => 'Create Account';

  @override
  String get register_signInLink => 'Already have an account? Sign In';

  @override
  String get register_backToRoleSelection => 'Back to Role Selection';

  @override
  String get register_checkYourEmail => 'Check Your Email';

  @override
  String get register_confirmationEmailSent =>
      'We\'ve sent a confirmation email to:';

  @override
  String get register_confirmationInstructions =>
      'Please check your email and click the confirmation link to verify your account. After verification, your account will be pending admin approval.';

  @override
  String get register_goToLogin => 'Go to Login';

  @override
  String get register_pendingApproval =>
      'Your account is pending admin approval. You will be notified once approved.';

  @override
  String get register_emailFormatValidation =>
      'Please enter a valid email address (e.g., name@example.com)';

  @override
  String get resetPassword_title => 'Reset Password';

  @override
  String get resetPassword_subtitle => 'Enter your new password below';

  @override
  String get resetPassword_newPasswordLabel => 'New Password';

  @override
  String get resetPassword_confirmLabel => 'Confirm New Password';

  @override
  String get resetPassword_button => 'Reset Password';

  @override
  String get resetPassword_backToLogin => 'Back to Login';

  @override
  String get resetPassword_successMessage =>
      'Password set successfully! Redirecting...';

  @override
  String get resetPassword_sessionExpired =>
      'Session expired. Please open the invite link again.';

  @override
  String get adminRegistration_title => 'Admin Registration';

  @override
  String get adminRegistration_subtitle =>
      'Register as an administrator for RGS HVAC Services';

  @override
  String get adminRegistration_fullNameLabel => 'Full Name';

  @override
  String get adminRegistration_fullNameHint => 'Enter full name';

  @override
  String get adminRegistration_emailLabel => 'Email Address';

  @override
  String get adminRegistration_emailHint => 'Enter company email';

  @override
  String get adminRegistration_passwordLabel => 'Password';

  @override
  String get adminRegistration_passwordHint => 'Minimum 6 characters';

  @override
  String get adminRegistration_confirmPasswordLabel => 'Confirm Password';

  @override
  String get adminRegistration_confirmPasswordHint => 'Re-enter password';

  @override
  String get adminRegistration_registerButton => 'Register as Admin';

  @override
  String get adminRegistration_alreadyHaveAccount => 'Already have an account?';

  @override
  String get adminRegistration_loadingRole => 'Loading admin role...';

  @override
  String get adminRegistration_positionNotConfigured =>
      'Super Admin position not configured. Please run the admin positions migration.';

  @override
  String get adminRegistration_accountCreated =>
      'Admin account created successfully! Welcome to RGS HVAC Services.';

  @override
  String adminRegistration_invalidDomain(String domains) {
    return 'Invalid email domain for admin registration. Use $domains';
  }

  @override
  String get adminRegistration_checkEmailConfirmation =>
      'Please check your email and click the confirmation link to verify your admin account. You must confirm your email before you can log in.';

  @override
  String get adminRegistration_afterConfirmation =>
      'After confirming your email, you can log in with your admin credentials.';

  @override
  String get adminRegistration_connectionError =>
      'Connection error: Please check your internet connection and try again.';

  @override
  String get adminRegistration_emailAlreadyRegistered =>
      'This email is already registered. Please use a different email or try logging in.';

  @override
  String get adminRegistration_invalidEmail =>
      'Invalid email address. Please check and try again.';

  @override
  String get adminRegistration_weakPassword =>
      'Password is too weak. Please use a stronger password.';

  @override
  String get techRegistration_title => 'Technician Registration';

  @override
  String get techRegistration_subtitle =>
      'Register as a technician for RGS HVAC Services';

  @override
  String get techRegistration_fullNameLabel => 'Full Name';

  @override
  String get techRegistration_fullNameHint => 'Enter full name';

  @override
  String get techRegistration_emailLabel => 'Email Address';

  @override
  String get techRegistration_emailHint => 'Enter email address';

  @override
  String get techRegistration_phoneLabel => 'Phone Number';

  @override
  String get techRegistration_phoneHint => 'Enter phone number';

  @override
  String get techRegistration_departmentLabel => 'Department';

  @override
  String get techRegistration_departmentHint => 'Select department';

  @override
  String get techRegistration_passwordLabel => 'Password';

  @override
  String get techRegistration_passwordHint => 'Minimum 6 characters';

  @override
  String get techRegistration_confirmPasswordLabel => 'Confirm Password';

  @override
  String get techRegistration_confirmPasswordHint => 'Re-enter password';

  @override
  String get techRegistration_registerButton => 'Register as Technician';

  @override
  String get techRegistration_alreadyHaveAccount => 'Already have an account?';

  @override
  String get pendingApproval_titlePending => 'Account Pending Approval';

  @override
  String get pendingApproval_titleRejected => 'Account Approval Rejected';

  @override
  String get pendingApproval_descriptionPending =>
      'Your technician account has been created and submitted for admin approval. You will be notified once your account is approved and you can access the system.';

  @override
  String get pendingApproval_descriptionRejected =>
      'Your technician account request has been rejected. Please review the reason below and contact your administrator if you have questions.';

  @override
  String get pendingApproval_currentStatus => 'Current Status';

  @override
  String get pendingApproval_statusPending => 'Pending Admin Approval';

  @override
  String get pendingApproval_statusRejected => 'Rejected';

  @override
  String get pendingApproval_rejectionReason => 'Rejection Reason:';

  @override
  String pendingApproval_rejectionWarning(int count) {
    return 'Warning: This is rejection #$count. After 3 rejections, your account will be permanently deleted.';
  }

  @override
  String get pendingApproval_checkStatus => 'Check Approval Status';

  @override
  String get pendingApproval_checking => 'Checking...';

  @override
  String get pendingApproval_autoRefresh =>
      'Status is checked automatically every 5 seconds';

  @override
  String get pendingApproval_contactAdmin =>
      'Questions? Contact your administrator';

  @override
  String get pendingApproval_approved =>
      'Your account has been approved! Welcome to RGS HVAC Services.';

  @override
  String pendingApproval_errorSigningOut(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get adminHome_dashboard => 'Dashboard';

  @override
  String get adminHome_tools => 'Tools';

  @override
  String get adminHome_sharedTools => 'Shared Tools';

  @override
  String get adminHome_technicians => 'Technicians';

  @override
  String get adminHome_reports => 'Reports';

  @override
  String get adminHome_maintenance => 'Maintenance';

  @override
  String get adminHome_approvals => 'Approvals';

  @override
  String get adminHome_toolIssues => 'Tool Issues';

  @override
  String get adminHome_toolHistory => 'Tool History';

  @override
  String get adminHome_notifications => 'Notifications';

  @override
  String get adminHome_myTools => 'My Tools';

  @override
  String get adminHome_manageAdmins => 'Manage Admins';

  @override
  String get adminHome_settings => 'Settings';

  @override
  String get adminHome_deleteAccount => 'Delete Account';

  @override
  String get adminHome_account => 'Account';

  @override
  String get adminHome_accountDetails => 'Account Details';

  @override
  String get adminHome_preferences => 'Preferences';

  @override
  String get adminHome_security => 'Security';

  @override
  String get adminHome_editName => 'Edit Name';

  @override
  String get adminHome_fullName => 'Full Name';

  @override
  String get adminHome_enterFullName => 'Enter your full name';

  @override
  String get adminHome_nameUpdated => 'Name updated successfully';

  @override
  String get adminHome_failedToUpdateName => 'Failed to update name';

  @override
  String get adminHome_memberSince => 'Member Since';

  @override
  String get adminHome_role => 'Role';

  @override
  String get adminHome_adminPanel => 'Admin Panel';

  @override
  String get adminHome_somethingWentWrong => 'Something went wrong';

  @override
  String get adminHome_tryLoggingOut => 'Please try logging out and back in';

  @override
  String get adminHome_logoutAndTryAgain => 'Logout & Try Again';

  @override
  String get adminDashboard_title => 'Dashboard';

  @override
  String get adminDashboard_overview =>
      'Overview of your tools, technicians, and approvals.';

  @override
  String get adminDashboard_keyMetrics => 'Key Metrics';

  @override
  String get adminDashboard_totalTools => 'Total Tools';

  @override
  String get adminDashboard_technicians => 'Technicians';

  @override
  String get adminDashboard_totalValue => 'Total Value';

  @override
  String get adminDashboard_maintenance => 'Maintenance';

  @override
  String get adminDashboard_last30Days => 'Last 30 Days';

  @override
  String get adminDashboard_quickActions => 'Quick Actions';

  @override
  String get adminDashboard_addTool => 'Add Tool';

  @override
  String get adminDashboard_assignTool => 'Assign Tool';

  @override
  String get adminDashboard_authorizeUsers => 'Authorize Users';

  @override
  String get adminDashboard_reports => 'Reports';

  @override
  String get adminDashboard_toolIssues => 'Tool Issues';

  @override
  String get adminDashboard_approvals => 'Approvals';

  @override
  String get adminDashboard_maintenanceSchedule => 'Maintenance Schedule';

  @override
  String get adminDashboard_toolHistory => 'Tool History';

  @override
  String get adminDashboard_fleetStatus => 'Fleet status';

  @override
  String get adminDashboard_toolStatus => 'Tool Status';

  @override
  String get adminDashboard_greetingMorning => 'Good Morning';

  @override
  String get adminDashboard_greetingAfternoon => 'Good Afternoon';

  @override
  String get adminDashboard_greetingEvening => 'Good Evening';

  @override
  String get adminDashboard_manageTools =>
      'Manage your HVAC tools and technicians';

  @override
  String get adminManagement_title => 'Admins';

  @override
  String get adminManagement_loading => 'Loading admins...';

  @override
  String get adminManagement_noAdmins => 'No admins yet';

  @override
  String get adminManagement_tapPlusToAdd => 'Tap + to add an admin';

  @override
  String get adminManagement_removeAdmin => 'Remove Admin';

  @override
  String adminManagement_removeConfirm(String name) {
    return 'Are you sure you want to remove $name from admin access?';
  }

  @override
  String get adminManagement_removeNote =>
      'Their authentication account will remain but they will lose admin privileges.';

  @override
  String adminManagement_removed(String name) {
    return '$name has been removed from admin access';
  }

  @override
  String get adminManagement_removeFailed => 'Failed to remove admin';

  @override
  String get adminManagement_unassigned => 'Unassigned';

  @override
  String get adminNotification_title => 'Notifications';

  @override
  String get adminNotification_markAllRead => 'Mark All Read';

  @override
  String get adminNotification_errorLoading => 'Error loading notifications';

  @override
  String get adminNotification_empty => 'No notifications';

  @override
  String get adminNotification_emptyHint =>
      'You\'ll see technician requests here';

  @override
  String get adminNotification_technicianDetails => 'Technician Details:';

  @override
  String get adminNotification_time => 'Time';

  @override
  String get adminNotification_justNow => 'Just now';

  @override
  String adminNotification_minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String adminNotification_hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String adminNotification_daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get adminNotification_markRead => 'Mark Read';

  @override
  String get adminNotification_markUnread => 'Mark Unread';

  @override
  String get tools_title => 'Tools';

  @override
  String get tools_searchHint => 'Search tools...';

  @override
  String get tools_emptyTitle => 'No tools found';

  @override
  String get tools_emptySubtitle => 'Add your first tool to get started';

  @override
  String get tools_addTool => 'Add Tool';

  @override
  String get tools_filterAll => 'All';

  @override
  String get tools_filterAvailable => 'Available';

  @override
  String get tools_filterAssigned => 'Assigned';

  @override
  String get tools_filterMaintenance => 'Maintenance';

  @override
  String get tools_deleteTool => 'Delete Tool';

  @override
  String get tools_deleteConfirm =>
      'Are you sure you want to delete this tool? This action cannot be undone.';

  @override
  String get toolDetail_title => 'Tool Details';

  @override
  String get toolDetail_brand => 'Brand';

  @override
  String get toolDetail_model => 'Model';

  @override
  String get toolDetail_serialNumber => 'Serial Number';

  @override
  String get toolDetail_category => 'Category';

  @override
  String get toolDetail_condition => 'Condition';

  @override
  String get toolDetail_location => 'Location';

  @override
  String get toolDetail_assignedTo => 'Assigned To';

  @override
  String get toolDetail_purchaseDate => 'Purchase Date';

  @override
  String get toolDetail_purchasePrice => 'Purchase Price';

  @override
  String get toolDetail_currentValue => 'Current Value';

  @override
  String get toolDetail_notes => 'Notes';

  @override
  String get toolDetail_status => 'Status';

  @override
  String get toolDetail_toolType => 'Tool Type';

  @override
  String get toolDetail_history => 'History';

  @override
  String get toolDetail_noHistory => 'No history available';

  @override
  String get toolDetail_unassigned => 'Unassigned';

  @override
  String get toolDetail_returnTool => 'Return Tool';

  @override
  String get toolDetail_assignTool => 'Assign Tool';

  @override
  String get toolDetail_editTool => 'Edit Tool';

  @override
  String get toolDetail_deleteTool => 'Delete Tool';

  @override
  String get addTool_title => 'Add Tool';

  @override
  String get addTool_nameLabel => 'Tool Name';

  @override
  String get addTool_nameHint => 'Enter tool name';

  @override
  String get addTool_nameRequired => 'Please enter a tool name';

  @override
  String get addTool_categoryLabel => 'Category';

  @override
  String get addTool_categoryHint => 'Select category';

  @override
  String get addTool_categoryRequired => 'Please select a category';

  @override
  String get addTool_brandLabel => 'Brand';

  @override
  String get addTool_brandHint => 'Enter brand';

  @override
  String get addTool_modelLabel => 'Model';

  @override
  String get addTool_modelHint => 'Enter model';

  @override
  String get addTool_serialNumberLabel => 'Serial Number';

  @override
  String get addTool_serialNumberHint => 'Enter serial number';

  @override
  String get addTool_purchaseDateLabel => 'Purchase Date';

  @override
  String get addTool_purchasePriceLabel => 'Purchase Price';

  @override
  String get addTool_currentValueLabel => 'Current Value';

  @override
  String get addTool_conditionLabel => 'Condition';

  @override
  String get addTool_conditionHint => 'Select condition';

  @override
  String get addTool_locationLabel => 'Location';

  @override
  String get addTool_locationHint => 'Enter location';

  @override
  String get addTool_toolTypeLabel => 'Tool Type';

  @override
  String get addTool_notesLabel => 'Notes';

  @override
  String get addTool_notesHint => 'Enter notes (optional)';

  @override
  String get addTool_saveButton => 'Save Tool';

  @override
  String get addTool_success => 'Tool added successfully!';

  @override
  String get addTool_attachPhoto => 'Attach photo (optional)';

  @override
  String get editTool_title => 'Edit Tool';

  @override
  String get editTool_saveButton => 'Update Tool';

  @override
  String get editTool_success => 'Tool updated successfully!';

  @override
  String get toolHistory_title => 'Tool History';

  @override
  String get toolHistory_noHistory => 'No history records found';

  @override
  String get toolHistory_allHistory => 'All Tool History';

  @override
  String get toolInstances_title => 'Tool Instances';

  @override
  String get toolInstances_empty => 'No instances found';

  @override
  String get toolIssues_title => 'Tool Issues';

  @override
  String get toolIssues_all => 'All';

  @override
  String get toolIssues_open => 'Open';

  @override
  String get toolIssues_inProgress => 'In Progress';

  @override
  String get toolIssues_resolved => 'Resolved';

  @override
  String get toolIssues_closed => 'Closed';

  @override
  String get toolIssues_empty => 'No issues found';

  @override
  String get toolIssues_emptyHint => 'No tool issues have been reported';

  @override
  String get toolIssues_reportIssue => 'Report Issue';

  @override
  String get addToolIssue_title => 'Report Tool Issue';

  @override
  String get addToolIssue_selectTool => 'Select Tool *';

  @override
  String get addToolIssue_issueDetails => 'Issue Details';

  @override
  String get addToolIssue_issueType => 'Issue Type';

  @override
  String get addToolIssue_priority => 'Priority';

  @override
  String get addToolIssue_description => 'Description *';

  @override
  String get addToolIssue_descriptionHint => 'Describe the issue in detail';

  @override
  String get addToolIssue_descriptionRequired =>
      'Please provide a description of the issue';

  @override
  String get addToolIssue_additionalInfo => 'Additional Information';

  @override
  String get addToolIssue_location => 'Location';

  @override
  String get addToolIssue_locationHint => 'Where did this occur? (optional)';

  @override
  String get addToolIssue_estimatedCost => 'Estimated Cost';

  @override
  String get addToolIssue_estimatedCostHint => 'Cost to fix/replace (optional)';

  @override
  String get addToolIssue_priorityGuidelines => 'Priority Guidelines';

  @override
  String get addToolIssue_criticalGuideline =>
      'Safety hazard or complete tool failure';

  @override
  String get addToolIssue_highGuideline => 'Tool unusable but no safety risk';

  @override
  String get addToolIssue_mediumGuideline => 'Tool partially functional';

  @override
  String get addToolIssue_lowGuideline => 'Minor issue, tool still usable';

  @override
  String get addToolIssue_submitButton => 'Submit Report';

  @override
  String get addToolIssue_success => 'Issue reported successfully!';

  @override
  String get addToolIssue_toolNotFound =>
      'Selected tool not found. Please refresh and try again.';

  @override
  String get addToolIssue_tableNotFound =>
      'Tool issues table not found. Please contact administrator.';

  @override
  String get addToolIssue_sessionExpired =>
      'Session expired. Please log in again.';

  @override
  String get addToolIssue_permissionDenied =>
      'Permission denied. You may not have permission to report issues.';

  @override
  String get addToolIssue_fillRequired => 'Please fill in all required fields.';

  @override
  String get addToolIssue_networkError =>
      'Network error. Please check your connection and try again.';

  @override
  String get technicians_title => 'Technicians';

  @override
  String get technicians_subtitle =>
      'Manage active, inactive, and assigned technicians';

  @override
  String get technicians_searchHint => 'Search technicians...';

  @override
  String get technicians_emptyTitle => 'No technicians found';

  @override
  String get technicians_emptySubtitle =>
      'Add your first technician to get started';

  @override
  String get technicians_filterAll => 'All';

  @override
  String get technicians_filterActive => 'Active';

  @override
  String get technicians_filterInactive => 'Inactive';

  @override
  String get technicians_filterWithTools => 'With Tools';

  @override
  String get technicians_filterWithoutTools => 'Without Tools';

  @override
  String get technicians_deleteTitle => 'Delete Technician';

  @override
  String technicians_deleteConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get technicians_noTools => 'No tools';

  @override
  String get technicians_noDepartment => 'No department';

  @override
  String get technicianDetail_profile => 'Profile';

  @override
  String get technicianDetail_tools => 'Tools';

  @override
  String get technicianDetail_issues => 'Issues';

  @override
  String get technicianDetail_editTechnician => 'Edit Technician';

  @override
  String get technicianDetail_deleteTechnician => 'Delete Technician';

  @override
  String get technicianDetail_contactInfo => 'Contact Information';

  @override
  String get technicianDetail_employmentDetails => 'Employment Details';

  @override
  String get technicianDetail_statusInfo => 'Status Information';

  @override
  String get technicianDetail_employeeId => 'Employee ID';

  @override
  String get technicianDetail_department => 'Department';

  @override
  String get technicianDetail_hireDate => 'Hire Date';

  @override
  String get technicianDetail_created => 'Created';

  @override
  String get technicianDetail_noTools => 'No tools assigned';

  @override
  String get technicianDetail_noToolsDesc =>
      'This technician has no tools assigned to them';

  @override
  String get technicianDetail_noIssues => 'No issues reported';

  @override
  String get technicianDetail_noIssuesDesc =>
      'This technician has not reported any tool issues';

  @override
  String get technicianDetail_deleteWarning => 'This will permanently delete:';

  @override
  String get technicianDetail_deleteLine1 => 'The technician record';

  @override
  String get technicianDetail_deleteLine2 => 'All associated data';

  @override
  String get technicianDetail_deleteCannotUndo =>
      'This action cannot be undone!';

  @override
  String get technicianDetail_deleteHasTools =>
      'Cannot delete technician with assigned tools. Please reassign or return them first.';

  @override
  String get technicianHome_account => 'Account';

  @override
  String get technicianHome_accountDetails => 'Account Details';

  @override
  String get technicianHome_preferences => 'Preferences';

  @override
  String get technicianHome_security => 'Security';

  @override
  String get technicianHome_editName => 'Edit Name';

  @override
  String get technicianHome_fullName => 'Full Name';

  @override
  String get technicianHome_enterFullName => 'Enter your full name';

  @override
  String get technicianHome_memberSince => 'Member Since';

  @override
  String get technicianHome_role => 'Role';

  @override
  String get technicianHome_administrator => 'Administrator';

  @override
  String get technicianHome_technician => 'Technician';

  @override
  String get technicianHome_noNotifications => 'No notifications';

  @override
  String get technicianHome_notificationsHint =>
      'You\'ll see notifications here when you receive tool requests';

  @override
  String get technicianHome_requestAccountDeletion =>
      'Request Account Deletion';

  @override
  String get techDashboard_greetingMorning => 'Good Morning';

  @override
  String get techDashboard_greetingAfternoon => 'Good Afternoon';

  @override
  String get techDashboard_greetingEvening => 'Good Evening';

  @override
  String get techDashboard_welcome =>
      'Manage your tools and access shared resources';

  @override
  String get techDashboard_sharedTools => 'Shared Tools';

  @override
  String get techDashboard_seeAll => 'See All';

  @override
  String get techDashboard_myTools => 'My Tools';

  @override
  String get techDashboard_noTools => 'No tools available';

  @override
  String get techDashboard_noToolsHint =>
      'You have no assigned tools. You can add your first tool or request tool assignment.';

  @override
  String get techDashboard_noSharedTools => 'No shared tools available';

  @override
  String get techDashboard_noAssignedTools => 'No tools assigned yet';

  @override
  String get techDashboard_noAssignedToolsHint =>
      'Add or badge tools you currently have to see them here.';

  @override
  String get techDashboard_shared => 'SHARED';

  @override
  String get techDashboard_request => 'Request';

  @override
  String get myTools_title => 'My Tools';

  @override
  String get myTools_searchHint => 'Search tools...';

  @override
  String get myTools_categoryFilter => 'Category';

  @override
  String get myTools_statusFilter => 'Status';

  @override
  String get myTools_empty => 'No tools found';

  @override
  String get myTools_emptyHint => 'Add your first tool to get started';

  @override
  String get myTools_addButton => 'Add Tool';

  @override
  String get addTechnician_addTitle => 'Add Technician';

  @override
  String get addTechnician_editTitle => 'Edit Technician';

  @override
  String get addTechnician_addSubtitle =>
      'Add technicians so they can receive assignments and tool access.';

  @override
  String get addTechnician_editSubtitle =>
      'Update technician details to keep assignments current.';

  @override
  String get addTechnician_nameLabel => 'Full Name';

  @override
  String get addTechnician_nameHint => 'Enter full name';

  @override
  String get addTechnician_employeeIdLabel => 'Employee ID';

  @override
  String get addTechnician_employeeIdHint => 'Enter employee ID (optional)';

  @override
  String get addTechnician_phoneLabel => 'Phone Number';

  @override
  String get addTechnician_phoneHint => 'Enter phone number';

  @override
  String get addTechnician_emailLabel => 'Email Address';

  @override
  String get addTechnician_emailHint => 'Enter email address';

  @override
  String get addTechnician_emailInvalid => 'Enter a valid email address';

  @override
  String get addTechnician_departmentLabel => 'Department';

  @override
  String get addTechnician_departmentHint => 'Select department';

  @override
  String get addTechnician_statusLabel => 'Status';

  @override
  String get addTechnician_hireDateHint => 'Select hire date';

  @override
  String get addTechnician_addButton => 'Add Technician';

  @override
  String get addTechnician_updateButton => 'Update Technician';

  @override
  String get addTechnician_addSuccess => 'Technician added successfully!';

  @override
  String addTechnician_inviteEmailSent(String email) {
    return 'Invite email sent to $email';
  }

  @override
  String get addTechnician_inviteHint =>
      'Technician should use the invite email to set their password.';

  @override
  String get addTechnician_updateSuccess => 'Technician updated successfully!';

  @override
  String get addTechnician_nameRequired => 'Please enter technician\'s name';

  @override
  String get addTechnician_chooseFromGallery => 'Choose from Gallery';

  @override
  String get addTechnician_takePhoto => 'Take Photo';

  @override
  String get addTechnician_removePhoto => 'Remove Photo';

  @override
  String get department_repairing => 'Repairing';

  @override
  String get department_maintenance => 'Maintenance';

  @override
  String get department_retrofit => 'Retrofit';

  @override
  String get department_installation => 'Installation';

  @override
  String get department_factory => 'Factory';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_accountSection => 'Account';

  @override
  String get settings_accountDetailsSection => 'Account Details';

  @override
  String get settings_accountManagementSection => 'Account Management';

  @override
  String get settings_preferencesSection => 'Preferences';

  @override
  String get settings_notificationsSection => 'Notifications';

  @override
  String get settings_dataBackupSection => 'Data & Backup';

  @override
  String get settings_aboutSection => 'About';

  @override
  String get settings_languageLabel => 'Language';

  @override
  String get settings_currencyLabel => 'Currency';

  @override
  String get settings_pushNotifications => 'Push Notifications';

  @override
  String get settings_pushNotificationsSubtitle =>
      'Receive maintenance reminders and updates';

  @override
  String get settings_autoBackup => 'Auto Backup';

  @override
  String get settings_autoBackupSubtitle =>
      'Automatically backup data to cloud';

  @override
  String get settings_exportData => 'Export Data';

  @override
  String get settings_exportDataSubtitle => 'Download your data as CSV';

  @override
  String get settings_importData => 'Import Data';

  @override
  String get settings_importDataSubtitle => 'Restore from backup file';

  @override
  String get settings_importDataMessage =>
      'To import data, please contact support at support@rgstools.app. We will help you restore your data from a backup file.';

  @override
  String get settings_appVersion => 'App Version';

  @override
  String get settings_helpSupport => 'Help & Support';

  @override
  String get settings_helpSupportSubtitle => 'Get help and contact support';

  @override
  String get settings_privacyPolicy => 'Privacy Policy';

  @override
  String get settings_privacyPolicySubtitle => 'Read our privacy policy';

  @override
  String get settings_termsOfService => 'Terms of Service';

  @override
  String get settings_termsOfServiceSubtitle => 'Read our terms of service';

  @override
  String get settings_selectLanguage => 'Select Language';

  @override
  String get settings_selectCurrency => 'Select Currency';

  @override
  String get settings_deleteAccount => 'Delete Account';

  @override
  String get settings_deleteAccountSubtitle =>
      'Permanently delete your account and data';

  @override
  String get settings_requestAccountDeletion => 'Request Account Deletion';

  @override
  String get settings_requestAccountDeletionSubtitle =>
      'Ask your administrator to delete your account';

  @override
  String get settings_versionInfo => 'Version Information';

  @override
  String get settings_rgsToolsManager => 'RGS Tools Manager';

  @override
  String get settings_couldNotOpenPage => 'Could not open support page';

  @override
  String settings_exportSuccess(int count) {
    return 'Data exported successfully! $count file(s) created.';
  }

  @override
  String settings_exportError(String error) {
    return 'Error exporting data: $error';
  }

  @override
  String get currency_usd => 'US Dollar';

  @override
  String get currency_eur => 'Euro';

  @override
  String get currency_gbp => 'British Pound';

  @override
  String get currency_aed => 'UAE Dirham';

  @override
  String get reports_title => 'Reports';

  @override
  String get reports_toolsOverview => 'Tools Overview';

  @override
  String get reports_technicianActivity => 'Technician Activity';

  @override
  String get reports_maintenanceReport => 'Maintenance Report';

  @override
  String get reports_exportReport => 'Export Report';

  @override
  String get reports_generateReport => 'Generate Report';

  @override
  String get reports_noData => 'No data available for this report';

  @override
  String get reports_dateRange => 'Date Range';

  @override
  String get reports_last7Days => 'Last 7 Days';

  @override
  String get reports_last30Days => 'Last 30 Days';

  @override
  String get reports_last90Days => 'Last 90 Days';

  @override
  String get reports_custom => 'Custom';

  @override
  String get maintenance_title => 'Maintenance';

  @override
  String get maintenance_schedule => 'Schedule Maintenance';

  @override
  String get maintenance_noScheduled => 'No maintenance scheduled';

  @override
  String get maintenance_upcoming => 'Upcoming';

  @override
  String get maintenance_overdue => 'Overdue';

  @override
  String get maintenance_completed => 'Completed';

  @override
  String get checkin_title => 'Check In / Check Out';

  @override
  String get checkin_scanBarcode => 'Scan Barcode';

  @override
  String get checkin_manualEntry => 'Manual Entry';

  @override
  String get checkin_toolId => 'Tool ID';

  @override
  String get checkin_checkInButton => 'Check In';

  @override
  String get checkin_checkOutButton => 'Check Out';

  @override
  String get sharedTools_title => 'Shared Tools';

  @override
  String get sharedTools_empty => 'No shared tools available';

  @override
  String get sharedTools_emptyHint => 'Tools marked as shared will appear here';

  @override
  String get sharedTools_badgeIn => 'Badge In';

  @override
  String get sharedTools_badgeOut => 'Badge Out';

  @override
  String get sharedTools_currentHolder => 'Current Holder';

  @override
  String get sharedTools_noCurrentHolder => 'No current holder';

  @override
  String get bulkImport_title => 'Bulk Import';

  @override
  String get bulkImport_selectFile => 'Select CSV File';

  @override
  String get bulkImport_importButton => 'Import';

  @override
  String get bulkImport_preview => 'Preview';

  @override
  String bulkImport_rowsFound(int count) {
    return '$count rows found';
  }

  @override
  String bulkImport_success(int count) {
    return 'Successfully imported $count tools';
  }

  @override
  String bulkImport_error(String error) {
    return 'Import failed: $error';
  }

  @override
  String get permanentAssignment_title => 'Permanent Assignment';

  @override
  String get permanentAssignment_selectTechnician => 'Select Technician';

  @override
  String get permanentAssignment_selectTools => 'Select Tools';

  @override
  String get permanentAssignment_assignButton => 'Assign';

  @override
  String get permanentAssignment_success => 'Tools assigned successfully';

  @override
  String get reassignTool_title => 'Reassign Tool';

  @override
  String get reassignTool_currentTechnician => 'Current Technician';

  @override
  String get reassignTool_newTechnician => 'New Technician';

  @override
  String get reassignTool_reassignButton => 'Reassign';

  @override
  String get reassignTool_success => 'Tool reassigned successfully';

  @override
  String get requestNewTool_title => 'New Request';

  @override
  String get requestNewTool_subtitle =>
      'Submit a request for tools, assignments, transfers, or maintenance';

  @override
  String get requestNewTool_requestType => 'Request Type';

  @override
  String get requestNewTool_requestInfo => 'Request Information';

  @override
  String get requestNewTool_titleLabel => 'Title (Optional)';

  @override
  String get requestNewTool_titleHint => 'Auto-generated if left blank';

  @override
  String get requestNewTool_descriptionLabel => 'Description (Optional)';

  @override
  String get requestNewTool_descriptionHint => 'Auto-generated if left blank';

  @override
  String get requestNewTool_justification => 'Justification / Reason *';

  @override
  String get requestNewTool_neededBy => 'Needed By (Optional)';

  @override
  String get requestNewTool_selectDate => 'Select date';

  @override
  String get requestNewTool_siteLocation => 'Site / Location';

  @override
  String get requestNewTool_siteLocationHint => 'e.g., Building A, Floor 3';

  @override
  String get requestNewTool_submitButton => 'Submit Request';

  @override
  String get requestNewTool_success => 'Request submitted successfully!';

  @override
  String get requestNewTool_toolDetails => 'Tool Details';

  @override
  String get requestNewTool_assignmentDetails => 'Assignment Details';

  @override
  String get requestNewTool_transferDetails => 'Transfer Details';

  @override
  String get requestNewTool_maintenanceDetails => 'Maintenance Details';

  @override
  String get requestNewTool_disposalDetails => 'Disposal Details';

  @override
  String get requestNewTool_toolName => 'Tool Name';

  @override
  String get requestNewTool_toolSerial => 'Tool Serial Number (Optional)';

  @override
  String get requestNewTool_quantity => 'Quantity';

  @override
  String get requestNewTool_unitPrice => 'Unit Price (AED)';

  @override
  String get requestNewTool_totalCost => 'Total Cost (AED)';

  @override
  String get requestNewTool_supplier => 'Supplier (Optional)';

  @override
  String get requestNewTool_assignTo =>
      'Assign To (Your Name or Another Technician)';

  @override
  String get requestNewTool_project => 'Project/Site';

  @override
  String get requestNewTool_fromLocation => 'From Location';

  @override
  String get requestNewTool_toLocation => 'To Location';

  @override
  String get requestNewTool_maintenanceType => 'Maintenance Type';

  @override
  String get requestNewTool_currentCondition => 'Current Condition';

  @override
  String get requestNewTool_attachPhoto => 'Attach photo or spec (optional)';

  @override
  String get requestNewTool_enterValidNumber => 'Enter a valid number';

  @override
  String get requestType_toolPurchase => 'Tool Purchase';

  @override
  String get requestType_toolAssignment => 'Tool Assignment';

  @override
  String get requestType_transfer => 'Transfer';

  @override
  String get requestType_maintenance => 'Maintenance';

  @override
  String get requestType_toolDisposal => 'Tool Disposal';
}
