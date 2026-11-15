import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'core/services/local_prefs_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/customer_login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/order/screens/customer_shell_screen.dart';

void setupAppErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] Caught framework error: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint('[FlutterError] Stack: ${details.stack}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformDispatcher] Caught unhandled startup/runtime error: $error');
    debugPrint('[PlatformDispatcher] Stack: $stack');
    return true;
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupAppErrorHandling();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('[FirebaseInit] Failed to initialize Firebase: $e\n$stack');
    // Prevent silent native crash if Firebase init fails on startup
  }

  if (!kIsWeb) {
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
    } catch (e, stack) {
      debugPrint('[FirebaseDatabase] Failed to enable persistence: $e\n$stack');
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

  Future<ResolvedSession?> _resolveCustomerSession(AuthService authService) async {
    final remember = await LocalPrefsService.getRememberMe();
    if (!remember) {
      await authService.signOut();
      return null;
    }
    final session = await authService.resolveCurrentSession();
    if (session != null && session.role != 'customer') {
      await authService.signOut();
      return null;
    }
    return session;
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return const CustomerLoginScreen();
    }

    final authService = AuthService();
    return FutureBuilder<ResolvedSession?>(
      future: _resolveCustomerSession(authService),
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
          return CustomerShellScreen(currentUser: session!.customer!);
        }
        return const CustomerLoginScreen();
      },
    );
  }
}
