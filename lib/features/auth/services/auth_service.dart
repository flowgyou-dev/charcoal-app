import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../../driver/models/driver_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';

class ResolvedSession {
  final String role; // 'customer' | 'driver'
  final AppUser? customer;
  final DriverProfile? driver;

  const ResolvedSession({
    required this.role,
    this.customer,
    this.driver,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Resolves an already signed-in FirebaseAuth session on app launch.
  Future<ResolvedSession?> resolveCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userSnap = await _database.ref('${AppConstants.dbUsers}/${user.uid}').get();
    if (!userSnap.exists || userSnap.value is! Map) {
      await _auth.signOut();
      return null;
    }

    final appUser = AppUser.fromMap(user.uid, userSnap.value as Map<dynamic, dynamic>);
    if (!appUser.isActive) {
      await _auth.signOut();
      return null;
    }

    if (appUser.role == 'customer') {
      return ResolvedSession(role: 'customer', customer: appUser);
    }

    if (appUser.role == 'driver') {
      final driverSnap = await _database.ref('${AppConstants.dbDrivers}/${user.uid}').get();
      if (!driverSnap.exists || driverSnap.value is! Map) {
        await _auth.signOut();
        return null;
      }
      final driverProfile = DriverProfile.fromMap(
        user.uid,
        driverSnap.value as Map<dynamic, dynamic>,
      );
      if (!driverProfile.isActive) {
        await _auth.signOut();
        return null;
      }
      return ResolvedSession(role: 'driver', driver: driverProfile);
    }

    await _auth.signOut();
    return null;
  }

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
      isActive: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await _database.ref('${AppConstants.dbUsers}/${user.uid}').set(appUser.toMap());
    } catch (e) {
      // Roll back Auth user so no orphaned Auth-only user gets stranded
      try {
        await user.delete();
      } catch (_) {}
      rethrow;
    }
    return appUser;
  }

  // 2. Customer Sign In (with strict DB profile + active check)
  Future<AppUser> signInCustomer({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final snap = await _database.ref('${AppConstants.dbUsers}/${cred.user!.uid}').get();
    if (!snap.exists || snap.value is! Map) {
      await _auth.signOut();
      throw Exception('Hindi makita ang Customer profile sa database. Mag-register muli o makipag-ugnayan sa Admin.');
    }

    final appUser = AppUser.fromMap(cred.user!.uid, snap.value as Map<dynamic, dynamic>);
    if (appUser.role != 'customer') {
      await _auth.signOut();
      throw Exception('Ang account na ito ay hindi Customer account. Gamitin ang tamang portal.');
    }
    if (!appUser.isActive) {
      await _auth.signOut();
      throw Exception('Ang account na ito ay naka-deactivate. Makipag-ugnayan sa Admin.');
    }
    return appUser;
  }

  // 3. Driver Sign In (Firebase Auth + active driver verification)
  Future<DriverProfile> signInDriver({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final uid = cred.user!.uid;
    final driverSnap = await _database.ref('${AppConstants.dbDrivers}/$uid').get();
    final userSnap = await _database.ref('${AppConstants.dbUsers}/$uid').get();

    if (!driverSnap.exists || !userSnap.exists || driverSnap.value is! Map || userSnap.value is! Map) {
      await _auth.signOut();
      throw Exception('Hindi verified na Driver account ito. Makipag-ugnayan sa Admin.');
    }

    final userMap = userSnap.value as Map<dynamic, dynamic>;
    final role = userMap['role']?.toString();
    final userActive = userMap['isActive'] != false;

    final driverProfile = DriverProfile.fromMap(uid, driverSnap.value as Map<dynamic, dynamic>);

    if (role != 'driver' || !userActive || !driverProfile.isActive) {
      await _auth.signOut();
      throw Exception('Ang Driver account na ito ay naka-deactivate o walang access.');
    }

    return driverProfile;
  }

  // 4. Forgot Password
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  // 5. Update Profile Name & Phone
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    bool isDriver = false,
  }) async {
    final cleanName = Validators.sanitizeText(name);
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]'), '').trim();
    if (isDriver) {
      await _database.ref('${AppConstants.dbDrivers}/$uid').update({
        'phone': cleanPhone,
      });
      await _database.ref('${AppConstants.dbUsers}/$uid').update({
        'phone': cleanPhone,
      });
    } else {
      await _database.ref('${AppConstants.dbUsers}/$uid').update({
        'name': cleanName,
        'phone': cleanPhone,
      });
    }
  }

  // 6. Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Walang aktibong user session.');
    }
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  // 7. Delete Account
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
