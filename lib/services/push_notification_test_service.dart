import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'push_notification_service.dart';
import '../utils/logger.dart';

/// Test service to diagnose push notification issues
class PushNotificationTestService {
  /// Test push notification to current user
  static Future<Map<String, dynamic>> testPushToCurrentUser() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'steps': <Map<String, dynamic>>[],
    };

    try {
      // Add overall timeout to prevent infinite hanging
      return await Future.any([
        _performTest(results),
        Future.delayed(const Duration(seconds: 30), () {
          results['error'] = 'Test timed out after 30 seconds';
          results['steps'].add({
            'step': 'Timeout',
            'status': 'failed',
            'message': 'Test took too long - check Edge Function logs',
          });
          return results;
        }),
      ]);
    } catch (e, stackTrace) {
      results['error'] = e.toString();
      results['stack_trace'] = stackTrace.toString();
      results['steps'].add({
        'step': 'Error',
        'status': 'failed',
        'message': e.toString(),
      });
      return results;
    }
  }

  static Future<Map<String, dynamic>> _performTest(Map<String, dynamic> results) async {
    try {
      // Step 1: Check if user is logged in
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        results['error'] = 'No user logged in';
        results['steps'].add({
          'step': 'Check user login',
          'status': 'failed',
          'message': 'User is not logged in',
        });
        return results;
      }

      results['steps'].add({
        'step': 'Check user login',
        'status': 'success',
        'message': 'User logged in: ${user.email}',
        'user_id': user.id,
      });

      // Step 2: Get FCM tokens from database
      final tokensResponse = await SupabaseService.client
          .from('user_fcm_tokens')
          .select('fcm_token, platform, created_at, updated_at')
          .eq('user_id', user.id);

      if (tokensResponse.isEmpty) {
        results['error'] = 'No FCM tokens found for user';
        results['steps'].add({
          'step': 'Get FCM tokens',
          'status': 'failed',
          'message': 'No FCM tokens found in database',
        });
        return results;
      }

      results['steps'].add({
        'step': 'Get FCM tokens',
        'status': 'success',
        'message': 'Found ${tokensResponse.length} token(s)',
        'tokens': tokensResponse.map((t) => {
          'platform': t['platform'],
          'token_preview': (t['fcm_token'] as String?)?.substring(0, 30) ?? 'null',
          'created_at': t['created_at'],
          'updated_at': t['updated_at'],
        }).toList(),
      });

      // Step 3: Test sending to each token
      int successCount = 0;
      int failCount = 0;
      final tokenResults = <Map<String, dynamic>>[];

      for (final tokenRecord in tokensResponse) {
        final token = tokenRecord['fcm_token'] as String?;
        final platform = tokenRecord['platform'] as String?;

        if (token == null || token.isEmpty) {
          tokenResults.add({
            'platform': platform ?? 'unknown',
            'status': 'failed',
            'message': 'Token is null or empty',
          });
          failCount++;
          continue;
        }

        Logger.debug('🧪 [Test] Testing push notification to ${platform ?? 'unknown'} token...');
        
        final success = await PushNotificationService.sendToToken(
          token: token,
          title: '🧪 Test Push Notification',
          body: 'This is a test notification sent at ${DateTime.now().toString().substring(11, 19)}',
          data: {
            'test': 'true',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            Logger.debug('⚠️ [Test] sendToToken timed out after 10 seconds');
            return false;
          },
        );

        if (success) {
          tokenResults.add({
            'platform': platform ?? 'unknown',
            'status': 'success',
            'message': 'Notification sent successfully',
          });
          successCount++;
        } else {
          tokenResults.add({
            'platform': platform ?? 'unknown',
            'status': 'failed',
            'message': 'Failed to send notification (check Edge Function logs)',
          });
          failCount++;
        }
      }

      results['steps'].add({
        'step': 'Send test notifications',
        'status': successCount > 0 ? 'partial' : 'failed',
        'message': 'Sent to $successCount/${tokensResponse.length} tokens',
        'success_count': successCount,
        'fail_count': failCount,
        'token_results': tokenResults,
      });

      results['success'] = successCount > 0;
      results['summary'] = 'Test completed: $successCount success, $failCount failed';

      return results;
    } catch (e, stackTrace) {
      results['error'] = e.toString();
      results['stack_trace'] = stackTrace.toString();
      results['steps'].add({
        'step': 'Error',
        'status': 'failed',
        'message': e.toString(),
      });
      return results;
    }
  }

  /// Test Edge Function directly
  static Future<Map<String, dynamic>> testEdgeFunction(String token) async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      Logger.debug('🧪 [Test] Testing Edge Function directly with token: ${token.substring(0, 20)}...');

      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'token': token,
          'title': '🧪 Direct Edge Function Test',
          'body': 'Testing Edge Function directly at ${DateTime.now().toString().substring(11, 19)}',
        },
      );

      results['status_code'] = response.status;
      results['response_data'] = response.data;
      results['success'] = response.status == 200;

      if (response.status == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          results['message'] = 'Edge Function returned success';
        } else if (responseData is Map && responseData['error'] != null) {
          results['message'] = 'Edge Function error: ${responseData['error']}';
          results['error'] = responseData['error'];
        } else {
          results['message'] = 'Unexpected response format';
        }
      } else {
        results['message'] = 'Edge Function returned status ${response.status}';
        results['error'] = response.data;
      }

    } catch (e, stackTrace) {
      results['error'] = e.toString();
      results['stack_trace'] = stackTrace.toString();
      results['success'] = false;
      results['message'] = 'Exception: $e';
    }

    return results;
  }

  /// Get diagnostic information
  static Future<Map<String, dynamic>> getDiagnostics() async {
    final diagnostics = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        diagnostics['user'] = null;
        return diagnostics;
      }

      diagnostics['user'] = {
        'id': user.id,
        'email': user.email,
        'email_confirmed': user.emailConfirmedAt != null,
      };

      // Get FCM tokens
      final tokens = await SupabaseService.client
          .from('user_fcm_tokens')
          .select('*')
          .eq('user_id', user.id);

      diagnostics['fcm_tokens'] = {
        'count': tokens.length,
        'tokens': tokens.map((t) => {
          'platform': t['platform'],
          'token_length': (t['fcm_token'] as String?)?.length ?? 0,
          'created_at': t['created_at'],
          'updated_at': t['updated_at'],
        }).toList(),
      };

      // Get user role
      final userRecord = await SupabaseService.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      diagnostics['user_role'] = userRecord?['role'];

      // Check recent notifications
      final recentNotifications = await SupabaseService.client
          .from('admin_notifications')
          .select('id, title, type, timestamp')
          .order('timestamp', ascending: false)
          .limit(5);

      diagnostics['recent_notifications'] = recentNotifications.length;

    } catch (e) {
      diagnostics['error'] = e.toString();
    }

    return diagnostics;
  }
}

