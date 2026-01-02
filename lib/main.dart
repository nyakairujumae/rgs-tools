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
import 'providers/technician_notification_provider.dart';
import 'providers/approval_workflows_provider.dart';
import 'providers/connectivity_provider.dart';
import 'database/database_helper.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';
import 'services/supabase_auth_storage.dart';
import 'services/image_upload_service.dart';
import 'services/last_route_service.dart';
import 'services/firebase_messaging_service.dart' as fcm_service
    if (dart.library.html) 'services/firebase_messaging_service_stub.dart';
// Import background handler (top-level function)
import 'services/firebase_messaging_service.dart' show firebaseMessagingBackgroundHandler
    if (dart.library.html) 'services/firebase_messaging_service_stub.dart' show firebaseMessagingBackgroundHandler;
import 'services/push_notification_service.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) 'services/firebase_messaging_stub.dart';

// Note: Firebase Messaging is handled through FirebaseMessagingService which is stubbed on web
bool _splashRemoved = false;
String? _cachedLastRoute;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL: Splash screen ONLY on fresh install (first launch)
  // After first launch, NEVER show splash again, even if user is not logged in
  // Use single persistent boolean flag - save immediately when splash is shown
  bool shouldShowSplash = false;
  
  try {
    final isFirstLaunch = await FirstLaunchService.isFirstLaunch();
    shouldShowSplash = isFirstLaunch;
    _cachedLastRoute = await LastRouteService.getLastRoute();
    
    if (isFirstLaunch) {
      print('🚀 App starting (FIRST INSTALL) - will show splash screen');
      // CRITICAL: Save flag IMMEDIATELY before preserving splash
      // This ensures splash will never show again, even if app crashes
      await FirstLaunchService.markSplashShown();
      print('✅ Splash flag saved - will never show again');
      
      // Only preserve native splash screen on first install
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());
      print('🚀 Native splash preserved (first install only)');
    } else {
      // Not first install - remove splash immediately
      FlutterNativeSplash.remove();
      print('🚀 Skipping splash screen (already shown before)');
    }
  } catch (e) {
    // If check fails, assume splash was shown (don't show again)
    print('⚠️ Error checking splash status: $e - assuming splash was shown');
    shouldShowSplash = false;
    FlutterNativeSplash.remove();
  }

  print('🚀 App starting...');

  // Add global error handling for mobile
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // CRITICAL: Register background message handler BEFORE runApp()
  // Must be top-level function with @pragma('vm:entry-point')
  // Note: This can only be called once, subsequent calls are ignored
  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      print('✅ Background message handler registered');
    } catch (e) {
      print('⚠️ Could not register background handler: $e');
    }
  }

  print('🚀 Starting app immediately - initialization will happen in background...');
  
  // Run the app IMMEDIATELY - don't wait for initialization
  runApp(HvacToolsManagerApp(
    initialFirstLaunch: shouldShowSplash,
    cachedLastRoute: _cachedLastRoute,
  ));
  
  // Initialize everything in background AFTER UI is shown
  // This allows the app to open quickly while services load
  _initializeServicesInBackground();
}

/// Initialize all services in background after UI is shown
/// This prevents blocking the splash screen and allows app to open quickly
Future<void> _initializeServicesInBackground() async {
  print('🔄 Starting background initialization...');

  // Initialize Firebase (required before using any Firebase services)
  if (!kIsWeb) {
    try {
      // CRITICAL: Check if Firebase is already initialized (prevents duplicate initialization)
      if (Firebase.apps.isNotEmpty) {
        print('⚠️ Firebase already initialized (${Firebase.apps.length} app(s))');
        for (final app in Firebase.apps) {
          print('⚠️ Existing app: ${app.name}, Project: ${app.options.projectId}');
        }
        print('⚠️ Skipping duplicate initialization to prevent duplicate notifications');
      } else {
        // Initialize Firebase in background
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
        print('✅ Firebase initialized successfully (background)');
        print('✅ Firebase project: ${Firebase.app().options.projectId}');
      }
    } catch (e, stackTrace) {
      print('❌ Firebase initialization failed: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  // Initialize Supabase (works on web too)
  // CRITICAL: Initialize Supabase FIRST before other services
  // This ensures session persistence works correctly
  print('🔄 Initializing Supabase in background (priority)...');
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
          print('✅ Supabase initialized successfully (background)');
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

      if (supabaseInitialized && !kIsWeb) {
        try {
          print('🔥 Starting Firebase Messaging initialization (background)...');
          // Initialize Firebase Messaging Service after Supabase init to avoid fallback auth client usage
          await fcm_service.FirebaseMessagingService.initialize();
          print('✅ Firebase Messaging initialized (background)');
          
          // Verify token was obtained
          final token = fcm_service.FirebaseMessagingService.fcmToken;
          if (token != null && token.isNotEmpty) {
            print('✅ FCM token obtained: ${token.substring(0, 20)}...');
          } else {
            print('⚠️ WARNING: FCM token is null after initialization');
            print('⚠️ This may prevent push notifications from working');
            print('⚠️ Check notification permissions and Firebase configuration');
          }
        } catch (e, stackTrace) {
          print('❌ Firebase Messaging initialization failed: $e');
          print('❌ Error type: ${e.runtimeType}');
          print('❌ Stack trace: $stackTrace');
        }
      } else {
        if (kIsWeb) {
          print('⚠️ Skipping Firebase Messaging initialization (web platform)');
        } else if (!supabaseInitialized) {
          print('⚠️ Skipping Firebase Messaging initialization (Supabase not initialized)');
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
        print('🔄 Initializing local database (background)...');
        await DatabaseHelper.instance.database;
        print('✅ Local database initialized successfully (background)');
      } catch (e) {
        print('⚠️ Database initialization failed: $e');
        // Continue without local database
      }

      // Ensure image storage bucket exists (non-blocking)
      print('🔄 Checking image storage bucket (background)...');
      try {
        await ImageUploadService.ensureBucketExists();
        print('✅ Image storage bucket ready (background)');
      } catch (e) {
        print('⚠️ Image storage bucket check failed (non-critical): $e');
        // Continue without failing - this is not critical for app startup
      }

      // Initialize session management for extended timeouts
      print('🔄 Initializing session management (background)...');
      try {
        // This will be handled by AuthProvider
        print('✅ Session management ready for 30-day timeouts (background)');
      } catch (e) {
        print('⚠️ Session management initialization failed (non-critical): $e');
      }
    }

  print('✅ Background initialization complete');
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

/// Simplified wrapper - just uses the initial state passed from main()
/// No re-checking, no async operations, no state changes
/// The flag is already saved in main() before this widget is created
class _FirstLaunchWrapper extends StatelessWidget {
  final Widget firstLaunchChild;
  final Widget defaultChild;
  final bool shouldShowSplash;
  
  const _FirstLaunchWrapper({
    required this.firstLaunchChild,
    required this.defaultChild,
    required this.shouldShowSplash,
  });
  
  @override
  Widget build(BuildContext context) {
    // Simple check: if shouldShowSplash is true, show splash child
    // Otherwise show default child (login/role selection)
    // No async, no state changes, no re-checking
    return shouldShowSplash ? firstLaunchChild : defaultChild;
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
  final bool initialFirstLaunch;
  final String? cachedLastRoute;

  const HvacToolsManagerApp({
    super.key,
    required this.initialFirstLaunch,
    required this.cachedLastRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final authProvider = AuthProvider();
            // Initialize in background - don't block UI
            authProvider.initialize().catchError((e) {
              print('⚠️ Auth initialization error (non-blocking): $e');
            });
            return authProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => SupabaseToolProvider()),
        ChangeNotifierProvider(create: (_) => SupabaseTechnicianProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ToolIssueProvider()),
        ChangeNotifierProvider(create: (_) => PendingApprovalsProvider()),
        ChangeNotifierProvider(create: (_) => RequestThreadProvider()),
        ChangeNotifierProvider(create: (_) => AdminNotificationProvider()),
        ChangeNotifierProvider(create: (_) => TechnicianNotificationProvider()),
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
          
          // Remove splash screen quickly - don't wait for initialization
          if (!_splashRemoved) {
            _splashRemoved = true;
            // Remove splash immediately - initialization happens in background
            WidgetsBinding.instance.addPostFrameCallback((_) {
            FlutterNativeSplash.remove();
              print('✅ Native splash removed immediately');
            });
          }
          
          // CRITICAL: Check session FIRST - if logged in, go directly to home screen
          // No intermediate screens, no waiting, no flashes
          final hasSession = SupabaseService.client.auth.currentSession != null;
          final currentUser = SupabaseService.client.auth.currentUser;
          
          Widget initialRoute;
          
          // If user is logged in, route directly to home screen based on role
          if (hasSession && currentUser != null && currentUser.emailConfirmedAt != null) {
            // Determine role from provider (if initialized) or metadata (if not)
            bool isAdmin = false;
            bool isPending = false;
            
            if (authProvider.isInitialized) {
              // Provider initialized - use its role (most reliable)
              isAdmin = authProvider.isAdmin;
              isPending = authProvider.isPendingApproval || authProvider.userRole == UserRole.pending;
            } else {
              // Provider not initialized - check metadata and pending approval table
              final roleFromMetadata = currentUser.userMetadata?['role'] as String?;
              final email = currentUser.email ?? '';
              isAdmin = roleFromMetadata == 'admin' || 
                  email.endsWith('@royalgulf.ae') || 
                  email.endsWith('@mekar.ae') || 
                  email.endsWith('@gmail.com');
              
              // Check pending approval synchronously if possible
              if (!isAdmin) {
                // Assume pending for technicians until provider confirms
                isPending = true;
              }
            }
            
            // Route directly to appropriate screen - NO intermediate screens
            if (isPending) {
              initialRoute = const PendingApprovalScreen();
            } else if (isAdmin) {
              initialRoute = AdminHomeScreenErrorBoundary(
                child: AdminHomeScreen(
                  key: ValueKey('admin_home'),
                ),
              );
            } else {
              initialRoute = const TechnicianHomeScreen();
            }
          } else if (!hasSession && cachedLastRoute != null && !authProvider.isLoggingOut) {
            // Session may still be restoring - reuse last known route to avoid flashes.
            if (cachedLastRoute == '/admin') {
              initialRoute = AdminHomeScreenErrorBoundary(
                child: AdminHomeScreen(
                  key: ValueKey('admin_home'),
                ),
              );
            } else if (cachedLastRoute == '/technician') {
              initialRoute = const TechnicianHomeScreen();
            } else if (cachedLastRoute == '/pending-approval') {
              initialRoute = const PendingApprovalScreen();
            } else {
              initialRoute = const RoleSelectionScreen();
            }
          } else {
            // No session - show role selection (only for logged out users)
            initialRoute = const RoleSelectionScreen();
          }
          
          // Always render MaterialApp immediately
          // Show UI right away - initialization happens in background
          // The Consumer will rebuild when auth state changes
          final defaultRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
          return MaterialApp(
            title: 'RGS HVAC Tools',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // Don't use home - let onGenerateRoute handle everything including deep links
            initialRoute: defaultRoute,
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
                final routeName = ModalRoute.of(context)?.settings.name;
                return ResetPasswordScreen(
                  accessToken: args?['access_token'] as String?,
                  refreshToken: args?['refresh_token'] as String?,
                  type: args?['type'] as String?,
                  deepLink: routeName,
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
              // Handle root route - use the initial route we determined
              if (settings.name == '/' || settings.name == null) {
                return MaterialPageRoute(
                  builder: (context) => initialRoute,
                  settings: settings,
                );
              }
              
              // Handle email confirmation deep links (auth/callback)
              // Check for various URL formats that Supabase might send
              if (settings.name != null) {
                final uriString = settings.name!;
                print('🔐 Checking deep link: $uriString');
                
                Map<String, String> extractParams(Uri uri) {
                  final params = <String, String>{};
                  params.addAll(uri.queryParameters);

                  if (uri.fragment.isNotEmpty) {
                    final fragment = uri.fragment.startsWith('?')
                        ? uri.fragment.substring(1)
                        : uri.fragment;
                    try {
                      params.addAll(Uri.splitQueryString(fragment));
                    } catch (e) {
                      print('⚠️ Could not parse fragment params: $e');
                    }
                  }

                  return params;
                }
                
                // Check if this is an auth callback URL (email confirmation, password reset, or OAuth)
                final isAuthCallback = uriString.contains('auth/callback') || 
                                      uriString.contains('access_token') ||
                                      uriString.contains('code=') ||
                                      uriString.contains('type=signup') ||
                                      uriString.contains('type=recovery') ||
                                      uriString.contains('type=invite') ||
                                      uriString.contains('type=oauth') ||
                                      uriString.contains('provider=') ||
                                      uriString.contains('email-confirmation');
                
                if (isAuthCallback) {
                  print('🔐 Auth deep link detected: $uriString');
                  final uri = Uri.parse(uriString);
                  final params = extractParams(uri);
                
                // Handle email confirmation callback
                  final type = params['type'];
                  final hasAccessToken = params.containsKey('access_token');
                  final code = params['code'];
                  
                  print('🔐 URL parameters - type: $type, hasAccessToken: $hasAccessToken');
                  
                  // CRITICAL: Handle signup email confirmation
                  // Technicians go to pending approval, Admins auto-login
                  if (type == 'signup') {
                    print('✅ Signup email confirmation detected');
                    
                    return MaterialPageRoute(
                      builder: (context) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          try {
                            print('🔐 Processing signup email confirmation...');
                            final sessionResponse = code != null && !hasAccessToken
                                ? await SupabaseService.client.auth.exchangeCodeForSession(code)
                                : await SupabaseService.client.auth.getSessionFromUrl(uri);
                            print('✅ Email confirmed - session created');
                            
                            if (sessionResponse.session != null && sessionResponse.session!.user != null) {
                              final user = sessionResponse.session!.user;
                              final email = user.email ?? '';
                              final fullName = user.userMetadata?['full_name'] as String? ?? 
                                              user.userMetadata?['name'] as String? ?? 
                                              email.split('@')[0];
                              final userId = user.id;
                              
                              print('✅ User details - Email: $email, Name: $fullName, ID: $userId');
                              
                              // CRITICAL: Check role from database, not just metadata
                              // Metadata might not be set for admin invites
                              String? role;
                              try {
                                final userRecord = await SupabaseService.client
                                    .from('users')
                                    .select('role')
                                    .eq('id', userId)
                                    .maybeSingle();
                                role = userRecord?['role'] as String?;
                                print('✅ Role from database: $role');
                              } catch (e) {
                                print('⚠️ Could not fetch role from database: $e');
                                // Fallback to metadata
                                role = user.userMetadata?['role'] as String?;
                                print('✅ Using role from metadata: $role');
                              }
                              
                              // Check if user is admin - admins should auto-login
                              final isAdmin = role == 'admin';
                              
                              if (isAdmin) {
                                print('✅ Admin email confirmation - auto-logging in...');
                                
                                // Initialize auth provider with the session
                                // The session is already set by exchangeCodeForSession/getSessionFromUrl
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                await authProvider.initialize();
                                
                                // Wait a bit for role to be loaded from database
                                await Future.delayed(const Duration(milliseconds: 1500));
                                
                                // Re-initialize to ensure role is loaded
                                await authProvider.initialize();
                                
                                if (authProvider.isAuthenticated && authProvider.isAdmin) {
                                  print('✅ Admin authenticated - routing to admin home');
                                  if (context.mounted) {
                                    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/admin', (route) => false);
                                  }
                                  return;
                                } else {
                                  print('⚠️ Admin not authenticated after initialization. isAuthenticated: ${authProvider.isAuthenticated}, isAdmin: ${authProvider.isAdmin}, userRole: ${authProvider.userRole}');
                                  // Fallback: try routing anyway if we have a session and confirmed role
                                  if (isAdmin && sessionResponse.session != null && context.mounted) {
                                    print('⚠️ Attempting fallback routing to admin home');
                                    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/admin', (route) => false);
                                  }
                                }
                              } else {
                                // Technician - route to pending approval
                                print('✅ Technician email confirmation - routing to pending approval screen');
                                
                                // Wait for database trigger to create pending approval record
                                print('⏳ Waiting for database trigger to create pending approval record...');
                                await Future.delayed(const Duration(milliseconds: 1500));
                                
                                // Create admin notification and send push notification after email confirmation
                                try {
                                  print('📧 Creating admin notification for new registration...');
                                  await SupabaseService.client.rpc(
                                    'create_admin_notification',
                                    params: {
                                      'p_title': 'New User Registration',
                                      'p_message': '$fullName has registered and is waiting for approval',
                                      'p_technician_name': fullName.toUpperCase(),
                                      'p_technician_email': email,
                                      'p_type': 'new_registration',
                                      'p_data': {
                                        'user_id': userId,
                                        'email': email,
                                      },
                                    },
                                  );
                                  print('✅ Admin notification created in notification center');
                                } catch (notifError) {
                                  print('⚠️ Could not create admin notification: $notifError');
                                  // Fallback: Try direct push notification
                                  try {
                                    await SupabaseService.client
                                        .from('admin_notifications')
                                        .insert({
                                          'title': 'New User Registration',
                                          'message': '$fullName has registered and is waiting for approval',
                                          'technician_name': fullName.toUpperCase(),
                                          'technician_email': email,
                                          'type': 'new_registration',
                                          'is_read': false,
                                          'timestamp': DateTime.now().toIso8601String(),
                                          'data': {
                                            'user_id': userId,
                                            'email': email,
                                          },
                                        });
                                    print('✅ Admin notification created via direct insert');
                                  } catch (insertError) {
                                    print('⚠️ Could not create admin notification via direct insert: $insertError');
                                  }
                                }
                                
                                // Send push notification to admins
                                try {
                                  await PushNotificationService.sendToAdmins(
                                    title: 'New User Registration',
                                    body: '$fullName has registered and is waiting for approval',
                                    data: {
                                      'type': 'new_registration',
                                      'user_id': userId,
                                      'email': email,
                                    },
                                  );
                                  print('✅ Push notification sent to admins for new registration');
                                } catch (pushError) {
                                  print('⚠️ Could not send push notification: $pushError');
                                }
                                
                                // Route to pending approval for technicians
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/pending-approval', (route) => false);
                                }
                              }
                            }
                          } catch (e) {
                            print('⚠️ Email confirmation error: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Email confirmation failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/role-selection', (route) => false);
                            }
                          }
                        });
                        // Show loading screen while processing
                        return Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      settings: RouteSettings(name: '/email-confirmation'),
                    );
                  } else if (type == 'recovery' || type == 'invite' || uriString.contains('reset-password')) {
                    // Password reset
                    print('🔐 Password reset route detected');
                    final accessToken = params['access_token'];
                    final refreshToken = params['refresh_token'];
                    
                    return MaterialPageRoute(
                      builder: (context) => ResetPasswordScreen(
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        type: type ?? 'recovery',
                        deepLink: uriString,
                      ),
                      settings: RouteSettings(name: '/reset-password'),
                    );
                  } else if (type == 'oauth' || hasAccessToken || uriString.contains('email-confirmation') || uri.queryParameters.containsKey('provider')) {
                    // Email confirmation or OAuth callback - get session from URL and auto-login
                    final isOAuth = type == 'oauth' || uri.queryParameters.containsKey('provider');
                    print('✅ ${isOAuth ? "OAuth" : "Email confirmation"} detected, getting session from URL...');
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
                            
                            // Get session from URL (this confirms the email/OAuth and creates the session)
                            final sessionResponse = code != null && !hasAccessToken
                                ? await SupabaseService.client.auth.exchangeCodeForSession(code)
                                : await SupabaseService.client.auth.getSessionFromUrl(uri);
                            
                            if (sessionResponse.session != null) {
                              print('✅ Session created from email confirmation');
                              print('✅ User: ${sessionResponse.session!.user.email}');
                              print('✅ Email confirmed: ${sessionResponse.session!.user.emailConfirmedAt != null}');
                              print('✅ User metadata: ${sessionResponse.session!.user.userMetadata}');
                              print('✅ Role in metadata: ${sessionResponse.session!.user.userMetadata?['role']}');
                              
                              // Get auth provider and initialize with the new session
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              await authProvider.initialize();
                              
                              // Wait for database trigger to create pending approval record (for technicians)
                              // The trigger fires when email_confirmed_at is set
                              print('⏳ Waiting for database trigger to create pending approval record...');
                              await Future.delayed(const Duration(milliseconds: 2000));
                              
                              // Re-initialize to pick up role and approval status from database
                              await authProvider.initialize();
                              
                              // Check authentication status after initialization
                              if (authProvider.isAuthenticated && authProvider.user != null) {
                                print('✅ User authenticated after email confirmation');
                                print('✅ User role from AuthProvider: ${authProvider.userRole}');
                                print('✅ Is admin from AuthProvider: ${authProvider.isAdmin}');
                                
                                // CRITICAL: Use checkApprovalStatus() as the source of truth
                                // This is the simplest and most reliable way to determine routing
                                final isApproved = await authProvider.checkApprovalStatus();
                                print('✅ Approval status: $isApproved');
                                
                              final navigator = Navigator.of(context, rootNavigator: true);
                                final isOAuthUser = authProvider.user?.appMetadata?['provider'] != null &&
                                    authProvider.user?.appMetadata?['provider'] != 'email';
                                
                                // If not approved (pending/rejected), route to pending approval screen
                                // This "traps" the user at pending approval until admin approves
                                if (isApproved == false) {
                                  print('✅ User is NOT approved - routing to pending approval screen');
                                  navigator.pushNamedAndRemoveUntil(
                                    '/pending-approval',
                                    (route) => false,
                                  );
                                  return;
                                }
                                
                                // If approved, route based on role
                                if (authProvider.isAdmin) {
                                  print('✅ Admin user - routing to admin home');
                                  navigator.pushNamedAndRemoveUntil(
                                    '/admin',
                                    (route) => false,
                                  );
                                } else if (authProvider.isTechnician) {
                                  print('✅ Approved technician - routing to technician home');
                                  navigator.pushNamedAndRemoveUntil(
                                    '/technician',
                                    (route) => false,
                                  );
                                } else if (authProvider.userRole == UserRole.pending && isOAuthUser) {
                                  // OAuth sign-in without an existing account
                                  print('🔐 OAuth user without account - signing out');
                                  await authProvider.signOut();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No account found for this email. Please register or request an invite.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  navigator.pushNamedAndRemoveUntil(
                                    '/role-selection',
                                    (route) => false,
                                  );
                                } else {
                                  // Fallback: Check metadata for role
                                  final roleFromMetadata = sessionResponse.session!.user.userMetadata?['role'] as String?;
                                  print('⚠️ Role not loaded - checking metadata: $roleFromMetadata');
                                  
                                  if (roleFromMetadata == 'admin') {
                                    navigator.pushNamedAndRemoveUntil(
                                      '/admin',
                                      (route) => false,
                                    );
                                  } else if (roleFromMetadata == 'technician') {
                                    // If metadata says technician but no approval status, assume pending
                                  navigator.pushNamedAndRemoveUntil(
                                    '/pending-approval',
                                    (route) => false,
                                  );
                                } else {
                                    // Unknown role - redirect to role selection
                                    print('⚠️ Unknown role - redirecting to role selection');
                                  navigator.pushNamedAndRemoveUntil(
                                      '/role-selection',
                                    (route) => false,
                                  );
                                  }
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
              
              if (settings.name != null && settings.name!.contains('reset-password')) {
                final uri = Uri.parse(settings.name!);
                final params = <String, String>{}
                  ..addAll(uri.queryParameters)
                  ..addAll(
                    uri.fragment.isNotEmpty
                        ? Uri.splitQueryString(
                            uri.fragment.startsWith('?')
                                ? uri.fragment.substring(1)
                                : uri.fragment,
                          )
                        : <String, String>{},
                  );
                return MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(
                    accessToken: params['access_token'],
                    refreshToken: params['refresh_token'],
                    type: params['type'],
                    deepLink: settings.name,
                  ),
                  settings: const RouteSettings(name: '/reset-password'),
                );
              }

              return MaterialPageRoute(
                builder: (context) => const RoleSelectionScreen(),
                settings: const RouteSettings(name: '/role-selection'),
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

}

// Background message handler is defined in firebase_messaging_service.dart
// It's imported above and registered in main() function
