import 'dart:math';
import '../constants/app_constants.dart';

class ShopSettings {
  final String hubName;
  final double hubLat;
  final double hubLng;
  final String deliveryFeeMode; // 'flat' | 'distance'
  final double flatDeliveryFee;
  final double distanceBaseFee;
  final double distancePerKm;
  final String paymentQrImage;
  final String paymentAccountName;
  final String paymentAccountNumber;

  const ShopSettings({
    this.hubName = 'Charcoal Central Warehouse',
    this.hubLat = AppConstants.defaultHubLat,
    this.hubLng = AppConstants.defaultHubLng,
    this.deliveryFeeMode = 'flat',
    this.flatDeliveryFee = 0,
    this.distanceBaseFee = 40,
    this.distancePerKm = 15,
    this.paymentQrImage = '',
    this.paymentAccountName = '',
    this.paymentAccountNumber = '',
  });

  bool get hasPaymentQr => paymentQrImage.trim().isNotEmpty;

  factory ShopSettings.fromMap(Map<dynamic, dynamic> map) {
    return ShopSettings(
      hubName: map['hubName']?.toString() ?? 'Charcoal Central Warehouse',
      hubLat: double.tryParse(map['hubLat']?.toString() ?? '') ?? AppConstants.defaultHubLat,
      hubLng: double.tryParse(map['hubLng']?.toString() ?? '') ?? AppConstants.defaultHubLng,
      deliveryFeeMode: map['deliveryFeeMode']?.toString() == 'distance' ? 'distance' : 'flat',
      flatDeliveryFee: double.tryParse(map['flatDeliveryFee']?.toString() ?? '0') ?? 0,
      distanceBaseFee: double.tryParse(map['distanceBaseFee']?.toString() ?? '40') ?? 40,
      distancePerKm: double.tryParse(map['distancePerKm']?.toString() ?? '15') ?? 15,
      paymentQrImage: map['paymentQrImage']?.toString() ?? '',
      paymentAccountName: map['paymentAccountName']?.toString() ?? '',
      paymentAccountNumber: map['paymentAccountNumber']?.toString() ?? '',
    );
  }

  /// Great-circle distance in kilometers from Hub to destination coordinates.
  double distanceFromHubKm(double destLat, double destLng) {
    return calculateHaversineKm(hubLat, hubLng, destLat, destLng);
  }

  /// Calculates rounded delivery fee in PHP based on Admin-configured mode.
  double calculateDeliveryFee({required double destLat, required double destLng}) {
    if (deliveryFeeMode == 'flat') {
      return flatDeliveryFee.roundToDouble();
    }
    final distKm = distanceFromHubKm(destLat, destLng);
    final raw = distanceBaseFee + (distKm * distancePerKm);
    return raw.roundToDouble();
  }

  static double calculateHaversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * pi / 180.0;
}
