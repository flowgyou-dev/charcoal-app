class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phPhoneRegex = RegExp(
    r'^(09\d{9}|\+639\d{9})$',
  );

  static final RegExp _htmlTagOrControlRegex = RegExp(r'''[<>"']|[\x00-\x1F\x7F]''');

  /// Removes leading/trailing spaces and strips HTML/script characters.
  static String sanitizeText(String input) {
    return input.trim().replaceAll(_htmlTagOrControlRegex, '');
  }

  static String? validateName(String? value, {String label = 'Pangalan'}) {
    final clean = sanitizeText(value ?? '');
    if (clean.isEmpty) {
      return 'Kailangan ilagay ang $label.';
    }
    if (clean.length < 2) {
      return 'Ang $label ay dapat hindi bababa sa 2 characters.';
    }
    if (clean.length > 60) {
      return 'Ang $label ay hanggang 60 characters lamang.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return 'Kailangan ilagay ang Email Address.';
    }
    if (clean.length > 100) {
      return 'Masyadong mahaba ang Email Address (max 100 characters).';
    }
    if (!_emailRegex.hasMatch(clean)) {
      return 'Hindi valid ang format ng Email Address.';
    }
    return null;
  }

  static String? validatePhPhone(String? value) {
    final clean = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '').trim();
    if (clean.isEmpty) {
      return 'Kailangan ilagay ang Mobile Number.';
    }
    if (!_phPhoneRegex.hasMatch(clean)) {
      return 'Gamitin ang valid PH mobile format (hal. 09171234567 o +639171234567).';
    }
    return null;
  }

  static String? validateStrongPassword(String? value) {
    final pass = value ?? '';
    if (pass.isEmpty) {
      return 'Kailangan ilagay ang Password.';
    }
    if (pass.length < 8) {
      return 'Ang Password ay dapat hindi bababa sa 8 characters.';
    }
    if (pass.length > 64) {
      return 'Ang Password ay hanggang 64 characters lamang.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(pass)) {
      return 'Maglagay ng kahit isang malaking letra (A-Z) sa password.';
    }
    if (!RegExp(r'[0-9]').hasMatch(pass)) {
      return 'Maglagay ng kahit isang numero (0-9) sa password.';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_+=~`]').hasMatch(pass)) {
      return 'Maglagay ng kahit isang symbol (hal. @, #, \$, !) sa password.';
    }
    return null;
  }

  static String? validateLoginPassword(String? value) {
    final pass = value ?? '';
    if (pass.trim().isEmpty) {
      return 'Kailangan ilagay ang Password.';
    }
    if (pass.length > 64) {
      return 'Masyadong mahaba ang Password.';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    final clean = sanitizeText(value ?? '');
    if (clean.isEmpty) {
      return 'Kailangan ilagay ang Delivery Address.';
    }
    if (clean.length < 10) {
      return 'Paki-kumpleto ang Delivery Address (hindi bababa sa 10 characters).';
    }
    if (clean.length > 200) {
      return 'Ang Delivery Address ay hanggang 200 characters lamang.';
    }
    return null;
  }

  static String? validateOrderQuantity(int quantity, int currentStock) {
    if (currentStock <= 0) {
      return 'Out of stock ang uling sa ngayon.';
    }
    if (quantity < 1) {
      return 'Hindi bababa sa 1 sako ang pwedeng i-order.';
    }
    if (quantity > currentStock) {
      return 'Paumanhin, $currentStock sako na lang ang natitira sa stock.';
    }
    return null;
  }
}
