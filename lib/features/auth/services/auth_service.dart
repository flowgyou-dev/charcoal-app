import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // 1. Customer Registration
  Future<AppUser> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = cred.user!;
    final appUser = AppUser(
      uid: user.uid,
      email: email.trim(),
      name: name.trim(),
      phone: phone.trim(),
      role: 'customer',
    );

    // Save to Realtime Database
    await _database.ref('${AppConstants.dbUsers}/${user.uid}').set(appUser.toMap());
    return appUser;
  }

  // 2. Customer Sign In
  Future<AppUser> signInCustomer({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final snap = await _database.ref('${AppConstants.dbUsers}/${cred.user!.uid}').get();
    if (snap.exists) {
      return AppUser.fromMap(cred.user!.uid, snap.value as Map<dynamic, dynamic>);
    }

    return AppUser(
      uid: cred.user!.uid,
      email: email.trim(),
      name: email.split('@').first,
      phone: '',
      role: 'customer',
    );
  }

  // 3. Driver Sign In (Admin-managed driver verification)
  Future<Map<String, dynamic>> signInDriver({
    required String email,
    required String password,
  }) async {
    // Check drivers collection created by Admin
    final snap = await _database.ref(AppConstants.dbDrivers).get();
    if (snap.exists) {
      final data = snap.value as Map<dynamic, dynamic>;
      for (final entry in data.entries) {
        final driverData = entry.value as Map<dynamic, dynamic>;
        if (driverData['email']?.toString().toLowerCase().trim() == email.toLowerCase().trim() &&
            driverData['password']?.toString().trim() == password.trim()) {
          return {
            'driverId': entry.key.toString(),
            'name': driverData['name']?.toString() ?? 'Driver',
            'phone': driverData['phone']?.toString() ?? '',
            'vehicle': driverData['vehicle']?.toString() ?? '',
            'plateNumber': driverData['plateNumber']?.toString() ?? '',
            'email': driverData['email']?.toString() ?? '',
          };
        }
      }
    }

    // Try standard Firebase Auth if available
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return {
        'driverId': cred.user!.uid,
        'name': email.split('@').first,
        'phone': '',
        'vehicle': 'Motorcycle',
        'plateNumber': '',
        'email': email.trim(),
      };
    } catch (_) {
      throw Exception('Hindi tugma ang Driver credentials. Tiyaking ibinigay ng Admin ang iyong account.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
