import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../shared/widgets/jejak_app_bar.dart';
import '../../../services/vision/vision_matcher.dart';
import '../state/vision_tour_controller.dart';

/// Full application laptop preview: real camera or reference-photo walkthrough.
class WebVisionTourScreen extends ConsumerStatefulWidget {
  const WebVisionTourScreen({super.key});
  @override
  ConsumerState<WebVisionTourScreen> createState() =>
      _WebVisionTourScreenState();
}

class _WebVisionTourScreenState extends ConsumerState<WebVisionTourScreen> {
  CameraController? _camera;
  Timer? _timer;
  bool _busy = false;
  bool _starting = false;
  String? _error;
  List<Map<String, dynamic>> _references = [];
  String? _selected;
  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    try {
      final response = await http.get(Uri.base.resolve('/api/pois'));
      if (response.statusCode != 200)
        throw StateError('Server CV belum tersedia');
      final all =
          (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
      final seen = <String>{};
      final refs = all.where((r) => seen.add(r['poi_id'] as String)).toList();
      if (mounted)
        setState(() {
          _references = refs;
          _selected = refs.isEmpty ? null : refs.first['reference'] as String;
        });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _start() async {
    if (_starting || _camera != null) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    CameraController? c;
    try {
      final devices = await availableCameras();
      if (devices.isEmpty) throw StateError('Kamera tidak ditemukan');
      c = CameraController(devices.first, ResolutionPreset.medium,
          enableAudio: false);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _camera = c);
      _timer =
          Timer.periodic(const Duration(milliseconds: 1500), (_) => _capture());
    } catch (e) {
      await c?.dispose();
      if (mounted)
        setState(() => _error =
            'Kamera belum tersedia. Kamu tetap bisa mencoba foto lokasi POI. $e');
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

  Future<void> _process(Uint8List bytes) async {
    await ref.read(visionTourControllerProvider.notifier).processSiftFrame(
        bytes: bytes,
        width: 0,
        height: 0,
        stride: 0,
        pixelStride: 1,
        rotation: 0,
        encodedImage: true);
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
      await _process(await photo.readAsBytes());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _busy = false;
    }
  }

  Future<void> _sample() async {
    if (_busy || _selected == null) return;
    await _stop();
    if (!mounted) return;
    _busy = true;
    setState(() => _error = null);
    try {
      final response = await http.get(Uri.base.resolve('/$_selected'));
      if (response.statusCode != 200)
        throw StateError('Foto lokasi tidak dapat dimuat');
      ref.read(visionTourControllerProvider.notifier).resetRecognition();
      for (var i = 0; i < 3 && mounted; i++) {
        await _process(response.bodyBytes);
        if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) break;
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _busy = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
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
            ? (state.errorMessage ?? 'Pengenal tidak tersedia')
            : phase == VisionPhase.recognizing
                ? 'Mengenali ${state.decision!.top!.poi.name} (${state.decision!.streak}/3)'
                : phase == VisionPhase.ambiguous
                    ? 'Belum yakin. Dekatkan kamera ke panel.'
                    : phase == VisionPhase.confirmed
                        ? 'POI berhasil dikenali'
                        : 'Arahkan kamera ke ruangan atau panel POI.';
    return Scaffold(
        appBar: JejakAppBar(title: const Text('Kenali Pameran')),
        body: SingleChildScrollView(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: ColoredBox(
                                          color: Colors.black87,
                                          child: _camera != null
                                              ? CameraPreview(_camera!)
                                              : const Center(
                                                  child: Icon(
                                                      Icons
                                                          .photo_camera_outlined,
                                                      size: 72,
                                                      color:
                                                          Colors.white54))))),
                              const SizedBox(height: 16),
                              Text(message,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              if (phase == VisionPhase.recognizing)
                                LinearProgressIndicator(
                                    value: state.decision!.progress),
                              if (_error != null)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Text(_error!)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                  onPressed: _starting
                                      ? null
                                      : _camera == null
                                          ? _start
                                          : _stop,
                                  icon: Icon(_camera == null
                                      ? Icons.videocam
                                      : Icons.stop),
                                  label: Text(_starting
                                      ? 'Membuka kamera...'
                                      : _camera == null
                                          ? 'Aktifkan kamera laptop'
                                          : 'Hentikan kamera')),
                              const SizedBox(height: 24),
                              Text('Coba alur dengan foto lokasi',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const Text(
                                  'Pilih POI lalu coba pengenalan. Foto contoh diproses CV lokal; hasilnya membuka alur POI yang sama seperti kamera.'),
                              DropdownButtonFormField<String>(
                                  initialValue: _selected,
                                  isExpanded: true,
                                  items: [
                                    for (final r in _references)
                                      DropdownMenuItem(
                                          value: r['reference'] as String,
                                          child: Text(
                                              "${r['poi_id']} · ${r['name']}"))
                                  ],
                                  onChanged: _busy
                                      ? null
                                      : (value) =>
                                          setState(() => _selected = value)),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                  onPressed: _selected == null ||
                                          _busy ||
                                          state.status != VisionTourStatus.ready
                                      ? null
                                      : _sample,
                                  icon: const Icon(Icons.image_search),
                                  label: Text(_busy
                                      ? 'Memeriksa foto...'
                                      : 'Kenali foto lokasi')),
                              const SizedBox(height: 16),
                              const Text(
                                  'Versi uji lokal laptop. Kamera fisik museum tetap diperlukan untuk menilai akurasi lapangan.'),
                            ]))))));
  }
}
