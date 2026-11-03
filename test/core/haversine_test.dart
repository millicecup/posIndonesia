// test/core/haversine_test.dart
// Uji rumus Haversine & bearing.

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/core/utils/haversine.dart';

void main() {
  test('jarak titik yang sama = 0', () {
    expect(haversineDistanceMeters(-6.9, 107.6, -6.9, 107.6), 0);
  });

  test('1 derajat bujur di khatulistiwa ~ 111.195 km', () {
    final d = haversineDistanceMeters(0, 0, 0, 1);
    expect(d, closeTo(111195, 5));
  });

  test('0.0001 derajat lintang ~ 11.1 m', () {
    final d = haversineDistanceMeters(-6.9023, 107.619, -6.9024, 107.619);
    expect(d, closeTo(11.12, 0.05));
  });

  test('simetris', () {
    final a = haversineDistanceMeters(-6.9023, 107.6190, -6.9026, 107.6205);
    final b = haversineDistanceMeters(-6.9026, 107.6205, -6.9023, 107.6190);
    expect(a, closeTo(b, 1e-9));
  });

  test('bearing & label arah', () {
    expect(bearingDegrees(0, 0, 1, 0), closeTo(0, 1e-6));
    expect(bearingDegrees(0, 0, 0, 1), closeTo(90, 1e-6));
    expect(compassLabel(0), 'utara');
    expect(compassLabel(90), 'timur');
    expect(compassLabel(200), 'selatan');
    expect(compassLabel(350), 'utara');
  });
}
