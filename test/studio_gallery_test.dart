import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/features/photo_studio/studio_gallery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const native = MethodChannel('id.jejakpos/photo_gallery');
  const gal = MethodChannel('gal');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(native, null);
    messenger.setMockMethodCallHandler(gal, null);
  });

  test('save sends PNG filename and requires a gallery URI', () async {
    messenger.setMockMethodCallHandler(gal, (_) async => true);
    Map<Object?, Object?>? arguments;
    messenger.setMockMethodCallHandler(native, (call) async {
      expect(call.method, 'savePng');
      arguments = call.arguments as Map<Object?, Object?>;
      return 'content://media/external/images/media/123';
    });
    final png = Uint8List.fromList([137, 80, 78, 71]);
    await StudioGallery(android: true).save(png, 'JejakPOS_123');
    expect(arguments!['name'], 'JejakPOS_123.png');
    expect(arguments!['bytes'], png);

    messenger.setMockMethodCallHandler(native, (_) async => null);
    await expectLater(StudioGallery(android: true).save(png, 'JejakPOS_123'),
        throwsStateError);
  });

  test('permission denial does not attempt to save', () async {
    messenger.setMockMethodCallHandler(gal, (_) async => false);
    var saved = false;
    messenger.setMockMethodCallHandler(native, (_) async {
      saved = true;
      return 'content://photo';
    });
    await expectLater(
        StudioGallery(android: true).save(Uint8List(1), 'JejakPOS_123'),
        throwsStateError);
    expect(saved, isFalse);
  });
}
