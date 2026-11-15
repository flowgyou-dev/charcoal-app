import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LocalPrefsService {
  static const _channel = MethodChannel('com.coal.charcoal_app/device_utils');

  static const _keyRememberMe = 'customer_remember_me';
  static const _keyRememberedEmail = 'customer_remembered_email';

  static Future<bool> getRememberMe() async {
    try {
      final res = await _channel.invokeMethod<bool>('getPrefBool', {
        'key': _keyRememberMe,
        'defaultValue': true,
      });
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setRememberMe(bool value) async {
    try {
      await _channel.invokeMethod('setPrefBool', {
        'key': _keyRememberMe,
        'value': value,
      });
    } catch (e) {
      debugPrint('[LocalPrefsService] setRememberMe failed: $e');
    }
  }

  static Future<String> getRememberedEmail() async {
    try {
      final res = await _channel.invokeMethod<String>('getPrefString', {
        'key': _keyRememberedEmail,
      });
      return res ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> setRememberedEmail(String email) async {
    try {
      await _channel.invokeMethod('setPrefString', {
        'key': _keyRememberedEmail,
        'value': email.trim(),
      });
    } catch (e) {
      debugPrint('[LocalPrefsService] setRememberedEmail failed: $e');
    }
  }

  static Future<String> saveImageToGallery(Uint8List bytes, String fileName) async {
    final savedPath = await _channel.invokeMethod<String>('saveImageToGallery', {
      'bytes': bytes,
      'fileName': fileName,
    });
    return savedPath ?? 'Pictures/CharCoal/$fileName';
  }
}
