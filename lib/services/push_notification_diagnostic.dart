import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'push_notification_service.dart';

/// Comprehensive diagnostic tool for push notifications
/// Run this to identify exactly where push notifications are failing
class PushNotificationDiagnostic {
  /// Run complete diagnostic
  static Future<Map<String, dynamic>> runDiagnostic() async {
    final results = <String, dynamic>{};
    
    debugPrint('🔍 [Diagnostic] ========== STARTING PUSH NOTIFICATION DIAGNOSTIC ==========');
    
    // 1. Check if user is logged in
    results['user_logged_in'] = await _checkUserLoggedIn();
    
    // 2. Check FCM tokens in database
    results['tokens_in_database'] = await _checkTokensInDatabase();
    
    // 3. Check Edge Function deployment
    results['edge_function'] = await _checkEdgeFunction();
    
    // 4. Test sending a notification
    results['test_send'] = await _testSendNotification();
    
    // 5. Check admin users
    results['admin_users'] = await _checkAdminUsers();
    
    debugPrint('🔍 [Diagnostic] ========== DIAGNOSTIC COMPLETE ==========');
    debugPrint('🔍 [Diagnostic] Results: $results');
    
    return results;
  }
  
  /// Check if user is logged in
  static Future<Map<String, dynamic>> _checkUserLoggedIn() async {
    debugPrint('🔍 [Diagnostic] Checking if user is logged in...');
    try {
      final user = SupabaseService.client.auth.currentUser;
      final session = SupabaseService.client.auth.currentSession;
      
      final result = {
        'has_user': user != null,
        'has_session': session != null,
        'user_id': user?.id,
        'user_email': user?.email,
        'session_expired': session?.isExpired ?? false,
      };
      
      debugPrint('🔍 [Diagnostic] User logged in: ${result['has_user']}');
      debugPrint('🔍 [Diagnostic] Session exists: ${result['has_session']}');
      
      return result;
    } catch (e) {
      debugPrint('❌ [Diagnostic] Error checking user: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Check FCM tokens in database
  static Future<Map<String, dynamic>> _checkTokensInDatabase() async {
    debugPrint('🔍 [Diagnostic] Checking FCM tokens in database...');
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        return {'error': 'User not logged in'};
      }
      
      // Check current user's tokens
      final userTokens = await SupabaseService.client
          .from('user_fcm_tokens')
          .select('fcm_token, platform, updated_at')
          .eq('user_id', user.id);
      
      // Check all tokens (to see if RLS is blocking)
      List<dynamic> allTokens = [];
      try {
        allTokens = await SupabaseService.client
            .from('user_fcm_tokens')
            .select('user_id, platform')
            .limit(10);
      } catch (e) {
        debugPrint('⚠️ [Diagnostic] Could not query all tokens (RLS may be blocking): $e');
      }
      
      final result = {
        'user_tokens_count': userTokens.length,
        'user_tokens': userTokens.map((t) => {
          'platform': t['platform'],
          'token_preview': (t['fcm_token'] as String?)?.substring(0, 20) ?? 'null',
          'updated_at': t['updated_at'],
        }).toList(),
        'all_tokens_count': allTokens.length,
        'can_query_all_tokens': allTokens.isNotEmpty || userTokens.isNotEmpty,
      };
      
      debugPrint('🔍 [Diagnostic] User tokens: ${result['user_tokens_count']}');
      debugPrint('🔍 [Diagnostic] All tokens in DB: ${result['all_tokens_count']}');
      
      return result;
    } catch (e) {
      debugPrint('❌ [Diagnostic] Error checking tokens: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Check Edge Function deployment
  static Future<Map<String, dynamic>> _checkEdgeFunction() async {
    debugPrint('🔍 [Diagnostic] Checking Edge Function...');
    try {
      // Try to invoke the Edge Function with a test payload
      final testToken = 'test_token_12345';
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'token': testToken,
          'title': 'Test',
          'body': 'Test',
        },
      );
      
      final result = {
        'function_exists': true,
        'status': response.status,
        'response': response.data,
        'error': response.status != 200 ? response.data : null,
      };
      
      if (response.status == 200) {
        debugPrint('✅ [Diagnostic] Edge Function exists and responds');
      } else if (response.status == 404) {
        debugPrint('❌ [Diagnostic] Edge Function NOT FOUND (404) - needs to be deployed');
        result['error'] = 'Edge Function not deployed. Run: supabase functions deploy send-push-notification';
      } else if (response.status == 500) {
        debugPrint('❌ [Diagnostic] Edge Function error (500) - check secrets');
        result['error'] = 'Edge Function error - check GOOGLE_PROJECT_ID, GOOGLE_CLIENT_EMAIL, GOOGLE_PRIVATE_KEY secrets';
      } else {
        debugPrint('⚠️ [Diagnostic] Edge Function returned status: ${response.status}');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ [Diagnostic] Error checking Edge Function: $e');
      
      // Check if it's a "function not found" error
      if (e.toString().contains('Function not found') || 
          e.toString().contains('404') ||
          e.toString().contains('not found')) {
        return {
          'function_exists': false,
          'error': 'Edge Function not deployed. Run: supabase functions deploy send-push-notification',
        };
      }
      
      return {'error': e.toString()};
    }
  }
  
  /// Test sending a notification
  static Future<Map<String, dynamic>> _testSendNotification() async {
    debugPrint('🔍 [Diagnostic] Testing notification send...');
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        return {'error': 'User not logged in'};
      }
      
      // Try to send a test notification to current user
      final success = await PushNotificationService.sendToUser(
        userId: user.id,
        title: 'Test Notification',
        body: 'This is a test notification from diagnostic tool',
        data: {'type': 'test', 'diagnostic': 'true'},
      );
      
      return {
        'success': success,
        'message': success 
            ? 'Test notification sent successfully' 
            : 'Test notification failed - check logs for details',
      };
    } catch (e) {
      debugPrint('❌ [Diagnostic] Error testing notification: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Check admin users
  static Future<Map<String, dynamic>> _checkAdminUsers() async {
    debugPrint('🔍 [Diagnostic] Checking admin users...');
    try {
      List<Map<String, dynamic>> admins = [];
      
      // Try RPC function first
      try {
        final rpcResponse = await SupabaseService.client.rpc('get_admin_user_ids');
        if (rpcResponse != null && rpcResponse is List) {
          admins = List<Map<String, dynamic>>.from(rpcResponse);
          debugPrint('✅ [Diagnostic] Found ${admins.length} admins via RPC');
        }
      } catch (e) {
        debugPrint('⚠️ [Diagnostic] RPC function failed: $e');
        
        // Try direct query
        try {
          admins = await SupabaseService.client
              .from('users')
              .select('id, email, role')
              .eq('role', 'admin');
          debugPrint('✅ [Diagnostic] Found ${admins.length} admins via direct query');
        } catch (e2) {
          debugPrint('❌ [Diagnostic] Direct query also failed: $e2');
        }
      }
      
      // Check tokens for each admin
      final adminsWithTokens = <Map<String, dynamic>>[];
      for (final admin in admins) {
        try {
          final tokens = await SupabaseService.client
              .from('user_fcm_tokens')
              .select('platform')
              .eq('user_id', admin['id'] as String);
          
          adminsWithTokens.add({
            'id': admin['id'],
            'email': admin['email'],
            'has_tokens': tokens.isNotEmpty,
            'token_count': tokens.length,
            'platforms': tokens.map((t) => t['platform']).toList(),
          });
        } catch (e) {
          adminsWithTokens.add({
            'id': admin['id'],
            'email': admin['email'],
            'error': 'Could not check tokens: $e',
          });
        }
      }
      
      return {
        'admin_count': admins.length,
        'admins': adminsWithTokens,
        'admins_with_tokens': adminsWithTokens.where((a) => a['has_tokens'] == true).length,
      };
    } catch (e) {
      debugPrint('❌ [Diagnostic] Error checking admins: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Print diagnostic summary
  static void printSummary(Map<String, dynamic> results) {
    debugPrint('\n');
    debugPrint('📊 [Diagnostic] ========== SUMMARY ==========');
    
    // User
    final user = results['user_logged_in'] as Map<String, dynamic>?;
    if (user != null) {
      debugPrint('👤 User: ${user['has_user'] == true ? "✅ Logged in" : "❌ Not logged in"}');
      if (user['user_email'] != null) {
        debugPrint('   Email: ${user['user_email']}');
      }
    }
    
    // Tokens
    final tokens = results['tokens_in_database'] as Map<String, dynamic>?;
    if (tokens != null) {
      debugPrint('🔑 Tokens: ${tokens['user_tokens_count'] ?? 0} token(s) for current user');
      if (tokens['user_tokens'] != null) {
        final tokenList = tokens['user_tokens'] as List;
        for (final token in tokenList) {
          debugPrint('   - ${token['platform']}: ${token['token_preview']}...');
        }
      }
    }
    
    // Edge Function
    final edgeFunction = results['edge_function'] as Map<String, dynamic>?;
    if (edgeFunction != null) {
      if (edgeFunction['function_exists'] == true) {
        debugPrint('⚡ Edge Function: ✅ Deployed');
        if (edgeFunction['status'] == 200) {
          debugPrint('   Status: ✅ Working');
        } else {
          debugPrint('   Status: ❌ Error (${edgeFunction['status']})');
          if (edgeFunction['error'] != null) {
            debugPrint('   Error: ${edgeFunction['error']}');
          }
        }
      } else {
        debugPrint('⚡ Edge Function: ❌ NOT DEPLOYED');
        debugPrint('   Action: Run: supabase functions deploy send-push-notification');
      }
    }
    
    // Admin Users
    final admins = results['admin_users'] as Map<String, dynamic>?;
    if (admins != null) {
      debugPrint('👥 Admins: ${admins['admin_count'] ?? 0} admin(s)');
      debugPrint('   With tokens: ${admins['admins_with_tokens'] ?? 0}');
    }
    
    // Test Send
    final testSend = results['test_send'] as Map<String, dynamic>?;
    if (testSend != null) {
      if (testSend['success'] == true) {
        debugPrint('📤 Test Send: ✅ Success');
      } else {
        debugPrint('📤 Test Send: ❌ Failed');
        if (testSend['error'] != null) {
          debugPrint('   Error: ${testSend['error']}');
        }
      }
    }
    
    debugPrint('📊 [Diagnostic] ============================');
    debugPrint('\n');
  }
}


