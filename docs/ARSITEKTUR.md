# Arsitektur JejakPOS (Sprint 1)

## 1. Teknologi dan alasan

| Kebutuhan | Pilihan | Versi | Alasan singkat |
|---|---|---|---|
| Bahasa | Dart | SDK ≥ 3.5 | Bahasa resmi Flutter, null-safety, mendukung `sealed class` dan pattern matching. |
| Framework | Flutter stable | ≥ 3.24 | Satu codebase untuk 5 orang, hot reload, jalan di Android Emulator. |
| IDE | Android Studio + plugin Flutter & Dart | terbaru | Sudah ada AVD Manager dan Extended Controls (simulasi GPS). |
| State management | **Riverpod** (`flutter_riverpod`) | ^2.6.1 | Lihat penjelasan di bawah. |
| Routing | `go_router` | ^14.8.1 | Rute berbasis path (`/poi/P01`), mendukung bottom-nav dengan `StatefulShellRoute`. |
| Lokasi | `geolocator`, `permission_handler` | ^13.0.2, ^11.4.0 | Stream posisi + status izin yang lengkap (denied, deniedForever, serviceDisabled). |
| Peta | `flutter_map` + `latlong2` | ^7.0.2, ^0.9.1 | Mendukung `CrsSimple`, jadi denah bisa berupa gambar biasa tanpa koordinat asli. |
| QR | `mobile_scanner` | ^6.0.2 | Kamera + decode QR dalam satu widget (ML Kit di Android). |
| Audio | `just_audio` | ^0.9.42 | Stream posisi, durasi, dan status yang rapi untuk play, pause, lanjut, dan seek. Di Android memakai ExoPlayer/Media3 (PRD 8.1 menyebut "Android Media3/audioplayers", lihat ASUMSI A20). |
| Penyimpanan | `shared_preferences` | ^2.3.3 | Cukup untuk list id kunjungan dan perangko. Tidak ada sinkronisasi cloud (NG05). |
| Media POI | Firebase Hosting (Spark) + `path_provider` | ^2.1.6 | Audio dan foto bisa dikeluarkan dari APK tanpa SDK Firebase dan tanpa biaya. Lihat [MEDIA_HOSTING.md](MEDIA_HOSTING.md). |
| Data POI | JSON lokal di `assets/data/pois.json` | – | Mudah diedit tim konten tanpa mengubah kode. |
| BLE | `flutter_blue_plus` | ^1.35.3 (di-comment) | Hanya untuk PoC PB05 di perangkat fisik. Di emulator memakai simulasi. |
| Kamera (Photo Studio) | `camera` | ^0.11.0+2 (di-comment) | Disiapkan untuk Sprint berikutnya. |
| Testing | `flutter_test` | SDK | Unit test backend dan widget test. |

**Kenapa Riverpod, bukan Provider:** Riverpod tidak bergantung pada `BuildContext`, jadi service seperti TriggerEngine dan repository bisa dipakai di mana saja dan mudah di-*override* saat test atau mode simulasi. Dependensi antar-provider (misalnya `positionStreamProvider` yang otomatis berpindah antara GPS dan simulasi) dideklarasikan dengan `ref.watch`, sehingga tidak perlu menulis kode sinkronisasi manual. Kesalahan seperti provider yang belum didaftarkan juga ketahuan saat compile, bukan saat runtime.

## 2. Lapisan arsitektur

```
┌──────────────────────────────────────────────────────────────┐
│ PRESENTATION  lib/features/*/presentation, lib/shared/widgets│  ← Farella, Denaya, Belinda, Firda
│   Screen & widget. Hanya membaca provider, tanpa logika data.│
├──────────────────────────────────────────────────────────────┤
│ STATE         lib/features/*/state, lib/providers/           │  ← pemilik fitur + Matilda
│   Riverpod provider/notifier. Menggabungkan data untuk UI.   │
├──────────────────────────────────────────────────────────────┤
│ DOMAIN/REPO   lib/data/repositories/ (abstract + impl)       │  ← Matilda
│   Kontrak PoiRepository & ProgressRepository.                │
├──────────────────────────────────────────────────────────────┤
│ DATA/SERVICE  lib/data/datasources/, lib/services/           │  ← Matilda (+ Firda untuk lokasi/beacon)
│   JSON assets, shared_preferences, GPS, audio, QR, simulasi. │
└──────────────────────────────────────────────────────────────┘
Aturan: panah dependensi hanya ke bawah. Screen TIDAK BOLEH import datasource langsung.
```

### Alur data: JSON sampai UI

```
assets/data/pois.json
      │  rootBundle.loadString()
      ▼
PoiLocalDataSource.loadPois() ──► parsePois(): jsonDecode → Poi.fromJson() → urut tourOrder
      │                                   (error → DataLoadException / DataParseException)
      ▼
PoiRepositoryImpl  (cache di memori, search/filter/nearby/rekomendasi/validasi)
      │
      ▼
poisProvider (FutureProvider)  ──►  homeSummaryProvider / poiSearchResultsProvider / ...
      │
      ▼
HomeExplorerScreen: ref.watch(...) → AsyncValueView → ListView(PoiCard × 13)
```

### Alur location trigger: GPS sampai notifikasi POI

```
[GPS emulator/HP]                [Panel simulasi]           [Beacon (PB05)]   [QR / input manual]
 Geolocator.getPositionStream     SimulationService          BeaconScanner     QrService.validate()
        │                          .positionStream            .signals              │
        ▼                                 │                      │ RSSI ≥ ambang   │ QrValid
 LocationService (log "LOKASI")           │                      ▼                 ▼
        │                                 │            getPoiByBeaconOrQr   reportIdentification(poi, qr)
        └──────── positionStreamProvider ◄┘ (pilih sesuai simulationModeProvider)  │
                         │                                       │                 │
                         ▼                                       ▼                 ▼
               triggerCoordinatorProvider ──► TriggerEngine.updatePosition() / reportIdentification()
                                                     │
                     ┌───────────────────────────────┤
                     │ 1. abaikan jika akurasi > 50 m
                     │ 2. geofence museum (pusat placeholder, 150 m)
                     │ 3. jarak Haversine ke tiap POI
                     │ 4. status kandidat + hysteresis (+3 m untuk keluar)
                     │ 5. debounce: 2 pembacaan berturut-turut
                     │ 6. transisi: outside → approaching (≤15 m) → triggered (≤10 m)
                     │ 7. triggered hanya jika belum ada di _triggeredThisSession
                     │    (disimpan di shared_preferences; reset hanya lewat
                     │     "Akhiri kunjungan" di UI21 → sekali per kunjungan, PRD 4.2)
                     ▼
              Stream<TriggerEvent>  (log "TRIGGER")
                     │
          ┌──────────┴───────────┐
          ▼                      ▼
 app.dart: SnackBar        ProgressController.markVisited()
 "Kamu berada di …"        (shared_preferences, tetap ada setelah app ditutup)
   └─ LIHAT → UI07 TriggerAlertScreen → UI10 PoiDetailScreen
```

Mekanisme hybrid dari PRD 4.2: GPS dipakai untuk menentukan apakah pengguna berada di sekitar museum (`isInsideMuseum`). GPS **bukan** acuan utama untuk membedakan koleksi di dalam ruangan. Identifikasi POI dilakukan lewat beacon BLE (PB05/PB08) atau computer vision (4.2), dengan QR sebagai fallback (lihat ASUMSI A15). Selama koordinat asli belum ada, Sprint 1 juga memakai jarak GPS per POI dengan koordinat placeholder yang diturunkan dari denah, supaya alur trigger bisa diuji di emulator.

## 3. Pohon folder

```
posIndonesia/
├── pubspec.yaml                         # dependency & daftar assets            [Matilda]
├── analysis_options.yaml                # aturan lint                            [Matilda]
├── android/app/src/main/AndroidManifest.xml  # izin lokasi/kamera/notif/BLE      [Matilda]
├── assets/                                                       ── BACKEND/DATA ──
│   ├── data/pois.json                   # dataset 13 POI (placeholder konten)    [Matilda]
│   ├── images/pois/                     # foto POI placeholder pNN_1.png          [Matilda]
│   ├── images/stamps/                   # gambar perangko stamp_pNN.png           [Matilda]
│   ├── images/onboarding.png            # ilustrasi onboarding                    [Farella]
│   ├── audio/                           # narasi & Mars (WAV placeholder)         [Matilda]
│   └── map/museum_floor_plan.png        # denah 2D placeholder 1000×700           [Matilda]
├── lib/
│   ├── main.dart                        # entry: SharedPreferences + ProviderScope [Matilda]
│   ├── core/                                                     ── BACKEND ──
│   │   ├── constants/app_constants.dart # path aset, key prefs, regex kode        [Matilda]
│   │   ├── config/app_config.dart       # radius, hysteresis, mode simulasi       [Matilda]
│   │   ├── errors/app_exception.dart    # DataLoad/DataParse/Location/Audio       [Matilda]
│   │   └── utils/                       # haversine, app_logger, json_utils       [Matilda]
│   ├── data/
│   │   ├── models/                      # Poi, PoiCategory, PoiZone, TriggerRule, Stamp,
│   │   │                                # MapPosition, VisitProgress, LocationStatus [Matilda]
│   │   ├── datasources/                 # poi_local (JSON), progress_local (prefs) [Matilda]
│   │   └── repositories/                # abstract + impl Poi & Progress           [Matilda]
│   ├── services/                        # location, permission, trigger_engine, qr,
│   │                                    # audio, beacon, simulation    [Matilda; beacon: Firda]
│   ├── providers/providers.dart         # DI: semua provider backend               [Matilda]
│   ├── app/                                                      ── FRONTEND ──
│   │   ├── app.dart                     # MaterialApp.router + listener trigger    [Farella]
│   │   ├── router.dart, routes.dart     # rute UI01–UI12                           [Farella]
│   │   ├── main_shell.dart              # bottom nav: Jelajah/Peta/Album/Progres   [Farella]
│   │   └── theme.dart                   # oranye/putih/abu gelap                   [Farella]
│   ├── shared/widgets/                  # PoiCard, CategoryChip, SearchBarField,
│   │                                    # ProgressBadge, AsyncValueView     [Farella review]
│   └── features/
│       ├── onboarding/                  # UI01                                     [Farella]
│       ├── permission/                  # UI02 status izin & deteksi lokasi        [Firda]
│       ├── home_explorer/               # UI03 daftar POI + pintasan               [Farella]
│       ├── poi_list_search/             # UI04 explorer, cari, filter kategori     [Denaya]
│       ├── map_navigation/              # UI05/06 peta, UI07 navigasi,
│       │                                # UI08 trigger notification        [Farella + Firda]
│       ├── visual_tour_guide/           # UI09 pemandu 2D + rekomendasi            [Farella]
│       ├── poi_detail/                  # UI10 cerita POI                          [Belinda]
│       ├── audio_player/                # UI11 pemutar audio                       [Belinda]
│       ├── qr_scanner/                  # UI12 QR + input manual                   [Firda]
│       ├── album/                       # UI14 album perangko (dasar)              [Sprint 3]
│       ├── progress/                    # UI21 progres, rekomendasi, akhiri kunjungan [Farella]
│       └── simulation_debug/            # panel simulasi emulator          [Matilda + Firda]
├── test/                                # unit & widget test                       [Matilda]
│   ├── helpers/test_data.dart
│   ├── core/haversine_test.dart
│   ├── data/poi_parsing_test.dart, poi_repository_test.dart, progress_repository_test.dart
│   ├── services/trigger_engine_test.dart, qr_service_test.dart
│   └── widget_test.dart
└── docs/                                # dokumen tim + contoh GPX
```

Setiap folder fitur memakai pola `presentation/` (screen), `widgets/` (widget khusus fitur, jika ada), dan `state/` (provider fitur).

## 4. Pemetaan rute

Penomoran mengikuti PRD Bagian 5.1. Wireframe ada di PRD Gambar 5.1–5.8.

| Kode | Nama di PRD | Path | Screen | Wireframe |
|---|---|---|---|---|
| UI01 | Welcome / Onboarding | `/onboarding` | OnboardingScreen | Gbr 5.1 |
| UI02 | Izin Akses | `/permission` | PermissionScreen (**berfungsi**) | Gbr 5.1 |
| UI03 | Home / Museum Explorer | `/explore` (tab Jelajah) | HomeExplorerScreen (**berfungsi**) | Gbr 5.1 |
| UI04 | Search POI | `/pois?category=<id>` | PoiListScreen | Gbr 5.2 |
| UI05/UI06 | Explore Map state 1 / state 2 | `/map` (tab Peta) | MapScreen | Gbr 5.3 |
| UI07 | Navigasi ke POI | `/navigate/:poiId` | RouteGuidanceScreen | Gbr 5.2 |
| UI08 | POI Trigger Notification | `/trigger/:poiId` | TriggerAlertScreen | Gbr 5.3 |
| UI09 | Visual Tour Guide | `/tour` | VisualTourGuideScreen | Gbr 5.4 |
| UI10 | POI Detail | `/poi/:poiId` | PoiDetailScreen | Gbr 5.4 |
| UI11 | Audio Player | `/poi/:poiId/audio` | AudioPlayerScreen | Gbr 5.4 |
| UI12 | Pindai QR (fallback) | `/qr` | QrScannerScreen | Gbr 5.2 |
| UI14 | Album Perangko Digital | `/album` (tab Album) | AlbumScreen (dasar) | Gbr 5.5 |
| UI21 | Progres & Rekomendasi | `/progress` (tab Progres) | ProgressScreen | Gbr 5.7 |
| – | (debug, bukan PRD) | `/debug/simulation` | SimulationPanelScreen | – |

UI13 dan UI15–UI23 (perangko terbuka, Photo Studio, kuis, Mystery Clue, visualisasi perangko, Jejak Misi, ringkasan + postmark, postcard) dikerjakan pada Sprint 2–4 sesuai backlog PRD.
