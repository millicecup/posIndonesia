// lib/providers/providers.dart
// Registrasi (DI) semua service & repository untuk frontend (PIC: Matilda).
// Frontend cukup: `import 'package:jejakpos/providers/providers.dart';`

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';
import '../data/datasources/poi_local_datasource.dart';
import '../data/datasources/progress_local_datasource.dart';
import '../data/models/models.dart';
import '../data/repositories/poi_repository.dart';
import '../data/repositories/poi_repository_impl.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/progress_repository_impl.dart';
import '../services/audio_service.dart';
import '../services/beacon_service.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../services/permission_service.dart';
import '../services/qr_service.dart';
import '../services/simulation_service.dart';
import '../services/trigger_engine.dart';

// ================= Konfigurasi =================

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

/// Di-override di main.dart setelah SharedPreferences.getInstance().
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider harus di-override di main()'),
);

// ================= Data POI =================

final poiLocalDataSourceProvider =
    Provider<PoiLocalDataSource>((ref) => PoiLocalDataSource());

final poiRepositoryProvider = Provider<PoiRepository>(
  (ref) => PoiRepositoryImpl(
    ref.watch(poiLocalDataSourceProvider),
    remoteMediaEnabled: ref.watch(mediaServiceProvider).isRemoteEnabled,
  ),
);

/// Semua POI (urut tourOrder).
final poisProvider = FutureProvider<List<Poi>>(
  (ref) => ref.watch(poiRepositoryProvider).getAllPois(),
);

final poiCategoriesProvider = FutureProvider<List<PoiCategory>>(
  (ref) => ref.watch(poiRepositoryProvider).getCategories(),
);

final poiByIdProvider = FutureProvider.family<Poi?, String>(
  (ref, id) => ref.watch(poiRepositoryProvider).getPoiById(id),
);

final datasetValidationProvider = FutureProvider<DatasetValidationReport>(
  (ref) => ref.watch(poiRepositoryProvider).validateDataset(),
);

// ================= Progres =================

final progressLocalDataSourceProvider = Provider<ProgressLocalDataSource>(
  (ref) => ProgressLocalDataSource(ref.watch(sharedPreferencesProvider)),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepositoryImpl(
    ref.watch(progressLocalDataSourceProvider),
    ref.watch(poiRepositoryProvider),
  ),
);

class ProgressController extends AsyncNotifier<VisitProgress> {
  ProgressRepository get _repo => ref.read(progressRepositoryProvider);

  @override
  Future<VisitProgress> build() =>
      ref.watch(progressRepositoryProvider).getProgressSummary();

  Future<bool> markVisited(String poiId) async {
    final isNew = await _repo.markVisited(poiId);
    if (isNew) state = AsyncData(await _repo.getProgressSummary());
    return isNew;
  }

  Future<bool> collectStamp(String stampId) async {
    final isNew = await _repo.collectStamp(stampId);
    if (isNew) state = AsyncData(await _repo.getProgressSummary());
    return isNew;
  }

  Future<void> reset() async {
    await _repo.resetProgress();
    state = AsyncData(await _repo.getProgressSummary());
  }
}

/// Progres kunjungan & perangko (tersimpan permanen).
final progressProvider =
    AsyncNotifierProvider<ProgressController, VisitProgress>(ProgressController.new);

/// Rekomendasi POI berikutnya (F07).
final recommendedNextPoiProvider = FutureProvider<Poi?>((ref) async {
  final progress = await ref.watch(progressProvider.future);
  return ref
      .watch(poiRepositoryProvider)
      .getRecommendedNextPoi(progress.visitedPoiIds);
});

// ================= Services =================

final permissionServiceProvider =
    Provider<PermissionService>((ref) => PermissionService());

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final mediaServiceProvider = Provider<MediaService>((ref) {
  final service = MediaService(baseUrl: ref.watch(appConfigProvider).mediaBaseUrl);
  ref.onDispose(service.dispose);
  return service;
});

/// Lokasi audio/foto. `download: false` hanya memeriksa APK dan cache.
final mediaSourceProvider = FutureProvider.autoDispose
    .family<MediaSource?, ({String path, bool download})>(
  (ref, media) => ref
      .watch(mediaServiceProvider)
      .resolve(media.path, download: media.download),
);

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(media: ref.watch(mediaServiceProvider));
  ref.onDispose(service.dispose);
  return service;
});

final qrServiceProvider =
    Provider<QrService>((ref) => QrService(ref.watch(poiRepositoryProvider)));

final simulationServiceProvider = Provider<SimulationService>((ref) {
  final service = SimulationService(config: ref.watch(appConfigProvider));
  ref.onDispose(service.dispose);
  return service;
});

class SimulationModeController extends Notifier<bool> {
  @override
  bool build() => ref.watch(appConfigProvider).simulationModeDefault;

  void setEnabled(bool enabled) {
    state = enabled;
    AppLogger.info('SIMULASI', enabled ? 'Mode simulasi AKTIF' : 'Mode simulasi NONAKTIF (pakai GPS)');
  }

  void toggle() => setEnabled(!state);
}

/// true = posisi & beacon dari SimulationService, false = GPS asli.
final simulationModeProvider =
    NotifierProvider<SimulationModeController, bool>(SimulationModeController.new);

final beaconScannerProvider = Provider<BeaconScanner>((ref) {
  if (ref.watch(simulationModeProvider)) {
    return SimulatedBeaconScanner(ref.watch(simulationServiceProvider));
  }
  // TODO(Firda, PB05): ganti dengan scanner flutter_blue_plus di perangkat fisik.
  return UnsupportedBeaconScanner();
});

// ================= Lokasi & Trigger =================

/// Status izin/layanan lokasi. Panggil ref.invalidate(locationStatusProvider) setelah izin berubah.
final locationStatusProvider = FutureProvider<LocationStatus>(
  (ref) => ref.watch(locationServiceProvider).checkStatus(),
);

/// Sumber posisi aktif: simulasi atau GPS (hanya jika izin diberikan).
final positionStreamProvider = StreamProvider<UserPosition>((ref) {
  if (ref.watch(simulationModeProvider)) {
    return ref.watch(simulationServiceProvider).positionStream;
  }
  final status = ref.watch(locationStatusProvider).valueOrNull;
  if (status != LocationStatus.granted) return const Stream<UserPosition>.empty();
  return ref.watch(locationServiceProvider).positionStream();
});

final triggerEngineProvider = Provider<TriggerEngine>((ref) {
  final engine = TriggerEngine(config: ref.watch(appConfigProvider));
  // Sesi kunjungan bertahan sampai "Akhiri kunjungan" (PRD 4.2, UI08 "sekali per kunjungan").
  engine.restoreSession(
      ref.read(progressLocalDataSourceProvider).readSessionTriggeredIds());
  ref.listen<AsyncValue<List<Poi>>>(
    poisProvider,
    (_, next) => next.whenData(engine.setPois),
    fireImmediately: true,
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// Stream event trigger (approaching/triggered/exited) untuk UI.
final triggerEventsProvider = StreamProvider<TriggerEvent>(
  (ref) => ref.watch(triggerEngineProvider).events,
);

/// Status kedekatan semua POI (untuk peta & daftar).
final poiProximityProvider = StreamProvider<Map<String, PoiProximityStatus>>(
  (ref) => ref.watch(triggerEngineProvider).statusStream,
);

/// Penghubung: posisi -> TriggerEngine, beacon -> TriggerEngine, triggered -> progres.
/// Cukup di-watch sekali di app.dart agar aktif sepanjang aplikasi.
final triggerCoordinatorProvider = Provider<void>((ref) {
  final engine = ref.watch(triggerEngineProvider);
  final config = ref.watch(appConfigProvider);

  ref.listen<AsyncValue<UserPosition>>(positionStreamProvider, (_, next) {
    next.whenData(engine.updatePosition);
  });

  final scanner = ref.watch(beaconScannerProvider);
  final beaconSub = scanner.signals.listen((signal) async {
    if (signal.rssi < config.beaconRssiThreshold) return;
    final poi =
        await ref.read(poiRepositoryProvider).getPoiByBeaconOrQr(signal.beaconId);
    if (poi != null) engine.reportIdentification(poi, TriggerSource.beacon);
  });
  unawaited(scanner.start());

  final eventSub = engine.events.listen((event) {
    if (event.type == TriggerEventType.triggered) {
      // Simpan status sesi agar tidak terpicu ulang setelah app dibuka lagi.
      ref
          .read(progressLocalDataSourceProvider)
          .writeSessionTriggeredIds(engine.triggeredThisSession.toList());
      ref.read(progressProvider.notifier).markVisited(event.poi.id);
    }
  });

  ref.onDispose(() {
    beaconSub.cancel();
    eventSub.cancel();
    scanner.stop();
  });
});

// ================= Statistik aktivitas & postmark =================

/// Jumlah kuis selesai (A01), foto Photo Studio (F08), dan cap kunjungan (A06).
class ActivityStats {
  const ActivityStats({
    required this.quizCompleted,
    required this.photoCount,
    required this.postmarks,
    this.randomStampSeed,
  });

  final int quizCompleted;

  /// Seed desain perangko acak P11; null = belum diambil.
  final int? randomStampSeed;
  final int photoCount;

  /// Tanggal tiap kunjungan yang sudah diakhiri, urut dari yang terlama.
  final List<DateTime> postmarks;

  DateTime? get lastPostmark => postmarks.isEmpty ? null : postmarks.last;
}

class ActivityStatsController extends Notifier<ActivityStats> {
  ProgressLocalDataSource get _local => ref.read(progressLocalDataSourceProvider);

  @override
  ActivityStats build() {
    final local = ref.watch(progressLocalDataSourceProvider);
    return ActivityStats(
      quizCompleted: local.readQuizCompleted(),
      photoCount: local.readPhotoCount(),
      postmarks: local.readPostmarks(),
      randomStampSeed: local.readRandomStampSeed(),
    );
  }

  /// Acak desain perangko P11 sekali saja; pengambilan berikutnya memakai desain yang sama.
  Future<int> ensureRandomStampSeed() async {
    final existing = state.randomStampSeed;
    if (existing != null) return existing;
    final seed = math.Random().nextInt(1 << 31);
    await _local.writeRandomStampSeed(seed);
    ref.invalidateSelf();
    return seed;
  }

  Future<void> addQuizCompleted() async {
    await _local.writeQuizCompleted(state.quizCompleted + 1);
    ref.invalidateSelf();
  }

  Future<void> addPhoto() async {
    await _local.writePhotoCount(state.photoCount + 1);
    ref.invalidateSelf();
  }

  Future<DateTime> addPostmark([DateTime? at]) async {
    final date = at ?? DateTime.now();
    await _local.writePostmarks([...state.postmarks, date]);
    ref.invalidateSelf();
    return date;
  }
}

final activityStatsProvider =
    NotifierProvider<ActivityStatsController, ActivityStats>(
        ActivityStatsController.new);

/// Mengakhiri sesi kunjungan (tombol "Akhiri kunjungan" di UI21).
/// Progres & perangko TETAP tersimpan; hanya status "sudah terpicu" yang direset.
/// Setiap kunjungan yang diakhiri mendapat cap kunjungan digital (A06).
class VisitSessionController {
  VisitSessionController(this._ref);
  final Ref _ref;

  Future<DateTime> endVisit() async {
    _ref.read(triggerEngineProvider).resetSession();
    await _ref.read(progressLocalDataSourceProvider).clearSession();
    final date = await _ref.read(activityStatsProvider.notifier).addPostmark();
    AppLogger.info('SESI', 'Kunjungan diakhiri, postmark $date');
    return date;
  }
}

final visitSessionProvider =
    Provider<VisitSessionController>((ref) => VisitSessionController(ref));

/// Log deteksi (bukti PB02) untuk ditampilkan di UI02.
final detectionLogProvider = StreamProvider<List<LogEntry>>((ref) async* {
  yield AppLogger.entries;
  yield* AppLogger.stream;
});
