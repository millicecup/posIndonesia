// test/features/random_stamp_test.dart
// P11 Stempel Museum: perangko digital acak (kreasi tim). Desain tetap untuk seed yang sama,
// seed disimpan sekali dan ikut terhapus saat progres direset.

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/data/datasources/progress_local_datasource.dart';
import 'package:jejakpos/shared/widgets/random_stamp_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_data.dart';

void main() {
  test('P11 memakai perangko acak, POI lain tidak', () {
    for (final p in loadDataset()) {
      expect(p.stamp.isRandom, p.id == 'P11', reason: p.id);
    }
  });

  test('desain acak deterministik per seed dan bervariasi antar seed', () {
    final a = RandomStampDesign.fromSeed(42);
    final b = RandomStampDesign.fromSeed(42);
    expect(a.motifName, b.motifName);
    expect(a.background, b.background);
    expect(a.value, b.value);
    final designs = {
      for (var s = 0; s < 50; s++) RandomStampDesign.fromSeed(s).motifName,
    };
    expect(designs.length, greaterThan(1));
  });

  test('seed tersimpan lalu terhapus saat progres direset', () async {
    SharedPreferences.setMockInitialValues({});
    final local = ProgressLocalDataSource(await SharedPreferences.getInstance());
    expect(local.readRandomStampSeed(), isNull);
    await local.writeRandomStampSeed(1234);
    expect(local.readRandomStampSeed(), 1234);
    await local.clear();
    expect(local.readRandomStampSeed(), isNull);
  });
}
