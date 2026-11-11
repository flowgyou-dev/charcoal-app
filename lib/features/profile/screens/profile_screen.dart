import 'package:flutter/material.dart';
import '../../auth/screens/role_select_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String role;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _isProcessing = false;

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        title: const Text('Privacy Policy', style: TextStyle(color: AppTheme.inkCharcoal, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'CharCoal Hub Privacy Notice\n\n'
            '1. Data We Collect: We store your name, email, phone number, delivery address, and GPS pin to process and deliver charcoal (uling) orders.\n\n'
            '2. Location Data: Customer GPS pins are used once per order to locate the drop-off point. Driver GPS coordinates are shared only while GPS tracking is turned ON for active deliveries.\n\n'
            '3. Data Security: Passwords are encrypted and managed by Firebase Authentication. Access is restricted by user role.\n\n'
            '4. Account Deletion: You may permanently delete your account and profile data at any time using the Delete Account button on this screen.',
            style: TextStyle(color: AppTheme.mutedSlate, fontSize: 13, height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.headerForest, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final passCtrl = TextEditingController();
    String? dialogError;

    final confirmedPassword = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardWhite,
          title: Text('Delete Account', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sigurado ka bang gusto mong burahin ang iyong account? Hindi na ito maibabalik.',
                style: TextStyle(color: AppTheme.mutedSlate, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: AppTheme.inkCharcoal),
                decoration: const InputDecoration(
                  labelText: 'I-type ang Password para i-confirm',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(dialogError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedSlate)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () {
                final err = Validators.validateLoginPassword(passCtrl.text);
                if (err != null) {
                  setDialogState(() => dialogError = err);
                  return;
                }
                Navigator.pop(ctx, passCtrl.text);
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      ),
    );

    passCtrl.dispose();
    if (confirmedPassword == null || confirmedPassword.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      await _authService.deleteAccount(
        password: confirmedPassword,
        isDriver: widget.role == 'driver',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.emeraldGreen,
            content: Text('Matagumpay na nabura ang iyong account.'),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: const Text('Hindi nabura ang account. Pakitingnan kung tama ang password.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.headerForest.withValues(alpha: 0.12),
                        child: Text(
                          widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: AppTheme.headerForest, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.inkCharcoal)),
                            const SizedBox(height: 2),
                            Text(widget.email, style: const TextStyle(fontSize: 12, color: AppTheme.mutedSlate)),
                            if (widget.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(widget.phone, style: const TextStyle(fontSize: 12, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      'Role: ${widget.role.toUpperCase()}',
                      style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.headerForest),
                  title: const Text('Privacy Policy', style: TextStyle(color: AppTheme.inkCharcoal, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Basahin kung paano pinoprotektahan ang iyong data.', style: TextStyle(color: AppTheme.mutedSlate, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.mutedSlate),
                  onTap: _showPrivacyPolicy,
                ),
                const Divider(height: 1, color: AppTheme.surfaceBorder),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.inkCharcoal),
                  title: const Text('Sign Out', style: TextStyle(color: AppTheme.inkCharcoal, fontWeight: FontWeight.w600)),
                  onTap: _isProcessing ? null : _handleSignOut,
                ),
                const Divider(height: 1, color: AppTheme.surfaceBorder),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
                  title: Text('Delete Account', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Permanenteng burahin ang iyong account at profile data.', style: TextStyle(color: AppTheme.mutedSlate, fontSize: 12)),
                  onTap: _isProcessing ? null : _handleDeleteAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
