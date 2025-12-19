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
      debugPrint('📤 [Push] ========== SENDING TO USER ==========');
      debugPrint('📤 [Push] User ID: $userId');
      debugPrint('📤 [Push] Title: $title');
      debugPrint('📤 [Push] Body: $body');
      
      // Get ALL FCM tokens for the user (both Android and iOS)
      debugPrint('🔍 [Push] Querying tokens for user: $userId');
      final tokensResponse = await SupabaseService.client
          .from('user_fcm_tokens')
          .select('fcm_token, platform, updated_at')
          .eq('user_id', userId);

      debugPrint('📊 [Push] Found ${tokensResponse.length} token(s) for user');
      
      if (tokensResponse.isEmpty) {
        debugPrint('⚠️ [Push] ========== NO TOKENS FOUND ==========');
        debugPrint('⚠️ [Push] No FCM tokens found for user: $userId');
        debugPrint('⚠️ [Push] This means:');
        debugPrint('⚠️ [Push] 1. Token was never saved to database');
        debugPrint('⚠️ [Push] 2. RLS policy is blocking the query');
        debugPrint('⚠️ [Push] 3. User logged out and token was deleted');
        debugPrint('⚠️ [Push] ======================================');
        
        // Try to query all tokens to see if RLS is the issue
        try {
          final allTokens = await SupabaseService.client
              .from('user_fcm_tokens')
              .select('user_id, platform')
              .limit(5);
          debugPrint('🔍 [Push] Sample tokens in database: ${allTokens.length} total');
        } catch (e) {
          debugPrint('⚠️ [Push] Could not query tokens table (RLS may be blocking): $e');
        }
        
        return false;
      }

      // Send to all tokens for this user
      int successCount = 0;
      for (final tokenRecord in tokensResponse) {
        final token = tokenRecord['fcm_token'] as String?;
        final platform = tokenRecord['platform'] as String?;
        final updatedAt = tokenRecord['updated_at'] as String?;
        
        debugPrint('📱 [Push] Token record: platform=$platform, updated=$updatedAt');
        
        if (token != null && token.isNotEmpty) {
          debugPrint('📤 [Push] Sending to ${platform ?? 'unknown'} token (${token.substring(0, 20)}...)');
          final success = await sendToToken(
            token: token,
            title: title,
            body: body,
            data: data,
          );
          if (success) {
            successCount++;
            debugPrint('✅ [Push] Successfully sent to ${platform ?? 'unknown'} token');
          } else {
            debugPrint('❌ [Push] Failed to send to ${platform ?? 'unknown'} token');
          }
        } else {
          debugPrint('⚠️ [Push] Token is null or empty for platform: $platform');
        }
      }

      debugPrint('✅ [Push] Sent to $successCount/${tokensResponse.length} tokens for user: $userId');
      debugPrint('📤 [Push] ======================================');
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
      debugPrint('📤 [Push] ========== SENDING TO ADMINS ==========');
      debugPrint('📤 [Push] Title: $title');
      debugPrint('📤 [Push] Body: $body');
      
      // Get all admin user IDs
      // First try using RPC function (bypasses RLS), fallback to direct query
      List<Map<String, dynamic>> adminsResponse;
      
      try {
        // Try RPC function first (bypasses RLS)
        debugPrint('🔍 [Push] Attempting to get admin users via RPC function...');
        final rpcResponse = await SupabaseService.client.rpc('get_admin_user_ids');
        if (rpcResponse != null && rpcResponse is List) {
          adminsResponse = List<Map<String, dynamic>>.from(rpcResponse);
          debugPrint('✅ [Push] Found ${adminsResponse.length} admin users via RPC function');
        } else {
          throw Exception('RPC function returned unexpected format');
        }
      } catch (rpcError) {
        debugPrint('⚠️ [Push] RPC function not available, using direct query: $rpcError');
        // Fallback to direct query
        debugPrint('🔍 [Push] Querying users table for admin role...');
        adminsResponse = await SupabaseService.client
            .from('users')
            .select('id, email, role')
            .eq('role', 'admin');
        debugPrint('🔍 [Push] Found ${adminsResponse.length} admin users via direct query');
      }

      if (adminsResponse.isEmpty) {
        debugPrint('❌ [Push] ========== NO ADMIN USERS FOUND ==========');
        debugPrint('❌ [Push] No admin users found with role="admin"');
        debugPrint('❌ [Push] This might be due to:');
        debugPrint('❌ [Push] 1. No users have role="admin" in database');
        debugPrint('❌ [Push] 2. RLS policies blocking the query');
        debugPrint('❌ [Push] 3. Case sensitivity issue (check if role is "Admin" instead of "admin")');
        
        // Try to get all users to debug
        try {
          final allUsers = await SupabaseService.client
              .from('users')
              .select('id, email, role')
              .limit(10);
          debugPrint('🔍 [Push] Sample users in database: $allUsers');
        } catch (e) {
          debugPrint('⚠️ [Push] Could not query users table: $e');
        }
        debugPrint('❌ [Push] =========================================');
        return 0;
      }

      debugPrint('📤 [Push] Sending to ${adminsResponse.length} admin(s)...');
      int successCount = 0;
      int failCount = 0;
      for (final admin in adminsResponse) {
        final adminId = admin['id'] as String;
        final adminEmail = admin['email'] as String? ?? 'unknown';
        debugPrint('📤 [Push] Sending to admin: $adminEmail ($adminId)');
        final success = await sendToUser(
          userId: adminId,
          title: title,
          body: body,
          data: data,
        );
        if (success) {
          successCount++;
          debugPrint('✅ [Push] Successfully sent to admin: $adminEmail');
        } else {
          failCount++;
          debugPrint('❌ [Push] Failed to send to admin: $adminEmail');
        }
      }

      debugPrint('✅ [Push] ========== ADMIN NOTIFICATION SUMMARY ==========');
      debugPrint('✅ [Push] Total admins: ${adminsResponse.length}');
      debugPrint('✅ [Push] Success: $successCount');
      debugPrint('✅ [Push] Failed: $failCount');
      debugPrint('✅ [Push] ================================================');
      return successCount;
    } catch (e, stackTrace) {
      debugPrint('❌ [Push] ========== ERROR SENDING TO ADMINS ==========');
      debugPrint('❌ [Push] Error: $e');
      debugPrint('❌ [Push] Stack trace: $stackTrace');
      debugPrint('❌ [Push] =============================================');
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
      debugPrint('📤 [Push] ========== CALLING EDGE FUNCTION ==========');
      debugPrint('📤 [Push] Token: ${token.substring(0, 20)}...');
      debugPrint('📤 [Push] Title: $title');
      debugPrint('📤 [Push] Body: $body');
      debugPrint('📤 [Push] Data: $data');
      debugPrint('📤 [Push] Edge Function: send-push-notification');
      
      // CRITICAL: Log that we're about to invoke the Edge Function
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('📤 [Push] Invoking Edge Function at: $timestamp');
      debugPrint('📤 [Push] Function name: send-push-notification');
      debugPrint('📤 [Push] Request payload: {token: ${token.substring(0, 20)}..., title: $title, body: $body}');
      
      // Call Supabase Edge Function to send notification
      final stopwatch = Stopwatch()..start();
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'token': token,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
      stopwatch.stop();
      debugPrint('📥 [Push] Edge Function call completed in ${stopwatch.elapsedMilliseconds}ms');
      
      debugPrint('📥 [Push] ========== EDGE FUNCTION RESPONSE ==========');
      debugPrint('📥 [Push] Response received at: ${DateTime.now().toIso8601String()}');

      debugPrint('📥 [Push] Edge Function response status: ${response.status}');
      debugPrint('📥 [Push] Edge Function response data: ${response.data}');

      // Check for FCM token errors in the response
      if (response.data is Map) {
        final responseData = response.data as Map;
        if (responseData['details'] is Map) {
          final details = responseData['details'] as Map;
          if (details['error'] is Map) {
            final fcmError = details['error'] as Map;
            final errorCode = fcmError['errorCode'];
            final message = fcmError['message'];
            
            if (errorCode == 'UNREGISTERED' || message == 'NotRegistered') {
              debugPrint('❌ [Push] ========== FCM TOKEN INVALID ==========');
              debugPrint('❌ [Push] The FCM token is invalid/expired/unregistered');
              debugPrint('❌ [Push] This usually means:');
              debugPrint('❌ [Push] 1. App was uninstalled and reinstalled');
              debugPrint('❌ [Push] 2. Token expired and needs refresh');
              debugPrint('❌ [Push] 3. App data was cleared');
              debugPrint('❌ [Push] SOLUTION: Delete old token and get a fresh one');
              debugPrint('❌ [Push] The app should automatically refresh tokens on next launch');
              debugPrint('❌ [Push] =========================================');
              
              // Try to delete the invalid token from database
              try {
                final currentUser = SupabaseService.client.auth.currentUser;
                if (currentUser != null) {
                  await SupabaseService.client
                      .from('user_fcm_tokens')
                      .delete()
                      .eq('fcm_token', token);
                  debugPrint('✅ [Push] Deleted invalid token from database');
                  debugPrint('✅ [Push] App will generate a new token on next launch');
                }
              } catch (e) {
                debugPrint('⚠️ [Push] Could not delete invalid token: $e');
              }
              
              return false;
            }
          }
        }
      }

      // Handle response based on status
      if (response.status == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          debugPrint('✅ [Push] Notification sent successfully');
          debugPrint('✅ [Push] FCM message name: ${responseData['name']}');
          return true;
        } else if (responseData is Map && responseData['error'] != null) {
          // Edge Function returned error in response body
          debugPrint('❌ [Push] ========== EDGE FUNCTION ERROR ==========');
          debugPrint('❌ [Push] Error: ${responseData['error']}');
          debugPrint('❌ [Push] Error details: ${responseData['details']}');
          debugPrint('❌ [Push] =========================================');
          
          // Check if it's an FCM token error
          if (responseData['details'] is Map) {
            final details = responseData['details'] as Map;
            if (details['error'] is Map) {
              final fcmError = details['error'] as Map;
              final errorCode = fcmError['errorCode'];
              if (errorCode == 'UNREGISTERED') {
                debugPrint('❌ [Push] FCM token is UNREGISTERED - deleting from database');
                try {
                  final currentUser = SupabaseService.client.auth.currentUser;
                  if (currentUser != null) {
                    await SupabaseService.client
                        .from('user_fcm_tokens')
                        .delete()
                        .eq('fcm_token', token);
                    debugPrint('✅ [Push] Deleted invalid token');
                  }
                } catch (e) {
                  debugPrint('⚠️ [Push] Could not delete invalid token: $e');
                }
              }
            }
          }
          
          return false;
        } else {
          debugPrint('⚠️ [Push] Unexpected response format: $responseData');
          debugPrint('⚠️ [Push] Expected: {"success": true} or {"error": "..."}');
          return false;
        }
      } else if (response.status == 404) {
        // Handle 404 errors (including UNREGISTERED tokens)
        debugPrint('❌ [Push] ========== EDGE FUNCTION 404 ERROR ==========');
        debugPrint('❌ [Push] Status: 404');
        debugPrint('❌ [Push] Response: ${response.data}');
        
        // Check if it's an FCM UNREGISTERED error
        if (response.data is Map) {
          final responseData = response.data as Map;
          if (responseData['details'] is Map) {
            final details = responseData['details'] as Map;
            if (details['error'] is Map) {
              final fcmError = details['error'] as Map;
              final errorCode = fcmError['errorCode'];
              if (errorCode == 'UNREGISTERED') {
                debugPrint('❌ [Push] FCM token is UNREGISTERED - deleting from database');
                try {
                  final currentUser = SupabaseService.client.auth.currentUser;
                  if (currentUser != null) {
                    await SupabaseService.client
                        .from('user_fcm_tokens')
                        .delete()
                        .eq('fcm_token', token);
                    debugPrint('✅ [Push] Deleted invalid token');
                  }
                } catch (e) {
                  debugPrint('⚠️ [Push] Could not delete invalid token: $e');
                }
              }
            }
          }
        }
        
        debugPrint('❌ [Push] =========================================');
        return false;
      } else {
        debugPrint('❌ [Push] ========== EDGE FUNCTION FAILED ==========');
        debugPrint('❌ [Push] Status code: ${response.status}');
        debugPrint('❌ [Push] Response: ${response.data}');
        
        // Provide specific guidance based on status code
        if (response.status == 404) {
          debugPrint('❌ [Push] Edge Function NOT FOUND (404)');
          debugPrint('⚠️ [Push] ACTION REQUIRED: Deploy Edge Function');
          debugPrint('⚠️ [Push] Run: supabase functions deploy send-push-notification');
        } else if (response.status == 401 || response.status == 403) {
          debugPrint('❌ [Push] Authentication/Authorization error (${response.status})');
          debugPrint('⚠️ [Push] Check Supabase anon key and RLS policies');
        } else if (response.status == 500) {
          debugPrint('❌ [Push] Edge Function server error (500)');
          debugPrint('⚠️ [Push] Check Edge Function logs in Supabase Dashboard');
          debugPrint('⚠️ [Push] Likely cause: Missing secrets or invalid credentials');
        }
        
        // Try to extract error message
        if (response.data is Map) {
          final errorMsg = response.data['error'] ?? 'Unknown error';
          debugPrint('❌ [Push] Error message: $errorMsg');
        }
        
        debugPrint('❌ [Push] =========================================');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Push] Exception sending notification: $e');
      debugPrint('❌ [Push] Stack trace: $stackTrace');
      
      // Check if it's a FunctionException with 404/UNREGISTERED error
      try {
        // Try to access exception properties using reflection/dynamic access
        final exceptionStr = e.toString();
        final exceptionType = e.runtimeType.toString();
        
        // Check if it's a FunctionException (from functions_client package)
        if (exceptionType.contains('FunctionException') || exceptionStr.contains('FunctionException')) {
          // Try to extract status and details using dynamic access
          dynamic functionException = e;
          
          // Check if exception has 'status' property
          if (functionException.status != null) {
            final status = functionException.status;
            debugPrint('❌ [Push] FunctionException status: $status');
            
            // Check if it's a 404 with UNREGISTERED token
            if (status == 404) {
              // Try to extract details
              if (functionException.details != null) {
                final details = functionException.details;
                debugPrint('❌ [Push] FunctionException details: $details');
                
                // Check for UNREGISTERED error code
                // Structure: details.error.details.error.errorCode
                if (details is Map) {
                  final error = details['error'];
                  if (error is Map) {
                    final errorDetails = error['details'];
                    if (errorDetails is Map) {
                      final innerError = errorDetails['error'];
                      if (innerError is Map) {
                        final errorCode = innerError['errorCode'];
                        if (errorCode == 'UNREGISTERED') {
                          debugPrint('❌ [Push] ========== FCM TOKEN UNREGISTERED ==========');
                          debugPrint('❌ [Push] The FCM token is invalid/expired/unregistered');
                          debugPrint('❌ [Push] Deleting invalid token from database...');
                          
                          // Delete invalid token
                          try {
                            final currentUser = SupabaseService.client.auth.currentUser;
                            if (currentUser != null) {
                              await SupabaseService.client
                                  .from('user_fcm_tokens')
                                  .delete()
                                  .eq('fcm_token', token);
                              debugPrint('✅ [Push] Deleted invalid token from database');
                              debugPrint('✅ [Push] App will generate a new token on next launch');
                            }
                          } catch (deleteError) {
                            debugPrint('⚠️ [Push] Could not delete invalid token: $deleteError');
                          }
                          
                          debugPrint('❌ [Push] =========================================');
                          return false;
                        }
                      }
                      // Also check if errorCode is in details array
                      final detailsArray = errorDetails['details'];
                      if (detailsArray is List && detailsArray.isNotEmpty) {
                        final firstDetail = detailsArray[0];
                        if (firstDetail is Map) {
                          final errorCode = firstDetail['errorCode'];
                          if (errorCode == 'UNREGISTERED') {
                            debugPrint('❌ [Push] ========== FCM TOKEN UNREGISTERED ==========');
                            debugPrint('❌ [Push] The FCM token is invalid/expired/unregistered');
                            debugPrint('❌ [Push] Deleting invalid token from database...');
                            
                            // Delete invalid token
                            try {
                              final currentUser = SupabaseService.client.auth.currentUser;
                              if (currentUser != null) {
                                await SupabaseService.client
                                    .from('user_fcm_tokens')
                                    .delete()
                                    .eq('fcm_token', token);
                                debugPrint('✅ [Push] Deleted invalid token from database');
                                debugPrint('✅ [Push] App will generate a new token on next launch');
                              }
                            } catch (deleteError) {
                              debugPrint('⚠️ [Push] Could not delete invalid token: $deleteError');
                            }
                            
                            debugPrint('❌ [Push] =========================================');
                            return false;
                          }
                        }
                      }
                    }
                  }
                }
              }
              
              // 404 but not UNREGISTERED - might be function not deployed
              debugPrint('⚠️ [Push] Edge Function returned 404');
              debugPrint('⚠️ [Push] This might mean the function is not deployed');
              debugPrint('⚠️ [Push] Or the FCM token is invalid');
            }
          }
        }
      } catch (parseError) {
        debugPrint('⚠️ [Push] Could not parse exception details: $parseError');
      }
      
      // Fallback: Check error message strings for UNREGISTERED
      final errorStr = e.toString();
      if (errorStr.contains('UNREGISTERED') || errorStr.contains('NotRegistered')) {
        debugPrint('❌ [Push] ========== FCM TOKEN UNREGISTERED (detected from error string) ==========');
        debugPrint('❌ [Push] The FCM token is invalid/expired/unregistered');
        debugPrint('❌ [Push] Deleting invalid token from database...');
        
        // Delete invalid token
        try {
          final currentUser = SupabaseService.client.auth.currentUser;
          if (currentUser != null) {
            await SupabaseService.client
                .from('user_fcm_tokens')
                .delete()
                .eq('fcm_token', token);
            debugPrint('✅ [Push] Deleted invalid token from database');
            debugPrint('✅ [Push] App will generate a new token on next launch');
          }
        } catch (deleteError) {
          debugPrint('⚠️ [Push] Could not delete invalid token: $deleteError');
        }
        
        debugPrint('❌ [Push] =========================================');
        return false;
      }
      
      // Check if it's a function not found error
      if (errorStr.contains('Function not found') || 
          errorStr.contains('404') ||
          errorStr.contains('not found')) {
        debugPrint('⚠️ [Push] Edge Function may not be deployed');
        debugPrint('⚠️ [Push] Please deploy the send-push-notification function to Supabase');
      }
      
      // Check if it's an authentication error
      if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
        debugPrint('⚠️ [Push] Authentication error - check Supabase secrets');
        debugPrint('⚠️ [Push] Ensure GOOGLE_CLIENT_EMAIL, GOOGLE_PRIVATE_KEY, and GOOGLE_PROJECT_ID are set');
      }
      
      return false;
    }
  }

}



