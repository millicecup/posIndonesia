// Keep the native TFLite runtime out of the browser preview.
export 'image_embedder_web.dart'
    if (dart.library.io) 'image_embedder_native.dart';
