import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Flutter adaptation of the supplied envelope-to-logo HTML animation.
class SplashScreen extends StatefulWidget {
  const SplashScreen(
      {super.key,
      required this.onFinished,
      this.playSound = true,
      this.autoContinue = true});
  final VoidCallback onFinished;
  final bool playSound;
  final bool autoContinue;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  AudioPlayer? _player;
  bool _finished = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4200))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && widget.autoContinue) {
          _finish();
        }
      })
      ..forward();
    if (widget.playSound) unawaited(_sound());
  }

  Future<void> _sound() async {
    try {
      final player = _player ??= AudioPlayer();
      await player.setVolume(0.45);
      await player.setAsset('assets/audio/splash_opening.wav');
      if (!mounted || _finished) return;
      unawaited(player.play().catchError((Object _) {}));
    } catch (_) {
      // Browser autoplay restrictions must never hold up onboarding.
    }
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    unawaited(_player?.stop());
    widget.onFinished();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_player?.stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    unawaited(_player?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
              gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 1,
                  colors: [
                Color(0xFFFBF4E8),
                Color(0xFFF6ECDD),
                Color(0xFFEFE0C8)
              ])),
          child: SafeArea(
              child: Stack(children: [
            Center(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: FittedBox(
                        child: SizedBox(
                      width: 340,
                      height: 340,
                      child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final t = MediaQuery.disableAnimationsOf(context)
                                ? 4.0
                                : _controller.value * 4.2;
                            final flip = _phase(t, 2.2, 2.6);
                            final shift = Curves.easeInOutCubic
                                .transform(_phase(t, 2.65, 3.17));
                            final reveal = Curves.easeInOutCubic
                                .transform(_phase(t, 2.85, 3.5));
                            final pulse = 1 +
                                0.06 * math.sin(math.pi * _phase(t, 3.5, 3.82));
                            return Transform.scale(
                                scale: pulse,
                                child: Stack(children: [
                                  Positioned.fill(
                                      child: CustomPaint(
                                          painter: _PostalPainter(t))),
                                  if (t >= 2.2)
                                    Positioned(
                                      left: 121.5 - 97.4 * shift,
                                      top: 121.6,
                                      width: 97.3,
                                      height: 90.5,
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.diagonal3Values(
                                            Curves.easeOutBack
                                                .transform(flip)
                                                .clamp(0.0, 1.15),
                                            1,
                                            1),
                                        child: Image.asset(
                                            'assets/images/splash_icon.png',
                                            semanticLabel:
                                                'Ikon prangko JejakPOS'),
                                      ),
                                    ),
                                  if (reveal > 0)
                                    Positioned(
                                      left: 108.6,
                                      top: 137.6,
                                      width: 207.3,
                                      height: 71.4,
                                      child: ClipRect(
                                          clipper: _RevealClipper(reveal),
                                          child: Image.asset(
                                              'assets/images/splash_word.png',
                                              fit: BoxFit.fill,
                                              semanticLabel: 'JejakPOS')),
                                    ),
                                ]));
                          }),
                    )),
                  )),
            )),
            Positioned(
                bottom: 14,
                left: 20,
                right: 20,
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (widget.playSound)
                    IconButton(
                        tooltip: 'Putar suara pembuka',
                        onPressed: _sound,
                        icon: const Icon(Icons.volume_up_outlined)),
                ])),
          ])),
        ),
      );
}

double _phase(double t, double start, double end) =>
    ((t - start) / (end - start)).clamp(0.0, 1.0);

class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.fraction);
  final double fraction;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  @override
  bool shouldReclip(_RevealClipper old) => fraction != old.fraction;
}

class _PostalPainter extends CustomPainter {
  const _PostalPainter(this.t);
  final double t;
  void _shape(Canvas c, Path path, Color color, {double alpha = 1}) {
    c.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
    c.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF8A5A2B).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (t < 0.1) return;
    final pop = Curves.easeOutBack.transform(_phase(t, .1, .56));
    final envFade = 1 - _phase(t, 1.3, 1.68);
    canvas.save();
    canvas.translate(170, 175 + 24 * (1 - pop));
    canvas.scale(0.6 + 0.4 * pop);
    canvas.translate(-170, -175);
    if (envFade > 0) {
      canvas.save();
      canvas.translate(0, 36 * (1 - envFade));
      _shape(
          canvas,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                const Rect.fromLTWH(80, 115, 180, 120),
                const Radius.circular(6))),
          const Color(0xFFE3C79A),
          alpha: envFade);
      final open = _phase(t, .76, 1.02);
      _shape(
          canvas,
          Path()
            ..moveTo(80, 115)
            ..lineTo(260, 115)
            ..lineTo(170, 115 - 63 * open)
            ..close(),
          const Color(0xFFD7B583),
          alpha: envFade);
      canvas.restore();
    }
    if (t < 2.2) {
      final u = _phase(t, .95, 2.2);
      final lift = u < .32
          ? -62 * Curves.easeOut.transform(u / .32)
          : u < .5
              ? -62 + 12 * (u - .32) / .18
              : -50 + 45 * (u - .5) / .5;
      final turn = _phase(t, 1.4, 2.2);
      canvas.save();
      canvas.translate(170, 175 + lift);
      canvas.rotate(turn * 2 * math.pi);
      canvas.scale(1 - .38 * turn);
      canvas.translate(-170, -175);
      _shape(
          canvas,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                const Rect.fromLTWH(95, 125, 150, 100),
                const Radius.circular(4))),
          const Color(0xFFFBF4E6),
          alpha: 1 - _phase(t, 2.05, 2.2));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(207, 134, 28, 32), const Radius.circular(2)),
          Paint()..color = const Color(0xFFD9542F));
      final lines = Paint()
        ..color = const Color(0xFFC9A06B)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(Offset(110, 170 + i * 12.0),
            Offset(i == 1 ? 175 : 190, 170 + i * 12.0), lines);
      }
      canvas.restore();
    }
    if (envFade > 0) {
      canvas.save();
      canvas.translate(0, 36 * (1 - envFade));
      _shape(
          canvas,
          Path()
            ..moveTo(80, 121)
            ..lineTo(170, 182)
            ..lineTo(260, 121)
            ..lineTo(260, 229)
            ..quadraticBezierTo(260, 235, 254, 235)
            ..lineTo(86, 235)
            ..quadraticBezierTo(80, 235, 80, 229)
            ..close(),
          const Color(0xFFEED8B3),
          alpha: envFade);
      if (t < .76) {
        final close = 1 - _phase(t, .56, .76);
        _shape(
            canvas,
            Path()
              ..moveTo(80, 115)
              ..lineTo(260, 115)
              ..lineTo(170, 115 + 70 * close)
              ..close(),
            const Color(0xFFF2DFBF),
            alpha: envFade);
      }
      canvas.restore();
    }
    canvas.restore();
    if (t >= 1.35 && t < 2.2) {
      final u = _phase(t, 1.35, 2.2);
      canvas.save();
      canvas.translate(170, 170);
      canvas.rotate((-40 + 360 * u) * math.pi / 180);
      for (var i = 0; i < 4; i++) {
        canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: 68 + i * 12.0),
            i * 1.6,
            0.6 + 0.4 * (i % 2),
            false,
            Paint()
              ..color =
                  (i.isEven ? const Color(0xFF1F3A5F) : const Color(0xFFE8892B))
                      .withValues(alpha: math.sin(math.pi * u))
              ..style = PaintingStyle.stroke
              ..strokeWidth = i == 1 ? 6 : 3
              ..strokeCap = StrokeCap.round);
      }
      canvas.restore();
    }
    if (t >= 2.25 && t < 2.77) {
      final u = _phase(t, 2.25, 2.77);
      for (var i = 0; i < 12; i++) {
        final a = i / 12 * 2 * math.pi + .26;
        final r = 50 + 35 * u;
        canvas.drawLine(
            Offset(170 + math.cos(a) * r, 170 + math.sin(a) * r),
            Offset(170 + math.cos(a) * (r + 13), 170 + math.sin(a) * (r + 13)),
            Paint()
              ..color = const Color(0xFFE8892B).withValues(alpha: 1 - u)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(_PostalPainter old) => old.t != t;
}
