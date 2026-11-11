import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../order/screens/customer_home_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    final nameErr = Validators.validateName(_nameCtrl.text, label: 'Pangalan / Negosyo');
    final phoneErr = Validators.validatePhPhone(_phoneCtrl.text);
    final emailErr = Validators.validateEmail(_emailCtrl.text);
    final passErr = Validators.validateStrongPassword(_passCtrl.text);

    final firstError = nameErr ?? phoneErr ?? emailErr ?? passErr;
    if (firstError != null) {
      setState(() => _errorMessage = firstError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.registerCustomer(
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => CustomerHomeScreen(currentUser: user)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Hindi makapag-rehistro. Subukang gumamit ng ibang email o i-check ang internet.';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Gumawa ng Bagong Account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.inkCharcoal),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mabilisang pag-order ng dekalidad na uling para sa iyong negosyo.',
                style: TextStyle(fontSize: 13, color: AppTheme.mutedSlate),
              ),
              const SizedBox(height: 24),

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
                controller: _nameCtrl,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Pangalan / Tindahan / Ihawan Name',
                  prefixIcon: Icon(Icons.person_outline),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneCtrl,
                maxLength: 15,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number (09XXXXXXXXX)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailCtrl,
                maxLength: 100,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                maxLength: 64,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Strong Password (8+ chars, A-Z, 0-9, symbol)',
                  prefixIcon: Icon(Icons.lock_outline),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('CREATE CUSTOMER ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
