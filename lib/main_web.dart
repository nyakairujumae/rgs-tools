import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'no_backend_web.dart';
import 'screens/web/web_login_screen.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Web App starting...');

  // For web, use a completely simplified approach
  if (kIsWeb) {
    print('🌐 Web platform detected - using web-optimized initialization');
    runApp(const WebApp());
    return;
  }

  // This should never be reached on web
  runApp(const NoBackendWebApp());
}

class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'RGS Tools - Web',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const WebLoginScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}