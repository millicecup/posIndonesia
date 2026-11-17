import 'dart:typed_data';

abstract class ImageEmbedder {
  Future<Float32List> embed(Float32List rgb);
  Future<void> dispose();
}

/// The on-device TFLite model runs in the Android app, not the web preview.
class TfliteImageEmbedder implements ImageEmbedder {
  static const modelAsset = 'assets/models/mobilenet_v3_small_embedder.tflite';

  static Future<TfliteImageEmbedder> load() async {
    throw UnsupportedError('Kenali Pameran tersedia di aplikasi Android.');
  }

  @override
  Future<Float32List> embed(Float32List rgb) async {
    throw UnsupportedError('Kenali Pameran tersedia di aplikasi Android.');
  }

  @override
  Future<void> dispose() async {}
}
