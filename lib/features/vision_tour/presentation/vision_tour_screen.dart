// lib/features/vision_tour/presentation/vision_tour_screen.dart
// "Kenali pameran": arahkan kamera ke pameran -> POI dikenali otomatis.
// Pengenal utama saat tur (GPS di dalam gedung terlalu kasar, POI hanya 1-10 m).
// Layar tetap terbuka selama tur; tiap POI baru membuka UI08 lewat app.dart.

import '../../../shared/widgets/jejak_app_bar.dart';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/providers.dart';
import '../../../services/vision/frame_converter.dart';
import '../../../services/vision/vision_matcher.dart';
import '../state/vision_tour_controller.dart';
import 'web_vision_tour_screen.dart';

class VisionTourScreen extends ConsumerStatefulWidget {
  const VisionTourScreen({super.key});

  @override
  ConsumerState<VisionTourScreen> createState() => _VisionTourScreenState();
}

class _VisionTourScreenState extends ConsumerState<VisionTourScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  String? _cameraError;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final back =
          cameras.where((c) => c.lensDirection == CameraLensDirection.back);
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'Kamera tidak ditemukan');
      }
      final description = back.isEmpty ? cameras.first : back.first;
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.startImageStream(
          (image) => _onFrame(image, description.sensorOrientation));
      setState(() {
        _camera = controller;
        _cameraError = null;
      });
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _cameraError = e.code.startsWith('CameraAccessDenied')
            ? 'Izin kamera ditolak. Aktifkan di Pengaturan, atau pakai QR.'
            : 'Kamera tidak bisa dibuka (${e.description ?? e.code}).');
      }
    } catch (e) {
      // Error lain (mis. plugin kamera tidak tersedia): jangan biarkan spinner
      // berputar selamanya.
      if (mounted) {
        setState(() => _cameraError =
            'Kamera tidak bisa dibuka. Coba lagi atau pakai QR.');
      }
    }
  }

  void _stopCamera() {
    final c = _camera;
    _camera = null;
    if (c == null) return;
    if (c.value.isStreamingImages) c.stopImageStream().catchError((_) {});
    c.dispose();
  }

  void _onFrame(CameraImage image, int sensorOrientation) {
    final interval = ref.read(appConfigProvider).visionFrameInterval;
    final now = DateTime.now();
    if (now.difference(_lastFrame) < interval) return;
    // Jangan analisis saat halaman lain (UI08/detail POI) sedang tampil.
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final controller = ref.read(visionTourControllerProvider.notifier);
    if (controller.isBusy) return;
    _lastFrame = now;

    if (controller.usesSift) {
      if (image.format.group != ImageFormatGroup.yuv420 ||
          image.planes.isEmpty) {
        return;
      }
      final y = image.planes.first;
      controller.processSiftFrame(
          bytes: Uint8List.fromList(y.bytes),
          width: image.width,
          height: image.height,
          stride: y.bytesPerRow,
          pixelStride: y.bytesPerPixel ?? 1,
          rotation: sensorOrientation);
      return;
    }
    final input = _toModelInput(image, sensorOrientation);
    if (input != null) controller.processFrame(input);
  }

  Float32List? _toModelInput(CameraImage image, int rotation) {
    FramePlane plane(Plane p) => FramePlane(
        bytes: p.bytes,
        bytesPerRow: p.bytesPerRow,
        bytesPerPixel: p.bytesPerPixel ?? 1);
    switch (image.format.group) {
      case ImageFormatGroup.yuv420 when image.planes.length >= 3:
        return yuv420ToModelInput(
          width: image.width,
          height: image.height,
          y: plane(image.planes[0]),
          u: plane(image.planes[1]),
          v: plane(image.planes[2]),
          rotationDegrees: rotation,
        );
      case ImageFormatGroup.bgra8888:
        return bgraToModelInput(
          width: image.width,
          height: image.height,
          plane: plane(image.planes[0]),
          rotationDegrees: rotation,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const WebVisionTourScreen();
    final state = ref.watch(visionTourControllerProvider);
    final camera = _camera;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: JejakAppBar(
        title: const Text('Kenali pameran'),
        actions: [
          IconButton(
            tooltip: 'Pindai QR (cadangan)',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push(AppRoutes.qrScanner),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (camera != null && camera.value.isInitialized)
            _CameraView(controller: camera)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _cameraError == null
                    ? const CircularProgressIndicator()
                    : Text(_cameraError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white)),
              ),
            ),
          IgnorePointer(child: _GuideFrame(phase: state.decision?.phase)),
          Align(
            alignment: Alignment.bottomCenter,
            child: _StatusPanel(state: state),
          ),
        ],
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({required this.controller});
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize!;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

/// Panduan membidik panel. SIFT Android menganalisis seluruh frame.
class _GuideFrame extends StatelessWidget {
  const _GuideFrame({this.phase});
  final VisionPhase? phase;

  @override
  Widget build(BuildContext context) {
    final color = switch (phase) {
      VisionPhase.recognizing || VisionPhase.confirmed => AppColors.orange,
      _ => Colors.white70,
    };
    return LayoutBuilder(builder: (context, c) {
      final side = c.maxWidth * 0.85;
      return Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: side,
          height: side,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    });
  }
}

class _StatusPanel extends ConsumerWidget {
  const _StatusPanel({required this.state});
  final VisionTourState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final decision = state.decision;
    final recognized = state.recognizedPoi;

    final Widget body;
    if (state.status == VisionTourStatus.loading) {
      body = const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Menyiapkan pengenal pameran...'),
      );
    } else if (state.status == VisionTourStatus.error) {
      body = ListTile(
        leading: const Icon(Icons.error_outline, color: AppColors.danger),
        title: Text(state.errorMessage ?? 'Pengenal pameran tidak tersedia'),
        trailing: TextButton(
          onPressed: () => context.push(AppRoutes.qrScanner),
          child: const Text('Pakai QR'),
        ),
      );
    } else if (state.showNotRecognizedHelp) {
      body = const _NotRecognizedHelp();
    } else {
      final (icon, text) = switch (decision?.phase) {
        VisionPhase.recognizing => (
            Icons.center_focus_strong,
            'Mengenali ${decision!.top!.poi.name}... tahan sebentar'
          ),
        VisionPhase.ambiguous => (
            Icons.zoom_in,
            'Kurang yakin. Dekatkan kamera ke papan informasi pameran.'
          ),
        VisionPhase.confirmed => (Icons.check_circle, 'Pameran dikenali!'),
        _ => (
            Icons.photo_camera,
            'Arahkan kamera ke pameran di dalam bingkai.'
          ),
      };
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
              leading: Icon(icon, color: AppColors.orange), title: Text(text)),
          if (decision?.phase == VisionPhase.recognizing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(value: decision!.progress),
            ),
          if (recognized != null)
            Card(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              color: AppColors.orangeLight,
              child: ListTile(
                leading: const Icon(Icons.museum, color: AppColors.orange),
                title: Text('${recognized.id}: ${recognized.name}'),
                subtitle: Text(state.newlyTriggered
                    ? 'Baru saja dikenali'
                    : 'Sudah dikunjungi di sesi ini'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.poiDetail(recognized.id)),
              ),
            ),
          if (kDebugMode &&
              decision?.top != null &&
              ref.read(siftRecognizerProvider) == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                [decision!.top, decision.runnerUp]
                    .whereType<VisionScore>()
                    .map((s) => '${s.poi.id} ${s.similarity.toStringAsFixed(2)}'
                        '${s.gpsPenalty > 0 ? ' (gps -${s.gpsPenalty.toStringAsFixed(2)})' : ''}')
                    .join('   '),
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
        ],
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: body,
      ),
    );
  }
}

/// DF-02: objek di kamera tidak cocok dengan koleksi POI mana pun selama
/// beberapa frame. Beri tahu pengguna dan tawarkan jalan lain.
class _NotRecognizedHelp extends ConsumerWidget {
  const _NotRecognizedHelp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      key: const Key('vision-not-recognized'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline, color: AppColors.orange),
              SizedBox(width: 10),
              Expanded(
                child: Text('Koleksi ini belum dikenali',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Objek ini kemungkinan bukan koleksi POI JejakPOS. Arahkan kamera '
            'ke koleksi lain yang punya papan informasi, atau pindai QR di '
            'penanda koleksi.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.qrScanner),
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Pindai QR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.poiList),
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('Daftar POI'),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => ref
                .read(visionTourControllerProvider.notifier)
                .resetRecognition(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba koleksi lain'),
          ),
        ],
      ),
    );
  }
}
