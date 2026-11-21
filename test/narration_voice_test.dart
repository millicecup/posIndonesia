// Pemandu suara harus selalu memakai suara bahasa Indonesia, bukan suara default HP.

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/services/narration_service.dart';

void main() {
  test('memilih suara Indonesia, utamakan yang offline', () {
    final voice = pickIndonesianVoice([
      {'name': 'en-us-x-sfg-local', 'locale': 'en-US'},
      {'name': 'id-id-x-ide-network', 'locale': 'id-ID'},
      {'name': 'id-id-x-dfz-local', 'locale': 'id-ID'},
    ]);
    expect(voice, {'name': 'id-id-x-dfz-local', 'locale': 'id-ID'});
  });

  test('mengenali kode lama in-ID / ind-IDN', () {
    expect(pickIndonesianVoice([
      {'name': 'a', 'locale': 'in_ID'}
    ])?['name'], 'a');
    expect(pickIndonesianVoice([
      {'name': 'b', 'locale': 'ind-IDN'}
    ])?['name'], 'b');
  });

  test('null bila tidak ada suara Indonesia (tidak jatuh ke Inggris diam-diam)', () {
    expect(
        pickIndonesianVoice([
          {'name': 'en', 'locale': 'en-US'},
          {'name': 'india', 'locale': 'hi-IN'},
        ]),
        isNull);
    expect(pickIndonesianVoice(null), isNull);
  });
}
