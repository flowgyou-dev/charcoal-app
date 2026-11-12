import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/password_reset_dialog.dart';
import '../../driver/screens/driver_dashboard_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    await PasswordResetDialog.show(
      context,
      authService: _authService,
      initialEmail: _emailCtrl.text,
      title: 'Reset Driver Password',
      subtitle: 'Enter your Driver email address to receive a password reset link.',
      emailLabel: 'Driver Email Address',
    );
  }

  Future<void> _handleDriverLogin() async {
    if (_isLoading) return;

    final emailErr = Validators.validateEmail(_emailCtrl.text);
    final passErr = Validators.validateLoginPassword(_passCtrl.text);
    final firstError = emailErr ?? passErr;
    if (firstError != null) {
      setState(() => _errorMessage = firstError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _authService.signInDriver(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => DriverDashboardScreen(driverProfile: profile)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Portal Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.headerForest.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        size: 38,
                        color: AppTheme.headerForest,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Delivery Rider Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.inkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.emeraldGreen, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Note: Only the Admin creates Driver accounts. Please get your login credentials from your Admin.',
                            style: TextStyle(color: AppTheme.inkCharcoal, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),

                  TextField(
                    controller: _emailCtrl,
                    maxLength: 100,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppTheme.inkCharcoal),
                    decoration: const InputDecoration(
                      labelText: 'Driver Email Address',
                      prefixIcon: Icon(Icons.badge_outlined),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    maxLength: 64,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleDriverLogin(),
                    style: const TextStyle(color: AppTheme.inkCharcoal),
                    decoration: InputDecoration(
                      labelText: 'Assigned Password',
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
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.headerForest),
                      onPressed: _isLoading ? null : _handleDriverLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('LOG IN AS DRIVER'),
                    ),
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
