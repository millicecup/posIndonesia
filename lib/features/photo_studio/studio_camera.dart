import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../providers/providers.dart';
import '../../services/permission_service.dart';

final studioCameraFactoryProvider = Provider<StudioCamera Function()>(
  (ref) => DeviceStudioCamera.new,
);

/// Izin kamera untuk Photo Studio (DF-04). Di-override di test.
final studioCameraPermissionProvider = Provider<CameraPermissionGate>(
  (ref) => PermissionHandlerCameraGate(ref.watch(permissionServiceProvider)),
);

abstract class CameraPermissionGate {
  Future<AppPermissionStatus> status();
  Future<AppPermissionStatus> request();
  Future<bool> openSettings();
}

class PermissionHandlerCameraGate implements CameraPermissionGate {
  PermissionHandlerCameraGate(this._service);
  final PermissionService _service;

  // Web / platform tanpa plugin izin: biarkan plugin kamera yang meminta izin.
  Future<AppPermissionStatus> _guard(
      Future<AppPermissionStatus> Function() call) async {
    if (kIsWeb) return AppPermissionStatus.granted;
    try {
      return await call();
    } catch (e) {
      // Plugin izin tidak tersedia/bermasalah: plugin kamera tetap akan
      // meminta izin sendiri dan error-nya ditangani layar Photo Studio.
      AppLogger.warning('PHOTO', 'Cek izin kamera gagal, lanjut ke kamera: $e');
      return AppPermissionStatus.granted;
    }
  }

  @override
  Future<AppPermissionStatus> status() =>
      _guard(() => _service.check(AppPermissionType.camera));

  @override
  Future<AppPermissionStatus> request() =>
      _guard(() => _service.request(AppPermissionType.camera));

  @override
  Future<bool> openSettings() => _service.openSettings();
}

abstract class StudioCamera {
  Future<void> initialize();
  Widget preview();
  bool get mirrorPhoto;

  /// Rasio lebar/tinggi preview dalam posisi potret. Kanvas Photo Studio
  /// mengikuti rasio ini agar preview tidak dipotong (DF-10: terlalu zoom).
  double get aspectRatio;
  Future<Uint8List> takePhoto();
  Future<void> dispose();
}

class DeviceStudioCamera implements StudioCamera {
  CameraController? _controller;

  @override
  bool get mirrorPhoto =>
      _controller?.description.lensDirection == CameraLensDirection.front;

  @override
  double get aspectRatio {
    final size = _controller?.value.previewSize;
    if (size == null || size.width == 0 || size.height == 0) return 3 / 4;
    // previewSize dilaporkan dalam orientasi lanskap sensor.
    final portrait = size.shortestSide / size.longestSide;
    return portrait;
  }

  @override
  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('NoCamera', 'Kamera tidak ditemukan.');
    }
    final front =
        cameras.where((c) => c.lensDirection == CameraLensDirection.front);
    final controller = CameraController(
      front.isEmpty ? cameras.first : front.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    await controller.initialize();
    if (!kIsWeb) {
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    }
    // DF-10: pakai sudut pandang terlebar yang didukung kamera.
    try {
      await controller.setZoomLevel(await controller.getMinZoomLevel());
    } catch (_) {
      // Zoom tidak didukung (mis. web): abaikan.
    }
  }

  @override
  Widget preview() {
    final controller = _controller!;
    final size = controller.value.previewSize!;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.shortestSide,
          height: size.longestSide,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  @override
  Future<Uint8List> takePhoto() async {
    final file = await _controller!.takePicture();
    return file.readAsBytes();
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
