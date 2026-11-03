// lib/data/models/poi_zone.dart
// Zona fisik POI di museum (kode + deskripsi area).

import '../../core/utils/json_utils.dart';

class PoiZone {
  const PoiZone({required this.code, required this.description});

  final String code;
  final String description;

  factory PoiZone.fromJson(Map<String, dynamic> json) => PoiZone(
        code: readRequired<String>(json, 'code', context: 'zone'),
        description: readRequired<String>(json, 'description', context: 'zone'),
      );

  Map<String, dynamic> toJson() => {'code': code, 'description': description};

  PoiZone copyWith({String? code, String? description}) => PoiZone(
        code: code ?? this.code,
        description: description ?? this.description,
      );

  String get label => 'Zona $code - $description';

  @override
  bool operator ==(Object other) =>
      other is PoiZone && other.code == code && other.description == description;

  @override
  int get hashCode => Object.hash(code, description);
}
