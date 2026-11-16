// test/services/trigger_engine_test.dart
// Uji TriggerEngine: trigger sekali per sesi, approaching, hysteresis, debounce.

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/core/config/app_config.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/services/trigger_engine.dart';

import '../helpers/test_data.dart';

// 1 derajat lintang ~ 111.195 m
const double _metersPerDegLat = 111195;

UserPosition _at(Poi poi, {double northMeters = 0, double accuracy = 5}) =>
    UserPosition(
      latitude: poi.latitude! + northMeters / _metersPerDegLat,
      longitude: poi.longitude!,
      accuracyMeters: accuracy,
      timestamp: DateTime.now(),
    );

void main() {
  late List<Poi> pois;
  late Poi p01;
  late TriggerEngine engine;

  setUp(() {
    pois = loadDataset();
    p01 = pois.first;
    // Debounce 2 pembacaan, hysteresis 1 m (default)
    engine = TriggerEngine(config: const AppConfig())..setPois(pois);
  });

  tearDown(() => engine.dispose());

  List<TriggerEvent> feed(UserPosition pos, {int times = 1}) {
    final all = <TriggerEvent>[];
    for (var i = 0; i < times; i++) {
      all.addAll(engine.updatePosition(pos));
    }
    return all;
  }

  List<TriggerEvent> triggeredFor(List<TriggerEvent> events, String id) => events
      .where((e) => e.type == TriggerEventType.triggered && e.poi.id == id)
      .toList();

  test('masuk radius 3 m memicu POI setelah debounce', () {
    final first = feed(_at(p01, northMeters: 2));
    expect(triggeredFor(first, 'P01'), isEmpty, reason: 'baru 1 pembacaan');
    final second = feed(_at(p01, northMeters: 2));
    expect(triggeredFor(second, 'P01'), hasLength(1));
    expect(engine.hasTriggered('P01'), isTrue);
  });

  test('tetap di area tidak memicu berulang', () {
    final events = feed(_at(p01), times: 20);
    expect(triggeredFor(events, 'P01'), hasLength(1));
  });

  test('keluar lalu masuk lagi dalam sesi yang sama tidak memicu ulang', () {
    final events = <TriggerEvent>[
      ...feed(_at(p01), times: 3),
      ...feed(_at(p01, northMeters: 60), times: 3), // keluar jauh
      ...feed(_at(p01), times: 3), // masuk lagi
    ];
    expect(triggeredFor(events, 'P01'), hasLength(1));
    expect(
        events.where((e) => e.poi.id == 'P01' && e.type == TriggerEventType.exited),
        hasLength(1));
  });

  test('status approaching saat sekitar 4-6 m', () {
    final events = feed(_at(p01, northMeters: 5), times: 2);
    expect(
        events.where(
            (e) => e.poi.id == 'P01' && e.type == TriggerEventType.approaching),
        hasLength(1));
    expect(engine.statuses['P01']!.proximity, PoiProximity.approaching);
    expect(engine.hasTriggered('P01'), isFalse);
  });

  test('hysteresis: berkedip di sekitar batas 3 m tidak keluar dari triggered', () {
    feed(_at(p01, northMeters: 2.5), times: 2);
    expect(engine.statuses['P01']!.proximity, PoiProximity.triggered);
    // 3.5 m masih dalam batas keluar (3 + 1 m)
    final events = <TriggerEvent>[];
    for (var i = 0; i < 10; i++) {
      events.addAll(engine.updatePosition(_at(p01, northMeters: i.isEven ? 3.5 : 2.5)));
    }
    expect(engine.statuses['P01']!.proximity, PoiProximity.triggered);
    expect(events.where((e) => e.poi.id == 'P01'), isEmpty);
  });

  test('debounce: satu pembacaan liar tidak memicu', () {
    feed(_at(p01, northMeters: 60), times: 2);
    final events = <TriggerEvent>[
      ...engine.updatePosition(_at(p01)), // lompatan sesaat
      ...engine.updatePosition(_at(p01, northMeters: 60)),
    ];
    expect(triggeredFor(events, 'P01'), isEmpty);
  });

  test('akurasi buruk diabaikan', () {
    final events = feed(_at(p01, accuracy: 200), times: 5);
    expect(events, isEmpty);
  });

  test('GPS dalam gedung (akurasi > 5 m) hanya approaching, tidak memicu POI', () {
    final events = feed(_at(p01, accuracy: 12), times: 5);
    expect(triggeredFor(events, 'P01'), isEmpty);
    expect(engine.statuses['P01']!.proximity, PoiProximity.approaching);
    // Konfirmasi lewat computer vision tetap bisa memicu.
    expect(engine.reportIdentification(p01, TriggerSource.vision)?.source,
        TriggerSource.vision);
  });

  test('simulasi tidak terkena syarat akurasi GPS', () {
    final sim = _at(p01, accuracy: 12).copyWith(source: PositionSource.simulation);
    final events = feed(sim, times: 2);
    expect(triggeredFor(events, 'P01'), hasLength(1));
  });

  test('identifikasi beacon/QR hanya sekali per sesi', () {
    final first = engine.reportIdentification(p01, TriggerSource.qr);
    final second = engine.reportIdentification(p01, TriggerSource.beacon);
    expect(first, isNotNull);
    expect(second, isNull);
  });

  test('POI yang sudah terpicu via QR tidak terpicu lagi via GPS', () {
    engine.reportIdentification(p01, TriggerSource.qr);
    final events = feed(_at(p01), times: 3);
    expect(triggeredFor(events, 'P01'), isEmpty);
  });

  test('restoreSession: POI dari kunjungan yang sama tidak terpicu lagi', () {
    // Simulasi app ditutup lalu dibuka: engine baru dipulihkan dari penyimpanan.
    final reopened = TriggerEngine()
      ..setPois(pois)
      ..restoreSession(['P01']);
    final events = <TriggerEvent>[];
    for (var i = 0; i < 3; i++) {
      events.addAll(reopened.updatePosition(_at(p01)));
    }
    expect(triggeredFor(events, 'P01'), isEmpty);
    expect(reopened.reportIdentification(p01, TriggerSource.qr), isNull);
    reopened.dispose();
  });

  test('resetSession membuat POI bisa terpicu lagi', () {
    feed(_at(p01), times: 2);
    engine.resetSession();
    final events = feed(_at(p01), times: 2);
    expect(triggeredFor(events, 'P01'), hasLength(1));
  });

  test('triggerOncePerSession=false: boleh terpicu lagi setelah keluar', () {
    final repeatable = p01.copyWith(
        triggerRule: p01.triggerRule.copyWith(triggerOncePerSession: false));
    engine.setPois([repeatable]);
    final events = <TriggerEvent>[
      ...feed(_at(repeatable), times: 2),
      ...feed(_at(repeatable, northMeters: 60), times: 2),
      ...feed(_at(repeatable), times: 2),
    ];
    expect(triggeredFor(events, 'P01'), hasLength(2));
  });

  test('event dikirim juga lewat stream', () async {
    final future = engine.events.firstWhere((e) => e.type == TriggerEventType.triggered);
    feed(_at(p01), times: 2);
    final event = await future;
    expect(event.poi.id, 'P01');
  });
}
