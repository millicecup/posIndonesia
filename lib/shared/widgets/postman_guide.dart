// lib/shared/widgets/postman_guide.dart
// Karakter pemandu petugas pos 2D (F07, UI01/UI08/UI09). Digambar dengan kode
// (ilustrasi buatan sendiri, bukan aset museum - PRD R3). Bukan avatar 3D (NG03).

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class PostmanGuide extends StatelessWidget {
  const PostmanGuide({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size * 1.15,
        child: CustomPaint(painter: _PostmanPainter()),
      );
}

class _PostmanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = Paint()
      ..color = AppColors.darkGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeJoin = StrokeJoin.round;
    Paint fill(Color c) => Paint()..color = c;

    // Bayangan
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * .5, h * .96), width: w * .6, height: h * .05),
        fill(AppColors.lightGrey));

    // Badan (seragam)
    final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .26, h * .52, w * .48, h * .42), Radius.circular(w * .1));
    canvas.drawRRect(body, fill(const Color(0xFFD6D9DE)));
    canvas.drawRRect(body, outline);
    // Kerah
    final collar = Path()
      ..moveTo(w * .4, h * .52)
      ..lineTo(w * .5, h * .62)
      ..lineTo(w * .6, h * .52);
    canvas.drawPath(collar, outline);

    // Kepala
    final head = Offset(w * .5, h * .38);
    canvas.drawCircle(head, w * .17, fill(AppColors.white));
    canvas.drawCircle(head, w * .17, outline);
    // Mata & senyum
    canvas.drawCircle(Offset(w * .44, h * .38), w * .018, fill(AppColors.darkGrey));
    canvas.drawCircle(Offset(w * .56, h * .38), w * .018, fill(AppColors.darkGrey));
    canvas.drawArc(Rect.fromCenter(center: Offset(w * .5, h * .42), width: w * .12, height: h * .05),
        0.2, 2.7, false, outline);

    // Topi oranye
    final cap = Path()
      ..moveTo(w * .31, h * .3)
      ..quadraticBezierTo(w * .5, h * .1, w * .69, h * .3)
      ..close();
    canvas.drawPath(cap, fill(AppColors.orange));
    canvas.drawPath(cap, outline);
    final brim = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .27, h * .28, w * .46, h * .05), Radius.circular(w * .03));
    canvas.drawRRect(brim, fill(AppColors.orange));
    canvas.drawRRect(brim, outline);

    // Amplop
    final env = Rect.fromLTWH(w * .58, h * .64, w * .3, h * .18);
    canvas.drawRect(env, fill(AppColors.white));
    canvas.drawRect(env, outline);
    final flap = Path()
      ..moveTo(env.left, env.top)
      ..lineTo(env.center.dx, env.center.dy)
      ..lineTo(env.right, env.top);
    canvas.drawPath(flap, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
