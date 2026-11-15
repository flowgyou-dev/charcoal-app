import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:charcoal_app/main.dart';

void main() {
  test('setupAppErrorHandling registers FlutterError and PlatformDispatcher error handlers', () {
    setupAppErrorHandling();

    // Verify PlatformDispatcher.instance.onError is installed and returns true to mark handled
    final errorHandler = PlatformDispatcher.instance.onError;
    expect(errorHandler, isNotNull);

    final handled = errorHandler!(Exception('Simulated runtime error'), StackTrace.current);
    expect(handled, isTrue);

    // Verify FlutterError.onError is installed
    expect(FlutterError.onError, isNotNull);
  });
}
