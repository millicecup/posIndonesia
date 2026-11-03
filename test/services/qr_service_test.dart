// test/services/qr_service_test.dart
// Uji validasi QR (fallback F02).

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/services/qr_service.dart';

import '../helpers/test_data.dart';

void main() {
  final qr = QrService(buildRepository());

  test('QR valid mengembalikan POI yang benar', () async {
    final result = await qr.validate('QR-P07');
    expect(result, isA<QrValid>());
    expect((result as QrValid).poi.id, 'P07');
  });

  test('QR huruf kecil / berupa URL tetap dikenali', () async {
    expect(await qr.validate(' qr-p02 '), isA<QrValid>());
    final fromUrl = await qr.validate('https://jejakpos.example/scan/QR-P12');
    expect((fromUrl as QrValid).poi.id, 'P12');
  });

  test('format salah -> QrInvalidFormat', () async {
    expect(await qr.validate('HALO'), isA<QrInvalidFormat>());
    expect(await qr.validate(''), isA<QrInvalidFormat>());
  });

  test('kode beacon tidak diterima sebagai QR', () async {
    expect(await qr.validate('BCN-P01'), isA<QrInvalidFormat>());
  });

  test('format benar tapi tidak terdaftar -> QrNotFound', () async {
    expect(await qr.validate('QR-P99'), isA<QrNotFound>());
  });
}
