// lib/data/models/location_status.dart
// Status izin/layanan lokasi + posisi pengguna.

enum LocationStatus { unknown, granted, denied, deniedForever, serviceDisabled }

extension LocationStatusX on LocationStatus {
  String get label {
    switch (this) {
      case LocationStatus.granted:
        return 'Izin lokasi diberikan';
      case LocationStatus.denied:
        return 'Izin lokasi ditolak';
      case LocationStatus.deniedForever:
        return 'Izin lokasi ditolak permanen (buka Pengaturan)';
      case LocationStatus.serviceDisabled:
        return 'Layanan lokasi (GPS) nonaktif';
      case LocationStatus.unknown:
        return 'Status lokasi belum diperiksa';
    }
  }

  bool get isGranted => this == LocationStatus.granted;
}

/// Sumber posisi: GPS asli, simulasi debug, atau manual.
enum PositionSource { gps, simulation }

class UserPosition {
  const UserPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    this.source = PositionSource.gps,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;
  final PositionSource source;

  UserPosition copyWith({
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    DateTime? timestamp,
    PositionSource? source,
  }) =>
      UserPosition(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        accuracyMeters: accuracyMeters ?? this.accuracyMeters,
        timestamp: timestamp ?? this.timestamp,
        source: source ?? this.source,
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'timestamp': timestamp.toIso8601String(),
        'source': source.name,
      };

  factory UserPosition.fromJson(Map<String, dynamic> json) => UserPosition(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        source: PositionSource.values.byName(json['source'] as String),
      );

  @override
  String toString() =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)} '
      '(±${accuracyMeters.toStringAsFixed(1)} m, ${source.name})';
}
