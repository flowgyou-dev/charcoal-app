import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/shop_settings_model.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final bool isEstimated;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    this.isEstimated = false,
  });
}

class NominatimPlace {
  final String displayName;
  final LatLng location;

  const NominatimPlace({
    required this.displayName,
    required this.location,
  });
}

class RoutingService {
  static const Map<String, String> _headers = {
    'User-Agent': 'CharCoalExpressApp/1.0',
    'Accept': 'application/json',
  };

  /// Fetches real driving route polyline, road distance, and ETA via public OSRM API.
  /// Falls back gracefully to straight-line Haversine estimate when offline or unreachable.
  static Future<RouteResult> getDrivingRoute(LatLng from, LatLng to) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 7));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (data['code'] == 'Ok' && routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final coords = (route['geometry']['coordinates'] as List<dynamic>)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          final distanceKm = ((route['distance'] as num).toDouble()) / 1000.0;
          final durationMin = (((route['duration'] as num).toDouble()) / 60.0).round().clamp(1, 999);
          return RouteResult(
            points: coords,
            distanceKm: distanceKm,
            durationMinutes: durationMin,
            isEstimated: false,
          );
        }
      }
    } catch (_) {
      // Fallback below
    }

    final distKm = ShopSettings.calculateHaversineKm(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    return RouteResult(
      points: [from, to],
      distanceKm: distKm,
      durationMinutes: ((distKm / 25.0) * 60).round().clamp(1, 999),
      isEstimated: true,
    );
  }

  /// Forward-geocodes a Philippine address via OpenStreetMap Nominatim.
  static Future<List<NominatimPlace>> searchAddress(String query) async {
    final clean = query.trim();
    if (clean.length < 3) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&limit=5&countrycodes=ph&q=${Uri.encodeComponent(clean)}',
      );
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((item) => NominatimPlace(
                  displayName: item['display_name']?.toString() ?? '',
                  location: LatLng(
                    double.parse(item['lat'].toString()),
                    double.parse(item['lon'].toString()),
                  ),
                ))
            .where((p) => p.displayName.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Non-fatal
    }
    return [];
  }

  /// Reverse-geocodes coordinates into a readable street/barangay address string.
  static Future<String?> reverseGeocode(LatLng pos) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1',
      );
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final display = data['display_name']?.toString();
        if (display != null && display.trim().isNotEmpty) {
          return display.length > 180 ? display.substring(0, 180) : display;
        }
      }
    } catch (_) {
      // Non-fatal
    }
    return null;
  }
}
