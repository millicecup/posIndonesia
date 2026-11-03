// lib/core/utils/haversine.dart
// Hitung jarak dua titik GPS dalam meter (rumus Haversine).

import 'dart:math' as math;

const double _earthRadiusMeters = 6371000;

double _toRadians(double degree) => degree * math.pi / 180;

/// Jarak (meter) antara (lat1,lng1) dan (lat2,lng2).
double haversineDistanceMeters(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return _earthRadiusMeters * c;
}

/// Arah (derajat 0-360, 0 = utara) dari titik 1 ke titik 2.
double bearingDegrees(double lat1, double lng1, double lat2, double lng2) {
  final phi1 = _toRadians(lat1);
  final phi2 = _toRadians(lat2);
  final dLng = _toRadians(lng2 - lng1);
  final y = math.sin(dLng) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dLng);
  final deg = math.atan2(y, x) * 180 / math.pi;
  return (deg + 360) % 360;
}

/// Label arah mata angin Bahasa Indonesia.
String compassLabel(double bearing) {
  const labels = [
    'utara', 'timur laut', 'timur', 'tenggara',
    'selatan', 'barat daya', 'barat', 'barat laut',
  ];
  final index = ((bearing + 22.5) % 360 ~/ 45);
  return labels[index];
}
