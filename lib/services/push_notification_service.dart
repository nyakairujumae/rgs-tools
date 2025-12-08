import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Service to send FCM push notifications via Supabase Edge Function
class PushNotificationService {
  /// Send push notification to a specific user by user_id
  static Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get FCM token for the user
      final tokenResponse = await SupabaseService.client
          .from('user_fcm_tokens')
          .select('fcm_token')
          .eq('user_id', userId)
          .maybeSingle();

      if (tokenResponse == null || tokenResponse['fcm_token'] == null) {
        debugPrint('⚠️ [Push] No FCM token found for user: $userId');
        return false;
      }

      final token = tokenResponse['fcm_token'] as String;
      return await sendToToken(
        token: token,
        title: title,
        body: body,
        data: data,
      );
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

      if (response.status == 200) {
        debugPrint('✅ [Push] Notification sent successfully');
        return true;
      } else {
        debugPrint('❌ [Push] Edge Function returned status: ${response.status}');
        debugPrint('❌ [Push] Response: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Push] Error sending notification: $e');
      // If Edge Function doesn't exist, try direct FCM API call as fallback
      debugPrint('⚠️ [Push] Edge Function may not exist, trying direct FCM call...');
      return await _sendDirectFCM(
        token: token,
        title: title,
        body: body,
        data: data,
      );
    }
  }

  /// Fallback: Send directly to FCM API (requires FCM_SERVER_KEY in environment)
  static Future<bool> _sendDirectFCM({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // This would require FCM_SERVER_KEY which should be in Supabase secrets
      // For now, just log that we need the Edge Function
      debugPrint('⚠️ [Push] Direct FCM requires FCM_SERVER_KEY in Supabase secrets');
      debugPrint('⚠️ [Push] Please create the send-push-notification Edge Function');
      return false;
    } catch (e) {
      debugPrint('❌ [Push] Direct FCM error: $e');
      return false;
    }
  }
}



