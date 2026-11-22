import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Komponen Kartu Jejak Kunjungan (Paspor Museum Pos Indonesia)
/// dengan animasi stempel fisik yang turun mengecap kertas dan tetap membekas permanen.
///
/// Cara pemakaian pada halaman Ringkasan Kunjungan:
/// PassportPostmarkCard(
///   visitorName: 'Penjelajah Pos',
///   visitDate: '22.11.2026',
///   shortDate: '22-11-26 • BDG',
///   totalVisits: 3,
///   triggerStampAnimation: widget.fromEndVisitButton, // true hanya saat baru menekan 'Akhiri Kunjungan'
///   mascotAssetPath: 'assets/images/mascot_stamp.png', // sesuaikan dengan path aset maskot di repo
/// )
class PassportPostmarkCard extends StatefulWidget {
  final String visitorName;
  final String visitDate;
  final String shortDate;
  final int totalVisits;
  final bool triggerStampAnimation;
  final String? mascotAssetPath;
  final ValueChanged<String>? onVisitorNameChanged;

  const PassportPostmarkCard({
    super.key,
    this.visitorName = 'Penjelajah Pos',
    required this.visitDate,
    required this.shortDate,
    required this.totalVisits,
    this.triggerStampAnimation = false,
    this.mascotAssetPath,
    this.onVisitorNameChanged,
  });

  @override
  State<PassportPostmarkCard> createState() => _PassportPostmarkCardState();
}

class _PassportPostmarkCardState extends State<PassportPostmarkCard>
    with SingleTickerProviderStateMixin {
  // Palet warna resmi JejakPOS
  static const Color _posNavy = Color(0xFF1E2B45);
  static const Color _posOrange = Color(0xFFE85D04);
  static const Color _posTerracotta = Color(0xFFD85A26);
  static const Color _posGold = Color(0xFFFCBF49);
  static const Color _posGoldDeep = Color(0xFFD98A00);
  static const Color _posBrown = Color(0xFF7C583A);
  static const Color _passportCream = Color(0xFFFDF8EE);
  static const Color _passportWell = Color(0xFFF3E8D2);
  static const Color _passportBorder = Color(0xFFC5B396);

  late final AnimationController _controller;
  late final TextEditingController _nameController;
  bool _impactFeedbackPlayed = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.visitorName);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );

    _controller.addListener(() {
      // Picu getaran haptic halus tepat saat stempel menyentuh kertas (50% timeline)
      if (_controller.value >= 0.50 && !_impactFeedbackPlayed) {
        _impactFeedbackPlayed = true;
        HapticFeedback.mediumImpact();
      }
    });

    if (widget.triggerStampAnimation) {
      // Jalankan animasi otomatis sesaat setelah layar Ringkasan Kunjungan terbuka
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) {
          _playStampSequence();
        }
      });
    } else {
      // Jika dibuka dari Riwayat biasa, langsung tampilkan cap permanen tanpa animasi ulang
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant PassportPostmarkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visitorName != oldWidget.visitorName &&
        _nameController.text != widget.visitorName) {
      _nameController.text = widget.visitorName;
    }
    // Jalankan ulang hanya jika flag triggerStampAnimation berubah menjadi true
    if (widget.triggerStampAnimation && !oldWidget.triggerStampAnimation) {
      _playStampSequence();
    }
  }

  void _playStampSequence() {
    _impactFeedbackPlayed = false;
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Menghitung transformasi alat stempel fisik (turun -> tekan -> angkat)
  Matrix4 _computeStampToolTransform(double t) {
    double dx = 0;
    double dy = -160;
    double scale = 1.3;
    double angle = 0.25;

    if (t < 0.25) {
      final p = Curves.easeOut.transform(t / 0.25);
      dx = 36 * (1 - p) + 8 * p;
      dy = -160 * (1 - p) - 62 * p;
      scale = 1.35 * (1 - p) + 1.15 * p;
      angle = 0.26 * (1 - p) + 0.10 * p;
    } else if (t < 0.38) {
      final p = (t - 0.25) / 0.13;
      dx = 8 - 3 * p;
      dy = -62 - 10 * p;
      scale = 1.15 + 0.06 * p;
      angle = 0.10 + 0.04 * p;
    } else if (t < 0.50) {
      // Menghantam permukaan kertas
      final p = Curves.easeInCubic.transform((t - 0.38) / 0.12);
      dx = 5 * (1 - p);
      dy = -72 * (1 - p) + 4 * p;
      scale = 1.21 * (1 - p) + 0.94 * p;
      angle = 0.14 * (1 - p) - 0.03 * p;
    } else if (t < 0.64) {
      // Menahan tekanan tinta
      final p = (t - 0.50) / 0.14;
      dx = 0;
      dy = 4 * (1 - p);
      scale = 0.94 + 0.03 * p;
      angle = -0.03;
    } else if (t < 0.80) {
      // Terangkat ke atas
      final p = Curves.easeOut.transform((t - 0.64) / 0.16);
      dx = -12 * p;
      dy = -55 * p;
      scale = 0.97 + 0.14 * p;
      angle = -0.03 - 0.10 * p;
    } else {
      // Menghilang keluar layar
      final p = Curves.easeIn.transform((t - 0.80) / 0.20);
      dx = -12 - 28 * p;
      dy = -55 - 105 * p;
      scale = 1.11 + 0.20 * p;
      angle = -0.13 - 0.12 * p;
    }

    return Matrix4.identity()
      ..translate(dx, dy)
      ..rotateZ(angle)
      ..scale(scale);
  }

  double _computeStampToolOpacity(double t) {
    if (!widget.triggerStampAnimation && t >= 1.0) return 0.0;
    if (t <= 0.0 || t >= 1.0) return 0.0;
    if (t < 0.15) return t / 0.15;
    if (t > 0.82) return (1.0 - t) / 0.18;
    return 1.0;
  }

  // Getaran mikro pada kartu paspor saat tumbukan (t = 0.50 .. 0.72)
  Offset _computeCardShakeOffset(double t) {
    if (t < 0.50 || t > 0.72) return Offset.zero;
    final p = (t - 0.50) / 0.22;
    final decay = 1.0 - p;
    final dx = math.sin(p * math.pi * 4) * 2.2 * decay;
    final dy = math.cos(p * math.pi * 3) * 3.5 * decay;
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final shakeOffset = _computeCardShakeOffset(t);

        // Cap tinta muncul tepat saat tumbukan (t >= 0.49) dan tetap permanen setelahnya
        final bool isInkVisible = !widget.triggerStampAnimation || t >= 0.49;
        final double inkOpacity = !isInkVisible
            ? 0.0
            : (t < 0.56 ? ((t - 0.49) / 0.07).clamp(0.0, 0.94) : 0.94);
        final double inkScale = !isInkVisible
            ? 1.12
            : (t < 0.58 ? 0.96 + 0.04 * ((t - 0.49) / 0.09) : 1.0);

        return Transform.translate(
          offset: shakeOffset,
          child: Container(
            decoration: BoxDecoration(
              color: _passportCream,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE6D8C3), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: _posNavy.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background tekstur titik halus (Halftone dot-grid)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: CustomPaint(
                      painter: _HalftoneDotsPainter(),
                    ),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pita diagonal khas pos udara (Navy & Postal Orange) di bagian atas
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: SizedBox(
                        height: 10,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _AirmailRibbonPainter(),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Kartu + Ikon Maskot Prangko
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'KARTU JEJAK KUNJUNGAN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                        color: _posOrange,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Paspor Museum Pos Indonesia',
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        color: _posNavy,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Jl. Cilaki No. 73, Bandung 40115',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _posBrown,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildMascotBadge(),
                            ],
                          ),

                          const SizedBox(height: 12),
                          _buildDashedDivider(),
                          const SizedBox(height: 12),

                          // Dua Kotak Informasi: Nama Penjelajah & Tanggal Cap
                          Row(
                            children: [
                              Expanded(
                                flex: 7,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF6EE),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE5D7C3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'NAMA PENJELAJAH',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.7,
                                          color: _posBrown,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      TextField(
                                        controller: _nameController,
                                        onChanged: widget.onVisitorNameChanged,
                                        maxLength: 22,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _posNavy,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                          counterText: '',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF6EE),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE5D7C3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TANGGAL CAP',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.7,
                                          color: _posBrown,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        widget.shortDate,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: _posNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Area Kotak Cap Berbingkai Garis Putus-Putus + Cap Berwarna Permanen
                          _buildStampWellArea(
                            t: t,
                            inkOpacity: inkOpacity,
                            inkScale: inkScale,
                          ),

                          const SizedBox(height: 12),
                          _buildDashedDivider(),
                          const SizedBox(height: 10),

                          // Footer Kartu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                '#MelayaniSepenuhHati',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _posBrown,
                                ),
                              ),
                              Text(
                                'JEJAKPOS • BDG',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: _posNavy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Lekukan Tiket Setengah Lingkaran (Kiri & Kanan)
                Positioned(
                  left: -8,
                  top: 195,
                  child: _buildTicketNotch(),
                ),
                Positioned(
                  right: -8,
                  top: 195,
                  child: _buildTicketNotch(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMascotBadge() {
    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDFD2BE), width: 1.5),
      ),
      child: widget.mascotAssetPath != null
          ? Image.asset(
              widget.mascotAssetPath!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_post_office_rounded,
                color: _posOrange,
                size: 28,
              ),
            )
          : const Icon(
              Icons.local_post_office_rounded,
              color: _posOrange,
              size: 28,
            ),
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 7).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Container(
              width: 4,
              height: 1.2,
              color: const Color(0xFFD6C6AE),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTicketNotch() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE6D8C3), width: 1.2),
      ),
    );
  }

  Widget _buildStampWellArea({
    required double t,
    required double inkOpacity,
    required double inkScale,
  }) {
    final toolOpacity = _computeStampToolOpacity(t);
    final bool showBurst = widget.triggerStampAnimation && t >= 0.50 && t <= 0.85;
    final double burstProgress = showBurst ? ((t - 0.50) / 0.35).clamp(0.0, 1.0) : 0.0;

    return CustomPaint(
      painter: _DashedRoundedRectPainter(
        color: _passportBorder,
        radius: 18,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: _passportWell,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 158,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Cap Historis #1 (Kiri Atas - Heritage Navy)
                  Positioned(
                    top: 2,
                    left: 4,
                    child: Transform.rotate(
                      angle: -0.20,
                      child: Opacity(
                        opacity: 0.72,
                        child: _buildMiniRectangularStamp(
                          title: 'POS BANDUNG',
                          subtitle: '14.08.2026',
                          tag: 'KUNJUNGAN #1',
                          color: _posNavy,
                        ),
                      ),
                    ),
                  ),

                  // Cap Historis #2 (Kiri Bawah - Golden Yellow)
                  Positioned(
                    bottom: 0,
                    left: 6,
                    child: Transform.rotate(
                      angle: 0.22,
                      child: Opacity(
                        opacity: 0.82,
                        child: _buildMiniCircularSeal(
                          top: 'FILATELI',
                          mid: '03.10.2026',
                          bottom: '★ SAH ★',
                          color: _posGoldDeep,
                        ),
                      ),
                    ),
                  ),

                  // Cap Historis #3 (Kanan Atas - Coral Red)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Transform.rotate(
                      angle: 0.14,
                      child: Opacity(
                        opacity: 0.68,
                        child: _buildMiniRectangularStamp(
                          title: 'JASA POS RI',
                          subtitle: '40115 • BDG',
                          tag: 'ARSIP POS',
                          color: const Color(0xFFC83E37),
                        ),
                      ),
                    ),
                  ),

                  // Cap Bonus Kunjungan Terbaru (Kanan Bawah - muncul jika kunjungan > 3)
                  if (widget.totalVisits > 3 && inkOpacity > 0.2)
                    Positioned(
                      bottom: 2,
                      right: 6,
                      child: Transform.rotate(
                        angle: -0.18,
                        child: Opacity(
                          opacity: inkOpacity * 0.9,
                          child: _buildMiniCircularSeal(
                            top: 'JEJAKPOS',
                            mid: 'VISIT #${widget.totalVisits}',
                            bottom: 'BANDUNG',
                            color: _posNavy,
                          ),
                        ),
                      ),
                    ),

                  // Gelombang Kejut & Percikan Emas saat Tumbukan
                  if (showBurst)
                    IgnorePointer(
                      child: CustomPaint(
                        size: const Size(180, 158),
                        painter: _ImpactBurstPainter(
                          progress: burstProgress,
                          ringColor: _posTerracotta,
                          sparkleColor: _posGold,
                        ),
                      ),
                    ),

                  // CAP POS UTAMA (MUSEUM POS / TANGGAL / INDONESIA) — TETAP MEMBEKAS PERMANEN
                  Opacity(
                    opacity: inkOpacity,
                    child: Transform.scale(
                      scale: inkScale,
                      child: Transform.rotate(
                        angle: -0.07,
                        child: SizedBox(
                          width: 156,
                          height: 156,
                          child: CustomPaint(
                            painter: _DottedPostmarkPainter(
                              dateText: widget.visitDate,
                              inkColor: _posTerracotta,
                              fillColor: _passportCream.withValues(alpha: 0.84),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Alat Stempel Fisik (Hanya muncul & bergerak saat triggerStampAnimation == true)
                  if (toolOpacity > 0.01)
                    IgnorePointer(
                      child: Opacity(
                        opacity: toolOpacity.clamp(0.0, 1.0),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: _computeStampToolTransform(t),
                          child: SizedBox(
                            width: 112,
                            height: 138,
                            child: CustomPaint(
                              painter: _PhysicalStampToolPainter(),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Status Keterangan di Bagian Bawah Kotak Cap
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF39C53),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  (widget.triggerStampAnimation && t < 0.50)
                      ? 'Mengecap paspor...'
                      : 'Tercap Resmi • Koleksi Lencana Bertambah!',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _posBrown,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniRectangularStamp({
    required String title,
    required String subtitle,
    required String tag,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            height: 1,
            width: 54,
            color: color,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            tag,
            style: TextStyle(
              fontSize: 6.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCircularSeal({
    required String top,
    required String mid,
    required String bottom,
    required Color color,
  }) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              top,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              mid,
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              bottom,
              style: TextStyle(
                fontSize: 6.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Melukis Cap Lingkaran Bertitik-titik "MUSEUM POS / TANGGAL / INDONESIA"
class _DottedPostmarkPainter extends CustomPainter {
  final String dateText;
  final Color inkColor;
  final Color fillColor;

  _DottedPostmarkPainter({
    required this.dateText,
    required this.inkColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerDotRadius = size.width * 0.44;
    final innerRingRadius = size.width * 0.38;

    // 1. Lingkaran titik-titik luar
    final dotPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.fill;

    const int dotCount = 56;
    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi * i) / dotCount;
      final dx = center.dx + outerDotRadius * math.cos(angle);
      final dy = center.dy + outerDotRadius * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 2.1, dotPaint);
    }

    // 2. Latar lingkaran dalam + garis tepi solid
    final bgPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRingRadius, bgPaint);

    final ringPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(center, innerRingRadius, ringPaint);

    // 3. Kotak tanggal tengah
    final boxWidth = size.width * 0.68;
    final boxHeight = size.height * 0.21;
    final dateRect = Rect.fromCenter(
      center: center,
      width: boxWidth,
      height: boxHeight,
    );
    canvas.drawRect(dateRect, ringPaint..strokeWidth = 2.1);

    // 4. Teks "MUSEUM POS", Tanggal, dan "INDONESIA"
    _drawCenteredText(
      canvas,
      text: 'MUSEUM POS',
      offset: Offset(center.dx, center.dy - boxHeight * 0.92),
      fontSize: 11.2,
      letterSpacing: 0.5,
    );

    _drawCenteredText(
      canvas,
      text: dateText,
      offset: center,
      fontSize: 16.0,
      letterSpacing: 0.4,
    );

    _drawCenteredText(
      canvas,
      text: 'INDONESIA',
      offset: Offset(center.dx, center.dy + boxHeight * 0.92),
      fontSize: 11.2,
      letterSpacing: 0.7,
    );
  }

  void _drawCenteredText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required double fontSize,
    required double letterSpacing,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: inkColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        offset.dx - textPainter.width / 2,
        offset.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DottedPostmarkPainter oldDelegate) =>
      oldDelegate.dateText != dateText || oldDelegate.inkColor != inkColor;
}

/// Melukis Alat Stempel Fisik (Gagang Navy + Aksen Emas & Oranye Pos)
class _PhysicalStampToolPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gagang pegangan atas (Navy)
    final gripPaint = Paint()..color = const Color(0xFF1E2B45);
    final gripRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.22), width: w * 0.44, height: h * 0.34),
      const Radius.circular(24),
    );
    canvas.drawRRect(gripRect, gripPaint);

    // Cincin emas
    final goldPaint = Paint()..color = const Color(0xFFFCBF49);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.41), width: w * 0.26, height: h * 0.05),
        const Radius.circular(3),
      ),
      goldPaint,
    );

    // Leher stempel (Oranye Pos)
    final neckPaint = Paint()..color = const Color(0xFFE85D04);
    final neckPath = Path()
      ..moveTo(w * 0.39, h * 0.44)
      ..lineTo(w * 0.61, h * 0.44)
      ..lineTo(w * 0.65, h * 0.64)
      ..lineTo(w * 0.35, h * 0.64)
      ..close();
    canvas.drawPath(neckPath, neckPaint);

    // Blok dudukan kayu
    final woodPaint = Paint()..color = const Color(0xFF6F371D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.64, w * 0.76, h * 0.14),
        const Radius.circular(6),
      ),
      woodPaint,
    );

    // Bantalan karet tinta (Terracotta)
    final padPaint = Paint()..color = const Color(0xFFD85A26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.78, w * 0.70, h * 0.08),
        const Radius.circular(3),
      ),
      padPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Melukis gelombang kejut dan percikan tinta saat stempel menghantam kertas
class _ImpactBurstPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color sparkleColor;

  _ImpactBurstPainter({
    required this.progress,
    required this.ringColor,
    required this.sparkleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // Gelombang kejut melingkar
    final ringPaint = Paint()
      ..color = ringColor.withValues(alpha: opacity * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1.0 - progress * 0.6);
    canvas.drawCircle(center, 52 + 46 * progress, ringPaint);

    // 12 partikel percikan tinta & bintang emas
    const int count = 12;
    for (int i = 0; i < count; i++) {
      final angle = (2 * math.pi * i) / count;
      final dist = 54 + 42 * Curves.easeOut.transform(progress);
      final pos = Offset(
        center.dx + dist * math.cos(angle),
        center.dy + dist * math.sin(angle),
      );
      final pPaint = Paint()
        ..color = (i.isEven ? sparkleColor : ringColor).withValues(alpha: opacity);
      canvas.drawCircle(pos, i.isEven ? 3.2 : 2.4, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ImpactBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Pita diagonal Navy & Oranye Pos di bagian atas kartu paspor
class _AirmailRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFDF8EE);
    canvas.drawRect(Offset.zero & size, bgPaint);

    const double stripeWidth = 12;
    const double gap = 6;
    int index = 0;

    for (double x = -size.height; x < size.width + size.height; x += stripeWidth + gap) {
      final paint = Paint()
        ..color = index.isEven ? const Color(0xFF1E2B45) : const Color(0xFFE85D04);
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + stripeWidth, 0)
        ..lineTo(x + stripeWidth, size.height)
        ..close();
      canvas.drawPath(path, paint);
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tekstur bintik kertas halus (Halftone dot-grid)
class _HalftoneDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF7C583A).withValues(alpha: 0.11);
    const double spacing = 10;
    for (double y = 6; y < size.height; y += spacing) {
      for (double x = 6; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}