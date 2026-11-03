// lib/features/qr_scanner/presentation/qr_scanner_screen.dart
// UI12 QR Scanner: kamera (mobile_scanner) + input manual untuk emulator.
// TODO(Firda): bingkai pemindai sesuai wireframe, senter, catatan PoC PB05.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../services/qr_service.dart';
import '../state/qr_scanner_controller.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _manualController = TextEditingController();
  MobileScannerController? _cameraController;
  bool _cameraOn = false;

  @override
  void dispose() {
    _manualController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _toggleCamera() {
    setState(() {
      _cameraOn = !_cameraOn;
      if (_cameraOn) {
        _cameraController = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        );
      } else {
        _cameraController?.dispose();
        _cameraController = null;
      }
    });
  }

  Future<void> _submit(String raw) async {
    final result =
        await ref.read(qrScannerControllerProvider.notifier).submit(raw);
    if (!mounted || result == null) return;
    switch (result) {
      case QrValid(:final poi):
        context.pushReplacement(AppRoutes.poiDetail(poi.id));
      case QrInvalidFormat():
        _showMessage('Format QR tidak dikenali. Contoh: QR-P01');
      case QrNotFound():
        _showMessage('QR tidak terdaftar di koleksi museum.');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai QR Koleksi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _cameraOn && _cameraController != null
                  ? MobileScanner(
                      controller: _cameraController,
                      onDetect: (capture) {
                        final raw = capture.barcodes.isEmpty
                            ? null
                            : capture.barcodes.first.rawValue;
                        if (raw != null) _submit(raw);
                      },
                    )
                  : Container(
                      color: AppColors.darkGrey,
                      alignment: Alignment.center,
                      child: const Text(
                        'Kamera nonaktif.\nDi emulator, pakai input manual di bawah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _toggleCamera,
            icon: Icon(_cameraOn ? Icons.videocam_off : Icons.videocam),
            label: Text(_cameraOn ? 'Matikan kamera' : 'Aktifkan kamera'),
          ),
          const Divider(height: 32),
          Text('Input kode manual (fallback/emulator)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _manualController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Contoh: QR-P01',
              border: OutlineInputBorder(),
            ),
            onSubmitted: _submit,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _submit(_manualController.text),
            child: const Text('Cek Kode'),
          ),
        ],
      ),
    );
  }
}
