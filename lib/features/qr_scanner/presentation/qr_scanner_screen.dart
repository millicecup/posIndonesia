// lib/features/qr_scanner/presentation/qr_scanner_screen.dart
// UI12 QR Scanner: pemindaian kamera (mobile_scanner).
// DF-09: kamera langsung menyala saat layar dibuka (sama seperti "Kenali"),
// tanpa harus menekan "Aktifkan kamera" lagi. Tombol tetap ada untuk mematikan.

import '../../../shared/widgets/jejak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../services/qr_service.dart';
import '../state/qr_scanner_controller.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, this.autoStartCamera = true});

  /// true (default) = kamera langsung aktif saat layar dibuka.
  final bool autoStartCamera;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  MobileScannerController? _cameraController;
  bool _cameraOn = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStartCamera) _setCamera(true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _setCamera(bool on) {
    _cameraOn = on;
    if (on) {
      _cameraController ??= MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    } else {
      _cameraController?.dispose();
      _cameraController = null;
    }
  }

  void _toggleCamera() => setState(() => _setCamera(!_cameraOn));

  Future<void> _submit(String raw) async {
    final result =
        await ref.read(qrScannerControllerProvider.notifier).submit(raw);
    if (!mounted || result == null) return;
    switch (result) {
      case QrValid(:final poi):
        context.pushReplacement(AppRoutes.poiDetail(poi.id));
      case QrInvalidFormat():
        _showMessage('QR tidak dikenali. Pindai QR pada penanda koleksi museum.');
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
      appBar: JejakAppBar(
        title: const Text('Pindai QR koleksi'),
        leading: BackButton(onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.explore);
          }
        }),
      ),
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
                      errorBuilder: (context, error, _) => _CameraError(
                        permissionDenied: error.errorCode ==
                            MobileScannerErrorCode.permissionDenied,
                      ),
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
                        'Kamera nonaktif.\nAktifkan kamera untuk memindai QR koleksi.',
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
          const SizedBox(height: 16),
          const Text(
            'Arahkan kamera ke QR pada penanda koleksi. Informasi koleksi akan terbuka otomatis. Pemindaian dapat dilakukan tanpa koneksi internet.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.permissionDenied});
  final bool permissionDenied;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.darkGrey,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Text(
          permissionDenied
              ? 'Izin kamera dibutuhkan untuk memindai QR. '
                  'Izinkan kamera di Pengaturan aplikasi.'
              : 'Kamera belum bisa dibuka. Matikan lalu aktifkan kamera lagi.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      );
}
