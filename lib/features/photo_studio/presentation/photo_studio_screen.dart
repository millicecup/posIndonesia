// lib/features/photo_studio/presentation/photo_studio_screen.dart
// UI15 Photo Studio + UI16 Hasil Foto (F08, PB14). Wireframe: PRD Gambar 5.5 kanan & 5.6 kiri.
// Versi minimum sesuai NG04: ambil foto dari kamera, pilih template seragam
// 2D, geser/cubit overlay agar pas, lalu simpan ke galeri HP. Tanpa AR body tracking / AI.
// Overlay seragam & topi: PNG dari repo content/poi-dataset (POI004), 3 warna.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/postmark_stamp.dart';
import '../widgets/uniform_overlay.dart';

class PhotoStudioScreen extends ConsumerStatefulWidget {
  const PhotoStudioScreen({super.key, this.poiId});

  final String? poiId;

  @override
  ConsumerState<PhotoStudioScreen> createState() => _PhotoStudioScreenState();
}

class _PhotoStudioScreenState extends ConsumerState<PhotoStudioScreen> {
  final _boundaryKey = GlobalKey();
  final _picker = ImagePicker();

  File? _photo;
  UniformTemplate _template = UniformTemplate.values.first;

  // Posisi & skala topi dan seragam (relatif terhadap ukuran kanvas).
  Offset _capPos = const Offset(.5, .26);
  double _capScale = 1;
  Offset _bodyPos = const Offset(.5, .8);
  double _bodyScale = 1;

  double _gestureStartScale = 1; // skala saat gesture cubit dimulai

  Uint8List? _result; // UI16
  bool _saving = false;
  bool _saved = false;
  bool _takingPhoto = false;
  bool _rendering = false;
  bool _photoReady = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) _recoverPhoto();
  }

  void _setPhoto(XFile file) {
    if (!mounted) return;
    setState(() {
      _photo = File(file.path);
      _photoReady = false;
      _result = null;
      _saved = false;
    });
  }

  Future<void> _recoverPhoto() async {
    try {
      final response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) return;
      if (response.files?.isNotEmpty ?? false) {
        _setPhoto(response.files!.first);
      } else if (response.exception != null) {
        _snack(
            'Foto sebelumnya tidak berhasil dipulihkan. Coba ambil foto lagi.');
      }
    } catch (e) {
      AppLogger.error('PHOTO', 'Gagal memulihkan foto: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (_takingPhoto) return;
    setState(() => _takingPhoto = true);
    try {
      final permission = await Permission.camera.request();
      if (!mounted) return;
      if (!permission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Izinkan akses kamera untuk mengambil foto.'),
          action: permission.isPermanentlyDenied
              ? const SnackBarAction(
                  label: 'Pengaturan', onPressed: openAppSettings)
              : null,
        ));
        return;
      }
      final file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          preferredCameraDevice: CameraDevice.front);
      if (file != null) _setPhoto(file);
    } on PlatformException catch (e) {
      AppLogger.error('PHOTO', 'Kamera gagal (${e.code}): ${e.message}');
      _snack('Kamera tidak bisa dibuka (${e.code}). '
          '${e.message ?? 'Tutup aplikasi kamera lain, lalu coba lagi.'}');
    } catch (e) {
      AppLogger.error('PHOTO', 'Gagal mengambil foto: $e');
      _snack('Gagal mengambil foto. Coba buka kamera lagi.');
    } finally {
      if (mounted) setState(() => _takingPhoto = false);
    }
  }

  Future<void> _capture() async {
    if (_rendering || !_photoReady) return;
    setState(() => _rendering = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (!mounted || bytes == null) return;
        setState(() => _result = bytes.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    } catch (e) {
      AppLogger.error('PHOTO', 'Gagal membuat hasil foto: $e');
      _snack('Hasil foto belum bisa dibuat. Coba lagi setelah foto tampil.');
    } finally {
      if (mounted) setState(() => _rendering = false);
    }
  }

  Future<void> _save() async {
    final bytes = _result;
    if (bytes == null) return;
    setState(() => _saving = true);
    try {
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putImageBytes(bytes,
          name: 'JejakPOS_${DateTime.now().millisecondsSinceEpoch}');
      if (!mounted) return;
      await ref.read(activityStatsProvider.notifier).addPhoto();
      if (!mounted) return;
      setState(() => _saved = true);
      _snack('Foto tersimpan di galeri (album Pictures).');
    } catch (e) {
      AppLogger.error('PHOTO', 'Gagal menyimpan foto: $e');
      _snack('Gagal menyimpan foto: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_result == null ? 'Photo Studio' : 'Hasil Foto'),
        leading: _result == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _result = null),
              ),
      ),
      body: _result == null ? _buildStudio() : _buildResult(),
    );
  }

  // ---------------- UI15 ----------------

  Widget _buildStudio() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: LayoutBuilder(
                  builder: (context, c) => RepaintBoundary(
                    key: _boundaryKey,
                    child: _buildCanvas(c.biggest),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                  child: Text('Pilih template seragam',
                      style: TextStyle(fontWeight: FontWeight.w600))),
              TextButton.icon(
                onPressed: () => setState(() {
                  _capPos = const Offset(.5, .26);
                  _bodyPos = const Offset(.5, .8);
                  _capScale = 1;
                  _bodyScale = 1;
                }),
                icon: const Icon(Icons.center_focus_strong, size: 18),
                label: const Text('Atur ulang'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 86,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final t in UniformTemplate.values)
                GestureDetector(
                  onTap: () => setState(() => _template = t),
                  child: Container(
                    width: 96,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: t == _template
                              ? AppColors.orange
                              : AppColors.lightGrey,
                          width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Expanded(child: UniformThumbnail(template: t)),
                        Text(t.label, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: AppColors.orange),
                    onPressed: _takingPhoto ? null : _takePhoto,
                    child: _takingPhoto
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.camera_alt, size: 30),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: !_photoReady || _takingPhoto || _rendering
                      ? null
                      : _capture,
                  icon: const Icon(Icons.check),
                  label: const Text('Jadikan'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCanvas(Size size) {
    final capW = size.width * .55 * _capScale;
    final bodyW = size.width * .9 * _bodyScale;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_photo != null)
            Image.file(
              _photo!,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, synchronous) {
                if ((synchronous || frame != null) && !_photoReady) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_photoReady) {
                      setState(() => _photoReady = true);
                    }
                  });
                }
                return child;
              },
              errorBuilder: (_, __, ___) => const Center(
                child: Text('Foto tidak dapat dibuka. Ambil foto ulang.'),
              ),
            )
          else
            const ColoredBox(
              color: Color(0xFF4A4F57),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Ambil foto dengan tombol kamera di bawah.\n'
                    'Geser dan cubit topi/seragam agar pas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          // Seragam (bagian bawah)
          _movable(
            size: size,
            pos: _bodyPos,
            width: bodyW,
            aspect: _template.bodyAspect,
            onChanged: (p, s) => setState(() {
              _bodyPos = p;
              _bodyScale = s;
            }),
            scale: _bodyScale,
            child: UniformBody(template: _template),
          ),
          // Topi
          _movable(
            size: size,
            pos: _capPos,
            width: capW,
            aspect: _template.capAspect,
            onChanged: (p, s) => setState(() {
              _capPos = p;
              _capScale = s;
            }),
            scale: _capScale,
            child: UniformCap(template: _template),
          ),
          // Bingkai label (wireframe UI16: "Museum Pos Indonesia · P04")
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: const Color(0x99000000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Seragam ${_template.label}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 11)),
                  Text(
                    'Museum Pos Indonesia${widget.poiId == null ? '' : ' · ${widget.poiId}'}'
                    ' · ${formatPostmarkDate(DateTime.now())}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bagian overlay yang bisa digeser (1 jari) dan diubah ukurannya (cubit 2 jari).
  Widget _movable({
    required Size size,
    required Offset pos,
    required double width,
    required double aspect,
    required double scale,
    required void Function(Offset pos, double scale) onChanged,
    required Widget child,
  }) {
    final height = width * aspect;
    return Positioned(
      left: pos.dx * size.width - width / 2,
      top: pos.dy * size.height - height / 2,
      width: width,
      height: height,
      child: GestureDetector(
        onScaleStart: (_) => _gestureStartScale = scale,
        onScaleUpdate: (d) {
          final next = Offset(
            (pos.dx + d.focalPointDelta.dx / size.width).clamp(0.0, 1.0),
            (pos.dy + d.focalPointDelta.dy / size.height).clamp(0.0, 1.0),
          );
          onChanged(next, (_gestureStartScale * d.scale).clamp(.4, 2.5));
        },
        child: child,
      ),
    );
  }

  // ---------------- UI16 ----------------

  Widget _buildResult() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGrey, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Expanded(
                        child: Image.memory(_result!, fit: BoxFit.contain)),
                    const SizedBox(height: 8),
                    Text(
                        'Museum Pos Indonesia${widget.poiId == null ? '' : ' · ${widget.poiId}'}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  _saved
                      ? '✓ Foto sudah tersimpan di galeri'
                      : '✓ Foto siap disimpan',
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.darkGrey),
              onPressed: _saving || _saved ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: Text(_saved ? 'Tersimpan' : 'Simpan ke galeri'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _result = null),
                    child: const Text('Ulangi'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Selesai'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
