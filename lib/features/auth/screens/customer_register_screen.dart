import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/email_otp_service.dart';
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
      // 1. Send 6-digit verification code to the user's recognized email address
      final challenge = await EmailOtpService.sendVerificationCode(
        email: _emailCtrl.text,
        name: composedName,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 2. Ask user to enter the 6-digit verification code
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _EmailOtpDialog(
          email: _emailCtrl.text.trim().toLowerCase(),
          fullName: composedName,
          initialToken: challenge.token,
        ),
      );

      if (verified != true || !mounted) return;

      // 3. Create verified Firebase Auth & RTDB user account
      setState(() => _isLoading = true);
      final user = await _authService.registerCustomer(
        firstName: _firstNameCtrl.text,
        middleName: _middleNameCtrl.text,
        lastName: _lastNameCtrl.text,
        phone: _phoneCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        emailVerified: true,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => CustomerHomeScreen(currentUser: user)),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg;
        switch (e.code) {
          case 'email-already-in-use':
            msg = 'This email address is already registered. Try logging in instead.';
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
                    maxLength: 15,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number (09XXXXXXXXX) *',
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailCtrl,
                    maxLength: 100,
                    keyboardType: TextInputType.emailAddress,
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

class _EmailOtpDialog extends StatefulWidget {
  final String email;
  final String fullName;
  final String initialToken;

  const _EmailOtpDialog({
    required this.email,
    required this.fullName,
    required this.initialToken,
  });

  @override
  State<_EmailOtpDialog> createState() => _EmailOtpDialogState();
}

class _EmailOtpDialogState extends State<_EmailOtpDialog> {
  final List<TextEditingController> _digitCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late String _token;
  int _resendSeconds = 60;
  Timer? _timer;
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _token = widget.initialToken;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digitCtrls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _enteredCode => _digitCtrls.map((c) => c.text.trim()).join();

  void _onDigitChanged(int idx, String val) {
    final digitsOnly = val.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 1) {
      // Handle pasted 6-digit code
      for (var i = 0; i < 6; i++) {
        _digitCtrls[i].text = i < digitsOnly.length ? digitsOnly[i] : '';
      }
      if (digitsOnly.length >= 6) {
        _focusNodes[5].requestFocus();
      }
      setState(() => _error = null);
      return;
    }

    if (digitsOnly != val) {
      _digitCtrls[idx].text = digitsOnly;
      _digitCtrls[idx].selection = TextSelection.collapsed(offset: digitsOnly.length);
    }

    if (digitsOnly.isNotEmpty && idx < 5) {
      _focusNodes[idx + 1].requestFocus();
    } else if (digitsOnly.isEmpty && idx > 0) {
      _focusNodes[idx - 1].requestFocus();
    }
    setState(() => _error = null);
  }

  Future<void> _submitVerification() async {
    final code = _enteredCode;
    if (code.length != 6) {
      setState(() => _error = 'Please enter all 6 digits of the verification code.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      await EmailOtpService.verifyCode(
        email: widget.email,
        code: code,
        token: _token,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendSeconds > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final res = await EmailOtpService.sendVerificationCode(
        email: widget.email,
        name: widget.fullName,
      );
      if (!mounted) return;
      _token = res.token;
      for (final c in _digitCtrls) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _startCountdown();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Verify Your Email',
        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.inkCharcoal),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter the 6-digit verification code sent to:\n${widget.email}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedSlate, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (idx) {
              return SizedBox(
                width: 40,
                child: TextField(
                  controller: _digitCtrls[idx],
                  focusNode: _focusNodes[idx],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.headerForest,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) => _onDigitChanged(idx, val),
                ),
              );
            }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          TextButton(
            onPressed: (_resendSeconds == 0 && !_resending) ? _handleResend : null,
            child: Text(
              _resending
                  ? 'Sending new code...'
                  : (_resendSeconds > 0
                      ? 'Resend code in ${_resendSeconds}s'
                      : 'Resend 6-digit code'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _verifying ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedSlate)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
          onPressed: _verifying ? null : _submitVerification,
          child: _verifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Verify Code'),
        ),
      ],
    );
  }
}
