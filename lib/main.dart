import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/order/screens/customer_home_screen.dart';
import 'features/driver/screens/driver_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
    } catch (_) {
      // Safe fallback on unsupported desktop test targets
    }
  }

  runApp(const CharCoalApp());
}

class CharCoalApp extends StatelessWidget {
  const CharCoalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CharCoal Express',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return const RoleSelectScreen();
    }

    final authService = AuthService();
    return FutureBuilder<ResolvedSession?>(
      future: authService.resolveCurrentSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text(
                    'Loading CharCoal Express...',
                    style: TextStyle(color: AppTheme.mutedSlate, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final session = snapshot.data;
        if (session?.role == 'customer' && session?.customer != null) {
          return CustomerHomeScreen(currentUser: session!.customer!);
        }
        if (session?.role == 'driver' && session?.driver != null) {
          return DriverDashboardScreen(driverProfile: session!.driver!);
        }
        return const RoleSelectScreen();
      },
    );
  }
}
