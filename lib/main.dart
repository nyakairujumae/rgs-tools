import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/technician_home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/tool_detail_screen.dart';
import 'models/tool.dart';
import 'providers/auth_provider.dart';
import 'providers/supabase_tool_provider.dart';
import 'providers/supabase_technician_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tool_issue_provider.dart';
import 'database/database_helper.dart';
import 'theme/app_theme.dart';
import 'config/supabase_config.dart';
import 'services/image_upload_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize local database (for offline support)
  await DatabaseHelper.instance.database;

  // Ensure image storage bucket exists
  await ImageUploadService.ensureBucketExists();

  runApp(const HvacToolsManagerApp());
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
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          return MaterialApp(
            title: 'RGS HVAC Tools',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: _getInitialRoute(authProvider),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/admin': (context) => const AdminHomeScreen(),
              '/technician': (context) => const TechnicianHomeScreen(),
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
    if (!authProvider.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      // Route based on user role
      if (authProvider.isAdmin) {
        return const AdminHomeScreen();
      } else {
        return const TechnicianHomeScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}