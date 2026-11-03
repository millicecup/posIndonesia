// test/helpers/test_data.dart
// Helper: membaca pois.json langsung dari disk agar test tidak butuh AssetBundle.

import 'dart:io';

import 'package:jejakpos/data/datasources/poi_local_datasource.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/data/repositories/poi_repository_impl.dart';

String readDatasetJson() => File('assets/data/pois.json').readAsStringSync();

List<Poi> loadDataset() => PoiLocalDataSource.parsePois(readDatasetJson());

class FileDataSource extends PoiLocalDataSource {
  FileDataSource([this.raw]);
  final String? raw;

  @override
  Future<List<Poi>> loadPois() async =>
      PoiLocalDataSource.parsePois(raw ?? readDatasetJson());
}

PoiRepositoryImpl buildRepository([String? raw]) => PoiRepositoryImpl(
      FileDataSource(raw),
      assetExists: (path) async => File(path).existsSync(),
    );
