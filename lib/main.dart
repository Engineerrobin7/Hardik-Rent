import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/owner/owner_dashboard.dart';
import 'ui/screens/tenant/tenant_dashboard.dart';
import 'ui/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const HardikRentApp(),
    ),
  );
}

class HardikRentApp extends StatelessWidget {
  const HardikRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HardikRent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/owner-dashboard': (context) => const OwnerDashboard(),
        '/tenant-dashboard': (context) => const TenantDashboard(),
      },
    );
  }
}
