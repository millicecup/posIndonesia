// lib/services/media_service.dart
// Sumber audio & foto POI: aset APK -> cache di HP -> unduh dari Firebase Hosting.
// Tanpa SDK Firebase; file disajikan sebagai HTTPS biasa (lihat docs/MEDIA_HOSTING.md).

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';

sealed class MediaSource {
  const MediaSource();
}

/// File masih dibundel di APK.
class BundledMedia extends MediaSource {
  const BundledMedia(this.assetPath);
  final String assetPath;
}

/// File sudah tersimpan di HP.
class CachedMedia extends MediaSource {
  const CachedMedia(this.file);
  final File file;
}

class MediaDownloadResult {
  const MediaDownloadResult({required this.total, required this.failed});

  final int total;
  final List<String> failed;
}

typedef MediaAssetChecker = Future<bool> Function(String path);
typedef MediaDirectoryProvider = Future<Directory> Function();
typedef MediaProgressCallback = void Function(int done, int total);

class MediaService {
  MediaService({
    required String baseUrl,
    MediaAssetChecker? isBundled,
    MediaDirectoryProvider? directory,
    HttpClient? httpClient,
  })  : baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
        _isBundled = isBundled ?? _defaultIsBundled,
        _directory = directory ?? _defaultDirectory,
        _http = (httpClient ?? HttpClient())
          ..connectionTimeout = _networkTimeout;

  static const _networkTimeout = Duration(seconds: 20);
  static const _assetPrefix = 'assets/';

  final String baseUrl;
  final MediaAssetChecker _isBundled;
  final MediaDirectoryProvider _directory;
  final HttpClient _http;
  final Map<String, Future<File>> _inFlight = {};

  bool get isRemoteEnabled => baseUrl.isNotEmpty;

  /// `assets/audio/p01.wav` -> `<baseUrl>/audio/p01.wav` (folder Hosting = assets/).
  Uri remoteUri(String path) => Uri.parse('$baseUrl/${_relativePath(path)}');

  /// Mengembalikan null jika file tidak tersedia dan tidak bisa diunduh.
  Future<MediaSource?> resolve(String path, {bool download = true}) async {
    if (await _isBundled(path)) return BundledMedia(path);
    final file = await _fileFor(path);
    if (await file.exists()) return CachedMedia(file);
    if (!download || !isRemoteEnabled) return null;
    try {
      return CachedMedia(await _download(path));
    } on MediaException catch (e) {
      AppLogger.error(AppConstants.logTagMedia, e.message, e.cause);
      return null;
    }
  }

  /// File yang belum ada di APK maupun di cache.
  Future<List<String>> missing(Iterable<String> paths) async {
    final result = <String>[];
    for (final path in paths.toSet()) {
      if (await resolve(path, download: false) == null) result.add(path);
    }
    return result;
  }

  /// Mengunduh semua file yang belum tersedia. Satu file gagal tidak
  /// menghentikan file lain, jadi tombol bisa ditekan lagi untuk sisanya.
  Future<MediaDownloadResult> downloadAll(
    Iterable<String> paths, {
    MediaProgressCallback? onProgress,
  }) async {
    final queue = await missing(paths);
    final failed = <String>[];
    for (var i = 0; i < queue.length; i++) {
      onProgress?.call(i, queue.length);
      try {
        await _download(queue[i]);
      } on MediaException catch (e) {
        AppLogger.error(AppConstants.logTagMedia, e.message, e.cause);
        failed.add(queue[i]);
      }
    }
    onProgress?.call(queue.length, queue.length);
    return MediaDownloadResult(total: queue.length, failed: failed);
  }

  void dispose() => _http.close(force: true);

  Future<File> _download(String path) {
    if (!isRemoteEnabled) {
      return Future.error(MediaException('Alamat media belum diatur: $path'));
    }
    return _inFlight[path] ??= _fetch(path).whenComplete(() {
      // Blok, bukan arrow: remove() mengembalikan future ini sendiri, dan
      // whenComplete akan menunggunya selamanya jika nilainya dikembalikan.
      _inFlight.remove(path);
    });
  }

  Future<File> _fetch(String path) async {
    final target = await _fileFor(path);
    await target.parent.create(recursive: true);
    // Ditulis ke .part dulu agar unduhan terputus tidak dianggap file utuh.
    final part = File('${target.path}.part');
    final uri = remoteUri(path);
    try {
      final request = await _http.getUrl(uri);
      final response = await request.close().timeout(_networkTimeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw MediaException('Unduh $uri gagal: HTTP ${response.statusCode}');
      }
      await response.timeout(_networkTimeout).pipe(part.openWrite());
      final file = await part.rename(target.path);
      AppLogger.info(AppConstants.logTagMedia, 'Media diunduh: $path');
      return file;
    } catch (e) {
      if (await part.exists()) await part.delete();
      if (e is MediaException) rethrow;
      throw MediaException('Unduh $uri gagal', cause: e);
    }
  }

  Future<File> _fileFor(String path) async {
    final root = await _directory();
    return File('${root.path}/${_relativePath(path)}');
  }

  static String _relativePath(String path) => path.startsWith(_assetPrefix)
      ? path.substring(_assetPrefix.length)
      : path;

  // Manifest dipakai agar pengecekan tidak memuat seluruh isi file audio.
  static Future<Set<String>>? _manifest;

  static Future<bool> _defaultIsBundled(String path) async {
    _manifest ??= AssetManifest.loadFromAssetBundle(rootBundle)
        .then((m) => m.listAssets().toSet());
    return (await _manifest!).contains(path);
  }

  static Future<Directory> _defaultDirectory() async {
    // Support dir, bukan cache dir: Android boleh menghapus cache dir saat
    // ruang penuh, padahal konten ini sengaja diunduh untuk dipakai offline.
    final root = await getApplicationSupportDirectory();
    return Directory('${root.path}/media');
  }
}
