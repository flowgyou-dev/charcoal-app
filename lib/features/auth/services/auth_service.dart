import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';

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
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = Validators.sanitizeText(name);
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]'), '').trim();

    final cred = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = cred.user!;
    final appUser = AppUser(
      uid: user.uid,
      email: cleanEmail,
      name: cleanName,
      phone: cleanPhone,
      role: 'customer',
    );

    // Save to Realtime Database
    await _database.ref('${AppConstants.dbUsers}/${user.uid}').set(appUser.toMap());
    return appUser;
  }

  // 2. Customer Sign In (with RBAC check)
  Future<AppUser> signInCustomer({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final snap = await _database.ref('${AppConstants.dbUsers}/${cred.user!.uid}').get();
    if (snap.exists) {
      final appUser = AppUser.fromMap(cred.user!.uid, snap.value as Map<dynamic, dynamic>);
      if (appUser.role != 'customer') {
        await _auth.signOut();
        throw Exception('Ang account na ito ay hindi Customer account. Gamitin ang tamang portal.');
      }
      return appUser;
    }

    return AppUser(
      uid: cred.user!.uid,
      email: email.trim().toLowerCase(),
      name: email.split('@').first,
      phone: '',
      role: 'customer',
    );
  }

  // 3. Driver Sign In (Firebase Auth + Admin-managed driver record verification)
  Future<Map<String, dynamic>> signInDriver({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final uid = cred.user!.uid;
    final driverSnap = await _database.ref('${AppConstants.dbDrivers}/$uid').get();
    final userRoleSnap = await _database.ref('${AppConstants.dbUsers}/$uid/role').get();
    final role = userRoleSnap.exists ? userRoleSnap.value?.toString() : null;

    if (!driverSnap.exists || role != 'driver') {
      await _auth.signOut();
      throw Exception('Hindi verified na Driver account ito. Makipag-ugnayan sa Admin.');
    }

    final driverData = driverSnap.value as Map<dynamic, dynamic>;
    return {
      'driverId': uid,
      'name': driverData['name']?.toString() ?? 'Driver',
      'phone': driverData['phone']?.toString() ?? '',
      'vehicle': driverData['vehicle']?.toString() ?? 'Motorcycle',
      'plateNumber': driverData['plateNumber']?.toString() ?? '',
      'email': driverData['email']?.toString() ?? email.trim().toLowerCase(),
    };
  }

  // 4. Delete Account (Play Store & App Store compliance)
  Future<void> deleteAccount({
    required String password,
    bool isDriver = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Walang aktibong user session.');
    }

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(cred);

    final uid = user.uid;
    await _database.ref('${AppConstants.dbUsers}/$uid').remove();
    if (isDriver) {
      await _database.ref('${AppConstants.dbDrivers}/$uid').remove();
      await _database.ref('${AppConstants.dbDriverLocations}/$uid').remove();
    }

    await user.delete();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
