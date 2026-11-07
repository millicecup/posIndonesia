// test/services/media_service_test.dart
// Memakai server HTTP lokal agar alur unduh diuji sungguhan, bukan tiruan.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/services/media_service.dart';

const _audio = 'assets/audio/p01_narasi.wav';
const _photo = 'assets/images/pois/p01_1.png';

void main() {
  late HttpServer server;
  late Directory cache;
  late List<String> requests;
  late Map<String, List<int>> hosted;

  MediaService buildService({
    String? baseUrl,
    Set<String> bundled = const {},
  }) {
    final service = MediaService(
      baseUrl: baseUrl ?? 'http://${server.address.host}:${server.port}/',
      isBundled: (path) async => bundled.contains(path),
      directory: () async => cache,
    );
    addTearDown(service.dispose);
    return service;
  }

  setUp(() async {
    requests = [];
    hosted = {};
    cache = await Directory.systemTemp.createTemp('jejakpos_media_');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      requests.add(path);
      final body = hosted[path];
      if (body == null) {
        request.response.statusCode = HttpStatus.notFound;
      } else {
        request.response.add(body);
      }
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await cache.delete(recursive: true);
  });

  test('remoteUri membuang prefix assets/ dan garis miring ganda', () {
    final service = buildService(baseUrl: 'https://demo.web.app/');
    expect(service.remoteUri(_audio).toString(),
        'https://demo.web.app/audio/p01_narasi.wav');
  });

  test('aset di APK dipakai tanpa request jaringan', () async {
    final service = buildService(bundled: {_audio});
    expect(await service.resolve(_audio), isA<BundledMedia>());
    expect(requests, isEmpty);
  });

  test('unduh sekali, berikutnya memakai cache', () async {
    hosted['/audio/p01_narasi.wav'] = [1, 2, 3];
    final service = buildService();

    final first = await service.resolve(_audio);
    expect(first, isA<CachedMedia>());
    expect(await (first! as CachedMedia).file.readAsBytes(), [1, 2, 3]);

    expect(await service.resolve(_audio), isA<CachedMedia>());
    expect(requests, hasLength(1));
  });

  test('download:false tidak menyentuh jaringan', () async {
    hosted['/audio/p01_narasi.wav'] = [1];
    final service = buildService();
    expect(await service.resolve(_audio, download: false), isNull);
    expect(requests, isEmpty);
  });

  test('HTTP 404 menghasilkan null dan tidak meninggalkan file', () async {
    final service = buildService();
    expect(await service.resolve(_audio), isNull);
    expect(cache.listSync(recursive: true).whereType<File>(), isEmpty);
  });

  test('tanpa baseUrl tidak mencoba mengunduh', () async {
    final service = buildService(baseUrl: '');
    expect(service.isRemoteEnabled, isFalse);
    expect(await service.resolve(_audio), isNull);
    expect(requests, isEmpty);
  });

  test('downloadAll melanjutkan file lain saat satu gagal', () async {
    hosted['/images/pois/p01_1.png'] = [9];
    final service = buildService();
    final progress = <int>[];

    final result = await service.downloadAll(
      [_audio, _photo],
      onProgress: (done, _) => progress.add(done),
    );

    expect(result.total, 2);
    expect(result.failed, [_audio]);
    expect(progress.last, 2);
    expect(await service.missing([_audio, _photo]), [_audio]);
  });

  test('downloadAll melewati file yang sudah tersedia', () async {
    hosted['/images/pois/p01_1.png'] = [9];
    final service = buildService(bundled: {_audio});

    await service.downloadAll([_audio, _photo]);
    final again = await service.downloadAll([_audio, _photo]);

    expect(again.total, 0);
    expect(requests, ['/images/pois/p01_1.png']);
  });
}
