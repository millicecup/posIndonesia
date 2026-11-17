// lib/services/vision/frame_converter.dart
// Frame kamera mentah (YUV420 Android / BGRA8888 iOS) -> input model 224x224 RGB 0..1.
// Pure Dart -> bisa diuji tanpa kamera.
//
// Pra-proses HARUS sama dengan tools/vision/build_vision_index.py:
// potong persegi di tengah, ubah ukuran ke 224x224, RGB float 0..1.
// Di sini pakai sampling nearest-neighbor (cukup untuk embedding, jauh lebih cepat).

import 'dart:typed_data';

const int kVisionInputSize = 224;

/// Satu plane gambar (salinan ringan dari CameraImage.planes).
class FramePlane {
  const FramePlane({
    required this.bytes,
    required this.bytesPerRow,
    this.bytesPerPixel = 1,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

/// Pemetaan koordinat persegi tegak (a,b dalam 0..1) ke koordinat sensor.
/// [rotationDegrees] = rotasi searah jarum jam yang dibutuhkan agar gambar
/// sensor menjadi tegak (CameraDescription.sensorOrientation di Android).
(double, double) _sensorCoord(double a, double b, int rotationDegrees) {
  switch (((rotationDegrees % 360) + 360) % 360) {
    case 90:
      return (b, 1 - a);
    case 180:
      return (1 - a, 1 - b);
    case 270:
      return (1 - b, a);
    default:
      return (a, b);
  }
}

/// Mengisi [out] (224*224*3) dengan sampler [rgbAt] (x,y piksel sensor -> RGB).
Float32List _sampleSquare({
  required int width,
  required int height,
  required int rotationDegrees,
  required void Function(int x, int y, Float32List out, int offset) rgbAt,
  int size = kVisionInputSize,
}) {
  final out = Float32List(size * size * 3);
  final side = width < height ? width : height;
  final left = (width - side) ~/ 2;
  final top = (height - side) ~/ 2;
  var o = 0;
  for (var row = 0; row < size; row++) {
    final b = (row + 0.5) / size;
    for (var col = 0; col < size; col++) {
      final a = (col + 0.5) / size;
      final (sx, sy) = _sensorCoord(a, b, rotationDegrees);
      final x = left + (sx * side).floor().clamp(0, side - 1);
      final y = top + (sy * side).floor().clamp(0, side - 1);
      rgbAt(x, y, out, o);
      o += 3;
    }
  }
  return out;
}

double _clamp01(double v) => v < 0 ? 0 : (v > 255 ? 1 : v / 255);

/// YUV420 (Android, 3 plane). Mendukung UV planar (pixelStride 1) maupun
/// semi-planar/NV21 (pixelStride 2).
Float32List yuv420ToModelInput({
  required int width,
  required int height,
  required FramePlane y,
  required FramePlane u,
  required FramePlane v,
  int rotationDegrees = 0,
  int size = kVisionInputSize,
}) {
  return _sampleSquare(
    width: width,
    height: height,
    rotationDegrees: rotationDegrees,
    size: size,
    rgbAt: (x, yy, out, o) {
      final yv = y.bytes[yy * y.bytesPerRow + x * y.bytesPerPixel].toDouble();
      final uvRow = yy >> 1;
      final uvCol = x >> 1;
      final uIndex = uvRow * u.bytesPerRow + uvCol * u.bytesPerPixel;
      final vIndex = uvRow * v.bytesPerRow + uvCol * v.bytesPerPixel;
      final uv = u.bytes[uIndex] - 128.0;
      final vv = v.bytes[vIndex] - 128.0;
      out[o] = _clamp01(yv + 1.402 * vv);
      out[o + 1] = _clamp01(yv - 0.344136 * uv - 0.714136 * vv);
      out[o + 2] = _clamp01(yv + 1.772 * uv);
    },
  );
}

/// BGRA8888 (iOS, 1 plane).
Float32List bgraToModelInput({
  required int width,
  required int height,
  required FramePlane plane,
  int rotationDegrees = 0,
  int size = kVisionInputSize,
}) {
  return _sampleSquare(
    width: width,
    height: height,
    rotationDegrees: rotationDegrees,
    size: size,
    rgbAt: (x, y, out, o) {
      final i = y * plane.bytesPerRow + x * 4;
      out[o] = plane.bytes[i + 2] / 255;
      out[o + 1] = plane.bytes[i + 1] / 255;
      out[o + 2] = plane.bytes[i] / 255;
    },
  );
}
