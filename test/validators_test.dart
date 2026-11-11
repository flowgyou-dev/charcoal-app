import 'package:flutter_test/flutter_test.dart';
import 'package:charcoal_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('sanitizeText strips HTML tags, quotes, and trims whitespace', () {
      expect(
        Validators.sanitizeText('  <script>Juan\'s "Charcoal"</script>  '),
        'scriptJuans Charcoal/script',
      );
    });

    test('validateEmail rejects invalid formats and accepts valid emails', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail('user@charcoal.ph'), isNull);
    });

    test('validatePhPhone enforces PH mobile format', () {
      expect(Validators.validatePhPhone('12345'), isNotNull);
      expect(Validators.validatePhPhone('0917-123-4567'), isNull);
      expect(Validators.validatePhPhone('+639171234567'), isNull);
    });

    test('validateStrongPassword requires length, uppercase, number, and symbol', () {
      expect(Validators.validateStrongPassword('short1!'), isNotNull);
      expect(Validators.validateStrongPassword('nouppercase1!'), isNotNull);
      expect(Validators.validateStrongPassword('NoNumber!'), isNotNull);
      expect(Validators.validateStrongPassword('NoSymbol123'), isNotNull);
      expect(Validators.validateStrongPassword('Charcoal#2026'), isNull);
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
