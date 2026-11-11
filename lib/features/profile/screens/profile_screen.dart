import 'package:flutter/material.dart';
import '../../auth/screens/role_select_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/connection_banner.dart';

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
  late String _displayName;
  late String _displayPhone;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _displayName = widget.name;
    _displayPhone = widget.phone;
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        title: const Text('Privacy Policy', style: TextStyle(color: AppTheme.inkCharcoal, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'CharCoal Hub Privacy Notice\n\n'
            '1. Data We Collect: We store your name, email, phone number, delivery address, GPS pin, and optional online payment receipt photos to process charcoal orders.\n\n'
            '2. Location Data: Customer GPS pins are used once per order to locate the drop-off point. Driver GPS coordinates are shared only while GPS tracking is active.\n\n'
            '3. Data Security: Passwords are encrypted and managed by Firebase Authentication. Access is restricted by user role.\n\n'
            '4. Account Deletion: Customers may permanently delete their account using the Delete Account button below.',
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

  Future<void> _handleEditProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: _displayName);
    final phoneCtrl = TextEditingController(text: _displayPhone);
    String? dialogError;
    final isDriver = widget.role == 'driver';

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardWhite,
          title: const Text('Edit Profile', style: TextStyle(color: AppTheme.inkCharcoal, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                enabled: !isDriver,
                decoration: InputDecoration(
                  labelText: isDriver ? 'Name (Admin-managed)' : 'Full Name / Business',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number (09XXXXXXXXX)',
                  prefixIcon: Icon(Icons.phone_outlined),
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
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedSlate)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!isDriver) {
                  final nameErr = Validators.validateName(nameCtrl.text);
                  if (nameErr != null) {
                    setDialogState(() => dialogError = nameErr);
                    return;
                  }
                }
                final phoneErr = Validators.validatePhPhone(phoneCtrl.text);
                if (phoneErr != null) {
                  setDialogState(() => dialogError = phoneErr);
                  return;
                }
                try {
                  await _authService.updateProfile(
                    uid: user.uid,
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    isDriver: isDriver,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (_) {
                  setDialogState(() => dialogError = 'Hindi ma-save ang profile changes.');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (updated == true && mounted) {
      setState(() {
        if (!isDriver) _displayName = Validators.sanitizeText(nameCtrl.text);
        _displayPhone = phoneCtrl.text.replaceAll(RegExp(r'[\s\-()]'), '').trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.emeraldGreen, content: Text('Na-update ang iyong profile!')),
      );
    }
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  Future<void> _handleChangePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    String? dialogError;

    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardWhite,
          title: const Text('Change Password', style: TextStyle(color: AppTheme.inkCharcoal, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Strong Password',
                  prefixIcon: Icon(Icons.key_outlined),
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
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedSlate)),
            ),
            ElevatedButton(
              onPressed: () async {
                final curErr = Validators.validateLoginPassword(currentCtrl.text);
                final newErr = Validators.validateStrongPassword(newCtrl.text);
                final firstErr = curErr ?? newErr;
                if (firstErr != null) {
                  setDialogState(() => dialogError = firstErr);
                  return;
                }
                try {
                  await _authService.changePassword(
                    currentPassword: currentCtrl.text,
                    newPassword: newCtrl.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (_) {
                  setDialogState(() => dialogError = 'Mali ang current password o mahina ang bagong password.');
                }
              },
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.emeraldGreen, content: Text('Matagumpay na napalitan ang password!')),
      );
    }
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
      body: ConnectionBanner(
        child: ListView(
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
                            _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: AppTheme.headerForest, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.inkCharcoal)),
                              const SizedBox(height: 2),
                              Text(widget.email, style: const TextStyle(fontSize: 12, color: AppTheme.mutedSlate)),
                              if (_displayPhone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(_displayPhone, style: const TextStyle(fontSize: 12, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w600)),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppTheme.headerForest),
                          tooltip: 'Edit Profile',
                          onPressed: _handleEditProfile,
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
                    leading: const Icon(Icons.key_outlined, color: AppTheme.headerForest),
                    title: const Text('Change Password', style: TextStyle(color: AppTheme.inkCharcoal, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Magpalit ng bagong password.', style: TextStyle(color: AppTheme.mutedSlate, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.mutedSlate),
                    onTap: _isProcessing ? null : _handleChangePassword,
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceBorder),
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
                  if (widget.role == 'customer') ...[
                    const Divider(height: 1, color: AppTheme.surfaceBorder),
                    ListTile(
                      leading: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
                      title: Text('Delete Account', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Permanenteng burahin ang iyong account at profile data.', style: TextStyle(color: AppTheme.mutedSlate, fontSize: 12)),
                      onTap: _isProcessing ? null : _handleDeleteAccount,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
