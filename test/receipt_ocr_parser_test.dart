import 'package:flutter_test/flutter_test.dart';
import 'package:charcoal_app/features/order/services/receipt_ocr_service.dart';

void main() {
  group('ReceiptOcrParser', () {
    test('extracts GCash reference number and amount', () {
      const sample = '''
        GCash
        Successfully Sent!
        Amount PHP 540.00
        Ref No. 9012 345 678912
        Date: Nov 11, 2026
      ''';

      final result = ReceiptOcrParser.parseText(sample);
      expect(result.hasValidRef, isTrue);
      expect(result.refNumber, isNotNull);
      expect(
        ReceiptOcrParser.normalizeRefKey(result.refNumber!),
        contains('9012345678912'),
      );
      expect(result.detectedAmount, closeTo(540.0, 0.01));
    });

    test('extracts Maya / InstaPay alphanumeric reference number', () {
      const sample = '''
        Maya Bank Transfer
        Total Amount: ₱1,250.50
        Reference ID: AB12CD345678
      ''';

      final result = ReceiptOcrParser.parseText(sample);
      expect(result.hasValidRef, isTrue);
      expect(
        ReceiptOcrParser.normalizeRefKey(result.refNumber!),
        'AB12CD345678',
      );
      expect(result.detectedAmount, closeTo(1250.50, 0.01));
    });

    test('returns invalid ref when receipt has no reference number', () {
      const sample = '''
        Thank you for shopping!
        Cash Received: PHP 250.00
      ''';

      final result = ReceiptOcrParser.parseText(sample);
      expect(result.hasValidRef, isFalse);
      expect(result.refNumber, isNull);
    });

    test('normalizeRefKey strips spaces/symbols while uppercasing valid key chars', () {
      expect(
        ReceiptOcrParser.normalizeRefKey('ref-9012 345#abc'),
        'REF-9012345ABC',
      );
    });
  });
}
