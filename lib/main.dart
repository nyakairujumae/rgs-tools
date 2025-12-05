import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

// Import all the actual classes
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin_home_screen.dart';
import 'screens/technician_home_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/pending_approval_screen.dart';
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
import 'providers/connectivity_provider.dart';
import 'database/database_helper.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';
import 'services/supabase_auth_storage.dart';
import 'services/image_upload_service.dart';
import 'services/firebase_messaging_service.dart'
    if (dart.library.html) 'services/firebase_messaging_service_stub.dart'
    as messaging_service;
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) 'services/firebase_messaging_stub.dart';

// Note: Firebase Messaging is handled through FirebaseMessagingService which is stubbed on web

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
      print('🔥 Platform: ${defaultTargetPlatform}');
      print('🔥 Firebase apps before init: ${Firebase.apps.length}');
      
      try {
        // Check if Firebase is already initialized
        if (Firebase.apps.isEmpty) {
          print('🔥 Firebase apps is empty, initializing...');
          
          try {
            // Get the platform-specific options
            final options = DefaultFirebaseOptions.currentPlatform;
            print('🔥 Using FirebaseOptions for: ${defaultTargetPlatform}');
            print('🔥 Project ID: ${options.projectId}');
            print('🔥 App ID: ${options.appId}');
            
            await Firebase.initializeApp(
              options: options,
            );
            
            print('🔥 Firebase.initializeApp() call completed');
            
            // Wait and check multiple times
            for (int i = 0; i < 10; i++) {
              await Future.delayed(Duration(milliseconds: 200));
              if (Firebase.apps.isNotEmpty) {
                print('✅ Firebase initialized successfully after ${(i + 1) * 200}ms');
                print('✅ Apps count: ${Firebase.apps.length}');
                print('✅ Firebase app name: ${Firebase.app().name}');
                break;
              }
              if (i == 9) {
                print('❌ Firebase.initializeApp() completed but apps list is still empty after 2 seconds');
                print('❌ This might indicate a configuration issue');
                print('❌ Please verify:');
                print('   1. google-services.json is in android/app/');
                print('   2. GoogleService-Info.plist is in ios/Runner/');
                print('   3. Firebase dependencies are properly installed');
              }
            }
          } catch (initError, stackTrace) {
            print('❌ Firebase.initializeApp() threw error: $initError');
            print('❌ Error type: ${initError.runtimeType}');
            print('❌ Error details: ${initError.toString()}');
            print('❌ Stack trace: $stackTrace');
            
            // Check if it's a configuration error
            if (initError.toString().contains('google-services') || 
                initError.toString().contains('GoogleService') ||
                initError.toString().contains('configuration')) {
              print('⚠️ This might be a Firebase configuration file issue');
              print('⚠️ Please verify google-services.json (Android) and GoogleService-Info.plist (iOS) are correct');
            }
            
            rethrow; // Re-throw to be caught by outer catch
          }
        } else {
          print('✅ Firebase already initialized. Apps: ${Firebase.apps.map((a) => a.name).join(", ")}');
        }
        
        // Final verification before proceeding
        print('🔥 Final check: Firebase apps count = ${Firebase.apps.length}');
        
        if (Firebase.apps.isEmpty) {
          print('❌ Firebase initialization failed - apps still empty after all attempts');
          print('⚠️ Continuing without Firebase Messaging...');
        } else {
          print('✅ Firebase verified. Setting up messaging...');
          
          // Set up Firebase Messaging background handler (only on non-web)
          // Register background message handler BEFORE initializing
          if (!kIsWeb) {
            FirebaseMessaging.onBackgroundMessage(
              messaging_service.firebaseMessagingBackgroundHandler,
            );
          }
          
          // Initialize Firebase Messaging
          await messaging_service.FirebaseMessagingService.initialize();
          print('✅ Firebase Messaging initialized successfully');
        }
      } catch (firebaseError, stackTrace) {
        print('❌ Firebase initialization failed: $firebaseError');
        print('❌ Error type: ${firebaseError.runtimeType}');
        print('❌ Stack trace: $stackTrace');
        // Continue without Firebase - this is not critical for basic app functionality
        print('⚠️ Continuing without Firebase...');
      }
    } else {
      print('🌐 Web platform detected - skipping Firebase initialization');
    }

    // Initialize Supabase (works on web too)
    print('Initializing Supabase...');
    bool supabaseInitialized = false;
    
    try {
      // Check if Supabase is already initialized
      try {
        final existingClient = Supabase.instance.client;
        print('✅ Supabase already initialized');
        supabaseInitialized = true;
      } catch (e) {
        // Not initialized yet, try to initialize it
        print('🔍 Supabase not initialized, initializing now...');
        print('🔍 Using bundle ID: com.rgs.app');
        
        try {
          // Add a small delay to allow native plugins to initialize
          await Future.delayed(const Duration(milliseconds: 500));
          
          await Supabase.initialize(
            url: SupabaseConfig.url,
            anonKey: SupabaseConfig.anonKey,
            authOptions: SupabaseAuthStorageFactory.createAuthOptions(),
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Supabase initialization timed out');
            },
          );
          print('✅ Supabase initialized successfully');
          supabaseInitialized = true;
        } on PlatformException catch (e) {
          // Handle shared_preferences channel errors
          if (e.code == 'channel-error' && (e.message?.contains('shared_preferences') == true || e.message?.contains('LegacyUserDefaultsApi') == true)) {
            print('⚠️ Supabase initialization failed due to shared_preferences channel error');
            print('⚠️ Error details: ${e.message}');
            print('⚠️ This is a native plugin issue. Using fallback client (limited session persistence)...');
            // Wait a bit and try fallback
            await Future.delayed(const Duration(milliseconds: 1000));
            // Use the fallback client from SupabaseService
            // This will create a direct client without full initialization
            try {
              final fallbackClient = SupabaseService.client;
              print('✅ Using fallback Supabase client (basic functionality available)');
              supabaseInitialized = true; // Mark as initialized even with fallback
            } catch (fallbackError) {
              print('❌ Fallback client creation also failed: $fallbackError');
              print('❌ Error type: ${fallbackError.runtimeType}');
              supabaseInitialized = false;
            }
          } else {
            print('❌ Supabase initialization failed with PlatformException: ${e.code} - ${e.message}');
            rethrow; // Re-throw if it's a different error
          }
        } catch (e, stackTrace) {
          // Catch any other errors
          print('❌ Supabase initialization failed: $e');
          print('❌ Error type: ${e.runtimeType}');
          print('❌ Stack trace: $stackTrace');
          // Try fallback even for other errors
          try {
            await Future.delayed(const Duration(milliseconds: 1000));
            final fallbackClient = SupabaseService.client;
            print('✅ Using fallback Supabase client after error');
            supabaseInitialized = true;
          } catch (fallbackError) {
            print('❌ Fallback client creation failed: $fallbackError');
            supabaseInitialized = false;
          }
        }
      }
      
      // Listen for auth state changes to handle password reset links
      if (supabaseInitialized && !kIsWeb) {
        try {
          // Try to get client from Supabase.instance, fallback to SupabaseService
          SupabaseClient? authClient;
          try {
            authClient = Supabase.instance.client;
          } catch (e) {
            // If Supabase.instance is not available, use fallback client
            authClient = SupabaseService.client;
          }
          
          if (authClient != null) {
            authClient.auth.onAuthStateChange.listen((data) {
              final event = data.event;
              final session = data.session;
              
              print('🔐 Auth state changed: $event');
              
              if (session != null) {
                print('✅ User logged in: ${session.user.email}');
              }

              // Handle password recovery - the deep link will navigate to reset screen
              if (event == AuthChangeEvent.passwordRecovery && session != null) {
                print('🔐 Password recovery detected - session available');
                // The reset password screen will handle the session via deep link
              }
              
              // Handle email confirmation
              if (event == AuthChangeEvent.signedIn && session != null) {
                print('🔐 User signed in - email may have been confirmed');
                // User is now signed in after email confirmation, app will handle navigation
              }
            });
          }
        } catch (e) {
          print('⚠️ Could not set up auth state listener: $e');
        }
      }
    } catch (supabaseError, stackTrace) {
      print('❌ Supabase initialization failed: $supabaseError');
      print('❌ Error type: ${supabaseError.runtimeType}');
      print('❌ Stack trace: $stackTrace');
      print('⚠️ App will continue but authentication features may not work properly');
      print('⚠️ Please restart the app or check your internet connection');
    }

    // Initialize local database (for offline support) - skip on web
    if (!kIsWeb) {
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
                        // Try to navigate to login screen using root navigator after frame
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen(),
                              settings: const RouteSettings(name: '/role-selection'),
                            ),
                            (route) => false,
                          );
                        });
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
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
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
          // Remove custom error widget to prevent blank error screens on back navigation
          // Flutter will handle errors with its default behavior
          ErrorWidget.builder = (FlutterErrorDetails details) {
            // During logout, silently handle errors
            if (authProvider.isLoggingOut) {
              return const SizedBox.shrink();
            }
            // For other errors, return empty widget to prevent blank screen
            // This prevents users from getting stuck on error screens when pressing back
            return const SizedBox.shrink();
          };
          
          // Wait for initialization to complete before showing any screen
          // This prevents the brief flash of role selection screen
          if (!authProvider.isInitialized || authProvider.isLoading) {
            return MaterialApp(
              title: 'RGS HVAC Tools',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: Scaffold(
                backgroundColor: AppTheme.appBackground,
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                  ),
                ),
              ),
              debugShowCheckedModeBanner: false,
            );
          }
          
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
              '/reset-password': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return ResetPasswordScreen(
                  accessToken: args?['access_token'] as String?,
                  refreshToken: args?['refresh_token'] as String?,
                  type: args?['type'] as String?,
                );
              },
              '/pending-approval': (context) => const PendingApprovalScreen(),
              '/admin': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                final initialTab = args?['initialTab'] as int? ?? 0;
                return AdminHomeScreenErrorBoundary(
                  child: AdminHomeScreen(initialTab: initialTab),
                );
              },
              '/technician': (context) => const TechnicianHomeScreen(),
              '/tool-detail': (context) {
                final tool = ModalRoute.of(context)!.settings.arguments as Tool;
                return ToolDetailScreen(tool: tool);
              },
            },
            onGenerateRoute: (settings) {
              // Handle password reset deep links
              if (settings.name != null && settings.name!.contains('reset-password')) {
                print('🔐 Password reset route detected: ${settings.name}');
                final uri = Uri.parse(settings.name!);
                final accessToken = uri.queryParameters['access_token'];
                final refreshToken = uri.queryParameters['refresh_token'];
                final type = uri.queryParameters['type'];
                
                return MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    type: type,
                  ),
                  settings: RouteSettings(name: '/reset-password'),
                );
              }
              
              // Handle unknown routes - prevent blank screens
              print('⚠️ Unknown route: ${settings.name}');
              
              // Default to role selection for unknown routes
              return MaterialPageRoute(
                builder: (context) => const RoleSelectionScreen(),
                settings: RouteSettings(name: '/role-selection'),
              );
            },
            onUnknownRoute: (settings) {
              // Fallback for any unhandled routes
              print('⚠️ Unknown route (onUnknownRoute): ${settings.name}');
              return MaterialPageRoute(
                builder: (context) => const RoleSelectionScreen(),
                settings: RouteSettings(name: '/role-selection'),
              );
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
    print('🔍 Current user: ${authProvider.user?.email ?? "None"}');
    
    try {
      // If we're in the middle of logging out, immediately show role selection.
      // This prevents a temporary blank screen caused by returning an empty widget while isLoading is true.
      if (authProvider.isLoggingOut) {
        print('🔍 isLoggingOut=true → Showing RoleSelectionScreen immediately');
        return const RoleSelectionScreen();
      }
      
      // For web, show role selection screen initially (no backend for now)
      // Desktop (Windows, macOS, Linux) uses real authentication like mobile
      if (kIsWeb) {
        print('🔍 Web platform detected, showing RoleSelectionScreen');
        return const RoleSelectionScreen();
      }
      
      // Desktop platforms use real Supabase authentication
      final isDesktopPlatform = defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux;
      if (isDesktopPlatform) {
        print('🔍 Desktop platform detected, using real Supabase authentication');
      }

      // At this point, initialization is complete (checked in Consumer2 builder)
      // Check authentication status and route accordingly
      if (authProvider.isAuthenticated) {
        print('🔍 User is authenticated, routing to appropriate screen');
        print('🔍 User role: ${authProvider.userRole}');
        print('🔍 Is admin: ${authProvider.isAdmin}');
        print('🔍 Is pending: ${authProvider.isPendingApproval}');
        
        // Route based on user role
        if (authProvider.isAdmin) {
          print('🔍 Routing to AdminHomeScreen');
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
          // Technician is approved - send to home screen
          print('🔍 Routing to TechnicianHomeScreen');
          return const TechnicianHomeScreen();
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
/// Only used on non-web platforms - defined in firebase_messaging_service.dart
