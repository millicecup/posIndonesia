import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studioCameraFactoryProvider = Provider<StudioCamera Function()>(
  (ref) => DeviceStudioCamera.new,
);

abstract class StudioCamera {
  Future<void> initialize();
  Widget preview();
  bool get mirrorPhoto;
  Future<Uint8List> takePhoto();
  Future<void> dispose();
}

class DeviceStudioCamera implements StudioCamera {
  CameraController? _controller;

  @override
  bool get mirrorPhoto =>
      _controller?.description.lensDirection == CameraLensDirection.front;

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
  }

  @override
  Widget preview() {
    final controller = _controller!;
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
