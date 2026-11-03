// lib/data/models/map_position.dart
// Posisi POI pada gambar denah, relatif 0-1 (0,0 = kiri atas).

import 'dart:math' as math;

import '../../core/utils/json_utils.dart';

class MapPosition {
  const MapPosition({required this.x, required this.y});

  final double x;
  final double y;

  bool get isValid => x >= 0 && x <= 1 && y >= 0 && y <= 1;

  /// Jarak relatif di denah (untuk rekomendasi POI terdekat).
  double distanceTo(MapPosition other) =>
      math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));

  factory MapPosition.fromJson(Map<String, dynamic> json) => MapPosition(
        x: readDouble(json, 'x', context: 'mapPosition'),
        y: readDouble(json, 'y', context: 'mapPosition'),
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  MapPosition copyWith({double? x, double? y}) =>
      MapPosition(x: x ?? this.x, y: y ?? this.y);

  @override
  bool operator ==(Object other) =>
      other is MapPosition && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
