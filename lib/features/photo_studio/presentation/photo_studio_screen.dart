// lib/features/photo_studio/presentation/photo_studio_screen.dart
// UI15 Photo Studio + UI16 Hasil Foto (F08, PB14). Wireframe: PRD Gambar 5.5 kanan & 5.6 kiri.
// Versi minimum sesuai NG04: ambil foto dari kamera, pilih template seragam
// 2D, geser/cubit overlay agar pas, lalu simpan ke galeri HP. Tanpa AR body tracking / AI.
// Overlay seragam & topi: PNG dari repo content/poi-dataset (POI004), 3 warna.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/postmark_stamp.dart';
import '../widgets/uniform_overlay.dart';
import '../studio_camera.dart';
import '../studio_gallery.dart';

class PhotoStudioScreen extends ConsumerStatefulWidget {
  const PhotoStudioScreen({super.key, this.poiId});

  final String? poiId;

  @override
  ConsumerState<PhotoStudioScreen> createState() => _PhotoStudioScreenState();
}

class _PhotoStudioScreenState extends ConsumerState<PhotoStudioScreen>
    with WidgetsBindingObserver {
  final _boundaryKey = GlobalKey();
  StudioCamera? _camera;
  Future<void> _cameraCleanup = Future<void>.value();
  bool _cameraReady = false;
  bool _cameraStarting = false;
  bool _appActive = true;
  int _cameraGeneration = 0;
  String? _cameraError;
  bool _mirrorPhoto = false;

  Uint8List? _photo;
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
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraGeneration++;
    unawaited(_camera?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appActive = true;
      if (_photo == null && !_cameraReady && !_cameraStarting) {
        unawaited(_startCamera());
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _appActive = false;
      _cameraGeneration++;
      final camera = _camera;
      _camera = null;
      _cameraReady = false;
      if (camera != null) _cameraCleanup = camera.dispose();
      if (mounted) setState(() {});
    }
  }

  Future<void> _startCamera() async {
    if (_cameraStarting || !_appActive || _photo != null) return;
    final generation = ++_cameraGeneration;
    setState(() {
      _cameraStarting = true;
      _cameraError = null;
    });
    final camera = ref.read(studioCameraFactoryProvider)();
    try {
      await _cameraCleanup;
      if (!mounted || generation != _cameraGeneration || !_appActive) return;
      await camera.initialize();
      if (!mounted || generation != _cameraGeneration || !_appActive) {
        await camera.dispose();
        return;
      }
      _camera = camera;
      setState(() => _cameraReady = true);
    } catch (e) {
      await camera.dispose();
      AppLogger.error('PHOTO', 'Gagal membuka preview kamera: $e');
      if (mounted && generation == _cameraGeneration) {
        setState(() => _cameraError = e is CameraException
            ? 'Kamera belum bisa dibuka (${e.code}). '
                'Periksa izin kamera dan tutup aplikasi kamera lain.'
            : 'Kamera belum bisa dibuka. Coba lagi.');
      }
    } finally {
      _cameraStarting = false;
      if (mounted) {
        setState(() {});
        if (_appActive && generation != _cameraGeneration && _photo == null) {
          unawaited(_startCamera());
        }
      }
    }
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (_takingPhoto || !_cameraReady || camera == null) return;
    setState(() => _takingPhoto = true);
    try {
      final mirror = camera.mirrorPhoto;
      final bytes = await camera.takePhoto();
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _mirrorPhoto = mirror;
        _photoReady = false;
        _saved = false;
        _cameraReady = false;
        _camera = null;
      });
      await camera.dispose();
    } catch (e) {
      AppLogger.error('PHOTO', 'Gagal menjepret foto: $e');
      _snack('Foto belum berhasil diambil. Coba jepret lagi.');
    } finally {
      if (mounted) setState(() => _takingPhoto = false);
    }
  }

  void _retake() {
    setState(() {
      _photo = null;
      _photoReady = false;
      _result = null;
      _saved = false;
    });
    unawaited(_startCamera());
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
        setState(() {
          _result = bytes.buffer.asUint8List();
          _saved = false;
        });
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
      await ref
          .read(studioGalleryProvider)
          .save(bytes, 'JejakPOS_${DateTime.now().millisecondsSinceEpoch}');
      if (!mounted) return;
      setState(() => _saved = true);
      _snack('Foto tersimpan di Galeri > Album JejakPOS.');
      try {
        await ref.read(activityStatsProvider.notifier).addPhoto();
      } catch (e) {
        AppLogger.error(
            'PHOTO', 'Foto tersimpan, statistik belum diperbarui: $e');
      }
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
              _photo == null
                  ? 'Sesuaikan posisi wajah dan tubuh dengan topi dan seragam, lalu jepret.'
                  : 'Geser atau cubit topi dan seragam agar pas, lalu pilih Lihat hasil.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
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
                  child: Tooltip(
                      message: _photo == null ? 'Jepret foto' : 'Ambil ulang',
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: AppColors.orange),
                        onPressed: _takingPhoto ||
                                _rendering ||
                                (_photo == null && !_cameraReady)
                            ? null
                            : (_photo == null ? _takePhoto : _retake),
                        child: _takingPhoto
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Icon(
                                _photo == null
                                    ? Icons.camera_alt
                                    : Icons.replay,
                                size: 30),
                      )),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: !_photoReady || _takingPhoto || _rendering
                      ? null
                      : _capture,
                  icon: const Icon(Icons.check),
                  label: const Text('Lihat hasil'),
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
            Transform.flip(
                flipX: _mirrorPhoto,
                child: Image.memory(
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
                ))
          else if (_cameraReady && _camera != null)
            _camera!.preview()
          else
            ColoredBox(
              color: const Color(0xFF4A4F57),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_cameraError ?? 'Menyiapkan kamera...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white)),
                      if (_cameraError != null) ...[
                        TextButton(
                            onPressed: _startCamera,
                            child: const Text('Coba lagi')),
                        const TextButton(
                            onPressed: openAppSettings,
                            child: Text('Pengaturan kamera')),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (_cameraReady || _photo != null) ...[
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
          ],
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
                      ? 'Foto tersimpan di album JejakPOS'
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
            if (_saved)
              TextButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(studioGalleryProvider).open();
                  } catch (_) {
                    _snack('Buka aplikasi Galeri, lalu pilih album JejakPOS.');
                  }
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Buka galeri'),
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
