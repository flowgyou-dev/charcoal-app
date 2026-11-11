import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'customer_register_screen.dart';
import '../../order/screens/customer_home_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final resetCtrl = TextEditingController(text: _emailCtrl.text.trim());
    String? dialogErr;

    final sentTo = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardWhite,
          title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.inkCharcoal)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ilagay ang iyong email address para padalhan ng password reset link.',
                style: TextStyle(fontSize: 12, color: AppTheme.mutedSlate),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resetCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              if (dialogErr != null) ...[
                const SizedBox(height: 8),
                Text(dialogErr!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedSlate)),
            ),
            ElevatedButton(
              onPressed: () async {
                final err = Validators.validateEmail(resetCtrl.text);
                if (err != null) {
                  setDialogState(() => dialogErr = err);
                  return;
                }
                try {
                  await _authService.sendPasswordReset(resetCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx, resetCtrl.text.trim());
                } catch (e) {
                  setDialogState(() => dialogErr = 'Hindi maipadala ang reset link. I-check ang email.');
                }
              },
              child: const Text('Send Link'),
            ),
          ],
        ),
      ),
    );

    resetCtrl.dispose();
    if (sentTo != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.emeraldGreen,
          content: Text('Naipadala ang password reset link sa $sentTo.'),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
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
      final user = await _authService.signInCustomer(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerHomeScreen(currentUser: user),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _errorMessage = msg.contains('firebase_auth')
              ? 'Mali ang email o password. Pakisubukan muli.'
              : msg;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.headerForest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, size: 38, color: AppTheme.headerForest),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Maligayang Pagbabalik!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.inkCharcoal),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mag-log in para makabili ng uling at i-track ang delivery.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.mutedSlate),
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
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
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppTheme.inkCharcoal),
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: const TextStyle(color: AppTheme.inkCharcoal),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('LOG IN AS CUSTOMER'),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Wala ka pang account? ', style: TextStyle(color: AppTheme.mutedSlate, fontSize: 13)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerRegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Mag-Sign Up dito',
                      style: TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
