import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

/// Shared Forgot Password dialog for Customer and Driver login portals.
class PasswordResetDialog {
  static Future<void> show(
    BuildContext context, {
    required AuthService authService,
    required String initialEmail,
    String title = 'Reset Password',
    String subtitle = 'Enter your registered email address to receive a password reset link.',
    String emailLabel = 'Email Address',
  }) async {
    final resetCtrl = TextEditingController(text: initialEmail.trim());
    String? dialogErr;
    bool sending = false;

    final sentTo = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardWhite,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.inkCharcoal),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.mutedSlate),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resetCtrl,
                maxLength: 100,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                decoration: InputDecoration(
                  labelText: emailLabel,
                  prefixIcon: const Icon(Icons.email_outlined),
                  counterText: '',
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
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedSlate)),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      final err = Validators.validateEmail(resetCtrl.text);
                      if (err != null) {
                        setDialogState(() => dialogErr = err);
                        return;
                      }
                      setDialogState(() {
                        sending = true;
                        dialogErr = null;
                      });
                      try {
                        await authService.sendPasswordReset(resetCtrl.text);
                        if (ctx.mounted) Navigator.pop(ctx, resetCtrl.text.trim().toLowerCase());
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() {
                            sending = false;
                            dialogErr = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      }
                    },
              child: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send Link'),
            ),
          ],
        ),
      ),
    );

    resetCtrl.dispose();
    if (sentTo != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.emeraldGreen,
          content: Text(
            'If an account is registered for $sentTo, a password reset link has been sent. Check your inbox or spam folder.',
          ),
        ),
      );
    }
  }
}
