import 'package:flutter_test/flutter_test.dart';
import 'package:charcoal_app/core/utils/email_domain_validator.dart';
import 'package:charcoal_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('sanitizeText strips HTML tags, quotes, and trims whitespace', () {
      expect(
        Validators.sanitizeText('  <script>Juan\'s "Charcoal"</script>  '),
        'scriptJuans Charcoal/script',
      );
    });

    test('validateEmail enforces format and recognized domain rules', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail('person@gmail.con'), isNotNull);
      expect(Validators.validateEmail('user@*.edu.ph'), isNotNull);
      expect(Validators.validateEmail('temp@mailinator.com'), isNotNull);
      expect(Validators.validateEmail('try@facebook.com'), isNotNull);
      expect(Validators.validateEmail('user@randomsite.net'), isNotNull);
      expect(Validators.validateEmail('user@charcoal.ph'), isNotNull);

      expect(Validators.validateEmail('user@gmail.com'), isNull);
      expect(Validators.validateEmail('staff@up.edu.ph'), isNull);
      expect(Validators.validateEmail('contact@company.com.ph'), isNull);
    });

    test('EmailDomainValidator validates public providers and institutional suffixes directly', () {
      expect(EmailDomainValidator.validateDomain('user@outlook.com'), isNull);
      expect(EmailDomainValidator.validateDomain('user@comcast.net'), isNull);
      expect(EmailDomainValidator.validateDomain('user@agency.gov.ph'), isNull);
      expect(EmailDomainValidator.validateDomain('try@facebook.com'), isNotNull);
      expect(EmailDomainValidator.validateDomain('user@gmil.com'), isNotNull);
      expect(EmailDomainValidator.validateDomain('user@example.invalid'), isNotNull);
    });

    test('composeFullName and validateMiddleName handle optional middle name', () {
      expect(Validators.validateMiddleName(''), isNull);
      expect(Validators.validateMiddleName('Santos'), isNull);
      expect(Validators.validateMiddleName('A' * 61), isNotNull);

      expect(
        Validators.composeFullName(
          firstName: '  Juan ',
          middleName: '',
          lastName: 'Dela Cruz  ',
        ),
        'Juan Dela Cruz',
      );
      expect(
        Validators.composeFullName(
          firstName: 'Juan',
          middleName: 'Santos',
          lastName: 'Dela Cruz',
        ),
        'Juan Santos Dela Cruz',
      );
    });

    test('validatePhPhone enforces PH mobile and telephone formats', () {
      expect(Validators.validatePhPhone('12345'), isNotNull);
      expect(Validators.validatePhPhone('099999999999999'), isNotNull);
      expect(Validators.validatePhPhone('0917-123-4567'), isNull);
      expect(Validators.validatePhPhone('+639171234567'), isNull);
      expect(Validators.validatePhPhone('(02) 8123-4567'), isNull);
      expect(Validators.validatePhPhone('02-123-4567'), isNull);
      expect(Validators.validatePhPhone('8123-4567'), isNull);
      expect(Validators.validatePhPhone('(046) 123-4567'), isNull);
      expect(Validators.validatePhPhone('+63281234567'), isNull);
    });

    test('PhPhoneInputFormatter caps digits by PH mobile and landline prefixes', () {
      final formatter = PhPhoneInputFormatter();
      final clippedMobile = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '099999999999999'),
      );
      expect(clippedMobile.text, '09999999999');

      final landline = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '(02) 8123-4567'),
      );
      expect(landline.text, '(02) 8123-4567');
    });

    test('validateStrongPassword requires length, uppercase, number, and symbol', () {
      expect(Validators.validateStrongPassword('short1!'), isNotNull);
      expect(Validators.validateStrongPassword('nouppercase1!'), isNotNull);
      expect(Validators.validateStrongPassword('NoNumber!'), isNotNull);
      expect(Validators.validateStrongPassword('NoSymbol123'), isNotNull);
      expect(Validators.validateStrongPassword('Charcoal#2026'), isNull);
    });

    test('validateConfirmPassword checks required input and match', () {
      expect(Validators.validateConfirmPassword('Charcoal#2026', ''), isNotNull);
      expect(
        Validators.validateConfirmPassword('Charcoal#2026', 'Different#2026'),
        isNotNull,
      );
      expect(
        Validators.validateConfirmPassword('Charcoal#2026', 'Charcoal#2026'),
        isNull,
      );
    });

    test('checkPasswordRequirements reports live status flags accurately', () {
      final partial = Validators.checkPasswordRequirements(
        'char',
        confirmPassword: 'char',
      );
      expect(partial.hasMinLength, isFalse);
      expect(partial.hasMaxLength, isTrue);
      expect(partial.hasUppercase, isFalse);
      expect(partial.hasNumber, isFalse);
      expect(partial.hasSpecialChar, isFalse);
      expect(partial.passwordsMatch, isTrue);
      expect(partial.allMet, isFalse);
      expect(partial.allMetWithConfirm, isFalse);

      final strongMismatch = Validators.checkPasswordRequirements(
        'Charcoal#2026',
        confirmPassword: 'Charcoal#2025',
      );
      expect(strongMismatch.allMet, isTrue);
      expect(strongMismatch.passwordsMatch, isFalse);
      expect(strongMismatch.allMetWithConfirm, isFalse);

      final full = Validators.checkPasswordRequirements(
        'Charcoal#2026',
        confirmPassword: 'Charcoal#2026',
      );
      expect(full.hasMinLength, isTrue);
      expect(full.hasMaxLength, isTrue);
      expect(full.hasUppercase, isTrue);
      expect(full.hasNumber, isTrue);
      expect(full.hasSpecialChar, isTrue);
      expect(full.passwordsMatch, isTrue);
      expect(full.allMet, isTrue);
      expect(full.allMetWithConfirm, isTrue);
    });

    test('validateAddress checks min and max lengths', () {
      expect(Validators.validateAddress('Manila'), isNotNull);
      expect(Validators.validateAddress('Brgy 4 Sampaloc Manila near Bakery'), isNull);
    });

    test('validateOrderQuantity enforces stock bounds', () {
      expect(Validators.validateOrderQuantity(1, 0), isNotNull);
      expect(Validators.validateOrderQuantity(0, 10), isNotNull);
      expect(Validators.validateOrderQuantity(11, 10), isNotNull);
      expect(Validators.validateOrderQuantity(5, 10), isNull);
    });
  });
}
