// lib/shared/widgets/random_stamp_art.dart
// Perangko digital acak untuk P11 Stempel Museum (kreasi tim JejakPOS, bukan desain resmi).
// Desain (warna, motif, nominal) ditentukan oleh [seed] yang disimpan saat perangko diambil,
// sehingga perangko yang sama selalu tampil sama di UI13, album, dan ringkasan.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class RandomStampDesign {
  const RandomStampDesign(this.background, this.ink, this.motif, this.motifName, this.value);

  final Color background;
  final Color ink;
  final IconData motif;
  final String motifName;
  final String value;

  static const _palettes = [
    (Color(0xFFF26522), Color(0xFFFFFFFF)),
    (Color(0xFF2F4A6D), Color(0xFFF5E6C8)),
    (Color(0xFF2E7D32), Color(0xFFFFFFFF)),
    (Color(0xFF8E2430), Color(0xFFF9E79F)),
    (Color(0xFF6A4C93), Color(0xFFFFFFFF)),
    (Color(0xFFF5E6C8), Color(0xFF5D4037)),
  ];

  static const _motifs = [
    (Icons.mail_outline, 'Surat'),
    (Icons.markunread_mailbox_outlined, 'Kotak Pos'),
    (Icons.local_shipping_outlined, 'Kiriman'),
    (Icons.train_outlined, 'Kereta Pos'),
    (Icons.pedal_bike, 'Sepeda Pos'),
    (Icons.museum_outlined, 'Museum'),
    (Icons.edit_note, 'Pena'),
    (Icons.public, 'Nusantara'),
  ];

  static const _values = ['500', '1000', '1500', '2000', '2500', '5000'];

  factory RandomStampDesign.fromSeed(int seed) {
    final r = math.Random(seed);
    final p = _palettes[r.nextInt(_palettes.length)];
    final m = _motifs[r.nextInt(_motifs.length)];
    return RandomStampDesign(p.$1, p.$2, m.$1, m.$2, _values[r.nextInt(_values.length)]);
  }
}

class RandomStampArt extends StatelessWidget {
  const RandomStampArt({super.key, required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final d = RandomStampDesign.fromSeed(seed);
    return LayoutBuilder(builder: (context, c) {
      final s = c.biggest.shortestSide;
      return Container(
        color: d.background,
        padding: EdgeInsets.all(s * .06),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: d.ink, width: s * .015)),
          child: Column(
            children: [
              SizedBox(height: s * .04),
              Text('MUSEUM POS',
                  style: TextStyle(
                      color: d.ink, fontSize: s * .085, fontWeight: FontWeight.w900)),
              Expanded(child: FittedBox(child: Icon(d.motif, color: d.ink))),
              Text(d.motifName,
                  style: TextStyle(color: d.ink, fontSize: s * .075)),
              Padding(
                padding: EdgeInsets.only(bottom: s * .03),
                child: Text('INDONESIA · Rp${d.value}',
                    style: TextStyle(
                        color: d.ink, fontSize: s * .07, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    });
  }
}
