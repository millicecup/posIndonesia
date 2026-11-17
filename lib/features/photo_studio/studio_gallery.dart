import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';

final studioGalleryProvider = Provider<StudioGallery>((ref) => StudioGallery());

class StudioGallery {
  StudioGallery({bool? android})
      : _android = android ?? (!kIsWeb && Platform.isAndroid);

  final bool _android;
  static const _channel = MethodChannel('id.jejakpos/photo_gallery');

  Future<void> save(Uint8List png, String name) async {
    if (kIsWeb) {
      throw StateError('Simpan ke galeri tersedia di aplikasi Android.');
    }
    final allowed = await Gal.hasAccess(toAlbum: true) ||
        await Gal.requestAccess(toAlbum: true);
    if (!allowed) throw StateError('Izin menyimpan foto belum diberikan.');
    if (_android) {
      final uri = await _channel.invokeMethod<String>('savePng', {
        'bytes': png,
        'name': '$name.png',
      });
      if (uri == null || uri.isEmpty) {
        throw StateError('Galeri belum mengonfirmasi penyimpanan foto.');
      }
    } else {
      await Gal.putImageBytes(png, album: 'JejakPOS', name: name);
    }
  }

  Future<void> open() => Gal.open();
}
