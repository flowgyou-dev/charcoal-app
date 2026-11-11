import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptParseResult {
  final String? refNumber;
  final double? detectedAmount;
  final String rawText;

  const ReceiptParseResult({
    this.refNumber,
    this.detectedAmount,
    required this.rawText,
  });

  bool get hasValidRef => refNumber != null && refNumber!.length >= 4;
}

class ReceiptScanResult {
  final String imageBase64DataUrl;
  final String refNumber;
  final double? detectedAmount;
  final String rawSnippet;

  const ReceiptScanResult({
    required this.imageBase64DataUrl,
    required this.refNumber,
    this.detectedAmount,
    required this.rawSnippet,
  });
}

class ReceiptOcrParser {
  static String normalizeRefKey(String refNumber) {
    return refNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '').toUpperCase();
  }

  /// Parses Philippine e-wallet / bank receipt text (GCash, Maya, InstaPay, QRPH)
  /// to extract the Reference / Transaction Number and detected PHP Amount.
  static ReceiptParseResult parseText(String rawText) {
    final normalized = rawText.replaceAll('\r', '\n');

    String? extractedRef;

    // 1. Explicit labeled Ref / Reference / Trace / Transaction ID lines
    final labelPatterns = [
      RegExp(
        r'(?:ref(?:erence)?\.?\s*(?:no\.?|number|id|#)?|trace\s*(?:no\.?|number|#)?|transaction\s*(?:id|no\.?|number)|approval\s*(?:code|no\.?)|retrieval\s*ref)\s*[:\-]?\s*([A-Z0-9][A-Z0-9\s\-]{4,28})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in labelPatterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) {
        final rawGroup = match.group(1) ?? '';
        // Stop at newline if multiple lines matched, strip whitespace/hyphens inside ref
        final firstLine = rawGroup.split('\n').first.trim();
        final compact = firstLine.replaceAll(RegExp(r'[\s\-]+'), '').toUpperCase();
        // Keep leading alphanumeric chunk with at least 6 chars and mostly digits/alphanum
        final tokenMatch = RegExp(r'^([A-Z0-9]{6,24})').firstMatch(compact);
        if (tokenMatch != null && RegExp(r'\d').hasMatch(tokenMatch.group(1)!)) {
          extractedRef = tokenMatch.group(1);
          break;
        }
      }
    }

    // 2. Fallback: look for standard GCash 13-digit grouped reference (e.g. 9012 345 678901 or 13 digits)
    if (extractedRef == null) {
      final spacedDigits = RegExp(r'\b(\d{4}[\s\-]?\d{3}[\s\-]?\d{6})\b').firstMatch(normalized);
      if (spacedDigits != null) {
        extractedRef = spacedDigits.group(1)!.replaceAll(RegExp(r'[\s\-]'), '');
      }
    }

    if (extractedRef == null) {
      final longNum = RegExp(r'\b(\d{9,16})\b').firstMatch(normalized);
      if (longNum != null) {
        final candidate = longNum.group(1)!;
        // Skip typical PH mobile numbers starting with 09 (11 digits) if better matches don't exist
        if (!(candidate.startsWith('09') && candidate.length == 11)) {
          extractedRef = candidate;
        }
      }
    }

    // 3. Extract PHP / Peso amount (prefer labeled total/amount lines first)
    double? detectedAmount;
    final amountLabelPattern = RegExp(
      r'(?:total\s*amount(?:\s*sent)?|amount\s*(?:paid|sent|due)?|you\s*sent|total)\s*[:\-]?\s*(?:PHP|Php|₱|P)?\s*([\d,]+\.\d{2})',
      caseSensitive: false,
    );
    final labeledAmt = amountLabelPattern.firstMatch(normalized);
    if (labeledAmt != null) {
      detectedAmount = double.tryParse(labeledAmt.group(1)!.replaceAll(',', ''));
    }

    if (detectedAmount == null) {
      final currencyPattern = RegExp(
        r'(?:PHP|Php|₱)\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      );
      final amtMatch = currencyPattern.firstMatch(normalized);
      if (amtMatch != null) {
        detectedAmount = double.tryParse(amtMatch.group(1)!.replaceAll(',', ''));
      }
    }

    return ReceiptParseResult(
      refNumber: extractedRef,
      detectedAmount: detectedAmount,
      rawText: normalized,
    );
  }
}

class ReceiptOcrService {
  static final ImagePicker _picker = ImagePicker();

  /// Lets customer pick/capture a receipt, compresses it for RTDB, and scans text via on-device ML Kit OCR.
  static Future<ReceiptScanResult?> pickAndScanReceipt(ImageSource source) async {
    if (kIsWeb) {
      throw Exception(
        'On-device OCR scanning is only supported on Android/iOS mobile devices. Use COD when testing in Chrome.',
      );
    }
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 65,
    );
    if (file == null) return null;

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.length > 320 * 1024) {
      throw Exception('Receipt image is too large (${(bytes.length / 1024).round()} KB). Please upload a clearer cropped screenshot.');
    }

    final inputImage = InputImage.fromFilePath(file.path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(inputImage);
      final parsed = ReceiptOcrParser.parseText(recognized.text);
      if (!parsed.hasValidRef) {
        throw Exception(
          'Hindi mabasa ng OCR ang Reference Number sa receipt. Siguraduhing malinaw at kita ang Ref No. sa screenshot at subukan muli.',
        );
      }

      final base64Str = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Str';
      final snippet = recognized.text.replaceAll('\n', ' ').trim();

      return ReceiptScanResult(
        imageBase64DataUrl: dataUrl,
        refNumber: parsed.refNumber!,
        detectedAmount: parsed.detectedAmount,
        rawSnippet: snippet.length > 180 ? snippet.substring(0, 180) : snippet,
      );
    } finally {
      await recognizer.close();
    }
  }
}
