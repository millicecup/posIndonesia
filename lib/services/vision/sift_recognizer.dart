import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

/// Android OpenCV SIFT runs on a dedicated native worker, entirely offline.
class SiftRecognizer {
  const SiftRecognizer();
  static const channel = MethodChannel('id.jejakpos/sift_vision');
  Future<Map<String, dynamic>> recognizeImage(Uint8List bytes) =>
      throw UnsupportedError(
          'Encoded frames are supported in the local browser demo.');
  Future<int> initialize() async =>
      (await channel.invokeMethod<int>('initialize'))!;
  Future<Map<String, dynamic>> recognize({
    required Uint8List bytes,
    required int width,
    required int height,
    required int stride,
    required int pixelStride,
    required int rotation,
  }) async =>
      Map<String, dynamic>.from((await channel.invokeMapMethod<String, dynamic>(
        'recognize',
        {
          'bytes': bytes,
          'width': width,
          'height': height,
          'stride': stride,
          'pixelStride': pixelStride,
          'rotation': rotation
        },
      ))!);
}

/// Local laptop demo. Android continues to use native OpenCV without this server.
class BrowserSiftRecognizer extends SiftRecognizer {
  const BrowserSiftRecognizer();
  @override
  Future<int> initialize() async {
    final response = await http.get(Uri.base.resolve('/api/health'));
    if (response.statusCode != 200)
      throw StateError('Server CV lokal belum siap');
    return (jsonDecode(response.body) as Map<String, dynamic>)['references']
        as int;
  }

  @override
  Future<Map<String, dynamic>> recognizeImage(Uint8List bytes) async {
    final response = await http.post(Uri.base.resolve('/api/recognize'),
        headers: {'Content-Type': 'image/jpeg'}, body: bytes);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200)
      throw StateError(data['error'] ?? 'Analisis foto gagal');
    final match = data['match'] as Map<String, dynamic>?;
    return {
      'status': data['status'],
      'match': match == null
          ? null
          : {
              'poiId': match['app_poi_id'],
              'inliers': match['inliers'],
              'inlierRatio': match['inlier_ratio']
            },
      'elapsedMs': data['elapsed_ms']
    };
  }
}
