import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Service to send FCM push notifications via Supabase Edge Function
class PushNotificationService {
  /// Send push notification to a specific user by user_id
  /// Sends to all tokens for that user (both Android and iOS if available)
  static Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get ALL FCM tokens for the user (both Android and iOS)
      final tokensResponse = await SupabaseService.client
          .from('user_fcm_tokens')
          .select('fcm_token, platform')
          .eq('user_id', userId);

      if (tokensResponse.isEmpty) {
        debugPrint('⚠️ [Push] No FCM tokens found for user: $userId');
        return false;
      }

      // Send to all tokens for this user
      int successCount = 0;
      for (final tokenRecord in tokensResponse) {
        final token = tokenRecord['fcm_token'] as String?;
        final platform = tokenRecord['platform'] as String?;
        
        if (token != null && token.isNotEmpty) {
          debugPrint('📤 [Push] Sending to ${platform ?? 'unknown'} token for user: $userId');
          final success = await sendToToken(
            token: token,
            title: title,
            body: body,
            data: data,
          );
          if (success) successCount++;
        }
      }

      debugPrint('✅ [Push] Sent to $successCount/${tokensResponse.length} tokens for user: $userId');
      return successCount > 0;
    } catch (e) {
      debugPrint('❌ [Push] Error sending to user $userId: $e');
      return false;
    }
  }

  /// Send push notification to all admin users
  static Future<int> sendToAdmins({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all admin user IDs
      final adminsResponse = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('role', 'admin');

      if (adminsResponse.isEmpty) {
        debugPrint('⚠️ [Push] No admin users found');
        return 0;
      }

      int successCount = 0;
      for (final admin in adminsResponse) {
        final adminId = admin['id'] as String;
        final success = await sendToUser(
          userId: adminId,
          title: title,
          body: body,
          data: data,
        );
        if (success) successCount++;
      }

      debugPrint('✅ [Push] Sent to $successCount/${adminsResponse.length} admins');
      return successCount;
    } catch (e) {
      debugPrint('❌ [Push] Error sending to admins: $e');
      return 0;
    }
  }

  /// Send push notification to a specific FCM token
  static Future<bool> sendToToken({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📤 [Push] Sending notification to token: ${token.substring(0, 20)}...');
      debugPrint('📤 [Push] Title: $title, Body: $body');
      
      // Call Supabase Edge Function to send notification
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'token': token,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );

      debugPrint('📥 [Push] Edge Function response status: ${response.status}');
      debugPrint('📥 [Push] Edge Function response data: ${response.data}');

      if (response.status == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          debugPrint('✅ [Push] Notification sent successfully');
          return true;
        } else if (responseData is Map && responseData['error'] != null) {
          debugPrint('❌ [Push] Edge Function error: ${responseData['error']}');
          debugPrint('❌ [Push] Error details: ${responseData['details']}');
          return false;
        } else {
          debugPrint('⚠️ [Push] Unexpected response format: $responseData');
          return false;
        }
      } else {
        debugPrint('❌ [Push] Edge Function returned status: ${response.status}');
        debugPrint('❌ [Push] Response: ${response.data}');
        
        // Try to extract error message
        if (response.data is Map) {
          final errorMsg = response.data['error'] ?? 'Unknown error';
          debugPrint('❌ [Push] Error message: $errorMsg');
        }
        
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Push] Exception sending notification: $e');
      debugPrint('❌ [Push] Stack trace: $stackTrace');
      
      // Check if it's a function not found error
      if (e.toString().contains('Function not found') || 
          e.toString().contains('404') ||
          e.toString().contains('not found')) {
        debugPrint('⚠️ [Push] Edge Function may not be deployed');
        debugPrint('⚠️ [Push] Please deploy the send-push-notification function to Supabase');
      }
      
      // Check if it's an authentication error
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('⚠️ [Push] Authentication error - check Supabase secrets');
        debugPrint('⚠️ [Push] Ensure GOOGLE_CLIENT_EMAIL, GOOGLE_PRIVATE_KEY, and GOOGLE_PROJECT_ID are set');
      }
      
      return false;
    }
  }

}



