class FirebaseConfig {
  // Firebase project configuration
  static const String projectId = 'rgs-hvac-tools';
  static const String apiKey = 'YOUR_API_KEY_HERE';
  static const String appId = 'YOUR_APP_ID_HERE';
  static const String messagingSenderId = 'YOUR_SENDER_ID_HERE';
  
  // FCM topics
  static const String adminTopic = 'admin_notifications';
  static const String technicianTopic = 'technician_notifications';
  static const String newRegistrationTopic = 'new_registrations';
  static const String toolIssuesTopic = 'tool_issues';
}
