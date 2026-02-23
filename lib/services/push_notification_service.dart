import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../utils/logger.dart';

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
      Logger.debug('📤 [Push] ========== SENDING TO USER ==========');
      Logger.debug('📤 [Push] User ID: $userId');
      Logger.debug('📤 [Push] Title: $title');
      Logger.debug('📤 [Push] Body: $body');
      
      // Send via Edge Function, which selects the latest token per platform
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );

      Logger.debug('📥 [Push] Edge Function response status: ${response.status}');
      Logger.debug('📥 [Push] Edge Function response data: ${response.data}');

      if (response.status == 200 && response.data is Map) {
        final responseData = response.data as Map;
        Logger.debug('📊 [Push] Response data type: ${responseData.runtimeType}');
        Logger.debug('📊 [Push] Response keys: ${responseData.keys.toList()}');
        
        // Check for success field
        final success = responseData['success'];
        Logger.debug('📊 [Push] Success value: $success (type: ${success.runtimeType})');
        
        if (success == true) {
          // Also check results array for detailed success info
          if (responseData['results'] != null && responseData['results'] is List) {
            final results = responseData['results'] as List;
            Logger.debug('📊 [Push] Results count: ${results.length}');
            for (var i = 0; i < results.length; i++) {
              final result = results[i];
              if (result is Map) {
                Logger.debug('📊 [Push] Result $i: success=${result['success']}, platform=${result['platform']}');
                if (result['error'] != null) {
                  Logger.debug('⚠️ [Push] Result $i error: ${result['error']}');
                }
              }
            }
          }
          
          Logger.debug('✅ [Push] Notification sent successfully via Edge Function');
          return true;
        } else {
          Logger.debug('❌ [Push] Edge Function returned success=false');
          Logger.debug('❌ [Push] Full response: ${responseData.toString()}');
        }
      } else {
        Logger.debug('❌ [Push] Invalid response format');
        Logger.debug('❌ [Push] Status: ${response.status}');
        Logger.debug('❌ [Push] Data type: ${response.data.runtimeType}');
        Logger.debug('❌ [Push] Data: ${response.data}');
      }

      Logger.debug('❌ [Push] Failed to send notification via Edge Function');
      return false;
    } catch (e, stackTrace) {
      Logger.debug('❌ [Push] Exception sending to user $userId: $e');
      Logger.debug('❌ [Push] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Send push notification to all admin users
  static Future<int> sendToAdmins({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? fromUserId, // Optional: user ID who triggered the notification
  }) async {
    try {
      Logger.debug('📤 [Push] ========== SENDING TO ADMINS ==========');
      Logger.debug('📤 [Push] Title: $title');
      Logger.debug('📤 [Push] Body: $body');
      
      // Get all admin user IDs
      // First try using RPC function (bypasses RLS), fallback to direct query
      List<Map<String, dynamic>> adminsResponse;
      
      try {
        // Try RPC function first (bypasses RLS)
        Logger.debug('🔍 [Push] Attempting to get admin users via RPC function...');
        final rpcResponse = await SupabaseService.client.rpc('get_admin_user_ids');
        if (rpcResponse != null && rpcResponse is List) {
          adminsResponse = List<Map<String, dynamic>>.from(rpcResponse);
          Logger.debug('✅ [Push] Found ${adminsResponse.length} admin users via RPC function');
        } else {
          throw Exception('RPC function returned unexpected format');
        }
      } catch (rpcError) {
        Logger.debug('⚠️ [Push] RPC function not available, using direct query: $rpcError');
        // Fallback to direct query
        Logger.debug('🔍 [Push] Querying users table for admin role...');
        adminsResponse = await SupabaseService.client
            .from('users')
            .select('id, email, role')
            .eq('role', 'admin');
        Logger.debug('🔍 [Push] Found ${adminsResponse.length} admin users via direct query');
      }

      if (adminsResponse.isEmpty) {
        Logger.debug('❌ [Push] ========== NO ADMIN USERS FOUND ==========');
        Logger.debug('❌ [Push] No admin users found with role="admin"');
        Logger.debug('❌ [Push] This might be due to:');
        Logger.debug('❌ [Push] 1. No users have role="admin" in database');
        Logger.debug('❌ [Push] 2. RLS policies blocking the query');
        Logger.debug('❌ [Push] 3. Case sensitivity issue (check if role is "Admin" instead of "admin")');
        
        // Try to get all users to debug
        try {
          final allUsers = await SupabaseService.client
              .from('users')
              .select('id, email, role')
              .limit(10);
          Logger.debug('🔍 [Push] Sample users in database: $allUsers');
        } catch (e) {
          Logger.debug('⚠️ [Push] Could not query users table: $e');
        }
        Logger.debug('❌ [Push] =========================================');
        return 0;
      }

      Logger.debug('📤 [Push] Sending to ${adminsResponse.length} admin(s)...');
      int successCount = 0;
      int failCount = 0;
      for (final admin in adminsResponse) {
        final adminId = admin['id'] as String;
        final adminEmail = admin['email'] as String? ?? 'unknown';
        Logger.debug('📤 [Push] Sending to admin: $adminEmail ($adminId)');
        final success = await sendToUser(
          userId: adminId,
          title: title,
          body: body,
          data: data,
        );
        if (success) {
          successCount++;
          Logger.debug('✅ [Push] Successfully sent to admin: $adminEmail');
        } else {
          failCount++;
          Logger.debug('❌ [Push] Failed to send to admin: $adminEmail');
        }
      }

      Logger.debug('✅ [Push] ========== ADMIN NOTIFICATION SUMMARY ==========');
      Logger.debug('✅ [Push] Total admins: ${adminsResponse.length}');
      Logger.debug('✅ [Push] Success: $successCount');
      Logger.debug('✅ [Push] Failed: $failCount');
      Logger.debug('✅ [Push] ================================================');
      return successCount;
    } catch (e, stackTrace) {
      Logger.debug('❌ [Push] ========== ERROR SENDING TO ADMINS ==========');
      Logger.debug('❌ [Push] Error: $e');
      Logger.debug('❌ [Push] Stack trace: $stackTrace');
      Logger.debug('❌ [Push] =============================================');
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
      Logger.debug('📤 [Push] ========== CALLING EDGE FUNCTION ==========');
      Logger.debug('📤 [Push] Token: ${token.substring(0, 20)}...');
      Logger.debug('📤 [Push] Title: $title');
      Logger.debug('📤 [Push] Body: $body');
      Logger.debug('📤 [Push] Data: $data');
      Logger.debug('📤 [Push] Edge Function: send-push-notification');
      
      // CRITICAL: Log that we're about to invoke the Edge Function
      final timestamp = DateTime.now().toIso8601String();
      Logger.debug('📤 [Push] Invoking Edge Function at: $timestamp');
      Logger.debug('📤 [Push] Function name: send-push-notification');
      Logger.debug('📤 [Push] Request payload: {token: ${token.substring(0, 20)}..., title: $title, body: $body}');
      
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
      Logger.debug('📥 [Push] Edge Function call completed in ${stopwatch.elapsedMilliseconds}ms');
      
      Logger.debug('📥 [Push] ========== EDGE FUNCTION RESPONSE ==========');
      Logger.debug('📥 [Push] Response received at: ${DateTime.now().toIso8601String()}');

      Logger.debug('📥 [Push] Edge Function response status: ${response.status}');
      Logger.debug('📥 [Push] Edge Function response data: ${response.data}');

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
              Logger.debug('❌ [Push] ========== FCM TOKEN INVALID ==========');
              Logger.debug('❌ [Push] The FCM token is invalid/expired/unregistered');
              Logger.debug('❌ [Push] This usually means:');
              Logger.debug('❌ [Push] 1. App was uninstalled and reinstalled');
              Logger.debug('❌ [Push] 2. Token expired and needs refresh');
              Logger.debug('❌ [Push] 3. App data was cleared');
              Logger.debug('❌ [Push] SOLUTION: Delete old token and get a fresh one');
              Logger.debug('❌ [Push] The app should automatically refresh tokens on next launch');
              Logger.debug('❌ [Push] =========================================');
              
              // Try to delete the invalid token from database
              try {
                final currentUser = SupabaseService.client.auth.currentUser;
                if (currentUser != null) {
                  await SupabaseService.client
                      .from('user_fcm_tokens')
                      .delete()
                      .eq('fcm_token', token);
                  Logger.debug('✅ [Push] Deleted invalid token from database');
                  Logger.debug('✅ [Push] App will generate a new token on next launch');
                }
              } catch (e) {
                Logger.debug('⚠️ [Push] Could not delete invalid token: $e');
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
          Logger.debug('✅ [Push] Notification sent successfully');
          Logger.debug('✅ [Push] FCM message name: ${responseData['name']}');
          return true;
        } else if (responseData is Map && responseData['error'] != null) {
          // Edge Function returned error in response body
          Logger.debug('❌ [Push] ========== EDGE FUNCTION ERROR ==========');
          Logger.debug('❌ [Push] Error: ${responseData['error']}');
          Logger.debug('❌ [Push] Error details: ${responseData['details']}');
          Logger.debug('❌ [Push] =========================================');
          
          // Check if it's an FCM token error
          if (responseData['details'] is Map) {
            final details = responseData['details'] as Map;
            if (details['error'] is Map) {
              final fcmError = details['error'] as Map;
              final errorCode = fcmError['errorCode'];
              if (errorCode == 'UNREGISTERED') {
                Logger.debug('❌ [Push] FCM token is UNREGISTERED - deleting from database');
                try {
                  final currentUser = SupabaseService.client.auth.currentUser;
                  if (currentUser != null) {
                    await SupabaseService.client
                        .from('user_fcm_tokens')
                        .delete()
                        .eq('fcm_token', token);
                    Logger.debug('✅ [Push] Deleted invalid token');
                  }
                } catch (e) {
                  Logger.debug('⚠️ [Push] Could not delete invalid token: $e');
                }
              }
            }
          }
          
          return false;
        } else {
          Logger.debug('⚠️ [Push] Unexpected response format: $responseData');
          Logger.debug('⚠️ [Push] Expected: {"success": true} or {"error": "..."}');
          return false;
        }
      } else if (response.status == 404) {
        // Handle 404 errors (including UNREGISTERED tokens)
        Logger.debug('❌ [Push] ========== EDGE FUNCTION 404 ERROR ==========');
        Logger.debug('❌ [Push] Status: 404');
        Logger.debug('❌ [Push] Response: ${response.data}');
        
        // Check if it's an FCM UNREGISTERED error
        if (response.data is Map) {
          final responseData = response.data as Map;
          if (responseData['details'] is Map) {
            final details = responseData['details'] as Map;
            if (details['error'] is Map) {
              final fcmError = details['error'] as Map;
              final errorCode = fcmError['errorCode'];
              if (errorCode == 'UNREGISTERED') {
                Logger.debug('❌ [Push] FCM token is UNREGISTERED - deleting from database');
                try {
                  final currentUser = SupabaseService.client.auth.currentUser;
                  if (currentUser != null) {
                    await SupabaseService.client
                        .from('user_fcm_tokens')
                        .delete()
                        .eq('fcm_token', token);
                    Logger.debug('✅ [Push] Deleted invalid token');
                  }
                } catch (e) {
                  Logger.debug('⚠️ [Push] Could not delete invalid token: $e');
                }
              }
            }
          }
        }
        
        Logger.debug('❌ [Push] =========================================');
        return false;
      } else {
        Logger.debug('❌ [Push] ========== EDGE FUNCTION FAILED ==========');
        Logger.debug('❌ [Push] Status code: ${response.status}');
        Logger.debug('❌ [Push] Response: ${response.data}');
        
        // Provide specific guidance based on status code
        if (response.status == 404) {
          Logger.debug('❌ [Push] Edge Function NOT FOUND (404)');
          Logger.debug('⚠️ [Push] ACTION REQUIRED: Deploy Edge Function');
          Logger.debug('⚠️ [Push] Run: supabase functions deploy send-push-notification');
        } else if (response.status == 401 || response.status == 403) {
          Logger.debug('❌ [Push] Authentication/Authorization error (${response.status})');
          Logger.debug('⚠️ [Push] Check Supabase anon key and RLS policies');
        } else if (response.status == 500) {
          Logger.debug('❌ [Push] Edge Function server error (500)');
          Logger.debug('⚠️ [Push] Check Edge Function logs in Supabase Dashboard');
          Logger.debug('⚠️ [Push] Likely cause: Missing secrets or invalid credentials');
        }
        
        // Try to extract error message
        if (response.data is Map) {
          final errorMsg = response.data['error'] ?? 'Unknown error';
          Logger.debug('❌ [Push] Error message: $errorMsg');
        }
        
        Logger.debug('❌ [Push] =========================================');
        return false;
      }
    } catch (e, stackTrace) {
      Logger.debug('❌ [Push] Exception sending notification: $e');
      Logger.debug('❌ [Push] Stack trace: $stackTrace');
      
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
            Logger.debug('❌ [Push] FunctionException status: $status');
            
            // Check if it's a 404 with UNREGISTERED token
            if (status == 404) {
              // Try to extract details
              if (functionException.details != null) {
                final details = functionException.details;
                Logger.debug('❌ [Push] FunctionException details: $details');
                
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
                          Logger.debug('❌ [Push] ========== FCM TOKEN UNREGISTERED ==========');
                          Logger.debug('❌ [Push] The FCM token is invalid/expired/unregistered');
                          Logger.debug('❌ [Push] Deleting invalid token from database...');
                          
                          // Delete invalid token
                          try {
                            final currentUser = SupabaseService.client.auth.currentUser;
                            if (currentUser != null) {
                              await SupabaseService.client
                                  .from('user_fcm_tokens')
                                  .delete()
                                  .eq('fcm_token', token);
                              Logger.debug('✅ [Push] Deleted invalid token from database');
                              Logger.debug('✅ [Push] App will generate a new token on next launch');
                            }
                          } catch (deleteError) {
                            Logger.debug('⚠️ [Push] Could not delete invalid token: $deleteError');
                          }
                          
                          Logger.debug('❌ [Push] =========================================');
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
                            Logger.debug('❌ [Push] ========== FCM TOKEN UNREGISTERED ==========');
                            Logger.debug('❌ [Push] The FCM token is invalid/expired/unregistered');
                            Logger.debug('❌ [Push] Deleting invalid token from database...');
                            
                            // Delete invalid token
                            try {
                              final currentUser = SupabaseService.client.auth.currentUser;
                              if (currentUser != null) {
                                await SupabaseService.client
                                    .from('user_fcm_tokens')
                                    .delete()
                                    .eq('fcm_token', token);
                                Logger.debug('✅ [Push] Deleted invalid token from database');
                                Logger.debug('✅ [Push] App will generate a new token on next launch');
                              }
                            } catch (deleteError) {
                              Logger.debug('⚠️ [Push] Could not delete invalid token: $deleteError');
                            }
                            
                            Logger.debug('❌ [Push] =========================================');
                            return false;
                          }
                        }
                      }
                    }
                  }
                }
              }
              
              // 404 but not UNREGISTERED - might be function not deployed
              Logger.debug('⚠️ [Push] Edge Function returned 404');
              Logger.debug('⚠️ [Push] This might mean the function is not deployed');
              Logger.debug('⚠️ [Push] Or the FCM token is invalid');
            }
          }
        }
      } catch (parseError) {
        Logger.debug('⚠️ [Push] Could not parse exception details: $parseError');
      }
      
      // Fallback: Check error message strings for UNREGISTERED
      final errorStr = e.toString();
      if (errorStr.contains('UNREGISTERED') || errorStr.contains('NotRegistered')) {
        Logger.debug('❌ [Push] ========== FCM TOKEN UNREGISTERED (detected from error string) ==========');
        Logger.debug('❌ [Push] The FCM token is invalid/expired/unregistered');
        Logger.debug('❌ [Push] Deleting invalid token from database...');
        
        // Delete invalid token
        try {
          final currentUser = SupabaseService.client.auth.currentUser;
          if (currentUser != null) {
            await SupabaseService.client
                .from('user_fcm_tokens')
                .delete()
                .eq('fcm_token', token);
            Logger.debug('✅ [Push] Deleted invalid token from database');
            Logger.debug('✅ [Push] App will generate a new token on next launch');
          }
        } catch (deleteError) {
          Logger.debug('⚠️ [Push] Could not delete invalid token: $deleteError');
        }
        
        Logger.debug('❌ [Push] =========================================');
        return false;
      }
      
      // Check if it's a function not found error
      if (errorStr.contains('Function not found') || 
          errorStr.contains('404') ||
          errorStr.contains('not found')) {
        Logger.debug('⚠️ [Push] Edge Function may not be deployed');
        Logger.debug('⚠️ [Push] Please deploy the send-push-notification function to Supabase');
      }
      
      // Check if it's an authentication error
      if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
        Logger.debug('⚠️ [Push] Authentication error - check Supabase secrets');
        Logger.debug('⚠️ [Push] Ensure GOOGLE_CLIENT_EMAIL, GOOGLE_PRIVATE_KEY, and GOOGLE_PROJECT_ID are set');
      }
      
      return false;
    }
  }

}


