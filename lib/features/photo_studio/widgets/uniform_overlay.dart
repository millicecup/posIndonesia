// lib/features/photo_studio/widgets/uniform_overlay.dart
// Overlay seragam petugas pos 2D untuk Photo Studio (F08, NG04).
// Gambar seragam dan topi (PNG transparan) dari repo content/poi-dataset POI004
// ("Photo Studio Seragam/Topi <warna>.png"), disimpan di assets/images/photo_studio/.

import 'package:flutter/material.dart';

enum UniformTemplate {
  coklatTua('Coklat Tua', 'coklat_tua', bodyAspect: 640 / 562, capAspect: 433 / 640),
  hijau('Hijau', 'hijau', bodyAspect: 608 / 640, capAspect: 431 / 640),
  khaki('Khaki', 'khaki', bodyAspect: 590 / 640, capAspect: 432 / 640);

  const UniformTemplate(this.label, this._key,
      {required this.bodyAspect, required this.capAspect});

  final String label;
  final String _key;

  /// Tinggi / lebar gambar (sudah dipotong rapat ke area tidak transparan).
  final double bodyAspect;
  final double capAspect;

  String get bodyAsset => 'assets/images/photo_studio/seragam_$_key.png';
  String get capAsset => 'assets/images/photo_studio/topi_$_key.png';
}

class UniformCap extends StatelessWidget {
  const UniformCap({super.key, required this.template});
  final UniformTemplate template;

  @override
  Widget build(BuildContext context) =>
      Image.asset(template.capAsset, fit: BoxFit.contain, gaplessPlayback: true);
}

class UniformBody extends StatelessWidget {
  const UniformBody({super.key, required this.template});
  final UniformTemplate template;

  @override
  Widget build(BuildContext context) =>
      Image.asset(template.bodyAsset, fit: BoxFit.contain, gaplessPlayback: true);
}

/// Pratinjau kecil template (topi + seragam) untuk pemilih template.
class UniformThumbnail extends StatelessWidget {
  const UniformThumbnail({super.key, required this.template});
  final UniformTemplate template;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(flex: 2, child: UniformCap(template: template)),
          Expanded(flex: 3, child: UniformBody(template: template)),
        ],
      );
}
