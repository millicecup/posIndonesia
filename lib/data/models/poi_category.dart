// lib/data/models/poi_category.dart
// Kategori POI (misal "Koleksi Museum"). Setara jika id sama.

import '../../core/utils/json_utils.dart';

class PoiCategory {
  const PoiCategory({required this.id, required this.label});

  final String id;
  final String label;

  factory PoiCategory.fromJson(Map<String, dynamic> json) => PoiCategory(
        id: readRequired<String>(json, 'id', context: 'category'),
        label: readRequired<String>(json, 'label', context: 'category'),
      );

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  PoiCategory copyWith({String? id, String? label}) =>
      PoiCategory(id: id ?? this.id, label: label ?? this.label);

  @override
  bool operator ==(Object other) => other is PoiCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PoiCategory($id, $label)';
}
