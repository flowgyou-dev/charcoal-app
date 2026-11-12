import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/email_verification_dialog.dart';
import '../widgets/password_requirements_indicator.dart';
import '../../order/screens/customer_home_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    final firstErr = Validators.validateName(_firstNameCtrl.text, label: 'First Name');
    final midErr = Validators.validateMiddleName(_middleNameCtrl.text);
    final lastErr = Validators.validateName(_lastNameCtrl.text, label: 'Last Name');
    final phoneErr = Validators.validatePhPhone(_phoneCtrl.text);
    final emailErr = Validators.validateEmail(_emailCtrl.text);
    final passErr = Validators.validateStrongPassword(_passCtrl.text);
    final confirmErr = Validators.validateConfirmPassword(_passCtrl.text, _confirmPassCtrl.text);

    final firstError = firstErr ?? midErr ?? lastErr ?? phoneErr ?? emailErr ?? passErr ?? confirmErr;
    if (firstError != null) {
      setState(() => _errorMessage = firstError);
      return;
    }

    final composedName = Validators.composeFullName(
      firstName: _firstNameCtrl.text,
      middleName: _middleNameCtrl.text,
      lastName: _lastNameCtrl.text,
    );
    if (composedName.length > 120) {
      setState(() => _errorMessage = 'Full name combined cannot exceed 120 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create Firebase Auth + RTDB account and send built-in verification link
      final createdUser = await _authService.registerCustomer(
        firstName: _firstNameCtrl.text,
        middleName: _middleNameCtrl.text,
        lastName: _lastNameCtrl.text,
        phone: _phoneCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 2. Prompt user to click the link in their email and tap "I've Verified"
      final verifiedUser = await showDialog<AppUser?>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EmailVerificationDialog(
          email: createdUser.email,
          authService: _authService,
        ),
      );

      if (!mounted) return;
      if (verifiedUser != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => CustomerHomeScreen(currentUser: verifiedUser)),
          (route) => false,
        );
      } else {
        await _authService.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.emeraldGreen,
            content: Text(
              'Account created! Verify the link sent to your email, then log in.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg;
        switch (e.code) {
          case 'email-already-in-use':
            msg = 'This email address is already registered. Try logging in to verify or access your account.';
            break;
          case 'weak-password':
            msg = 'Password is too weak. Please use a stronger combination.';
            break;
          case 'invalid-email':
            msg = 'Invalid email address format.';
            break;
          default:
            msg = e.message ?? 'Unable to register with Firebase.';
        }
        setState(() => _errorMessage = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '').isNotEmpty
              ? e.toString().replaceAll('Exception: ', '')
              : 'Registration failed. Please check your internet connection.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create a New Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.inkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fast, direct delivery of quality charcoal for your home or business.',
                    style: TextStyle(fontSize: 13, color: AppTheme.mutedSlate),
                  ),
                  const SizedBox(height: 22),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstNameCtrl,
                          maxLength: 40,
                          inputFormatters: [NameInputFormatter()],
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'First Name *',
                            prefixIcon: Icon(Icons.person_outline),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lastNameCtrl,
                          maxLength: 40,
                          inputFormatters: [NameInputFormatter()],
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Last Name *',
                            prefixIcon: Icon(Icons.badge_outlined),
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _middleNameCtrl,
                    maxLength: 40,
                    inputFormatters: [NameInputFormatter()],
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Middle Name (Optional)',
                      prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneCtrl,
                    maxLength: 12,
                    keyboardType: TextInputType.number,
                    inputFormatters: [PhPhoneInputFormatter()],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Mobile or Telephone Number *',
                      hintText: 'e.g. 09171234567 or 0281234567',
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailCtrl,
                    maxLength: 100,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email Address (Recognized Domain) *',
                      hintText: 'e.g. name@gmail.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    maxLength: 64,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      counterText: '',
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmPassCtrl,
                    maxLength: 64,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _handleRegister(),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password *',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      counterText: '',
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PasswordRequirementsIndicator(
                    password: _passCtrl.text,
                    confirmPassword: _confirmPassCtrl.text,
                    showConfirmCheck: true,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('VERIFY EMAIL & CREATE ACCOUNT'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: AppTheme.mutedSlate, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Log In here',
                          style: TextStyle(
                            color: AppTheme.emeraldGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
