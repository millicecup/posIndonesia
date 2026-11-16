// lib/features/photo_studio/widgets/uniform_overlay.dart
// Overlay seragam petugas pos 2D untuk Photo Studio (F08, NG04).
// Ilustrasi generik buatan sendiri (PRD R3): warna & bentuk tidak meniru seragam resmi.
// Ganti dengan aset resmi museum setelah izin penggunaan materi didapat (PB06).

import 'package:flutter/material.dart';

enum UniformTemplate {
  masa1('Masa 1', Color(0xFF8D7B55), Color(0xFF6B5B3A), Color(0xFFE0C068)),
  masa2('Masa 2', Color(0xFF2F4A6D), Color(0xFF1F3350), Color(0xFFE8E8E8)),
  masa3('Masa 3', Color(0xFFF26522), Color(0xFFC94E12), Color(0xFF333333));

  const UniformTemplate(this.label, this.main, this.dark, this.accent);

  final String label;
  final Color main;
  final Color dark;
  final Color accent;
}

class UniformCap extends StatelessWidget {
  const UniformCap({super.key, required this.template});
  final UniformTemplate template;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CapPainter(template), size: Size.infinite);
}

class UniformBody extends StatelessWidget {
  const UniformBody({super.key, required this.template});
  final UniformTemplate template;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BodyPainter(template), size: Size.infinite);
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

class _CapPainter extends CustomPainter {
  _CapPainter(this.t);
  final UniformTemplate t;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final line = Paint()
      ..color = t.dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .02;
    // Mahkota topi
    final crown = Path()
      ..moveTo(w * .12, h * .72)
      ..quadraticBezierTo(w * .08, h * .05, w * .5, h * .04)
      ..quadraticBezierTo(w * .92, h * .05, w * .88, h * .72)
      ..close();
    canvas.drawPath(crown, Paint()..color = t.main);
    canvas.drawPath(crown, line);
    // Pita
    canvas.drawRect(Rect.fromLTWH(w * .12, h * .56, w * .76, h * .14), Paint()..color = t.dark);
    // Lencana
    canvas.drawCircle(Offset(w * .5, h * .38), w * .07, Paint()..color = t.accent);
    canvas.drawCircle(Offset(w * .5, h * .38), w * .07, line);
    // Pet (visor)
    final visor = Path()
      ..moveTo(w * .1, h * .7)
      ..quadraticBezierTo(w * .5, h * 1.0, w * .9, h * .7)
      ..quadraticBezierTo(w * .5, h * .82, w * .1, h * .7)
      ..close();
    canvas.drawPath(visor, Paint()..color = const Color(0xFF222222));
  }

  @override
  bool shouldRepaint(covariant _CapPainter old) => old.t != t;
}

class _BodyPainter extends CustomPainter {
  _BodyPainter(this.t);
  final UniformTemplate t;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final line = Paint()
      ..color = t.dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .008;
    // Bahu & badan
    final body = Path()
      ..moveTo(w * .02, h)
      ..lineTo(w * .06, h * .3)
      ..quadraticBezierTo(w * .1, h * .1, w * .32, h * .06)
      ..lineTo(w * .42, h * .02)
      ..lineTo(w * .5, h * .3)
      ..lineTo(w * .58, h * .02)
      ..lineTo(w * .68, h * .06)
      ..quadraticBezierTo(w * .9, h * .1, w * .94, h * .3)
      ..lineTo(w * .98, h)
      ..close();
    canvas.drawPath(body, Paint()..color = t.main);
    canvas.drawPath(body, line);
    // Kerah kiri & kanan
    final collarL = Path()
      ..moveTo(w * .42, h * .02)
      ..lineTo(w * .5, h * .3)
      ..lineTo(w * .36, h * .32)
      ..lineTo(w * .32, h * .06)
      ..close();
    final collarR = Path()
      ..moveTo(w * .58, h * .02)
      ..lineTo(w * .5, h * .3)
      ..lineTo(w * .64, h * .32)
      ..lineTo(w * .68, h * .06)
      ..close();
    final collarPaint = Paint()..color = t.dark;
    canvas.drawPath(collarL, collarPaint);
    canvas.drawPath(collarR, collarPaint);
    // Kancing
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(w * .5, h * (.45 + i * .18)), w * .012, Paint()..color = t.accent);
    }
    // Saku & lencana dada
    final pocket = Rect.fromLTWH(w * .2, h * .45, w * .16, h * .18);
    canvas.drawRect(pocket, line);
    canvas.drawRect(Rect.fromLTWH(w * .64, h * .42, w * .14, h * .07), Paint()..color = t.accent);
    // Tanda pundak
    canvas.drawRect(Rect.fromLTWH(w * .12, h * .14, w * .14, h * .05), Paint()..color = t.accent);
    canvas.drawRect(Rect.fromLTWH(w * .74, h * .14, w * .14, h * .05), Paint()..color = t.accent);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) => old.t != t;
}
