import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

class PasswordRequirementsIndicator extends StatelessWidget {
  final String password;
  final String? confirmPassword;
  final bool showConfirmCheck;

  const PasswordRequirementsIndicator({
    super.key,
    required this.password,
    this.confirmPassword,
    this.showConfirmCheck = true,
  });

  @override
  Widget build(BuildContext context) {
    final status = Validators.checkPasswordRequirements(
      password,
      confirmPassword: confirmPassword,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.canvasMist,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (showConfirmCheck ? status.allMetWithConfirm : status.allMet)
              ? AppTheme.emeraldGreen.withValues(alpha: 0.6)
              : AppTheme.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password Requirements',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.inkCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          _reqRow('At least 8 characters (8–64)', status.hasMinLength && status.hasMaxLength),
          _reqRow('At least 1 uppercase letter (A–Z)', status.hasUppercase),
          _reqRow('At least 1 number (0–9)', status.hasNumber),
          _reqRow('At least 1 special character (@, #, \$, !)', status.hasSpecialChar),
          if (showConfirmCheck)
            _reqRow('Passwords match', status.passwordsMatch),
        ],
      ),
    );
  }

  Widget _reqRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 15,
            color: met ? AppTheme.emeraldGreen : AppTheme.mutedSlate,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: met ? AppTheme.emeraldGreen : AppTheme.mutedSlate,
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
