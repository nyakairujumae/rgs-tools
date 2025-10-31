import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/web/web_login_screen.dart';
import 'screens/web/web_admin_dashboard.dart';
import 'screens/web/web_technician_dashboard.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

// Import all the actual classes
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin_home_screen.dart';
import 'screens/technician_home_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/initial_tool_setup_screen.dart';
import 'screens/tool_detail_screen.dart';
import 'models/tool.dart';
import 'models/user_role.dart';
import 'providers/auth_provider.dart';
import 'providers/supabase_tool_provider.dart';
import 'providers/supabase_technician_provider.dart';
import 'providers/tool_issue_provider.dart';
import 'providers/request_thread_provider.dart';
import 'providers/pending_approvals_provider.dart';
import 'providers/admin_notification_provider.dart';
import 'database/database_helper.dart';
import 'config/supabase_config.dart';
import 'services/image_upload_service.dart';
import 'services/firebase_messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 App starting...');

  // Add global error handling for mobile
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  try {
    // Initialize Firebase (skip on web for now to avoid issues)
    if (!kIsWeb) {
      print('🔥 Initializing Firebase...');
      try {
        // Check if Firebase is already initialized
        if (Firebase.apps.isEmpty) {
          print('🔥 Firebase apps is empty, initializing...');
          try {
            await Firebase.initializeApp();
            print('✅ Firebase initialized successfully. Apps count: ${Firebase.apps.length}');
            if (Firebase.apps.isNotEmpty) {
              print('✅ Firebase app name: ${Firebase.app().name}');
            }
          } catch (initError, stackTrace) {
            print('❌ Firebase.initializeApp() threw error: $initError');
            print('❌ Stack trace: $stackTrace');
            rethrow; // Re-throw to be caught by outer catch
          }
        } else {
          print('✅ Firebase already initialized. Apps: ${Firebase.apps.map((a) => a.name).join(", ")}');
        }
        
        // Verify Firebase is initialized before proceeding
        if (Firebase.apps.isEmpty) {
          print('❌ Firebase initialization failed - apps still empty');
        } else {
          print('✅ Firebase verified. Setting up messaging...');
          
          // Set up Firebase Messaging background handler
          FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
          
          // Initialize Firebase Messaging
          await FirebaseMessagingService.initialize();
          print('✅ Firebase Messaging initialized successfully');
        }
      } catch (firebaseError, stackTrace) {
        print('❌ Firebase initialization failed: $firebaseError');
        print('❌ Stack trace: $stackTrace');
        // Continue without Firebase - this is not critical for basic app functionality
        print('⚠️ Continuing without Firebase...');
      }
    }

    // Initialize Supabase (skip on web for now to avoid issues)
    if (!kIsWeb) {
      print('Initializing Supabase...');
      try {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );
        print('Supabase initialized successfully');
      } catch (supabaseError) {
        print('Supabase initialization failed: $supabaseError');
        // Continue without Supabase - this is not critical for basic app functionality
        print('Continuing without Supabase...');
      }

      // Initialize local database (for offline support) - skip on web
      try {
        print('Initializing local database...');
        await DatabaseHelper.instance.database;
        print('Local database initialized successfully');
      } catch (e) {
        print('Database initialization failed: $e');
        // Continue without local database
      }

      // Ensure image storage bucket exists (non-blocking)
      print('Checking image storage bucket...');
      try {
        await ImageUploadService.ensureBucketExists();
        print('Image storage bucket ready');
      } catch (e) {
        print('Image storage bucket check failed (non-critical): $e');
        // Continue without failing - this is not critical for app startup
      }

      // Initialize session management for extended timeouts
      print('Initializing session management...');
      try {
        // This will be handled by AuthProvider
        print('Session management ready for 30-day timeouts');
      } catch (e) {
        print('Session management initialization failed (non-critical): $e');
      }
    } else {
      print('🌐 Web platform detected - skipping Supabase initialization');
    }

    print('Starting app...');
    runApp(const HvacToolsManagerApp());
  } catch (e, stackTrace) {
    print('Error during app initialization: $e');
    print('Stack trace: $stackTrace');
    
    // Run app with error handling
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Failed to initialize the app. Please refresh the page.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Reload the page
                  if (kIsWeb) {
                    // For web, reload the page
                    // This will be handled by the browser
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                ),
                child: Text('Refresh Page'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

// Completely simplified web app that bypasses all complex initialization
class SimpleWebApp extends StatelessWidget {
  const SimpleWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🌐 SimpleWebApp building...');
    return MaterialApp(
      title: 'RGS Tools',
      theme: AppTheme.lightTheme,
      home: const WebLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  
  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e, stackTrace) {
          // Handle error silently in production
          
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.red,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Application Error',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Something went wrong. Please restart the app.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Try to navigate to login screen
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                      ),
                      child: Text('Restart App'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class HvacToolsManagerApp extends StatelessWidget {
  const HvacToolsManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => SupabaseToolProvider()),
        ChangeNotifierProvider(create: (_) => SupabaseTechnicianProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ToolIssueProvider()),
        ChangeNotifierProvider(create: (_) => PendingApprovalsProvider()),
        ChangeNotifierProvider(create: (_) => RequestThreadProvider()),
        ChangeNotifierProvider(create: (_) => AdminNotificationProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          return MaterialApp(
            title: 'RGS HVAC Tools',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: _getInitialRoute(authProvider),
            builder: (context, child) {
              return ResponsiveBreakpoints.builder(
                breakpoints: [
                  const Breakpoint(start: 0, end: 450, name: MOBILE),
                  const Breakpoint(start: 451, end: 800, name: TABLET),
                  const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                  const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
                ],
                child: ErrorBoundary(child: child!),
              );
            },
            routes: {
              '/role-selection': (context) => const RoleSelectionScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/pending-approval': (context) => const PendingApprovalScreen(),
              '/admin': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                final initialTab = args?['initialTab'] as int? ?? 0;
                // Use web dashboard for web, original for mobile
                if (kIsWeb) {
                  return const WebAdminDashboard();
                } else {
                  return AdminHomeScreenErrorBoundary(
                    child: AdminHomeScreen(initialTab: initialTab),
                  );
                }
              },
                  '/technician': (context) {
                    // Use web dashboard for web, original for mobile
                    if (kIsWeb) {
                      return const WebTechnicianDashboard();
                    } else {
                      // Check if initial setup is needed
                      return const InitialToolSetupScreen();
                    }
                  },
              '/tool-detail': (context) {
                final tool = ModalRoute.of(context)!.settings.arguments as Tool;
                return ToolDetailScreen(tool: tool);
              },
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  Widget _getInitialRoute(AuthProvider authProvider) {
    print('🔍 _getInitialRoute called');
    print('🔍 isInitialized: ${authProvider.isInitialized}');
    print('🔍 isLoading: ${authProvider.isLoading}');
    print('🔍 isAuthenticated: ${authProvider.isAuthenticated}');
    
    try {
      // For web, show role selection screen initially (no backend for now)
      if (kIsWeb) {
        print('🔍 Web platform detected, showing RoleSelectionScreen');
        return const RoleSelectionScreen();
      }
      
      // Show loading screen during initialization or any loading state
      if (!authProvider.isInitialized || authProvider.isLoading) {
        print('🔍 Showing loading screen');
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading RGS Tools...',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (authProvider.isAuthenticated) {
        print('🔍 User is authenticated, routing to appropriate screen');
        // Route based on user role
        if (authProvider.isAdmin) {
          return AdminHomeScreenErrorBoundary(
            child: AdminHomeScreen(
              key: ValueKey('admin_home_${DateTime.now().millisecondsSinceEpoch}'),
            ),
          );
        } else if (authProvider.isPendingApproval || authProvider.userRole == UserRole.pending) {
          // Check approval status for technicians
          print('🔍 Technician user detected, checking approval status...');
          return const PendingApprovalScreen();
        } else {
          // Technician is approved - check if they need to complete initial tool setup
          return InitialToolSetupScreen();
        }
      } else {
        print('🔍 User not authenticated, showing role selection screen');
        return const RoleSelectionScreen();
      }
    } catch (e, stackTrace) {
      // Always fallback to role selection screen on any error
      print('❌ Error in _getInitialRoute: $e');
      print('❌ Stack trace: $stackTrace');
      return const RoleSelectionScreen();
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔥 Background message handler: ${message.messageId}');
  print('🔥 Message data: ${message.data}');
}