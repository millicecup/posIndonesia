// lib/features/map_navigation/state/map_state.dart
// State peta denah 2D (PIC: Farella/Firda).
// Denah memakai CrsSimple: koordinat peta = posisi relatif x,y (0-1) x ukuran denah.

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/map_position.dart';

/// Ukuran "dunia" peta (unit CrsSimple). Rasio sama dengan denah asli
/// (AppConstants.mapImageWidth x mapImageHeight, portrait).
/// Nilai kecil dipakai karena LatLng membatasi lat -90..90 dan lng -180..180.
const double kMapUnitHeight = 90;
const double kMapUnitWidth =
    kMapUnitHeight * AppConstants.mapImageWidth / AppConstants.mapImageHeight;

final LatLngBounds kMapBounds = LatLngBounds(
  const LatLng(0, 0),
  const LatLng(kMapUnitHeight, kMapUnitWidth),
);

/// mapPosition (0,0 = kiri atas) -> LatLng CrsSimple (lat naik ke atas).
LatLng mapPositionToLatLng(MapPosition p) =>
    LatLng((1 - p.y) * kMapUnitHeight, p.x * kMapUnitWidth);

/// POI yang sedang dipilih di peta.
final selectedMapPoiIdProvider = StateProvider<String?>((ref) => null);
