import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/jejak_app_bar.dart';
import '../../../services/vision/vision_matcher.dart';
import '../state/vision_tour_controller.dart';

/// Camera-only browser preview of Kenali. Recognition runs in the local backend.
class WebVisionTourScreen extends ConsumerStatefulWidget {
  const WebVisionTourScreen({super.key});
  @override
  ConsumerState<WebVisionTourScreen> createState() =>
      _WebVisionTourScreenState();
}

class _WebVisionTourScreenState extends ConsumerState<WebVisionTourScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  Timer? _timer;
  bool _busy = false;
  bool _starting = false;
  bool _paused = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _paused = true;
      _stop();
    } else if (state == AppLifecycleState.resumed) {
      _paused = false;
      _start();
    }
  }

  Future<void> _start() async {
    if (_starting || _camera != null || _paused) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('Kamera tidak ditemukan.');
      final back = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.back);
      controller = CameraController(
          back.isEmpty ? cameras.first : back.first, ResolutionPreset.medium,
          enableAudio: false);
      await controller.initialize();
      if (!mounted || _paused) {
        await controller.dispose();
        return;
      }
      setState(() => _camera = controller);
      _timer =
          Timer.periodic(const Duration(milliseconds: 1500), (_) => _capture());
    } catch (error) {
      await controller?.dispose();
      if (mounted) {
        setState(() => _error =
            'Kamera tidak dapat dibuka. Izinkan akses kamera di browser, lalu coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    final camera = _camera;
    _camera = null;
    await camera?.dispose();
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (_busy ||
        camera == null ||
        !mounted ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    if (ref.read(visionTourControllerProvider).status != VisionTourStatus.ready)
      return;
    _busy = true;
    try {
      final photo = await camera.takePicture();
      final Uint8List bytes = await photo.readAsBytes();
      if (!mounted || _paused || !identical(camera, _camera)) return;
      await ref.read(visionTourControllerProvider.notifier).processSiftFrame(
          bytes: bytes,
          width: 0,
          height: 0,
          stride: 0,
          pixelStride: 1,
          rotation: 0,
          encodedImage: true);
    } catch (error) {
      if (mounted && identical(camera, _camera)) {
        setState(() => _error =
            'Gambar kamera belum dapat diproses. Coba buka ulang Kenali.');
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionTourControllerProvider);
    final phase = state.decision?.phase;
    final message = state.status == VisionTourStatus.loading
        ? 'Menyiapkan pengenal POI...'
        : state.status == VisionTourStatus.error
            ? state.errorMessage ?? 'Pengenal tidak tersedia'
            : state.showNotRecognizedHelp
                ? 'Koleksi ini belum dikenali, kemungkinan bukan POI. '
                    'Coba koleksi lain atau pindai QR.'
            : phase == VisionPhase.recognizing
                ? 'Mengenali ${state.decision!.top!.poi.name}... tahan sebentar'
                : phase == VisionPhase.ambiguous
                    ? 'Belum yakin. Dekatkan kamera ke panel POI.'
                    : phase == VisionPhase.confirmed
                        ? 'POI berhasil dikenali'
                        : 'Arahkan kamera ke ruangan atau panel POI.';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: JejakAppBar(title: const Text('Kenali pameran')),
      body: Column(children: [
        Expanded(
            child: SizedBox.expand(
                child: _camera != null
                    ? CameraPreview(_camera!)
                    : Center(
                        child: _starting
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.photo_camera_outlined,
                                size: 72, color: Colors.white54)))),
        SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                    child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error ?? message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (phase == VisionPhase.recognizing) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: state.decision!.progress),
                    ],
                    if (_error != null && !_starting) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                          onPressed: () async {
                            await _stop();
                            if (mounted) await _start();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi')),
                    ],
                  ]),
                )))),
      ]),
    );
  }
}
