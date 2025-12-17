import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, kDebugMode;
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

// Import all the actual classes
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin_home_screen.dart';
import 'screens/technician_home_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/tool_detail_screen.dart';
import 'services/first_launch_service.dart';
import 'models/tool.dart';
import 'models/user_role.dart';
import 'providers/auth_provider.dart';
import 'providers/supabase_tool_provider.dart';
import 'providers/supabase_technician_provider.dart';
import 'providers/tool_issue_provider.dart';
import 'providers/request_thread_provider.dart';
import 'providers/pending_approvals_provider.dart';
import 'providers/admin_notification_provider.dart';
import 'providers/approval_workflows_provider.dart';
import 'providers/connectivity_provider.dart';
import 'database/database_helper.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';
import 'services/supabase_auth_storage.dart';
import 'services/image_upload_service.dart';
import 'services/firebase_messaging_service.dart' as fcm_service
    if (dart.library.html) 'services/firebase_messaging_service_stub.dart';
// Import background handler (top-level function)
import 'services/firebase_messaging_service.dart' show firebaseMessagingBackgroundHandler
    if (dart.library.html) 'services/firebase_messaging_service_stub.dart' show firebaseMessagingBackgroundHandler;
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) 'services/firebase_messaging_stub.dart';

// Note: Firebase Messaging is handled through FirebaseMessagingService which is stubbed on web

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if this is first launch - only show splash on first launch
  final isFirstLaunch = await FirstLaunchService.isFirstLaunch();
  
  if (isFirstLaunch) {
    // Only preserve native splash screen on first launch
    FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());
    print('🚀 App starting (first launch) - showing splash screen...');
  } else {
    // Not first launch - remove splash immediately
    FlutterNativeSplash.remove();
    print('🚀 App starting (returning user) - skipping splash screen...');
  }

  print('🚀 App starting...');

  // Add global error handling for mobile
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // Initialize Firebase (required before using any Firebase services)
  if (!kIsWeb) {
    try {
      // CRITICAL: Initialize Firebase BEFORE runApp()
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
      
      // CRITICAL: Register background message handler BEFORE runApp()
      // Must be top-level function with @pragma('vm:entry-point')
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      print('✅ Background message handler registered');
      
      // Initialize Firebase Messaging Service (after Firebase and handler registration)
      await fcm_service.FirebaseMessagingService.initialize();
      print('✅ Firebase Messaging initialized');
    } catch (e, stackTrace) {
      print('❌ Firebase initialization failed: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  // Initialize Supabase (works on web too)
  print('Initializing Supabase...');
  bool supabaseInitialized = false;
  
  try {
      // Check if Supabase is already initialized
      try {
        Supabase.instance.client; // Check if initialized
        print('✅ Supabase already initialized');
        supabaseInitialized = true;
      } catch (e) {
        // Not initialized yet, try to initialize it
        print('🔍 Supabase not initialized, initializing now...');
        print('🔍 Using bundle ID: com.rgs.app');
        
        try {
          // Minimal delay to allow native plugins to initialize
          await Future.delayed(const Duration(milliseconds: 50));
          
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
              SupabaseService.client; // Initialize fallback client
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
            SupabaseService.client; // Initialize fallback client
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
          SupabaseClient authClient;
          try {
            authClient = Supabase.instance.client;
          } catch (e) {
            // If Supabase.instance is not available, use fallback client
            authClient = SupabaseService.client;
          }
          
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
  
  // Run the app
  runApp(const HvacToolsManagerApp());
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
        } catch (e) {
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

/// Wrapper to show splash screen only on first launch
class _FirstLaunchWrapper extends StatefulWidget {
  final Widget child;
  
  const _FirstLaunchWrapper({required this.child});
  
  @override
  State<_FirstLaunchWrapper> createState() => _FirstLaunchWrapperState();
}

class _FirstLaunchWrapperState extends State<_FirstLaunchWrapper> {
  @override
  void initState() {
    super.initState();
    // Mark first launch as complete in the background without blocking
    _markFirstLaunchCompleteInBackground();
  }

  void _markFirstLaunchCompleteInBackground() {
    // Check and mark first launch complete in the background
    // This doesn't block the UI - just runs silently
    FirstLaunchService.isFirstLaunch().then((isFirst) {
      if (isFirst) {
        // If it's the first launch, mark it as complete in the background
        FirstLaunchService.markFirstLaunchComplete();
      }
    }).catchError((e) {
      // Silently handle errors - don't block the app
      print('⚠️ Error checking first launch (non-critical): $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always show the child immediately - no loading screens
    return widget.child;
  }
}

/// Smooth fade-in transition wrapper for splash screen to app transition
class SplashTransition extends StatefulWidget {
  final Widget child;
  
  const SplashTransition({super.key, required this.child});
  
  @override
  State<SplashTransition> createState() => _SplashTransitionState();
}

class _SplashTransitionState extends State<SplashTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    // Start animation after a brief delay to ensure splash is removed
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
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
        ChangeNotifierProvider(create: (_) => ApprovalWorkflowsProvider()),
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
          
          // Remove native splash immediately when initialization completes
          // Only if it was preserved (first launch)
          // Do this synchronously to minimize delay
          if (authProvider.isInitialized && !authProvider.isLoading) {
            // Check if splash was preserved (first launch)
            // If not first launch, splash was already removed in main()
            FirstLaunchService.isFirstLaunch().then((isFirst) {
              if (isFirst) {
                FlutterNativeSplash.remove();
              }
            }).catchError((e) {
              // If check fails, try to remove anyway (safe to call multiple times)
              FlutterNativeSplash.remove();
            });
          }
          
          // Always render MaterialApp (like mom.dart)
          // The native splash (preserved in main()) stays visible until we remove it above
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
              // Handle email confirmation deep links (auth/callback)
              // Check for various URL formats that Supabase might send
              if (settings.name != null) {
                final uriString = settings.name!;
                print('🔐 Checking deep link: $uriString');
                
                // Check if this is an auth callback URL
                final isAuthCallback = uriString.contains('auth/callback') || 
                                      uriString.contains('access_token') ||
                                      uriString.contains('type=signup') ||
                                      uriString.contains('type=recovery') ||
                                      uriString.contains('email-confirmation');
                
                if (isAuthCallback) {
                  print('🔐 Auth deep link detected: $uriString');
                  final uri = Uri.parse(uriString);
                
                // Handle email confirmation callback
                  final type = uri.queryParameters['type'];
                  final hasAccessToken = uri.queryParameters.containsKey('access_token');
                  
                  print('🔐 URL parameters - type: $type, hasAccessToken: $hasAccessToken');
                  
                  if (type == 'recovery' || uriString.contains('reset-password')) {
                    // Password reset
                    print('🔐 Password reset route detected');
                    final accessToken = uri.queryParameters['access_token'];
                    final refreshToken = uri.queryParameters['refresh_token'];
                    
                    return MaterialPageRoute(
                      builder: (context) => ResetPasswordScreen(
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        type: type ?? 'recovery',
                      ),
                      settings: RouteSettings(name: '/reset-password'),
                    );
                  } else if (type == 'signup' || hasAccessToken || uriString.contains('email-confirmation')) {
                    // Email confirmation - get session from URL and auto-login
                    print('✅ Email confirmation detected, getting session from URL...');
                    print('🔐 Full URI: $uri');
                    print('🔐 Query parameters: ${uri.queryParameters}');
                    
                    // Process the session and navigate directly to home - no role selection
                    return MaterialPageRoute(
                      builder: (context) {
                        // Process the session when the route is built
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          try {
                            print('🔐 Getting session from URL...');
                            print('🔐 URI scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}');
                            
                            // Get session from URL (this confirms the email and creates the session)
                            final sessionResponse = await SupabaseService.client.auth.getSessionFromUrl(uri);
                            
                            if (sessionResponse.session != null) {
                              print('✅ Session created from email confirmation');
                              print('✅ User: ${sessionResponse.session!.user.email}');
                              print('✅ Email confirmed: ${sessionResponse.session!.user.emailConfirmedAt != null}');
                              print('✅ User metadata: ${sessionResponse.session!.user.userMetadata}');
                              print('✅ Role in metadata: ${sessionResponse.session!.user.userMetadata?['role']}');
                              
                              // Wait a moment for database trigger to create user record
                              // The trigger fires when email_confirmed_at is set
                              print('⏳ Waiting for database trigger to create user record...');
                              await Future.delayed(const Duration(seconds: 2));
                              
                              // Get auth provider and re-initialize to pick up new session
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              
                              // Wait for auth provider to fully initialize with the new session
                              await authProvider.initialize();
                              
                              // Wait a bit more to ensure auth state is fully updated
                              await Future.delayed(const Duration(milliseconds: 500));
                              
                              // Check authentication status after initialization
                              if (authProvider.isAuthenticated) {
                                print('✅ User authenticated after email confirmation');
                                print('✅ User role: ${authProvider.userRole}');
                                print('✅ Is admin: ${authProvider.isAdmin}');
                                print('✅ Is pending approval: ${authProvider.isPendingApproval}');
                                
                                // For technicians, explicitly check approval status
                                if (!authProvider.isAdmin) {
                                  print('🔍 Checking approval status for technician...');
                                  final approvalStatus = await authProvider.checkApprovalStatus();
                                  print('🔍 Approval status: $approvalStatus');
                                  
                                  if (approvalStatus == false) {
                                    // Technician is pending approval
                                    print('✅ Technician is pending approval - redirecting to pending approval screen');
                                    final navigator = Navigator.of(context, rootNavigator: true);
                                    navigator.pushNamedAndRemoveUntil(
                                      '/pending-approval',
                                      (route) => false,
                                    );
                                    return;
                                  }
                                }
                                
                                // Navigate directly to appropriate home screen based on role
                                final navigator = Navigator.of(context, rootNavigator: true);
                                
                                if (authProvider.isAdmin) {
                                  print('✅ Auto-logging in as admin - redirecting to admin home');
                                  navigator.pushNamedAndRemoveUntil(
                                    '/admin',
                                    (route) => false,
                                  );
                                } else if (authProvider.isPendingApproval || authProvider.userRole == UserRole.pending) {
                                  print('✅ Auto-logging in - pending approval');
                                  navigator.pushNamedAndRemoveUntil(
                                    '/pending-approval',
                                    (route) => false,
                                  );
                                } else {
                                  print('✅ Auto-logging in as technician - redirecting to technician home');
                                  navigator.pushNamedAndRemoveUntil(
                                    '/technician',
                                    (route) => false,
                                  );
                                }
                              } else {
                                // If still not authenticated after initialization, there's an issue
                                print('⚠️ Session created but user not authenticated after initialization');
                                print('⚠️ This might indicate a role assignment issue');
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Email confirmed, but authentication failed. Please try logging in.'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 5),
                                    ),
                                  );
                                  // Redirect to role selection as fallback
                                  Future.delayed(const Duration(seconds: 2), () {
                                    if (context.mounted) {
                                      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                                        '/role-selection',
                                        (route) => false,
                                      );
                                    }
                                  });
                                }
                              }
                            } else {
                              print('⚠️ No session returned from URL');
                              print('⚠️ This might mean the confirmation link is invalid or expired');
                              
                              // Show error message and redirect to role selection
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Email confirmation failed. The link may be invalid or expired.'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                                // Redirect to role selection after showing error
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (context.mounted) {
                                    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                                      '/role-selection',
                                      (route) => false,
                                    );
                                  }
                                });
                              }
                            }
                          } catch (e, stackTrace) {
                            print('❌ Error getting session from URL: $e');
                            print('❌ Stack trace: $stackTrace');
                            
                            // Show error message to user and redirect to role selection
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error confirming email: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                              // Redirect to role selection after showing error
                              Future.delayed(const Duration(seconds: 2), () {
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                                    '/role-selection',
                                    (route) => false,
                                  );
                                }
                              });
                            }
                          }
                        });
                        
                        // Return invisible widget - no loading screen
                        // The navigation will happen in the postFrameCallback above
                        return const SizedBox.shrink();
                      },
                      settings: RouteSettings(name: '/auth-callback'),
                    );
                  }
                }
              }
              
              // Handle password reset deep links (legacy format)
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
        return const SplashTransition(child: RoleSelectionScreen());
      }
      
      // Don't show any Flutter screen during initialization
      // The native splash (preserved in main()) stays visible until we remove it
      // The removal happens in the Consumer builder above
      if (!authProvider.isInitialized || authProvider.isLoading) {
        print('🔍 Waiting for initialization - native splash should be visible');
        // Return fully invisible widget so native splash remains visible
        // No Flutter paint, no Scaffold, no backgroundColor
        return const SizedBox.shrink();
      }
      
      // For web, show role selection screen initially (no backend for now)
      // Desktop (Windows, macOS, Linux) uses real authentication like mobile
      if (kIsWeb) {
        print('🔍 Web platform detected, showing RoleSelectionScreen');
        return _FirstLaunchWrapper(
          child: const SplashTransition(child: RoleSelectionScreen()),
        );
      }
      
      // Desktop platforms use real Supabase authentication
      final isDesktopPlatform = defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux;
      if (isDesktopPlatform) {
        print('🔍 Desktop platform detected, using real Supabase authentication');
      }

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
        } else if (!authProvider.isEmailConfirmed) {
          // Email not confirmed - show role selection (user needs to confirm email first)
          // After confirmation, they'll be auto-logged in via deep link
          print('❌ Email not confirmed - showing role selection');
          return const SplashTransition(child: RoleSelectionScreen());
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
        print('🔍 User not authenticated, checking first launch');
        // Check if this is first launch - show splash screen only on first launch
        return _FirstLaunchWrapper(
          child: const SplashTransition(child: RoleSelectionScreen()),
        );
      }
    } catch (e, stackTrace) {
      // Always fallback to role selection screen on any error (for new installs)
      print('❌ Error in _getInitialRoute: $e');
      print('❌ Stack trace: $stackTrace');
      return _FirstLaunchWrapper(
        child: const SplashTransition(child: RoleSelectionScreen()),
      );
    }
  }
}

// Background message handler is defined in firebase_messaging_service.dart
// It's imported above and registered in main() function
