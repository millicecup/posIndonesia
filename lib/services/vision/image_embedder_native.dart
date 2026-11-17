// lib/services/vision/image_embedder.dart
// Model TFLite on-device (MobileNetV3 Small, MediaPipe Image Embedder):
// gambar 224x224 RGB 0..1 -> vektor fitur 1024 dimensi. Tanpa internet.

import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import 'frame_converter.dart';

abstract class ImageEmbedder {
  /// [rgb] panjang 224*224*3 (lihat frame_converter.dart).
  Future<Float32List> embed(Float32List rgb);
  Future<void> dispose();
}

class TfliteImageEmbedder implements ImageEmbedder {
  TfliteImageEmbedder._(this._interpreter, this._isolate, this._outputLength);

  static const modelAsset = 'assets/models/mobilenet_v3_small_embedder.tflite';

  final Interpreter _interpreter;
  final IsolateInterpreter _isolate;
  final int _outputLength;

  static Future<TfliteImageEmbedder> load() async {
    final interpreter = await Interpreter.fromAsset(
      modelAsset,
      options: InterpreterOptions()..threads = 2,
    );
    final inputShape = interpreter.getInputTensor(0).shape;
    if (inputShape.length != 4 ||
        inputShape[1] != kVisionInputSize ||
        inputShape[2] != kVisionInputSize) {
      interpreter.close();
      throw StateError('Model vision tidak sesuai: input $inputShape');
    }
    final outLength = interpreter.getOutputTensor(0).shape.last;
    // Inferensi di isolate terpisah agar preview kamera tidak tersendat.
    final isolate =
        await IsolateInterpreter.create(address: interpreter.address);
    return TfliteImageEmbedder._(interpreter, isolate, outLength);
  }

  @override
  Future<Float32List> embed(Float32List rgb) async {
    final output = Float32List(_outputLength);
    await _isolate.run(rgb.buffer.asUint8List(), output.buffer.asUint8List());
    return output;
  }

  @override
  Future<void> dispose() async {
    await _isolate.close();
    _interpreter.close();
  }
}
