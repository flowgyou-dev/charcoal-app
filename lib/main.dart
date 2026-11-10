import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'firebase_options.dart';
import 'admin_orders_screen.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GoogleSignIn.instance.initialize();

  runApp(const CharCoalApp());
}

// ============================================================
// APP LOCALIZATION / LANGUAGE SYSTEM
// ============================================================

class AppLanguage {
  static final ValueNotifier<String> currentLanguage = ValueNotifier<String>('en');

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'CharCoal',
      'tagline': 'An Integrated Pick-Up Scheduling, Delivery Scheduling and ESP32-Based Delivery Tracking System',
      'language': 'Language / Wika',
      'english': 'English 🇺🇸',
      'tagalog': 'Tagalog 🇵🇭',
      'select_language': 'Select Language',
      'save': 'SAVE',
      'cancel': 'CANCEL',
      'confirm': 'CONFIRM',
      'close': 'CLOSE',
      'back': 'BACK',
      'login': 'SIGN IN',
      'google_login': 'SIGN IN WITH GOOGLE',
      'email_hint': 'Email Address',
      'password_hint': 'Password',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account? ",
      'sign_up': 'Sign Up',
      'logout': 'LOGOUT',
      'confirm_logout': 'Confirm Logout',
      'confirm_logout_msg': 'Are you sure you want to exit the application?',
      'home': 'Home',
      'profile': 'Profile',
      'my_profile': 'MY PROFILE',
      'edit_profile': 'EDIT PROFILE',
      'orders': 'Orders',
      'pickup_scheduling': 'Pick-Up Scheduling',
      'delivery_scheduling': 'Delivery Scheduling',
      'track_delivery': 'Track Delivery',
    },
    'tl': {
      'app_name': 'CharCoal',
      'tagline': 'Pinag-isang Pick-Up Scheduling, Delivery Scheduling at ESP32-Based Delivery Tracking System',
      'language': 'Wika / Language',
      'english': 'Ingles 🇺🇸',
      'tagalog': 'Tagalog 🇵🇭',
      'select_language': 'Pumili ng Wika',
      'save': 'I-SAVE',
      'cancel': 'IKANSEL',
      'confirm': 'KUMPIRMAHIN',
      'close': 'ISARA',
      'back': 'BUMALIK',
      'login': 'MAG-LOG IN',
      'google_login': 'MAG-LOG IN GAMIT ANG GOOGLE',
      'email_hint': 'Email Address',
      'password_hint': 'Password',
      'forgot_password': 'Nakalimutan ang Password?',
      'dont_have_account': 'Wala pang account? ',
      'sign_up': 'Mag-rehistro',
      'logout': 'MAG-LOGOUT',
      'confirm_logout': 'Kumpirmahin ang Pag-logout',
      'confirm_logout_msg': 'Sigurado ka bang gusto mong lumabas sa application?',
      'home': 'Tahanan',
      'profile': 'Profil',
      'my_profile': 'AKING PROFIL',
      'edit_profile': 'I-EDIT ANG PROFIL',
      'orders': 'Mga Order',
      'pickup_scheduling': 'Pick-Up Scheduling',
      'delivery_scheduling': 'Delivery Scheduling',
      'track_delivery': 'I-track ang Delivery',
    },
  };

  static String tr(String key) {
    final lang = currentLanguage.value;
    return _translations[lang]?[key] ?? _translations['en']?[key] ?? key;
  }

  static void setLanguage(String lang) {
    if (lang == 'en' || lang == 'tl') {
      currentLanguage.value = lang;
    }
  }
}

class LanguageSelectorWidget extends StatelessWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.currentLanguage,
      builder: (context, currentLang, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD7CCC8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 18, color: Color(0xFF3E2723)),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentLang,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3E2723)),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E2723),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('English 🇺🇸'),
                    ),
                    DropdownMenuItem(
                      value: 'tl',
                      child: Text('Tagalog 🇵🇭'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      AppLanguage.setLanguage(val);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CharCoalApp extends StatelessWidget {
  const CharCoalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.currentLanguage,
      builder: (context, currentLang, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppLanguage.tr('app_name'),
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3E2723),
              primary: const Color(0xFF3E2723),
              secondary: const Color(0xFF5D4037),
              tertiary: const Color(0xFF795548),
              surface: Colors.white,
              onSurface: const Color(0xFF3E2723),
            ),
            scaffoldBackgroundColor: const Color(0xFFF8F3EE),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF3E2723),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E2723),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF5D4037), width: 1.5),
              ),
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
              prefixIconColor: const Color(0xFF795548),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EE),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2723),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFF8F3EE),
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'CharCoal',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3E2723),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'An Integrated Pick-Up Scheduling, Delivery Scheduling and ESP32-Based Delivery Tracking System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF795548),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3E2723)),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROTOTYPE DATA
// ============================================================

class UserData {
  static String fullName = 'Juan Dela Cruz';
  static String email = 'juan.delacruz@email.com';
  static String phone = '09XX XXX XXXX';
  static String address = 'Enter your address';
}

class AppState {
  static int availableStocks = 110;
  static List<Map<String, dynamic>> orderHistory = [
    {
      'id': 'CC-2026-001',
      'product': 'Wood Charcoal',
      'quantity': 10,
      'method': 'Delivery',
      'date': 'September 24, 2026',
      'time': '10:00 AM',
      'total': 3500.0,
      'status': 'OUT FOR DELIVERY',
      'location': '123 Prototype Street, Manila',
    },
    {
      'id': 'ORD-000',
      'product': 'Wood Charcoal',
      'quantity': 5,
      'method': 'Pick-Up',
      'date': 'September 18, 2026',
      'time': '10:00 AM',
      'total': 1750.0,
      'status': 'SUCCESSFUL',
      'location': 'CharCoal Collection Point',
    }
  ];

  static Map<String, dynamic>? get activeOrder {
    if (orderHistory.isEmpty) return null;
    for (var order in orderHistory.reversed) {
      if (order['status'] != 'SUCCESSFUL' && order['status'] != 'CANCELLED') {
        return order;
      }
    }
    return null;
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'Customer';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password.'),
        ),
      );
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
        ),
      );
      return;
    }

    try {
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('User account could not be found.');
      }

      final DocumentSnapshot<Map<String, dynamic>> userDocument =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (!userDocument.exists) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your account information was not found. Please contact support.',
            ),
          ),
        );
        return;
      }

      final data = userDocument.data();

      if (data == null) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User information is incomplete.'),
          ),
        );
        return;
      }

      final String status =
      (data['status'] ?? '').toString().toLowerCase();

      if (status != 'active') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your account is not active. Please contact the administrator.',
            ),
          ),
        );
        return;
      }

      final String role =
      (data['role'] ?? '').toString().toLowerCase();

      if (!mounted) return;

      if (role != 'customer') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Only customer accounts can log in through the mobile app. '
                  'Please use the website for Admin or Driver access.',
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerHomeContent(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Login failed.';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many login attempts. Please try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser =
      await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google ID token is missing.');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      if (selectedRole == 'Customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerHomeContent(),
          ),
        );
      } else if (selectedRole == 'Driver') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DriverDashboardScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google login failed: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In was cancelled or failed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F3EE), Color(0xFFEFEBE9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.topRight,
                  child: LanguageSelectorWidget(),
                ),
                const SizedBox(height: 10),
                // LOGO AREA
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E2723),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFF8F3EE),
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CharCoal',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3E2723),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(height: 30),
                // EMAIL
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: AppLanguage.tr('email_hint'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                // PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: AppLanguage.tr('password_hint'),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                    child: Text(
                      AppLanguage.tr('forgot_password'),
                      style: const TextStyle(
                        color: Color(0xFF3E2723),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // LOGIN BUTTON
                ElevatedButton(
                  onPressed: login,
                  child: Text(
                    AppLanguage.tr('login'),
                    style: const TextStyle(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // GOOGLE SIGN IN
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: signInWithGoogle,
                    icon: const Icon(
                      Icons.account_circle_outlined,
                      color: Color(0xFF3E2723),
                    ),
                    label: Text(
                      AppLanguage.tr('google_login'),
                      style: const TextStyle(
                        color: Color(0xFF3E2723),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFFD7CCC8),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: AppLanguage.tr('dont_have_account'),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      children: [
                        TextSpan(
                          text: AppLanguage.tr('sign_up'),
                          style: const TextStyle(
                            color: Color(0xFF3E2723),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget roleButton(String role, IconData icon) {
    final bool selected = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 100,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3E2723) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: const Color(0xFF3E2723).withAlpha(76),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            else
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFF795548),
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              role,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF3E2723),
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// REGISTER SCREEN
// ============================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController firstNameController =
  TextEditingController();
  final TextEditingController middleNameController =
  TextEditingController();
  final TextEditingController lastNameController =
  TextEditingController();
  final TextEditingController emailController =
  TextEditingController();
  final TextEditingController phoneController =
  TextEditingController();
  final TextEditingController birthdayController =
  TextEditingController();
  final TextEditingController addressController =
  TextEditingController();
  final TextEditingController passwordController =
  TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  DateTime? selectedBirthday;

  Future<void> selectBirthday() async {
    final now = DateTime.now();

    final latestBirthday = DateTime(
      now.year - 18,
      now.month,
      now.day,
    );

    final earliestBirthday = DateTime(
      now.year - 70,
      now.month,
      now.day,
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(
        latestBirthday.year,
        latestBirthday.month,
        1,
      ),
      firstDate: earliestBirthday,
      lastDate: latestBirthday,
      helpText: 'Select your birthday',
    );

    if (picked != null) {
      setState(() {
        selectedBirthday = picked;
        birthdayController.text =
        '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> register() async {
    final firstName = firstNameController.text.trim();
    final middleName = middleNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        selectedBirthday == null ||
        address.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showError('Please fill in all required fields.');
      return;
    }

    final namePattern = RegExp(r"^[a-zA-Z .'-]+$");

    if (!namePattern.hasMatch(firstName)) {
      showError('Please enter a valid first name.');
      return;
    }

    if (middleName.isNotEmpty &&
        !namePattern.hasMatch(middleName)) {
      showError('Please enter a valid middle name.');
      return;
    }

    if (!namePattern.hasMatch(lastName)) {
      showError('Please enter a valid last name.');
      return;
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.com$',
      caseSensitive: false,
    ).hasMatch(email)) {
      showError('Please enter a valid email address.');
      return;
    }

    if (!RegExp(r'^[0-9]{11}$').hasMatch(phone)) {
      showError('Phone number must contain exactly 11 digits.');
      return;
    }

    final now = DateTime.now();
    final birthday = selectedBirthday!;

    var age = now.year - birthday.year;

    if (now.month < birthday.month ||
        (now.month == birthday.month &&
            now.day < birthday.day)) {
      age--;
    }

    if (age < 18 || age > 70) {
      showError('You must be between 18 and 70 years old.');
      return;
    }

    if (password != confirmPassword) {
      showError('Passwords do not match.');
      return;
    }

    if (password.length < 6 || password.length > 12) {
      showError('Password must be at least 6-12 characters.');
      return;
    }

    try {
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'birthday': Timestamp.fromDate(birthday),
        'address': address,
        'role': 'customer',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await userCredential.user?.updateDisplayName(
        middleName.isEmpty
            ? '$firstName $lastName'
            : '$firstName $middleName $lastName',
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Registration Successful'),
          content: const Text(
            'Your CharCoal account has been created.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Registration failed.';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password must be at least 6-12 characters.';
      }

      showError(message);
    } catch (e) {
      if (!mounted) return;
      showError('Something went wrong. Please try again.');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CREATE ACCOUNT',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3E2723),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 20,
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),

            TextField(
              controller: firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'First Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: middleNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Middle Name (Optional)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Last Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                hintText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                counterText: '',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: birthdayController,
              readOnly: true,
              onTap: selectBirthday,
              decoration: const InputDecoration(
                hintText: 'Birthday',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: addressController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password (at least 6-12 characters)',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: register,
                child: const Text(
                  'REGISTER',
                  style: TextStyle(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthdayController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}


// ============================================================
// FORGOT PASSWORD SCREEN
// ============================================================

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Reset Link Sent'),
          content: const Text(
            'Password reset instructions have been sent to your email.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Unable to send reset link.';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FORGOT PASSWORD'),
        backgroundColor: const Color(0xFF3E2723),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Column(
          children: [
            const Icon(
              Icons.lock_reset_rounded,
              size: 80,
              color: Color(0xFF3E2723),
            ),
            const SizedBox(height: 24),
            const Text(
              'Forgot Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter your email address to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: sendResetLink,
              child: const Text(
                'SEND RESET LINK',
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'BACK TO LOGIN',
                style: TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// ============================================================
// CUSTOMER HOME CONTENT
// ============================================================

class CustomerHomeContent extends StatefulWidget {
  const CustomerHomeContent({super.key});

  @override
  State<CustomerHomeContent> createState() =>
      _CustomerHomeContentState();
}

class _CustomerHomeContentState extends State<CustomerHomeContent> {
  String customerName = 'Customer';
  Stream<int> getAvailableStock() {
    return FirebaseFirestore.instance
        .collection('stocks')
        .doc('charcoal')
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (data == null) {
        return 0;
      }

      return (data['availableStocks'] ?? 0).toInt();
    });
  }

  @override
  void initState() {
    super.initState();
    loadCustomerName();
  }

  Future<void> loadCustomerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snapshot.data();
      if (!mounted || data == null) return;

      final firstName = (data['firstName'] ?? '').toString().trim();

      setState(() {
        customerName = firstName.isNotEmpty ? firstName : 'Customer';
      });
    } catch (e) {
      debugPrint('Failed to load customer name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String stockStatus = 'OUT OF STOCK';

    if (AppState.availableStocks > 20) {
      stockStatus = 'IN STOCK';
    } else if (AppState.availableStocks > 0) {
      stockStatus = 'LOW STOCK';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CHARCOAL'),
        actions: [
          IconButton(
            onPressed: () => showNotifications(context),
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
          IconButton(
            onPressed: () => logoutAction(context),
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // GREETING
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $customerName!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Ready to manage your charcoal today?',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFFEFEBE9),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ==================================================
            // STOCK CARD
            // ==================================================

            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StockScreen(),
                  ),
                );

                if (!mounted) return;

                setState(() {});
              },

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3E2723),
                      Color(0xFF5D4037),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.circular(24),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3E2723)
                          .withAlpha(76),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                      children: [
                        const Text(
                          'AVAILABLE STOCKS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),

                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius:
                            BorderRadius.circular(20),
                          ),

                          child: Text(
                            stockStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Charcoal – Sack',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${AppState.availableStocks} sacks available',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final orders = snapshot.data!.docs.toList();

                orders.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aDate = aData['createdAt'];
                  final bDate = bData['createdAt'];

                  if (aDate is Timestamp && bDate is Timestamp) {
                    return bDate.compareTo(aDate);
                  }

                  return 0;
                });

                Map<String, dynamic>? activeOrder;

                for (final doc in orders) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toUpperCase();

                  if (status != 'SUCCESSFUL' &&
                      status != 'CANCELLED' &&
                      status != 'COMPLETED') {
                    activeOrder = data;
                    activeOrder['documentId'] = doc.id;
                    break;
                  }
                }

                if (activeOrder == null) {
                  return const SizedBox.shrink();
                }

                final status = (activeOrder['status'] ?? 'PENDING')
                    .toString()
                    .toUpperCase();

                final quantity = activeOrder['quantity'] ?? 0;
                final method = activeOrder['method'] ?? 'Delivery';
                final total = activeOrder['total'] ?? 0;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEBE9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Active Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E2723),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEBE9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 20,
                            color: Color(0xFF795548),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$quantity sacks • $method',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            size: 20,
                            color: Color(0xFF795548),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Total: ₱${(total as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OrderHistoryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('VIEW ORDER'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E2723),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            const SectionTitle(
              title: 'Our Services',
            ),

            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),

              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,

              children: [
                serviceCard(
                  context,
                  Icons.shopping_bag_rounded,
                  'Order Charcoal',
                  'Place a charcoal order',
                  const OrderScreen(),
                ),

                serviceCard(
                  context,
                  Icons.location_on_rounded,
                  'Track Order',
                  'Live monitoring',
                  const TrackingScreen(),
                ),

                serviceCard(
                  context,
                  Icons.inventory_2_rounded,
                  'Available Stocks',
                  'Check stock level',
                  const StockScreen(),
                ),

                serviceCard(
                  context,
                  Icons.history_rounded,
                  'Order History',
                  'View previous orders',
                  const OrderHistoryScreen(),
                ),
              ],
            ),

            const SizedBox(height: 32),

            const SectionTitle(
              title: 'Quick Information',
            ),

            const SizedBox(height: 16),

            infoCard(
              Icons.info_outline_rounded,
              'How it works',
              'Learn about our scheduling process.',
              onTap: () => showQuickInfo(
                context,
                'How it works',
                '1. Order charcoal through the app.\n'
                    '2. Choose between Pick-Up or Delivery.\n'
                    '3. Provide your location and schedule.\n'
                    '4. Track your order status in real-time.',
              ),
            ),

            infoCard(
              Icons.help_outline_rounded,
              'Support Center',
              'Get help with your charcoal delivery.',
              onTap: () => showQuickInfo(
                context,
                'Support Center',
                'If you have any issues with your order, '
                    'please contact our support team.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// NOTIFICATIONS
// ============================================================

void showNotifications(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        title: const Row(
          children: [
            Icon(
              Icons.notifications_rounded,
              color: Color(0xFF3E2723),
            ),
            SizedBox(width: 10),
            Text('Notifications'),
          ],
        ),

        content: const Text(
          'No new notifications at the moment.',
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}


// ============================================================
// QUICK INFORMATION
// ============================================================

void showQuickInfo(
    BuildContext context,
    String title,
    String message,
    ) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        title: Text(title),

        content: Text(message),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}


// ============================================================
// PROFILE SCREEN
// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          userData = {
            'firstName': '',
            'lastName': '',
            'email': user.email ?? '',
            'phone': '',
            'address': '',
            'role': 'customer',
          };

          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to load profile information.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final firstName =
        userData?['firstName']?.toString() ?? '';

    final lastName =
        userData?['lastName']?.toString() ?? '';

    final email =
        userData?['email']?.toString() ?? '';

    final phone =
        userData?['phone']?.toString() ?? '';

    final address =
        userData?['address']?.toString() ?? '';

    final role =
        userData?['role']?.toString() ?? 'customer';

    final fullName =
    '$firstName $lastName'.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLanguage.tr('my_profile')),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 40,
        ),

        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFFEFEBE9),

              child: Icon(
                Icons.person,
                size: 70,
                color: Color(0xFF3E2723),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              fullName.isEmpty
                  ? 'No Name'
                  : fullName,

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              email.isEmpty
                  ? 'No Email'
                  : email,

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            StatusBadge(
              label: role.toUpperCase(),
              color: const Color(0xFF3E2723),
            ),

            const SizedBox(height: 24),

            const Divider(),

            const SizedBox(height: 12),

            profileInfoRow(
              Icons.phone_rounded,
              'Phone',
              phone.isEmpty
                  ? 'Not provided'
                  : phone,
            ),

            profileInfoRow(
              Icons.location_on_rounded,
              'Address',
              address.isEmpty
                  ? 'Not provided'
                  : address,
            ),

            const SizedBox(height: 20),

            // LANGUAGE SELECTOR CARD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0D5CF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 22,
                    color: Color(0xFF795548),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      AppLanguage.tr('language'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ),
                  const LanguageSelectorWidget(),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const EditProfileScreen(),
                    ),
                  );

                  if (!mounted) return;

                  await loadUserData();
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor:
                  const Color(0xFF3E2723),

                  side: const BorderSide(
                    color: Color(0xFFE0D5CF),
                  ),

                  elevation: 0,
                ),

                child: Text(
                  AppLanguage.tr('edit_profile'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed: () =>
                    logoutAction(context),

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.red.shade800,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),

                child: Text(
                  AppLanguage.tr('logout'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileInfoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF795548),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// EDIT PROFILE SCREEN
// ============================================================


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController firstNameController =
  TextEditingController();
  final TextEditingController middleNameController =
  TextEditingController();
  final TextEditingController lastNameController =
  TextEditingController();
  final TextEditingController emailController =
  TextEditingController();
  final TextEditingController phoneController =
  TextEditingController();
  final TextEditingController addressController =
  TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (!mounted) return;

      firstNameController.text =
          data?['firstName']?.toString() ?? '';
      middleNameController.text =
          data?['middleName']?.toString() ?? '';
      lastNameController.text =
          data?['lastName']?.toString() ?? '';
      emailController.text =
          data?['email']?.toString() ?? user.email ?? '';
      phoneController.text =
          data?['phone']?.toString() ?? '';
      addressController.text =
          data?['address']?.toString() ?? '';

      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load profile information.'),
        ),
      );
    }
  }

  Future<void> saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final firstName = firstNameController.text.trim();
    final middleName = middleNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();

    if (firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First name is required.')),
      );
      return;
    }

    if (lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Last name is required.')),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is required.')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'address': address,
          'firebase_uid': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to update profile. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EDIT PROFILE'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(
              controller: firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: middleNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Middle Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveChanges,
                child: isSaving
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'SAVE CHANGES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// ORDER CHARCOAL
// ============================================================

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  int quantity = 1;
  late final TextEditingController quantityController =
      TextEditingController(text: '1');
  final double pricePerSack = 350.0;

  Stream<int> getAvailableStock() {
    return FirebaseFirestore.instance
        .collection('stocks')
        .doc('charcoal')
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (data == null) {
        return 0;
      }

      return (data['availableStocks'] ?? 0).toInt();
    });
  }

  String orderMethod = 'Delivery';
  String location = '';

  double? latitude;
  double? longitude;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final TextEditingController locationController =
  TextEditingController();

  @override
  void dispose() {
    quantityController.dispose();
    locationController.dispose();
    super.dispose();
  }
  Future<void> pinLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please turn on your phone location/GPS.'),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required.'),
          ),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is permanently denied. Please enable it in Settings.',
            ),
          ),
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;

        location =
        'GPS: ${position.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)}';

        locationController.text = location;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location pinned successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get your location: $e'),
        ),
      );
    }
  }

  Future<void> openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerMapScreen(
          title: orderMethod == 'Pick-Up'
              ? 'PIN PICK-UP LOCATION'
              : 'PIN DELIVERY LOCATION',
          initialLocation: (latitude != null && longitude != null)
              ? ll.LatLng(latitude!, longitude!)
              : null,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        latitude = result['latitude'] as double?;
        longitude = result['longitude'] as double?;
        locationController.text = result['address']?.toString() ?? '';
        location = locationController.text;
      });
    }
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> placeOrder() async {
    final int parsedQuantity =
        int.tryParse(quantityController.text.trim()) ?? quantity;

    if (parsedQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity (at least 1 sack).'),
        ),
      );
      return;
    }

    quantity = parsedQuantity;

    if (quantity > AppState.availableStocks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient stock. Only ${AppState.availableStocks} sacks are currently available.',
          ),
        ),
      );
      return;
    }

    if (locationController.text.trim().isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all order details.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first.'),
        ),
      );
      return;
    }

    final double total = quantity * pricePerSack;

    final String dateStr =
        '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}';

    final String timeStr =
    selectedTime!.format(context);

    try {
      final orderRef =
      FirebaseFirestore.instance.collection('orders').doc();

      final String orderId = orderRef.id;

      await orderRef.set({
        'orderId': orderId,
        'userId': user.uid,
        'customerEmail': user.email ?? '',
        'product': 'Wood Charcoal',
        'quantity': quantity,
        'method': orderMethod,
        'date': dateStr,
        'time': timeStr,
        'total': total,
        'status': 'PENDING',
        'location': locationController.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        AppState.availableStocks -= quantity;

        AppState.orderHistory.add({
          'id': orderId,
          'product': 'Wood Charcoal',
          'quantity': quantity,
          'method': orderMethod,
          'date': dateStr,
          'time': timeStr,
          'total': total,
          'status': 'PENDING',
          'location': locationController.text.trim(),
        });
      });

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Order Placed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your order has been successfully submitted.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Order ID:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  orderId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Status:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const StatusBadge(
                  label: 'PENDING',
                  color: Colors.orange,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(
                        order: AppState.orderHistory.last,
                      ),
                    ),
                  );
                },
                child: const Text('VIEW ORDER'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: const Text('DONE'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('PLACE ORDER ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to place order: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double total = quantity * pricePerSack;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ORDER CHARCOAL'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // STOCK INFORMATION
            // ============================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEBE9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFF3E2723),
                  ),
                  const SizedBox(width: 12),

                  const Text(
                    'AVAILABLE STOCK:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  const Spacer(),

                  StreamBuilder<int>(
                    stream: getAvailableStock(),
                    builder: (context, snapshot) {
                      final int availableStock = snapshot.data ?? 0;

                      return Text(
                        '$availableStock sacks',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF3E2723),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // ============================================================
            // QUANTITY
            // ============================================================

            const SectionTitle(
              title: 'Quantity',
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Number of Sacks',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () {
                          setState(() {
                            quantity--;
                            quantityController.text = quantity.toString();
                          });
                        }
                            : null,
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          color: Color(0xFF795548),
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 6,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF8F3EE),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7CCC8),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7CCC8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3E2723),
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val.trim());
                            if (parsed != null && parsed >= 0) {
                              setState(() {
                                quantity = parsed;
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: quantity < AppState.availableStocks
                            ? () {
                          setState(() {
                            quantity++;
                            quantityController.text = quantity.toString();
                          });
                        }
                            : null,
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // ORDER METHOD
            // ============================================================

            const SectionTitle(
              title: 'Order Method',
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: methodCard(
                    'Pick-Up',
                    Icons.store_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: methodCard(
                    'Delivery',
                    Icons.local_shipping_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ============================================================
            // LOCATION
            // ============================================================

            SectionTitle(
              title: orderMethod == 'Pick-Up'
                  ? 'Pick-Up Location'
                  : 'Delivery Address',
            ),

            const SizedBox(height: 12),

            TextField(
              controller: locationController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: orderMethod == 'Pick-Up'
                    ? 'Enter pick-up point or tap map icon'
                    : 'Enter delivery address or tap map icon',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: openMapPicker,
                      tooltip: 'Pin on Leaflet Map',
                      icon: const Icon(
                        Icons.map_rounded,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    IconButton(
                      onPressed: pinLocation,
                      tooltip: 'Use GPS Location',
                      icon: const Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFF795548),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // DATE AND TIME
            // ============================================================

            Row(
              children: [
                Expanded(
                  child: pickerField(
                    'Date',
                    selectedDate == null
                        ? 'Set Date'
                        : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                    Icons.calendar_today_rounded,
                    selectDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: pickerField(
                    'Time',
                    selectedTime == null
                        ? 'Set Time'
                        : selectedTime!.format(context),
                    Icons.access_time_rounded,
                    selectTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ============================================================
            // ORDER SUMMARY
            // ============================================================

            const SectionTitle(
              title: 'Order Summary',
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFF8F3EE),
                ),
              ),
              child: Column(
                children: [
                  summaryRow(
                    'Product',
                    'Charcoal – Sack',
                  ),
                  summaryRow(
                    'Quantity',
                    '$quantity sacks',
                  ),
                  summaryRow(
                    'Price per Sack',
                    '₱350.00',
                  ),
                  summaryRow(
                    'Order Method',
                    orderMethod,
                  ),
                  const Divider(
                    height: 32,
                  ),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ============================================================
            // PLACE ORDER
            // ============================================================

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: placeOrder,
                child: const Text(
                  'PLACE ORDER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // METHOD CARD
  // ============================================================

  Widget methodCard(
      String method,
      IconData icon,
      ) {
    final bool isSelected = orderMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          orderMethod = method;
          location = '';
          locationController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 300,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3E2723)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(
                isSelected ? 20 : 5,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF3E2723),
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              method,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF3E2723),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE / TIME FIELD
  // ============================================================

  Widget pickerField(
      String label,
      String value,
      IconData icon,
      VoidCallback onTap,
      ) {
    final bool isNotSet = value.startsWith('Set');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF3E2723),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF795548),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isNotSet
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget summaryRow(
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ORDER HISTORY
// ============================================================

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login first.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ORDER HISTORY'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load orders.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No orders yet.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          final orders = snapshot.data!.docs.toList();

          orders.sort((a, b) {
            final Timestamp? timeA =
            a.data()['createdAt'] as Timestamp?;

            final Timestamp? timeB =
            b.data()['createdAt'] as Timestamp?;

            if (timeA == null && timeB == null) {
              return 0;
            }

            if (timeA == null) {
              return 1;
            }

            if (timeB == null) {
              return -1;
            }

            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> order =
              orders[index].data();

              final String orderId =
              (order['orderId'] ??
                  orders[index].id)
                  .toString();

              final String status =
              (order['status'] ?? 'PENDING')
                  .toString();

              final String method =
              (order['method'] ?? 'Delivery')
                  .toString();

              final int quantity =
                  (order['quantity'] as num?)
                      ?.toInt() ??
                      0;

              final String date =
              (order['date'] ?? '').toString();

              final String time =
              (order['time'] ?? '').toString();

              final double total =
                  (order['total'] as num?)
                      ?.toDouble() ??
                      0.0;

              Color statusColor =
                  Colors.orange;

              if (status == 'SUCCESSFUL') {
                statusColor = Colors.green;
              } else if (status == 'CANCELLED') {
                statusColor = Colors.red;
              } else if (status ==
                  'OUT FOR DELIVERY') {
                statusColor = Colors.blue;
              } else if (status == 'PENDING') {
                statusColor = Colors.orange;
              }

              final Map<String, dynamic>
              orderForDetails = {
                ...order,
                'id': orderId,
              };

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OrderDetailsScreen(
                            order: orderForDetails,
                          ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(
                    bottom: 16,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset:
                        const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              orderId,
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          StatusBadge(
                            label: status,
                            color: statusColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Container(
                            padding:
                            const EdgeInsets.all(
                                10),
                            decoration:
                            const BoxDecoration(
                              color:
                              Color(0xFFF8F3EE),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              method == 'Pick-Up'
                                  ? Icons
                                  .store_rounded
                                  : Icons
                                  .local_shipping_rounded,
                              color:
                              const Color(
                                  0xFF3E2723),
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  '$quantity sacks of Charcoal',
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(
                                    height: 4),
                                Text(
                                  '$date at $time',
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            '₱${total.toStringAsFixed(2)}',
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.w900,
                              color:
                              Color(0xFF3E2723),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


// ============================================================
// ORDER DETAILS
// ============================================================

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final String status =
    (order['status'] ?? 'PENDING').toString();

    final double total =
        (order['total'] as num?)?.toDouble() ?? 0.0;

    final String product =
    (order['product'] ?? 'Wood Charcoal').toString();

    final String method =
    (order['method'] ?? '').toString();

    final String location =
    (order['location'] ?? 'Not provided').toString();

    final String date =
    (order['date'] ?? '').toString();

    final String time =
    (order['time'] ?? '').toString();

    final String orderId =
    (order['id'] ?? '').toString();

    final int orderQuantity =
        (order['quantity'] as num?)?.toInt() ?? 0;

    // Get GPS coordinates from Firestore
    final double? latitude =
    (order['latitude'] as num?)?.toDouble();

    final double? longitude =
    (order['longitude'] as num?)?.toDouble();

    final bool hasLocation =
        latitude != null && longitude != null;

    Color statusColor = Colors.orange;

    if (status == 'COMPLETED') {
      statusColor = Colors.green;
    } else if (status == 'CANCELLED') {
      statusColor = Colors.red;
    } else if (status == 'OUT FOR DELIVERY') {
      statusColor = Colors.blue;
    } else if (status == 'PROCESSING') {
      statusColor = Colors.blue;
    } else if (status == 'READY') {
      statusColor = Colors.purple;
    } else if (status == 'PENDING') {
      statusColor = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ORDER DETAILS'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Center(
                    child: StatusBadge(
                      label: status,
                      color: statusColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  detailRow(
                    'Order ID',
                    orderId,
                  ),

                  detailRow(
                    'Product',
                    product,
                  ),

                  detailRow(
                    'Quantity',
                    '$orderQuantity sacks',
                  ),

                  detailRow(
                    'Price per Sack',
                    '₱350.00',
                  ),

                  detailRow(
                    'Order Method',
                    method,
                  ),

                  detailRow(
                    'Location',
                    location,
                  ),

                  // ==================================================
                  // VIEW CUSTOMER LOCATION
                  // ==================================================

                  if (hasLocation) ...[
                    const SizedBox(height: 4),

                    SizedBox(
                      width: double.infinity,
                      height: 48,

                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerLocationMapScreen(
                                    latitude: latitude,
                                    longitude: longitude,
                                    locationLabel:
                                    'Delivery Location',
                                  ),
                            ),
                          );
                        },

                        icon: const Icon(
                          Icons.location_on_rounded,
                        ),

                        label: const Text(
                          'VIEW LOCATION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  detailRow(
                    'Schedule',
                    '$date at $time',
                  ),

                  const Divider(
                    height: 32,
                  ),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        '₱${total.toStringAsFixed(2)}',

                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text(
                  'BACK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,

            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AVAILABLE STOCKS
// ============================================================
class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  Stream<int> getAvailableStock() {
    return FirebaseFirestore.instance
        .collection('stocks')
        .doc('charcoal')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        debugPrint('STOCK DOCUMENT NOT FOUND');
        return 0;
      }

      final data = snapshot.data();

      debugPrint('FIREBASE STOCK DATA: $data');

      if (data == null) {
        debugPrint('STOCK DATA IS NULL');
        return 0;
      }

      final stockValue = data['availableStocks'];

      if (stockValue is num) {
        return stockValue.toInt();
      }

      return 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: getAvailableStock(),
      builder: (context, snapshot) {
        final availableStock = snapshot.data ?? 0;

        String stockStatus = 'OUT OF STOCK';
        Color stockColor = Colors.red;

        if (availableStock > 20) {
          stockStatus = 'IN STOCK';
          stockColor = Colors.green;
        } else if (availableStock > 0) {
          stockStatus = 'LOW STOCK';
          stockColor = Colors.orange;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('AVAILABLE STOCKS'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inventory_2_rounded,
                        size: 80,
                        color: Color(0xFF3E2723),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Charcoal – Sack',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      StatusBadge(
                        label: stockStatus,
                        color: stockColor,
                      ),

                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Quantity Available: ',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$availableStock sacks',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                ElevatedButton(
                  onPressed: availableStock > 0
                      ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderScreen(),
                    ),
                  )
                      : null,
                  child: const Text('ORDER NOW'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// DRIVER DASHBOARD
// ============================================================

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState
    extends State<DriverDashboardScreen> {
  StreamSubscription<Position>? _locationSubscription;

  bool _isLocationTracking = false;

  // ============================================================
  // OPEN CUSTOMER MAP
  // ============================================================

  void openMap(
      BuildContext context,
      Map<String, dynamic> order,
      ) {
    final double? latitude =
    (order['latitude'] as num?)?.toDouble();

    final double? longitude =
    (order['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Customer location is not available.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerLocationMapScreen(
          latitude: latitude,
          longitude: longitude,
          locationLabel: 'Customer Location',
        ),
      ),
    );
  }

  // ============================================================
  // UPDATE DELIVERY STATUS
  // ============================================================

  void updateStatus(
      BuildContext context,
      String orderId,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Update Delivery Status',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            statusOption(
              dialogContext,
              orderId,
              'PROCESSING',
            ),
            statusOption(
              dialogContext,
              orderId,
              'READY',
            ),
            statusOption(
              dialogContext,
              orderId,
              'OUT FOR DELIVERY',
            ),
            statusOption(
              dialogContext,
              orderId,
              'COMPLETED',
            ),
          ],
        ),
      ),
    );
  }

  Widget statusOption(
      BuildContext context,
      String orderId,
      String status,
      ) {
    return ListTile(
      leading: const Icon(
        Icons.local_shipping_rounded,
        color: Color(0xFF3E2723),
      ),
      title: Text(status),
      onTap: () async {
        Navigator.pop(context);

        try {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .update({
            'status': status,
          });

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Delivery status updated to $status.',
              ),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to update status: $e',
              ),
            ),
          );
        }
      },
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;

      case 'OUT FOR DELIVERY':
        return Colors.blue;

      case 'READY':
        return Colors.orange;

      case 'PROCESSING':
        return Colors.deepPurple;

      case 'CANCELLED':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // ACTIVE ORDER CHECK
  // ============================================================

  bool isActiveOrder(String status) {
    final String value = status.toUpperCase();

    return value != 'COMPLETED' &&
        value != 'CANCELLED';
  }

  // ============================================================
  // CUSTOMER NAME
  // ============================================================

  String customerName(
      Map<String, dynamic> order,
      ) {
    final String email =
    (order['customerEmail'] ?? '').toString();

    if (email.isEmpty) {
      return 'Customer';
    }

    return email;
  }

  // ============================================================
  // AUTOMATIC DRIVER LOCATION TRACKING
  // ============================================================

  Future<void> startAutomaticLocationTracking() async {
    try {
      // --------------------------------------------------------
      // CHECK GPS
      // --------------------------------------------------------

      final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint(
          'Driver GPS is turned off.',
        );
        return;
      }

      // --------------------------------------------------------
      // CHECK PERMISSION
      // --------------------------------------------------------

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        debugPrint(
          'Driver location permission denied.',
        );
        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        debugPrint(
          'Driver location permission permanently denied.',
        );
        return;
      }

      // --------------------------------------------------------
      // GET CURRENT DRIVER
      // --------------------------------------------------------

      final User? driver =
          FirebaseAuth.instance.currentUser;

      if (driver == null) {
        debugPrint(
          'No logged-in driver found.',
        );
        return;
      }

      // --------------------------------------------------------
      // GET INITIAL LOCATION
      // --------------------------------------------------------

      final Position initialPosition =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await saveDriverLocation(
        driver,
        initialPosition,
      );

      // --------------------------------------------------------
      // START REAL-TIME LOCATION STREAM
      // --------------------------------------------------------

      _locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
                (Position position) async {
              await saveDriverLocation(
                driver,
                position,
              );
            },
            onError: (error) {
              debugPrint(
                'Location stream error: $error',
              );
            },
          );

      if (mounted) {
        setState(() {
          _isLocationTracking = true;
        });
      }

      debugPrint(
        'Automatic driver location tracking started.',
      );
    } catch (e) {
      debugPrint(
        'Unable to start automatic location tracking: $e',
      );
    }
  }

  // ============================================================
  // SAVE DRIVER LOCATION TO FIRESTORE
  // ============================================================

  Future<void> saveDriverLocation(
      User driver,
      Position position,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('driverLocations')
          .doc(driver.uid)
          .set({
        'driverId': driver.uid,
        'email': driver.email ?? '',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'updatedAt':
        FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Driver location saved: '
            '${position.latitude}, '
            '${position.longitude}',
      );
    } catch (e) {
      debugPrint(
        'Unable to save driver location: $e',
      );
    }
  }

  // ============================================================
  // STOP LOCATION TRACKING
  // ============================================================

  Future<void> stopAutomaticLocationTracking() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;

    if (mounted) {
      setState(() {
        _isLocationTracking = false;
      });
    }

    debugPrint(
      'Automatic driver location tracking stopped.',
    );
  }

  // ============================================================
  // START AUTOMATIC TRACKING WHEN DASHBOARD OPENS
  // ============================================================

  @override
  void initState() {
    super.initState();

    startAutomaticLocationTracking();
  }

  // ============================================================
  // STOP TRACKING WHEN DASHBOARD CLOSES
  // ============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DRIVER PANEL',
        ),
        actions: [
          // ------------------------------------------------------
          // LOCATION STATUS
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.only(
              right: 4,
            ),
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _isLocationTracking
                      ? Colors.green.withAlpha(30)
                      : Colors.orange.withAlpha(30),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: _isLocationTracking
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isLocationTracking
                          ? 'LIVE'
                          : 'GPS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.bold,
                        color: _isLocationTracking
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ------------------------------------------------------
          // LOGOUT
          // ------------------------------------------------------

          IconButton(
            onPressed: () =>
                logoutAction(context),
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ==========================================================
      // ORDERS STREAM
      // ==========================================================

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy(
          'createdAt',
          descending: true,
        )
            .snapshots(),

        builder: (context, snapshot) {
          // ------------------------------------------------------
          // ERROR
          // ------------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(24),
                child: Text(
                  'Unable to load deliveries.\n\n'
                      '${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                ),
              ),
            );
          }

          // ------------------------------------------------------
          // LOADING
          // ------------------------------------------------------

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          final List<
              QueryDocumentSnapshot<
                  Map<String, dynamic>>>
          documents =
              snapshot.data?.docs ?? [];

          // ------------------------------------------------------
          // FIND ACTIVE ORDER
          // ------------------------------------------------------

          QueryDocumentSnapshot<
              Map<String, dynamic>>?
          activeOrder;

          for (final document in documents) {
            final Map<String, dynamic> data =
            document.data();

            final String status =
            (data['status'] ??
                'PENDING')
                .toString();

            if (isActiveOrder(status)) {
              activeOrder = document;
              break;
            }
          }

          // ------------------------------------------------------
          // COUNT ACTIVE ORDERS
          // ------------------------------------------------------

          final int activeCount =
              documents.where((document) {
                final String status =
                (document.data()['status'] ??
                    'PENDING')
                    .toString();

                return isActiveOrder(status);
              }).length;

          // ======================================================
          // MAIN CONTENT
          // ======================================================

          return SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                // ==================================================
                // HEADER
                // ==================================================

                Row(
                  children: [
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, Driver!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight:
                            FontWeight.w900,
                            color:
                            Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                        ),

                        Text(
                          activeCount == 0
                              ? 'No active delivery right now.'
                              : '$activeCount active delivery'
                              '${activeCount == 1 ? '' : 'ies'} available.',
                          style:
                          const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    const CircleAvatar(
                      radius: 25,
                      backgroundColor:
                      Color(0xFFEFEBE9),
                      child: Icon(
                        Icons.local_shipping,
                        color:
                        Color(0xFF3E2723),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ==================================================
                // ACTIVE DELIVERY
                // ==================================================

                if (activeOrder == null)

                  Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets.all(28),
                    decoration:
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(
                        24,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withAlpha(13),
                          blurRadius: 15,
                          offset:
                          const Offset(
                            0,
                            5,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons
                              .local_shipping_outlined,
                          size: 55,
                          color:
                          Color(0xFF8D6E63),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        const Text(
                          'No Active Delivery',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(0xFF3E2723),
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          'New customer orders '
                              'will appear here.',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ],
                    ),
                  )

                else

                  Builder(
                    builder: (context) {
                      final Map<String, dynamic>
                      order =
                      activeOrder!.data();

                      final String orderId =
                          activeOrder.id;

                      final String status =
                      (order['status'] ??
                          'PENDING')
                          .toString();

                      final String email =
                      customerName(order);

                      final String quantity =
                          '${order['quantity'] ?? 0} Sacks';

                      final String location =
                      (order['location'] ??
                          'No location provided')
                          .toString();

                      final String date =
                      (order['date'] ?? '')
                          .toString();

                      final String time =
                      (order['time'] ?? '')
                          .toString();

                      return Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets.all(
                          24,
                        ),
                        decoration:
                        BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(
                            24,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withAlpha(13),
                              blurRadius: 15,
                              offset:
                              const Offset(
                                0,
                                5,
                              ),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [

                            // --------------------------------------
                            // ORDER HEADER
                            // --------------------------------------

                            Row(
                              children: [
                                Container(
                                  padding:
                                  const EdgeInsets
                                      .all(10),
                                  decoration:
                                  BoxDecoration(
                                    color:
                                    const Color(
                                      0xFFEFEBE9,
                                    ),
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      12,
                                    ),
                                  ),
                                  child:
                                  const Icon(
                                    Icons
                                        .local_shipping_rounded,
                                    color:
                                    Color(
                                      0xFF3E2723,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child: Text(
                                    'Order #$orderId',
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                      fontSize: 16,
                                    ),
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                  ),
                                ),

                                const SizedBox(
                                  width: 8,
                                ),

                                StatusBadge(
                                  label: status,
                                  color:
                                  statusColor(
                                    status,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            // --------------------------------------
                            // CUSTOMER
                            // --------------------------------------

                            DeliveryInfoRow(
                              label: 'Customer',
                              value: email,
                            ),

                            // --------------------------------------
                            // QUANTITY
                            // --------------------------------------

                            DeliveryInfoRow(
                              label: 'Quantity',
                              value: quantity,
                            ),

                            // --------------------------------------
                            // DESTINATION
                            // --------------------------------------

                            DeliveryInfoRow(
                              label: 'Destination',
                              value: location,
                            ),

                            // --------------------------------------
                            // SCHEDULE
                            // --------------------------------------

                            if (date.isNotEmpty ||
                                time.isNotEmpty)
                              DeliveryInfoRow(
                                label: 'Schedule',
                                value:
                                '$date '
                                    '${time.isEmpty ? '' : '• $time'}',
                              ),

                            const SizedBox(
                              height: 20,
                            ),

                            const Divider(),

                            const SizedBox(
                              height: 10,
                            ),

                            // --------------------------------------
                            // BUTTONS
                            // --------------------------------------

                            Row(
                              children: [
                                Expanded(
                                  child:
                                  ElevatedButton(
                                    onPressed:
                                        () =>
                                        openMap(
                                          context,
                                          order,
                                        ),
                                    style:
                                    ElevatedButton
                                        .styleFrom(
                                      backgroundColor:
                                      const Color(
                                        0xFFEFEBE9,
                                      ),
                                      foregroundColor:
                                      const Color(
                                        0xFF3E2723,
                                      ),
                                      elevation: 0,
                                    ),
                                    child:
                                    const Text(
                                      'VIEW MAP',
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child:
                                  ElevatedButton(
                                    onPressed:
                                        () =>
                                        updateStatus(
                                          context,
                                          orderId,
                                        ),
                                    child:
                                    const Text(
                                      'UPDATE',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(
                  height: 32,
                ),

                // ==================================================
                // QUICK ACTIONS
                // ==================================================

                const SectionTitle(
                  title: 'Quick Actions',
                ),

                const SizedBox(
                  height: 16,
                ),

                Row(
                  children: [

                    // ----------------------------------------------
                    // LOCATION
                    // ----------------------------------------------

                    Expanded(
                      child:
                      driverActionCard(
                        Icons
                            .my_location_rounded,
                        'Location Tracking',
                        onTap: () {
                          ScaffoldMessenger
                              .of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                _isLocationTracking
                                    ? 'Automatic location tracking is ON.'
                                    : 'Automatic location tracking is not active.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    // ----------------------------------------------
                    // HISTORY
                    // ----------------------------------------------

                    Expanded(
                      child:
                      driverActionCard(
                        Icons
                            .history_rounded,
                        'Delivery History',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const DeliveryHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 32,
                ),

                // ==================================================
                // DELIVERY PROGRESS
                // ==================================================

                const SectionTitle(
                  title:
                  'Delivery Progress',
                ),

                const SizedBox(
                  height: 16,
                ),

                statusCard(
                  'Order Assigned',
                  Icons
                      .assignment_turned_in_rounded,
                  activeOrder != null,
                ),

                statusCard(
                  'Charcoal Picked Up',
                  Icons.inventory_2_rounded,
                  activeOrder != null &&
                      (
                          (
                              activeOrder.data()['status'] ??
                                  'PENDING'
                          )
                              .toString()
                              .toUpperCase() ==
                              'READY'

                              ||

                              (
                                  activeOrder.data()['status'] ??
                                      'PENDING'
                              )
                                  .toString()
                                  .toUpperCase() ==
                                  'OUT FOR DELIVERY'

                              ||

                              (
                                  activeOrder.data()['status'] ??
                                      'PENDING'
                              )
                                  .toString()
                                  .toUpperCase() ==
                                  'COMPLETED'
                      ),
                ),

                statusCard(
                  'Out for Delivery',
                  Icons
                      .local_shipping_rounded,
                  activeOrder != null &&
                      (
                          (
                              activeOrder.data()['status'] ??
                                  'PENDING'
                          )
                              .toString()
                              .toUpperCase() ==
                              'OUT FOR DELIVERY'

                              ||

                              (
                                  activeOrder.data()['status'] ??
                                      'PENDING'
                              )
                                  .toString()
                                  .toUpperCase() ==
                                  'COMPLETED'
                      ),
                ),

                statusCard(
                  'Successfully Delivered',
                  Icons.home_rounded,
                  activeOrder != null &&
                      (
                          activeOrder
                              .data()['status'] ??
                              'PENDING'
                      )
                          .toString()
                          .toUpperCase() ==
                          'COMPLETED',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// ADMIN DASHBOARD
// ============================================================

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN CONSOLE'),
        actions: [
          IconButton(
            onPressed: () => logoutAction(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Text(
                      'Real-time data for the CharCoal network.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const Spacer(),
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFEFEBE9),
                  child: Icon(Icons.admin_panel_settings, color: Color(0xFF3E2723)),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // SYSTEM STATS GRID
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                adminStatCard('12', 'Pending Pick-ups', Icons.inventory_2_rounded, Colors.orange),
                adminStatCard('18', 'Active Deliveries', Icons.local_shipping_rounded, Colors.blue),
                adminStatCard('5', 'Delayed Items', Icons.warning_amber_rounded, Colors.red),
                adminStatCard('135', 'Total Completed', Icons.check_circle_rounded, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const SectionTitle(title: 'Management Operations'),
            const SizedBox(height: 16),
            adminMenu(
              context,
              Icons.shopping_bag_rounded,
              'Order Management',
              'View and manage customer orders',
              const AdminOrdersScreen(),
            ),
            adminMenu(
              context,
              Icons.inventory_2_rounded,
              'Pick-Up Requests',
              'Authorize and schedule collections',
              const AdminPickupRequestsScreen(),
            ),
            adminMenu(
              context,
              Icons.calendar_month_rounded,
              'Delivery Schedule',
              'Optimize routes and time slots',
              const AdminDeliveryScheduleScreen(),
            ),
            adminMenu(
              context,
              Icons.people_alt_rounded,
              'Fleet Management',
              'Manage and track driver assignments',
              const AdminFleetManagementScreen(),
            ),
            adminMenu(
              context,
              Icons.map_rounded,
              'Real-time Tracking',
              'Live location of all active units',
              const AdminLiveTrackingScreen(),
            ),
            adminMenu(
              context,
              Icons.analytics_rounded,
              'Business Intelligence',
              'Performance metrics and reporting',
              const AnalyticsScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PICK-UP SCHEDULING
// ============================================================

class PickupScreen extends StatefulWidget {
  const PickupScreen({super.key});

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  final TextEditingController quantityController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedLocation;

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  void openMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerMapScreen(
          title: 'PIN PICK-UP LOCATION',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => selectedLocation = result['address']?.toString() ?? 'CharCoal Collection Point');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick-up location pinned successfully.')),
      );
    }
  }

  void confirmSchedule() {
    if (quantityController.text.isEmpty || selectedDate == null || selectedTime == null || selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required information.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Schedule Confirmed'),
          content: const Text('Your charcoal pick-up has been successfully scheduled.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PICK-UP SCHEDULING')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collection Request',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Fill in the details below',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const SectionTitle(title: 'Pick-Up Details'),
            const SizedBox(height: 16),
            const Text('Number of Sacks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter quantity',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Collection Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF795548)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedLocation ?? 'Set Pick-Up Location',
                      style: TextStyle(color: selectedLocation == null ? Colors.grey : Colors.black87),
                    ),
                  ),
                  TextButton(
                    onPressed: openMap,
                    child: const Text('OPEN MAP'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF795548)),
                              const SizedBox(width: 8),
                              Text(
                                selectedDate == null
                                    ? 'Set Date'
                                    : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: selectTime,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF795548)),
                              const SizedBox(width: 8),
                              Text(
                                selectedTime == null ? 'Set Time' : selectedTime!.format(context),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: confirmSchedule,
              child: const Text('CONFIRM SCHEDULE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DELIVERY SCHEDULING
// ============================================================

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Future<void> openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerMapScreen(
          title: 'PIN DELIVERY LOCATION',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        addressController.text = result['address']?.toString() ?? '';
      });
    }
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  void submitRequest() {
    if (nameController.text.isEmpty || addressController.text.isEmpty ||
        quantityController.text.isEmpty || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delivery Scheduled'),
        content: const Text('Your charcoal delivery has been successfully scheduled.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to Home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DELIVERY SCHEDULING')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_rounded, size: 48, color: Color(0xFF3E2723)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Complete the form to schedule your charcoal delivery.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            _field('Recipient Name', Icons.person_rounded, nameController),
            _field(
              'Delivery Address',
              Icons.location_on_rounded,
              addressController,
              onPinMap: openMapPicker,
            ),
            _field('Quantity (Sacks)', Icons.inventory_2_rounded, quantityController),
            Row(
              children: [
                Expanded(
                  child: pickerField(
                    'Date',
                    selectedDate == null ? 'Set Date' : '${selectedDate!.month}/${selectedDate!.day}',
                    Icons.calendar_today_rounded,
                    selectDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: pickerField(
                    'Time',
                    selectedTime == null ? 'Set Time' : selectedTime!.format(context),
                    Icons.access_time_rounded,
                    selectTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: submitRequest,
              child: const Text('SUBMIT REQUEST', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    IconData icon,
    TextEditingController controller, {
    VoidCallback? onPinMap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3E2723))),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              prefixIcon: Icon(icon, size: 20),
              suffixIcon: onPinMap != null
                  ? IconButton(
                      onPressed: onPinMap,
                      tooltip: 'Pin on Leaflet Map',
                      icon: const Icon(Icons.map_rounded, color: Color(0xFF3E2723)),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget pickerField(String label, String value, IconData icon, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3E2723))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF795548)),
                const SizedBox(width: 12),
                Text(value, style: TextStyle(color: value.contains('Set') ? Colors.grey : Colors.black87)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TRACKING
// ============================================================

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in first.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TRACK ORDER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading order.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _messageCard(
              icon: Icons.shopping_bag_outlined,
              title: 'No Orders Found',
              message: 'You do not have any orders yet.',
            );
          }

          final orders = snapshot.data!.docs.toList();

          // Sort newest order first.
          orders.sort((a, b) {
            final aData = a.data();
            final bData = b.data();

            final aCreated = aData['createdAt'];
            final bCreated = bData['createdAt'];

            if (aCreated is Timestamp && bCreated is Timestamp) {
              return bCreated.compareTo(aCreated);
            }

            return 0;
          });

          // Prefer an active order.
          final activeStatuses = [
            'PENDING',
            'PROCESSING',
            'READY',
            'OUT FOR DELIVERY',
          ];

          QueryDocumentSnapshot<Map<String, dynamic>> selectedOrder =
              orders.first;

          for (final order in orders) {
            final status =
            (order.data()['status'] ?? '').toString().toUpperCase();

            if (activeStatuses.contains(status)) {
              selectedOrder = order;
              break;
            }
          }

          return _buildTrackingContent(
            context,
            selectedOrder,
          );
        },
      ),
    );
  }

  Widget _buildTrackingContent(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> orderDoc,
      ) {
    final order = orderDoc.data();

    final String orderId =
    (order['orderId'] ?? orderDoc.id).toString();

    final String status =
    (order['status'] ?? 'PENDING').toString().toUpperCase();

    final String product =
    (order['product'] ?? 'Wood Charcoal').toString();

    final int quantity =
    _toInt(order['quantity']);

    final String method =
    (order['method'] ?? 'Delivery').toString();

    final String date =
    (order['date'] ?? '').toString();

    final String time =
    (order['time'] ?? '').toString();

    final String location =
    (order['location'] ?? 'Location not provided').toString();

    final String total =
    _formatTotal(order['total']);

    final String driverId =
    (order['driverId'] ?? '').toString();

    final double? customerLatitude =
    _toDouble(order['latitude']);

    final double? customerLongitude =
    _toDouble(order['longitude']);

    final bool isDelivery =
        method.toLowerCase() == 'delivery';

    final bool hasDriver =
        driverId.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(
          const Duration(milliseconds: 500),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ORDER HEADER
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F1E7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFD7C4B0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF795548),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ORDER ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#$orderId',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // LIVE TRACKING
          _sectionTitle(
            'LIVE TRACKING',
            Icons.location_on_rounded,
          ),

          const SizedBox(height: 10),

          if (!isDelivery)
            _messageCard(
              icon: Icons.storefront_rounded,
              title: 'Pick-Up Order',
              message:
              'This order is for pick-up. Live delivery tracking is not available.',
            )
          else if (!hasDriver)
            _messageCard(
              icon: Icons.person_search_rounded,
              title: 'Waiting for Driver Assignment',
              message:
              'Your order is already being processed. The driver location will appear here once a driver is assigned.',
            )
          else
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('driverLocations')
                  .doc(driverId)
                  .snapshots(),
              builder: (context, driverSnapshot) {
                if (driverSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    height: 330,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (driverSnapshot.hasError) {
                  return _messageCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to Load Driver Location',
                    message:
                    'Please check the driver location and try again.',
                  );
                }

                if (!driverSnapshot.hasData ||
                    !driverSnapshot.data!.exists) {
                  return _messageCard(
                    icon: Icons.location_searching_rounded,
                    title: 'Waiting for Driver Location',
                    message:
                    'The driver is assigned, but their current GPS location has not been received yet.',
                  );
                }

                final driverData =
                    driverSnapshot.data!.data() ?? {};

                final double? driverLatitude =
                _toDouble(driverData['latitude']);

                final double? driverLongitude =
                _toDouble(driverData['longitude']);

                final String driverEmail =
                (driverData['email'] ?? 'Driver').toString();

                if (driverLatitude == null ||
                    driverLongitude == null) {
                  return _messageCard(
                    icon: Icons.location_searching_rounded,
                    title: 'Waiting for Driver Location',
                    message:
                    'The driver is assigned, but GPS coordinates are not available yet.',
                  );
                }

                final driverLocation = ll.LatLng(
                  driverLatitude,
                  driverLongitude,
                );

                final ll.LatLng? customerLocation =
                customerLatitude != null &&
                    customerLongitude != null
                    ? ll.LatLng(
                  customerLatitude,
                  customerLongitude,
                )
                    : null;

                final List<fmap.Polyline> polylines = [];

                if (customerLocation != null) {
                  polylines.add(
                    fmap.Polyline(
                      points: [
                        driverLocation,
                        customerLocation,
                      ],
                      strokeWidth: 4,
                      color: const Color(0xFF795548),
                    ),
                  );
                }

                return Column(
                  children: [
                    Container(
                      height: 330,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFD7C4B0),
                        ),
                      ),
                      child: Stack(
                        children: [
                          fmap.FlutterMap(
                            options: fmap.MapOptions(
                              initialCenter: driverLocation,
                              initialZoom: 15,
                            ),
                            children: [
                              fmap.TileLayer(
                                urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                'com.example.charcoal_app',
                              ),

                              if (polylines.isNotEmpty)
                                fmap.PolylineLayer(
                                  polylines: polylines,
                                ),

                              fmap.MarkerLayer(
                                markers: [
                                  // DRIVER MARKER
                                  fmap.Marker(
                                    point: driverLocation,
                                    width: 65,
                                    height: 75,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding:
                                          const EdgeInsets.all(6),
                                          decoration:
                                          BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withAlpha(50),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons
                                                .local_shipping_rounded,
                                            color:
                                            Color(0xFF795548),
                                            size: 30,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_up,
                                          color:
                                          Color(0xFF795548),
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // CUSTOMER MARKER
                                  if (customerLocation != null)
                                    fmap.Marker(
                                      point: customerLocation,
                                      width: 60,
                                      height: 70,
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFF3E2723),
                                        size: 52,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),

                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withAlpha(35),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize:
                                MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration:
                                    const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                      color:
                                      Color(0xFF3E2723),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F1E7),
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_rounded,
                            color: Color(0xFF795548),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Driver Location',
                                  style: TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                    color:
                                    Color(0xFF3E2723),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  driverEmail,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.circle,
                            size: 10,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 22),

          // ORDER PROGRESS
          _sectionTitle(
            'ORDER PROGRESS',
            Icons.timeline_rounded,
          ),

          const SizedBox(height: 10),

          _progressCard(status),

          const SizedBox(height: 22),

          // ORDER DETAILS
          _sectionTitle(
            'ORDER DETAILS',
            Icons.shopping_bag_rounded,
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE0D5CA),
              ),
            ),
            child: Column(
              children: [
                _detailRow(
                  Icons.local_fire_department_rounded,
                  'Product',
                  product,
                ),
                _detailRow(
                  Icons.inventory_2_rounded,
                  'Quantity',
                  '$quantity sacks',
                ),
                _detailRow(
                  Icons.local_shipping_rounded,
                  'Method',
                  method,
                ),
                _detailRow(
                  Icons.calendar_today_rounded,
                  'Date',
                  date.isEmpty ? 'Not set' : date,
                ),
                _detailRow(
                  Icons.access_time_rounded,
                  'Time',
                  time.isEmpty ? 'Not set' : time,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // DELIVERY INFORMATION
          if (isDelivery) ...[
            _sectionTitle(
              'DELIVERY INFORMATION',
              Icons.location_on_rounded,
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE0D5CA),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF795548),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Location',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                color:
                                Color(0xFF3E2723),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              location,
                              style: const TextStyle(
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (customerLatitude != null &&
                      customerLongitude != null) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed_rounded,
                          size: 20,
                          color: Color(0xFF795548),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${customerLatitude.toStringAsFixed(6)}, '
                                '${customerLongitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 22),
          ],

          // ORDER SUMMARY
          _sectionTitle(
            'ORDER SUMMARY',
            Icons.receipt_rounded,
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F1E7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                ),
                Text(
                  '₱$total',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF795548),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _progressCard(String status) {
    final statuses = [
      'PENDING',
      'PROCESSING',
      'READY',
      'OUT FOR DELIVERY',
      'COMPLETED',
    ];

    final currentIndex =
    statuses.indexOf(status);

    final safeIndex =
    currentIndex < 0 ? 0 : currentIndex;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0D5CA),
        ),
      ),
      child: Column(
        children: List.generate(
          statuses.length,
              (index) {
            final bool completed =
                index <= safeIndex;

            final bool isLast =
                index == statuses.length - 1;

            return Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: completed
                            ? const Color(0xFF795548)
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        completed
                            ? Icons.check
                            : Icons.circle,
                        color: Colors.white,
                        size: completed ? 18 : 9,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 38,
                        color: index < safeIndex
                            ? const Color(0xFF795548)
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding:
                    const EdgeInsets.only(top: 5),
                    child: Text(
                      statuses[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                        completed
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: completed
                            ? const Color(0xFF3E2723)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1E7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0D5CA),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: const Color(0xFF795548),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E2723),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
      String title,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF795548),
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFF795548),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF3E2723),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _statusColor(status)
            .withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'OUT FOR DELIVERY':
        return Colors.blue;
      case 'READY':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.deepOrange;
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.grey;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  String _formatTotal(dynamic value) {
    if (value == null) {
      return '0.00';
    }

    if (value is num) {
      return value.toStringAsFixed(2);
    }

    final parsed =
    double.tryParse(value.toString());

    if (parsed != null) {
      return parsed.toStringAsFixed(2);
    }

    return value.toString();
  }
}

// ============================================================
// SCHEDULE SCREEN
// ============================================================

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MY SCHEDULES')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const SectionTitle(title: 'Upcoming Tasks'),
          const SizedBox(height: 16),
          scheduleCard(
            'Pick-Up',
            '10 sacks',
            'September 18, 2026',
            '10:00 AM',
            Icons.inventory_2_rounded,
            Colors.orange,
          ),
          scheduleCard(
            'Delivery',
            '5 sacks',
            'September 20, 2026',
            '02:30 PM',
            Icons.local_shipping_rounded,
            Colors.blue,
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'Past Activities'),
          const SizedBox(height: 16),
          scheduleCard(
            'Delivery',
            '12 sacks',
            'September 15, 2026',
            '11:15 AM',
            Icons.check_circle_rounded,
            Colors.green,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ANALYTICS
// ============================================================

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ANALYTICS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.analytics_rounded, size: 48, color: Color(0xFF3E2723)),
            ),
            const SizedBox(height: 16),
            const Text(
              'System-wide performance metrics and statistics.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _statCard('Total Pick-Ups', '1,240', Icons.inventory_2_rounded, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _statCard('Total Deliveries', '982', Icons.local_shipping_rounded, Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            progressStatCard('Successful Fulfillment', 0.985, '98.5%', Colors.green),
            const SizedBox(height: 16),
            progressStatCard('On-Time Delivery Rate', 0.82, '82%', Colors.purple),
            const SizedBox(height: 16),
            _statCard('Average Delivery Time', '45 mins', Icons.timer_rounded, Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  Widget progressStatCard(String label, double progress, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withAlpha(30),
            color: color,
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LEAFLET LOCATION PICKER MAP SCREEN
// ============================================================

class LocationPickerMapScreen extends StatefulWidget {
  final String title;
  final ll.LatLng? initialLocation;

  const LocationPickerMapScreen({
    super.key,
    this.title = 'PIN DELIVERY LOCATION',
    this.initialLocation,
  });

  @override
  State<LocationPickerMapScreen> createState() =>
      _LocationPickerMapScreenState();
}

class _LocationPickerMapScreenState extends State<LocationPickerMapScreen> {
  late ll.LatLng _pinnedLocation;
  late final fmap.MapController _mapController;
  bool _isLoadingCurrentLocation = false;
  String _addressText = '';

  @override
  void initState() {
    super.initState();
    _mapController = fmap.MapController();
    _pinnedLocation =
        widget.initialLocation ?? const ll.LatLng(14.599512, 120.984222);
    _updateAddressText(_pinnedLocation);
  }

  void _updateAddressText(ll.LatLng point) {
    setState(() {
      _addressText =
          'Pinned Location: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please turn on GPS/Location services.'),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to fetch current GPS.'),
          ),
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newPoint = ll.LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _pinnedLocation = newPoint;
        _updateAddressText(newPoint);
      });
      _mapController.move(newPoint, 16.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to fetch location: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingCurrentLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Use GPS Location',
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          fmap.FlutterMap(
            mapController: _mapController,
            options: fmap.MapOptions(
              initialCenter: _pinnedLocation,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _pinnedLocation = point;
                  _updateAddressText(point);
                });
              },
            ),
            children: [
              fmap.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.charcoal_app',
              ),
              fmap.MarkerLayer(
                markers: [
                  fmap.Marker(
                    point: _pinnedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap anywhere on the map to pin your location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoadingCurrentLocation)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Pinned Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_rounded, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _addressText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                        label: const Text('GPS'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3E2723),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'address': _addressText,
                              'latitude': _pinnedLocation.latitude,
                              'longitude': _pinnedLocation.longitude,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E2723),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'CONFIRM PIN LOCATION',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROTOTYPE COMPONENTS & SCREENS
// ============================================================

class PrototypeMapScreen extends StatelessWidget {
  final String title;
  final String locationLabel;
  final String address;

  const PrototypeMapScreen({
    super.key,
    required this.title,
    required this.locationLabel,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return LocationPickerMapScreen(
      title: title,
    );
  }
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(50)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.5, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DELIVERY HISTORY')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          historyItem('DEL-001', '10 sacks', 'September 18, 2026', 'Delivered'),
          historyItem('DEL-002', '5 sacks', 'September 16, 2026', 'Delivered'),
          historyItem('DEL-003', '12 sacks', 'September 14, 2026', 'Delivered'),
        ],
      ),
    );
  }

  Widget historyItem(String id, String qty, String date, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(qty, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date, style: const TextStyle(fontSize: 12)),
              Text(status, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminPickupRequestsScreen extends StatelessWidget {
  const AdminPickupRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PICK-UP REQUESTS')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          requestCard('PU-001', '10 sacks', 'Pending', Colors.orange),
          requestCard('PU-002', '5 sacks', 'Approved', Colors.green),
          requestCard('PU-003', '15 sacks', 'Pending', Colors.orange),
        ],
      ),
    );
  }

  Widget requestCard(String id, String qty, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request #$id', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(qty, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const Spacer(),
          StatusBadge(label: status, color: color),
          const SizedBox(width: 8),
          TextButton(onPressed: () {}, child: const Text('VIEW')),
        ],
      ),
    );
  }
}

class AdminDeliveryScheduleScreen extends StatelessWidget {
  const AdminDeliveryScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DELIVERY SCHEDULE')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          scheduleItem('DEL-001', 'Juan Dela Cruz', '10 sacks', '10:00 AM'),
          scheduleItem('DEL-002', 'Maria Santos', '5 sacks', '02:30 PM'),
        ],
      ),
    );
  }

  Widget scheduleItem(String id, String customer, String qty, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(time, style: const TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(customer),
          Text(qty, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class AdminFleetManagementScreen extends StatelessWidget {
  const AdminFleetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FLEET MANAGEMENT')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          driverItem('Driver 01', 'Available', Colors.green),
          driverItem('Driver 02', 'On Delivery', Colors.blue),
          driverItem('Driver 03', 'Available', Colors.green),
        ],
      ),
    );
  }

  Widget driverItem(String name, String status, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withAlpha(30), child: Icon(Icons.person, color: color)),
      title: Text(name),
      subtitle: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      trailing: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
        child: const Text('ASSIGN', style: TextStyle(fontSize: 10)),
      ),
    );
  }
}

// ============================================================
// ADMIN LIVE DRIVER TRACKING
// ============================================================

class AdminLiveTrackingScreen extends StatelessWidget {
  const AdminLiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LIVE FLEET TRACKING'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('driverLocations')
            .doc('GKsBjJXeWheL4fhDTpCfuVsQO7s1')
            .snapshots(),
        builder: (context, snapshot) {
          // --------------------------------------------------
          // ERROR
          // --------------------------------------------------
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load driver location.\n\n'
                      '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // --------------------------------------------------
          // LOADING
          // --------------------------------------------------
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // --------------------------------------------------
          // NO DRIVER LOCATION
          // --------------------------------------------------
          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_rounded,
                      size: 60,
                      color: Color(0xFF8D6E63),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Driver Location Available',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The driver has not updated '
                          'their location yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // --------------------------------------------------
          // GET DRIVER DATA
          // --------------------------------------------------
          final data = snapshot.data!.data();

          if (data == null) {
            return const Center(
              child: Text(
                'Driver location data is empty.',
              ),
            );
          }

          final double? latitude =
          (data['latitude'] as num?)?.toDouble();

          final double? longitude =
          (data['longitude'] as num?)?.toDouble();

          final String email =
          (data['email'] ?? 'Driver').toString();

          // --------------------------------------------------
          // INVALID COORDINATES
          // --------------------------------------------------
          if (latitude == null || longitude == null) {
            return const Center(
              child: Text(
                'Driver coordinates are not available.',
              ),
            );
          }

          final ll.LatLng driverLocation =
          ll.LatLng(latitude, longitude);

          // --------------------------------------------------
          // MAIN SCREEN
          // --------------------------------------------------
          return Column(
            children: [
              // ==================================================
              // MAP
              // ==================================================
              Expanded(
                child: Stack(
                  children: [
                    fmap.FlutterMap(
                      options: fmap.MapOptions(
                        initialCenter: driverLocation,
                        initialZoom: 16,
                      ),
                      children: [
                        // ------------------------------------------------
                        // OPEN STREET MAP
                        // ------------------------------------------------
                        fmap.TileLayer(
                          urlTemplate:
                          'https://tile.openstreetmap.org/'
                              '{z}/{x}/{y}.png',
                          userAgentPackageName:
                          'com.example.charcoal_app',
                        ),

                        // ------------------------------------------------
                        // DRIVER MARKER
                        // ------------------------------------------------
                        fmap.MarkerLayer(
                          markers: [
                            fmap.Marker(
                              point: driverLocation,
                              width: 90,
                              height: 100,
                              child: Column(
                                mainAxisSize:
                                MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_shipping_rounded,
                                    size: 52,
                                    color:
                                    Color(0xFF3E2723),
                                  ),
                                  Container(
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration:
                                    BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                      BorderRadius
                                          .circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withAlpha(30),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'DRIVER',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight:
                                        FontWeight.bold,
                                        color:
                                        Color(0xFF3E2723),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ==================================================
                    // LIVE INFORMATION CARD
                    // ==================================================
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.black.withAlpha(30),
                              blurRadius: 10,
                              offset:
                              const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color:
                              Color(0xFF3E2723),
                              size: 30,
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Live Driver Tracking',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.bold,
                                      color:
                                      Color(0xFF3E2723),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style:
                                    const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // LIVE BADGE
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                Colors.green.withAlpha(25),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // DRIVER INFORMATION
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // DRIVER EMAIL
                    DeliveryInfoRow(
                      label: 'Driver',
                      value: email,
                    ),

                    // LATITUDE
                    DeliveryInfoRow(
                      label: 'Latitude',
                      value:
                      latitude.toStringAsFixed(6),
                    ),

                    // LONGITUDE
                    DeliveryInfoRow(
                      label: 'Longitude',
                      value:
                      longitude.toStringAsFixed(6),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // VIEW DRIVER LOCATION
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerLocationMapScreen(
                                    latitude: latitude,
                                    longitude: longitude,
                                    locationLabel:
                                    'Driver Location',
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.map_rounded,
                        ),
                        label: const Text(
                          'VIEW DRIVER LOCATION',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// SHARED UI HELPERS
// ============================================================

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3E2723),
        letterSpacing: 0.5,
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withAlpha(51),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class DeliveryInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const DeliveryInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

void logoutAction(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(AppLanguage.tr('confirm_logout')),
        content: Text(AppLanguage.tr('confirm_logout_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLanguage.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseAuth.instance.signOut();
              await GoogleSignIn.instance.signOut();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              minimumSize: const Size(100, 45),
            ),
            child: Text(AppLanguage.tr('logout')),
          ),
        ],
      );
    },
  );
}

Widget serviceCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget page,
    ) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => page,
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F3EE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: Color(0xFF3E2723),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget infoCard(
    IconData icon,
    String title,
    String description, {
      VoidCallback? onTap,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEBE9),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3E2723),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

Widget driverActionCard(
    IconData icon,
    String title, {
      VoidCallback? onTap,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: const Color(0xFF3E2723),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget statusCard(
    String title,
    IconData icon,
    bool completed,
    ) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: completed
              ? Colors.green
              : Colors.grey,
          size: 22,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: completed
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: completed
                  ? const Color(0xFF3E2723)
                  : Colors.grey,
            ),
          ),
        ),
        if (completed)
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 18,
          )
        else
          const Text(
            'WAITING',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    ),
  );
}

Widget adminStatCard(
    String value,
    String title,
    IconData icon,
    Color color,
    ) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723),
              ),
            ),
            Icon(
              icon,
              color: color,
              size: 20,
            ),
          ],
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget adminMenu(
    BuildContext context,
    IconData icon,
    String title,
    String description, [
      Widget? page,
    ]) {
  return GestureDetector(
    onTap: () {
      if (page != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      }
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F3EE),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3E2723),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.grey,
            size: 14,
          ),
        ],
      ),
    ),
  );
}

Widget scheduleCard(
    String type,
    String quantity,
    String date,
    String time,
    IconData icon,
    Color color,
    ) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight:
                      FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                quantity,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius:
            BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: color,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF3E2723),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// ============================================================
// CUSTOMER / DRIVER LOCATION MAP
// ============================================================

class CustomerLocationMapScreen
    extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String locationLabel;

  const CustomerLocationMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.locationLabel = 'Customer Location',
  });

  @override
  Widget build(BuildContext context) {
    final ll.LatLng selectedLocation =
    ll.LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          locationLabel.toUpperCase(),
        ),
      ),
      body: Stack(
        children: [
          fmap.FlutterMap(
            options: fmap.MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 16,
            ),
            children: [
              fmap.TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                'com.example.charcoal_app',
              ),
              fmap.MarkerLayer(
                markers: [
                  fmap.Marker(
                    point: selectedLocation,
                    width: 60,
                    height: 70,
                    child: const Icon(
                      Icons.location_on,
                      size: 55,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(38),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF795548),
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          locationLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${latitude.toStringAsFixed(6)}, '
                              '${longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}