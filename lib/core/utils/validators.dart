import 'package:flutter/services.dart';
import 'email_domain_validator.dart';

class PasswordRequirementStatus {
  final bool hasMinLength;
  final bool hasMaxLength;
  final bool hasUppercase;
  final bool hasNumber;
  final bool hasSpecialChar;
  final bool passwordsMatch;

  const PasswordRequirementStatus({
    required this.hasMinLength,
    required this.hasMaxLength,
    required this.hasUppercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.passwordsMatch,
  });

  bool get allMet =>
      hasMinLength &&
      hasMaxLength &&
      hasUppercase &&
      hasNumber &&
      hasSpecialChar;

  bool get allMetWithConfirm => allMet && passwordsMatch;
}

class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phPhoneRegex = RegExp(
    r'^(09\d{9}|\+639\d{9}|02\d{7,8}|\+632\d{7,8}|0[3-8]\d{8}|\+63[3-8]\d{8}|[78]\d{7})$',
  );

  static final RegExp _htmlTagOrControlRegex = RegExp(r'''[<>"']|[\x00-\x1F\x7F]''');

  static final RegExp _specialCharRegex = RegExp(r'''[!@#\$%^&*(),.?":{}|<>\-_+=~`]''');

  /// Removes leading/trailing spaces and strips HTML/script characters.
  static String sanitizeText(String input) {
    return input.trim().replaceAll(_htmlTagOrControlRegex, '');
  }

  static String composeFullName({
    required String firstName,
    String middleName = '',
    required String lastName,
  }) {
    final parts = [
      sanitizeText(firstName),
      sanitizeText(middleName),
      sanitizeText(lastName),
    ].where((p) => p.isNotEmpty).toList();
    return parts.join(' ');
  }

  static String? validateName(String? value, {String label = 'Name'}) {
    final clean = sanitizeText(value ?? '');
    if (clean.isEmpty) {
      return 'Please enter $label.';
    }
    if (clean.length < 2) {
      return '$label must be at least 2 characters.';
    }
    if (clean.length > 60) {
      return '$label cannot exceed 60 characters.';
    }
    return null;
  }

  static String? validateMiddleName(String? value) {
    final clean = sanitizeText(value ?? '');
    if (clean.isEmpty) return null; // Optional
    if (clean.length > 60) {
      return 'Middle Name cannot exceed 60 characters.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return 'Please enter your Email Address.';
    }
    if (clean.length > 100) {
      return 'Email Address is too long (max 100 characters).';
    }
    if (!_emailRegex.hasMatch(clean)) {
      return 'Please enter a valid Email Address format.';
    }
    return EmailDomainValidator.validateDomain(clean);
  }

  static String? validatePhPhone(String? value) {
    final clean = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '').trim();
    if (clean.isEmpty) {
      return 'Please enter your Mobile or Telephone Number.';
    }
    if (!_phPhoneRegex.hasMatch(clean)) {
      return 'Use a valid PH mobile (e.g. 09171234567) or telephone number (e.g. (02) 8123-4567).';
    }
    return null;
  }

  static PasswordRequirementStatus checkPasswordRequirements(
    String password, {
    String? confirmPassword,
  }) {
    return PasswordRequirementStatus(
      hasMinLength: password.length >= 8,
      hasMaxLength: password.length <= 64,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasNumber: RegExp(r'[0-9]').hasMatch(password),
      hasSpecialChar: _specialCharRegex.hasMatch(password),
      passwordsMatch: confirmPassword != null &&
          password.isNotEmpty &&
          password == confirmPassword,
    );
  }

  static String? validateStrongPassword(String? value) {
    final pass = value ?? '';
    if (pass.isEmpty) {
      return 'Please enter a Password.';
    }
    if (pass.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (pass.length > 64) {
      return 'Password cannot exceed 64 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(pass)) {
      return 'Password must include at least 1 uppercase letter (A-Z).';
    }
    if (!RegExp(r'[0-9]').hasMatch(pass)) {
      return 'Password must include at least 1 number (0-9).';
    }
    if (!_specialCharRegex.hasMatch(pass)) {
      return 'Password must include at least 1 special character (e.g. @, #, \$, !).';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    final pass = password ?? '';
    final confirm = confirmPassword ?? '';
    if (confirm.isEmpty) {
      return 'Please confirm your Password.';
    }
    if (pass != confirm) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? validateLoginPassword(String? value) {
    final pass = value ?? '';
    if (pass.trim().isEmpty) {
      return 'Please enter your Password.';
    }
    if (pass.length > 64) {
      return 'Password is too long.';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    final clean = sanitizeText(value ?? '');
    if (clean.isEmpty) {
      return 'Please enter your Delivery Address.';
    }
    if (clean.length < 10) {
      return 'Please complete your Delivery Address (at least 10 characters).';
    }
    if (clean.length > 200) {
      return 'Delivery Address cannot exceed 200 characters.';
    }
    return null;
  }

  static String? validateOrderQuantity(int quantity, int currentStock) {
    if (currentStock <= 0) {
      return 'Charcoal is currently out of stock.';
    }
    if (quantity < 1) {
      return 'Minimum order quantity is 1 sack.';
    }
    if (quantity > currentStock) {
      return 'Sorry, only $currentStock sack(s) remaining in stock.';
    }
    return null;
  }
}

/// Restricts phone/telephone input to `[0-9+\-\s()]` and caps digit count
/// by Philippine prefix (`09` -> 11 digits, `02`/area code -> 10, `+63` -> 12, local `7`/`8` -> 8).
class PhPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = StringBuffer();
    for (var i = 0; i < newValue.text.length; i++) {
      final ch = newValue.text[i];
      if (RegExp(r'[0-9\-\s()]').hasMatch(ch) || (ch == '+' && cleaned.isEmpty)) {
        cleaned.write(ch);
      }
    }
    final preFiltered = cleaned.toString();
    final allDigits = preFiltered.replaceAll(RegExp(r'\D'), '');

    final int maxDigits;
    if (preFiltered.startsWith('+')) {
      maxDigits = 12;
    } else if (allDigits.startsWith('09')) {
      maxDigits = 11;
    } else if (allDigits.startsWith('0')) {
      maxDigits = 10;
    } else if (allDigits.startsWith('7') || allDigits.startsWith('8')) {
      maxDigits = 8;
    } else {
      maxDigits = 11;
    }

    final result = StringBuffer();
    var digitCount = 0;
    for (var i = 0; i < preFiltered.length; i++) {
      final ch = preFiltered[i];
      if (RegExp(r'\d').hasMatch(ch)) {
        if (digitCount >= maxDigits) continue;
        digitCount++;
      }
      result.write(ch);
    }

    final finalText = result.toString();
    final offset = newValue.selection.baseOffset.clamp(0, finalText.length);
    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
