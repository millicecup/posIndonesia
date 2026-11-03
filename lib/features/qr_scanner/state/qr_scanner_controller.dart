// lib/features/qr_scanner/state/qr_scanner_controller.dart
// Validasi QR -> laporkan ke TriggerEngine -> POI (fallback F02). PIC: Firda.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../../../services/qr_service.dart';
import '../../../services/trigger_engine.dart';

class QrScannerController extends AutoDisposeNotifier<QrResult?> {
  bool _busy = false;

  @override
  QrResult? build() => null;

  /// Dipanggil dari kamera atau input manual. Return hasil validasi.
  Future<QrResult?> submit(String raw) async {
    if (_busy) return null;
    _busy = true;
    try {
      final result = await ref.read(qrServiceProvider).validate(raw);
      if (result is QrValid) {
        // Catat sebagai identifikasi POI (sekali per sesi diatur engine).
        ref.read(triggerEngineProvider).reportIdentification(result.poi, TriggerSource.qr);
        await ref.read(progressProvider.notifier).markVisited(result.poi.id);
      }
      state = result;
      return result;
    } finally {
      _busy = false;
    }
  }

  void clear() => state = null;
}

final qrScannerControllerProvider =
    NotifierProvider.autoDispose<QrScannerController, QrResult?>(QrScannerController.new);
