import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../../driver/models/driver_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';

class EmailNotVerifiedException implements Exception {
  final String email;
  const EmailNotVerifiedException(this.email);

  @override
  String toString() =>
      'Please verify your email address ($email) using the link sent to your inbox.';
}

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

    var appUser = AppUser.fromMap(user.uid, userSnap.value as Map<dynamic, dynamic>);
    if (!appUser.isActive) {
      await _auth.signOut();
      return null;
    }

    if (appUser.role == 'customer') {
      try {
        await user.reload();
      } catch (_) {}
      final refreshed = _auth.currentUser;
      final isFirebaseVerified = refreshed?.emailVerified ?? user.emailVerified;
      if (!isFirebaseVerified && !appUser.emailVerified) {
        await _auth.signOut();
        return null;
      }
      if (isFirebaseVerified && !appUser.emailVerified) {
        await _database.ref('${AppConstants.dbUsers}/${user.uid}').update({
          'emailVerified': true,
        });
        appUser = _withEmailVerified(appUser);
      }
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

  /// Loads current user's stored name components (firstName, middleName, lastName) if available.
  Future<Map<String, String>> getUserNameParts(String uid) async {
    final snap = await _database.ref('${AppConstants.dbUsers}/$uid').get();
    if (snap.exists && snap.value is Map) {
      final map = snap.value as Map<dynamic, dynamic>;
      return {
        'firstName': map['firstName']?.toString() ?? '',
        'middleName': map['middleName']?.toString() ?? '',
        'lastName': map['lastName']?.toString() ?? '',
      };
    }
    return const {'firstName': '', 'middleName': '', 'lastName': ''};
  }

  AppUser _withEmailVerified(AppUser u) {
    return AppUser(
      uid: u.uid,
      email: u.email,
      name: u.name,
      firstName: u.firstName,
      middleName: u.middleName,
      lastName: u.lastName,
      phone: u.phone,
      role: u.role,
      isActive: u.isActive,
      emailVerified: true,
      createdAt: u.createdAt,
    );
  }

  // 1. Customer Registration + Built-in Firebase Email Verification Link
  Future<AppUser> registerCustomer({
    required String firstName,
    String middleName = '',
    required String lastName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanFirst = Validators.sanitizeText(firstName);
    final cleanMiddle = Validators.sanitizeText(middleName);
    final cleanLast = Validators.sanitizeText(lastName);
    final cleanName = Validators.composeFullName(
      firstName: cleanFirst,
      middleName: cleanMiddle,
      lastName: cleanLast,
    );
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
      firstName: cleanFirst,
      middleName: cleanMiddle,
      lastName: cleanLast,
      phone: cleanPhone,
      role: 'customer',
      isActive: true,
      emailVerified: false,
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

    try {
      await user.updateDisplayName(cleanName);
    } catch (_) {}
    await user.sendEmailVerification();

    return appUser;
  }

  /// Sends a fresh Firebase verification link to the currently signed-in user.
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No active registration session found. Please log in again.');
    }
    await user.sendEmailVerification();
  }

  /// Reloads FirebaseAuth user and syncs `emailVerified: true` into RTDB once verified.
  Future<AppUser?> checkAndSyncEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null || !refreshed.emailVerified) {
      return null;
    }

    final userRef = _database.ref('${AppConstants.dbUsers}/${refreshed.uid}');
    await userRef.update({'emailVerified': true});

    final snap = await userRef.get();
    if (!snap.exists || snap.value is! Map) return null;
    return AppUser.fromMap(refreshed.uid, snap.value as Map<dynamic, dynamic>);
  }

  // 2. Customer Sign In (with strict DB profile + active + email verified check)
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
      throw Exception(
        'Customer profile not found in the database. Please register again or contact Admin.',
      );
    }

    var appUser = AppUser.fromMap(cred.user!.uid, snap.value as Map<dynamic, dynamic>);
    if (appUser.role != 'customer') {
      await _auth.signOut();
      throw Exception('This account is not a Customer account. Please use the correct portal.');
    }
    if (!appUser.isActive) {
      await _auth.signOut();
      throw Exception('This account has been deactivated. Please contact Admin.');
    }

    try {
      await cred.user!.reload();
    } catch (_) {}
    final refreshed = _auth.currentUser;
    final isFirebaseVerified = refreshed?.emailVerified ?? cred.user!.emailVerified;

    if (!isFirebaseVerified && !appUser.emailVerified) {
      // Keep signed-in session briefly so login dialog can resend/reload verification
      throw EmailNotVerifiedException(refreshed?.email ?? appUser.email);
    }

    if (isFirebaseVerified && !appUser.emailVerified) {
      await _database.ref('${AppConstants.dbUsers}/${cred.user!.uid}').update({
        'emailVerified': true,
      });
      appUser = _withEmailVerified(appUser);
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
      throw Exception('This account is not a verified Driver account. Please contact Admin.');
    }

    final userMap = userSnap.value as Map<dynamic, dynamic>;
    final role = userMap['role']?.toString();
    final userActive = userMap['isActive'] != false;

    final driverProfile = DriverProfile.fromMap(uid, driverSnap.value as Map<dynamic, dynamic>);
    if (role != 'driver' || !userActive || !driverProfile.isActive) {
      await _auth.signOut();
      throw Exception('This Driver account has been deactivated or lacks portal access.');
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
    required String firstName,
    String middleName = '',
    required String lastName,
    required String phone,
    bool isDriver = false,
  }) async {
    final cleanFirst = Validators.sanitizeText(firstName);
    final cleanMiddle = Validators.sanitizeText(middleName);
    final cleanLast = Validators.sanitizeText(lastName);
    final cleanName = Validators.composeFullName(
      firstName: cleanFirst,
      middleName: cleanMiddle,
      lastName: cleanLast,
    );
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
        'firstName': cleanFirst,
        'middleName': cleanMiddle,
        'lastName': cleanLast,
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
      throw Exception('No active user session found.');
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
      throw Exception('No active user session found.');
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
