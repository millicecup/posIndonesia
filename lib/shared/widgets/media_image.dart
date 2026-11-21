// lib/shared/widgets/media_image.dart
// Foto POI dari aset APK atau cache; placeholder jika belum tersedia.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/providers.dart';
import '../../services/media_service.dart';

class MediaImage extends ConsumerWidget {
  const MediaImage(
    this.path, {
    super.key,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.download = true,
  });

  final String path;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  /// false = tidak mengunduh sendiri. Dipakai di daftar POI agar membuka
  /// daftar tidak menghabiskan kuota transfer Hosting.
  final bool download;

  Widget _placeholder(IconData icon) => SizedBox(
        height: height,
        width: height,
        child: ColoredBox(color: AppColors.lightGrey, child: Icon(icon)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source =
        ref.watch(mediaSourceProvider((path: path, download: download)));
    return source.when(
      loading: () => _placeholder(Icons.image_outlined),
      error: (_, __) => _placeholder(Icons.broken_image),
      data: (media) => switch (media) {
        BundledMedia(:final assetPath) => Image.asset(
            assetPath,
            height: height,
            fit: fit,
            alignment: alignment,
            errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image),
          ),
        CachedMedia(:final file) => Image.file(
            file,
            height: height,
            fit: fit,
            alignment: alignment,
            errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image),
          ),
        RemoteMedia(:final uri) => Image.network(
            uri.toString(),
            height: height,
            fit: fit,
            alignment: alignment,
            errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image),
          ),
        null => _placeholder(Icons.cloud_download_outlined),
      },
    );
  }
}
