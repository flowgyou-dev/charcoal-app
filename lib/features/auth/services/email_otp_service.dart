import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';

class OtpChallengeResult {
  final String token;
  final int expiresInSeconds;

  const OtpChallengeResult({
    required this.token,
    required this.expiresInSeconds,
  });
}

class EmailOtpService {
  static Uri _endpoint(String path) {
    final base = AppConstants.otpApiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  /// Sends a 6-digit verification code to [email] and returns the signed session token.
  static Future<OtpChallengeResult> sendVerificationCode({
    required String email,
    required String name,
  }) async {
    final response = await http
        .post(
          _endpoint('/send-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'name': name.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = _decodeJson(response.body);
    if (response.statusCode != 200 || body['ok'] != true) {
      final errMsg = body['error']?.toString() ??
          'Unable to send verification code (HTTP ${response.statusCode}).';
      throw Exception(errMsg);
    }

    return OtpChallengeResult(
      token: body['token']?.toString() ?? '',
      expiresInSeconds: int.tryParse(body['expiresInSeconds']?.toString() ?? '') ?? 600,
    );
  }

  /// Verifies the user-submitted 6-digit [code] against the signed [token].
  static Future<bool> verifyCode({
    required String email,
    required String code,
    required String token,
  }) async {
    final response = await http
        .post(
          _endpoint('/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'code': code.trim(),
            'token': token,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = _decodeJson(response.body);
    if (response.statusCode != 200 || body['verified'] != true) {
      final errMsg = body['error']?.toString() ??
          'Verification failed (HTTP ${response.statusCode}).';
      throw Exception(errMsg);
    }
    return true;
  }

  static Map<String, dynamic> _decodeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
}
