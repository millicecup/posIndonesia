// lib/shared/widgets/postmark_stamp.dart
// Cap kunjungan digital (A06, UI22): lingkaran bergaya stempel pos + tanggal kunjungan.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

String formatPostmarkDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

class PostmarkStamp extends StatelessWidget {
  const PostmarkStamp({super.key, required this.date, this.size = 160, this.color});

  final DateTime date;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.orange;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PostmarkPainter(c),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('MUSEUM POS',
                  style: TextStyle(
                      fontSize: size * .08, fontWeight: FontWeight.bold, color: c)),
              Container(
                margin: EdgeInsets.symmetric(vertical: size * .03),
                padding: EdgeInsets.symmetric(horizontal: size * .04, vertical: size * .01),
                decoration: BoxDecoration(border: Border.all(color: c, width: 2)),
                child: Text(formatPostmarkDate(date),
                    style: TextStyle(
                        fontSize: size * .11, fontWeight: FontWeight.w900, color: c)),
              ),
              Text('INDONESIA',
                  style: TextStyle(
                      fontSize: size * .08, fontWeight: FontWeight.bold, color: c)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostmarkPainter extends CustomPainter {
  _PostmarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    final dot = Paint()..color = color;
    // Lingkaran luar putus-putus seperti cap pos.
    const dots = 48;
    for (var i = 0; i < dots; i++) {
      final a = 2 * math.pi * i / dots;
      canvas.drawCircle(
          center + Offset(math.cos(a), math.sin(a)) * (r * .94), r * .025, dot);
    }
    canvas.drawCircle(
        center,
        r * .8,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant _PostmarkPainter old) => old.color != color;
}
