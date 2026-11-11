import 'package:flutter_test/flutter_test.dart';
import 'package:charcoal_app/core/models/shop_settings_model.dart';

void main() {
  group('ShopSettings delivery fee & distance calculations', () {
    test('calculates flat delivery fee when mode is flat', () {
      final settings = ShopSettings(
        hubName: 'Main Hub',
        hubLat: 14.5995,
        hubLng: 120.9842,
        deliveryFeeMode: 'flat',
        flatDeliveryFee: 45.0,
        distanceBaseFee: 30.0,
        distancePerKm: 12.0,
        paymentQrImage: '',
        paymentAccountName: '',
        paymentAccountNumber: '',
      );

      final fee = settings.calculateDeliveryFee(
        destLat: 14.6500,
        destLng: 121.0500,
      );
      expect(fee, 45.0);
    });

    test('calculates distance-based fee when mode is distance', () {
      final settings = ShopSettings(
        hubName: 'Main Hub',
        hubLat: 14.5995,
        hubLng: 120.9842,
        deliveryFeeMode: 'distance',
        flatDeliveryFee: 0.0,
        distanceBaseFee: 30.0,
        distancePerKm: 10.0,
        paymentQrImage: '',
        paymentAccountName: '',
        paymentAccountNumber: '',
      );

      final distKm = settings.distanceFromHubKm(14.6500, 121.0500);
      expect(distKm, greaterThan(5.0));

      final fee = settings.calculateDeliveryFee(
        destLat: 14.6500,
        destLng: 121.0500,
      );
      expect(fee, greaterThan(30.0));
      expect(fee, closeTo(30.0 + distKm * 10.0, 2.0));
    });

    test('haversine distance for identical coordinates is zero', () {
      final d = ShopSettings.calculateHaversineKm(14.5995, 120.9842, 14.5995, 120.9842);
      expect(d, 0.0);
    });
  });
}
