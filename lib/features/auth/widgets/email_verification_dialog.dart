import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

/// Prompts a customer to click Firebase Auth's verification link in their inbox,
/// check verification status via `reload()`, or resend the link.
class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final AuthService authService;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    required this.authService,
  });

  @override
  State<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  int _resendSeconds = 60;
  Timer? _timer;
  bool _checking = false;
  bool _resending = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  Future<void> _handleCheckVerified() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      final verifiedUser = await widget.authService.checkAndSyncEmailVerification();
      if (!mounted) return;
      if (verifiedUser != null) {
        Navigator.pop<AppUser?>(context, verifiedUser);
      } else {
        setState(() {
          _isError = true;
          _statusMessage =
              'Email is not verified yet. Please click the verification link in your inbox (check Spam too) and try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isError = true;
          _statusMessage = 'Unable to check verification status. Please check your connection.';
        });
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendSeconds > 0 || _resending) return;
    setState(() {
      _resending = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      await widget.authService.resendVerificationEmail();
      if (!mounted) return;
      _startCountdown();
      setState(() {
        _isError = false;
        _statusMessage = 'A new verification link has been sent to ${widget.email}.';
      });
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _statusMessage = e.code == 'too-many-requests'
              ? 'Too many requests. Please wait a minute before trying again.'
              : (e.message ?? 'Unable to resend verification email.');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isError = true;
          _statusMessage = 'Unable to resend verification email right now.';
        });
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
      title: const Row(
        children: [
          Icon(Icons.mark_email_read_outlined, color: AppTheme.emeraldGreen),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verify Your Email',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.inkCharcoal),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppTheme.mutedSlate, height: 1.45),
              children: [
                const TextSpan(text: 'We sent a verification link to:\n'),
                TextSpan(
                  text: widget.email,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.headerForest,
                  ),
                ),
                const TextSpan(
                  text:
                      '\n\nOpen your inbox (or Spam folder), click the link in the email, then tap "I\'ve Verified" below.',
                ),
              ],
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isError ? Colors.red.shade50 : const Color(0xFFE8F3EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isError ? Colors.red.shade200 : AppTheme.emeraldGreen.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _isError ? Colors.red.shade800 : AppTheme.headerForest,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: (_resendSeconds == 0 && !_resending) ? _handleResend : null,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(
              _resending
                  ? 'Sending verification email...'
                  : (_resendSeconds > 0
                      ? 'Resend link in ${_resendSeconds}s'
                      : 'Resend Verification Link'),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop<AppUser?>(context, null),
          child: const Text('Verify Later', style: TextStyle(color: AppTheme.mutedSlate)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
          onPressed: _checking ? null : _handleCheckVerified,
          child: _checking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text("I've Verified"),
        ),
      ],
    );
  }
}
