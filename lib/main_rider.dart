import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/driver_login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/driver/screens/driver_dashboard_screen.dart';

void setupRiderErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[RiderFlutterError] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[RiderPlatformError] $error\n$stack');
    return true;
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupRiderErrorHandling();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('[RiderFirebaseInit] Failed to initialize Firebase: $e\n$stack');
  }

  if (!kIsWeb) {
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
    } catch (e, stack) {
      debugPrint('[RiderFirebaseDatabase] Persistence error: $e\n$stack');
    }
  }

  runApp(const CharCoalRiderApp());
}

class CharCoalRiderApp extends StatelessWidget {
  const CharCoalRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CharCoal Rider',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RiderAuthGate(),
    );
  }
}

class RiderAuthGate extends StatelessWidget {
  const RiderAuthGate({super.key});

  Future<ResolvedSession?> _resolveDriverSession(AuthService authService) async {
    final session = await authService.resolveCurrentSession();
    if (session != null && session.role != 'driver') {
      await authService.signOut();
      return null;
    }
    return session;
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return const DriverLoginScreen();
    }

    final authService = AuthService();
    return FutureBuilder<ResolvedSession?>(
      future: _resolveDriverSession(authService),
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
                    'Loading CharCoal Rider...',
                    style: TextStyle(color: AppTheme.mutedSlate, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final session = snapshot.data;
        if (session?.role == 'driver' && session?.driver != null) {
          return DriverDashboardScreen(driverProfile: session!.driver!);
        }
        return const DriverLoginScreen();
      },
    );
  }
}
