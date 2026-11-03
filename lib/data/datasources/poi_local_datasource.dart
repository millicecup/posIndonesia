// lib/data/datasources/poi_local_datasource.dart
// Membaca & mem-parse assets/data/pois.json (PIC: Matilda).

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../models/poi.dart';

class PoiLocalDataSource {
  PoiLocalDataSource({
    AssetBundle? bundle,
    this.assetPath = AppConstants.poiDatasetPath,
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  /// Membaca file JSON dari assets lalu parse menjadi list Poi.
  Future<List<Poi>> loadPois() async {
    final String raw;
    try {
      raw = await _bundle.loadString(assetPath);
    } catch (e) {
      AppLogger.error(AppConstants.logTagData, 'Gagal membaca $assetPath', e);
      throw DataLoadException('File dataset $assetPath tidak dapat dibaca',
          cause: e);
    }
    final pois = parsePois(raw);
    AppLogger.info(
        AppConstants.logTagData, '${pois.length} POI dimuat dari $assetPath');
    return pois;
  }

  /// Parse string JSON. Dibuat static agar mudah di-unit-test.
  static List<Poi> parsePois(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw DataParseException('pois.json bukan JSON yang valid', cause: e);
    }

    // Mendukung format {"pois": [...]} maupun langsung [...]
    final List<dynamic> list;
    if (decoded is Map<String, dynamic> && decoded['pois'] is List) {
      list = decoded['pois'] as List<dynamic>;
    } else if (decoded is List) {
      list = decoded;
    } else {
      throw const DataParseException(
          'Struktur pois.json harus berupa {"pois": [...]} atau [...]');
    }

    final result = <Poi>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map<String, dynamic>) {
        throw DataParseException('Item ke-$i pada pois.json bukan objek');
      }
      try {
        result.add(Poi.fromJson(item));
      } on DataParseException {
        rethrow;
      } catch (e) {
        throw DataParseException('Gagal parse POI ke-$i', cause: e);
      }
    }
    result.sort((a, b) => a.tourOrder.compareTo(b.tourOrder));
    return List.unmodifiable(result);
  }
}
