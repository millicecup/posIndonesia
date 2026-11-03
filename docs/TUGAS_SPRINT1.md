# Pembagian Tugas Sprint 1 (Week 10)

## Aturan umum kepemilikan file

| Area | Pemilik | Orang lain boleh? |
|---|---|---|
| `lib/core/`, `lib/data/`, `lib/services/`, `lib/providers/`, `assets/data/`, `test/` | Matilda | **Tidak.** Ajukan kebutuhan lewat GitHub Issue berlabel `backend`. |
| `lib/services/beacon_service.dart`, `lib/services/location_service.dart` | Matilda + Firda | Firda boleh mengubah lewat PR yang di-review Matilda. |
| `lib/app/` (router, tema, shell) | Farella | Yang lain hanya menambah rute lewat PR yang di-review Farella. |
| `lib/shared/widgets/` | Farella (review) | Boleh menambah widget baru. **Tidak boleh** mengubah parameter widget yang sudah ada tanpa diskusi. |
| `lib/features/<fitur>/` | Pemilik fitur | Tidak, kecuali pemilik fitur meminta. |
| `pubspec.yaml`, `AndroidManifest.xml` | Matilda | Tambah dependency lewat PR yang di-review Matilda. |

**Cara memanggil backend (berlaku untuk semua frontend):**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jejakpos/providers/providers.dart';
import 'package:jejakpos/data/models/models.dart';

class ContohScreen extends ConsumerWidget {
  const ContohScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pois = ref.watch(poisProvider);          // AsyncValue<List<Poi>>
    return pois.when(
      data: (list) => Text('${list.length} POI'),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
// Aksi (di onPressed):
// ref.read(progressProvider.notifier).markVisited('P01');
// ref.read(progressProvider.notifier).collectStamp('STP-P01');
// final hasil = await ref.read(poiRepositoryProvider).searchPois('prangko');
```

---

## Matilda: Backend & Data

**File:** semua yang ada di `lib/core`, `lib/data`, `lib/services`, `lib/providers`, `assets/`, `test/`, `pubspec.yaml`, `AndroidManifest.xml`, dan `docs/`.

**Tugas:**
1. Membuat repo GitHub, branch `main` dan `develop`, proteksi branch (wajib PR dan 1 approval).
2. Push fondasi ini ke `develop` **paling lambat hari pertama sprint** (frontend butuh model dan provider).
3. Melengkapi dataset 13 POI (minimal 10 lengkap) dan menjaga `validateDataset()` tanpa error.
4. Memastikan `flutter analyze` dan `flutter test` hijau.
5. Membantu anggota lain menyambungkan provider. Jika ada kebutuhan data baru, Matilda yang menambah method di repository.

**Yang dipelajari:** Riverpod (Provider, FutureProvider, AsyncNotifier), `jsonDecode` dan model immutable, shared_preferences, unit test dengan `flutter_test`.

**Definition of Done:** `flutter test` lulus semua; app berjalan di emulator; UI03 menampilkan 13 POI; teks "Dataset valid: 13 POI" muncul di UI03.

**Evidence:** link commit/PR di GitHub, rekaman layar app berjalan (onboarding sampai daftar POI), tangkapan layar UI03 dan output `flutter test`.

---

## Farella: Frontend & PM

**File:** `lib/app/*`, `lib/features/onboarding/`, `lib/features/home_explorer/`, `lib/features/visual_tour_guide/`, `lib/features/map_navigation/presentation/map_screen.dart`, `lib/features/progress/`, review `lib/shared/widgets/`.

**Wireframe PRD:** Gambar 5.1 (UI01, UI03), 5.3 (UI05/UI06), 5.4 kiri (UI09), 5.7 kanan (UI21).

**Tugas:**
1. UI03 Home/Museum Explorer sesuai wireframe: toggle **Eksplorasi Bebas / Rute Rekomendasi**, kolom cari, chip kategori, kartu "Progres kunjungan 0/13 POI · 0 perangko", dan kartu POI dengan tombol **Pilih**.
2. UI01 onboarding 3 slide (Explore, Discover, Collect) dengan tombol "Mulai Menjelajah" dan "Lewati pengantar".
3. **Prototipe interaktif UI01–UI12 yang bisa diklik end-to-end (PB04)**. Minimal alur menurut PRD: **onboarding → peta → trigger → detail POI**. Untuk trigger di emulator, gunakan Panel Simulasi ("Pindah ke Pxx") atau GPX.
4. PM: papan tugas (GitHub Projects), daily check, merge `develop`, dan memastikan tidak ada konflik di `lib/app/`.

**Yang dipelajari:** go_router (`context.go` vs `context.push`, `StatefulShellRoute`), ThemeData, ConsumerWidget.

**Boleh:** mengubah tema, layout semua layar milik Farella, dan menambah rute. **Tidak boleh:** mengubah `lib/providers/` atau `lib/data/`.

**Contoh panggilan backend:**
```dart
final progress = ref.watch(progressProvider).valueOrNull;     // ProgressBadge
final next = ref.watch(recommendedNextPoiProvider).valueOrNull; // kartu rekomendasi
```

**Definition of Done:** semua 12 layar bisa dicapai dengan klik dari Home tanpa mengetik URL; bottom nav 4 tab berjalan; tidak ada error merah di layar.

**Evidence:** video klik-through UI01 sampai UI12, screenshot papan tugas, notulen/rekap progres sprint.

---

## Denaya: Frontend (POI List / Museum Explorer)

**File:** `lib/features/poi_list_search/**`.

**Wireframe PRD:** Gambar 5.2 kiri (UI04 Search POI).

**Tugas:** UI04 dengan daftar koleksi per kategori, pencarian sederhana (nama/kategori, contoh "perangko" → "2 hasil"), filter chip kategori, empty state, tap kartu ke UI10, serta tombol **"Jadikan tujuan: Pxx"** (ke UI07) dan **"Lihat di denah"** (ke tab Peta).

**Yang dipelajari:** `StateProvider`, `FutureProvider.autoDispose`, ListView dengan section, `SearchBarField` dan `CategoryChip`.

**Boleh:** mengubah file di folder fiturnya dan menambah widget di `poi_list_search/widgets/`. **Tidak boleh:** mengubah `PoiRepository.searchPois` (minta ke Matilda jika perlu perilaku baru).

**Contoh panggilan backend:**
```dart
ref.read(poiSearchQueryProvider.notifier).state = 'prangko';
final hasil = ref.watch(poiSearchResultsProvider);  // sudah gabung search + kategori
final kategori = ref.watch(poiCategoriesProvider);
context.push(AppRoutes.poiDetail(poi.id));
```

**Definition of Done:** mengetik "prangko" menampilkan P07 dan P09; memilih chip "Koleksi Museum" menampilkan P03 dan P11; tap kartu membuka detail.

**Evidence:** rekaman layar pencarian dan filter, screenshot hasil.

---

## Belinda: Frontend (POI Detail & Audio)

**File:** `lib/features/poi_detail/**`, `lib/features/audio_player/**`.

**Wireframe PRD:** Gambar 5.4 tengah dan kanan (UI10, UI11).

**Tugas:** UI10 (ringkasan, 3–5 fakta bernomor, gambar utama, baris tombol Audio/Galeri/Foto, tombol **"Selesai & ambil perangko"**) dan UI11 (play, pause, lanjut, seek, durasi, tombol **"Tampilkan teks"**). P05 menampilkan "Mars Pos Indonesia".

**Yang dipelajari:** `FutureProvider.family`, `StreamProvider` (posisi audio), `AudioService` (just_audio), PageView untuk galeri.

**Boleh:** mengubah tampilan dan menambah widget di folder fiturnya. **Tidak boleh:** mengubah `AudioService`; jika butuh fitur baru (misalnya kecepatan putar), minta ke Matilda.

**Contoh panggilan backend:**
```dart
final detail = ref.watch(poiDetailProvider(poiId));   // PoiDetailData?
final audio = ref.read(audioServiceProvider);
await audio.play(poi.audio!); await audio.pause(); await audio.resume();
await audio.seek(const Duration(seconds: 30));
final pos = ref.watch(audioPositionProvider);
```

**Definition of Done:** semua 13 POI bisa dibuka; audio P01 bisa diputar, dijeda, dan dilanjutkan; POI tanpa audio (saat ini P11) menampilkan pesan yang benar; minimal 10 POI punya audio (F03).

**Evidence:** rekaman layar membuka detail dan memutar audio, screenshot UI10 dan UI11.

---

## Firda: Frontend & Location

**File:** `lib/features/permission/**`, `lib/features/qr_scanner/**`, `lib/features/map_navigation/presentation/route_guidance_screen.dart` (UI07) dan `trigger_alert_screen.dart` (UI08), serta kolaborasi di `lib/services/beacon_service.dart`.

**Wireframe PRD:** Gambar 5.1 tengah (UI02), 5.2 tengah dan kanan (UI07, UI12), 5.3 kanan (UI08).

**Tugas:**
1. UI02: izin **Bluetooth & Lokasi**, Kamera, dan Notifikasi beserta penjelasannya, plus catatan "Tanpa Bluetooth, POI tetap bisa dibuka lewat pindai QR". Status deteksi lokasi dan log sudah berfungsi, tinggal dirapikan.
2. Uji pembacaan GPS di emulator (Single point dan GPX) serta catat hasilnya.
3. Eksplorasi location trigger: uji radius 5 m vs 10 m (lihat ASUMSI A3), lalu catat mana yang stabil.
4. **PoC PB05 (menurut PRD harus di area uji, bukan emulator):** beacon terpetakan ke POI pada perangkat uji; ambang sinyal awal dan interval stabil tercatat; **log uji + foto lokasi**. QR juga diuji. Gunakan HP fisik di branch `feature/firda-ble-poc`. Hasilnya dipakai untuk memutuskan ASUMSI A15 (BLE vs computer vision) dan A16 (format beacon, RSSI).

**Yang dipelajari:** geolocator, permission_handler, Extended Controls emulator, `TriggerEngine` (cukup membaca kodenya), mobile_scanner.

**Boleh:** mengubah UI fiturnya; mengusulkan perubahan `AppConfig` (radius, hysteresis) lewat PR. **Tidak boleh:** mengubah logika `TriggerEngine` tanpa memperbarui `trigger_engine_test.dart`.

**Contoh panggilan backend:**
```dart
final status = await ref.read(locationServiceProvider).requestPermission();
ref.invalidate(locationStatusProvider);              // stream GPS dibuat ulang
final pos = ref.watch(positionStreamProvider);       // AsyncValue<UserPosition>
ref.listen(triggerEventsProvider, (_, e) { /* ... */ });
await ref.read(qrScannerControllerProvider.notifier).submit('QR-P03');
```

**Definition of Done:** UI02 menampilkan status izin yang benar untuk diizinkan/ditolak/ditolak permanen; posisi terbaca saat Set Location; GPX `jalan_masuk_p12_p02_p01.gpx` memicu P12, P02, dan P01 masing-masing satu kali, dan tidak memicu ulang setelah app dibuka lagi sebelum "Akhiri kunjungan"; QR manual `QR-P03` membuka detail P03.

**Evidence:** rekaman layar UI02 + log deteksi (PB02), rekaman GPX trigger, dokumen PoC PB05 (1–2 halaman: temuan, keterbatasan emulator, rencana uji HP fisik).

---

## Git workflow

**Branch**
```
main      ← rilis/demo akhir sprint saja (dilindungi)
develop   ← integrasi harian (dilindungi, wajib PR)
feature/<nama>-<fitur>   contoh: feature/denaya-poi-search, feature/firda-permission-ui
fix/<nama>-<masalah>     contoh: fix/belinda-audio-seek
```

**Aturan PR**
1. Selalu `git pull origin develop` sebelum membuat branch dan sebelum membuat PR.
2. PR ke `develop`, minimal **1 approval**: perubahan backend di-review Matilda, `lib/app` dan `shared` di-review Farella, lainnya oleh siapa pun.
3. Sebelum PR wajib menjalankan `flutter analyze` (tanpa error) dan `flutter test` (hijau).
4. PR kecil (≤ ±400 baris) dan satu topik. Sertakan screenshot untuk perubahan UI.
5. Jangan commit `build/`, `.dart_tool/`, atau `android/local.properties` (sudah ada di `.gitignore`).
6. Merge memakai **Squash and merge** agar histori `develop` rapi.

**Konvensi pesan commit** (Conventional Commits):
```
<tipe>(<scope>): <ringkasan singkat>

tipe : feat | fix | refactor | test | docs | chore | style
scope: data | services | poi-list | poi-detail | audio | permission | qr | map | home | app
contoh:
feat(poi-list): kelompokkan daftar POI per kategori
fix(audio): tombol lanjut tidak bekerja setelah stop
test(services): tambah kasus hysteresis trigger
```

## Urutan kerja yang disarankan

| Hari | Backend (Matilda) | Frontend |
|---|---|---|
| 1 | Push fondasi ini ke `develop`: model, repository, provider, dan dataset placeholder sudah bisa dipakai. | Clone, `flutter pub get`, jalankan di emulator, baca file fitur masing-masing. |
| 2–3 | Lengkapi field dataset, cek `validateDataset()`, tambah test. | Kerjakan layout layar masing-masing memakai provider yang sudah ada (data placeholder sudah cukup). |
| 3–4 | Melayani permintaan method/field baru dari frontend. | Farella menyambungkan navigasi end-to-end; Firda menguji GPX dan trigger. |
| 5 | Merge `develop` → `main`, tag `sprint-1`. | Rekam evidence, isi checklist di bawah. |

Backend yang **harus selesai lebih dulu**: `models/`, `PoiRepository` (abstract), dan `providers.dart`. Semua ini sudah ada di fondasi, jadi frontend tidak terblokir. Konten JSON boleh terus diperbarui tanpa mengubah kode frontend.

## Checklist verifikasi Sprint 1

Kriteria dan evidence mengikuti PRD Bagian 6 (Product Backlog) dan Bagian 7 (Sprint 1 – Week 10).

| PB | Kriteria (PRD) | Cara cek | Evidence (PRD) | PIC |
|---|---|---|---|---|
| PB01 | Project Android dan **APK debug berjalan di perangkat uji tanpa crash** | `flutter build apk --debug`, pasang di HP uji, buka tanpa crash | Commit repositori + rekaman layar | Matilda |
| PB02 | Layar izin lokasi berfungsi dan status deteksi terbaca | UI02: izin diizinkan → Set Location / GPS asli → koordinat dan log `LOKASI` muncul | Log + rekaman layar | Firda (+Matilda) |
| PB03 | JSON dataset 10 POI (ID, nama, kategori, zona, ID beacon/QR) terbaca aplikasi | UI03 menampilkan 13 POI dan "Dataset valid"; `flutter test` hijau | Tangkapan layar daftar POI | Matilda |
| PB04 | Prototipe UI01–UI12 dapat diklik end-to-end (alur onboarding → peta → trigger → detail POI) | Klik dari onboarding sampai semua layar tanpa URL manual; trigger lewat Panel Simulasi | Rekaman layar | Farella |
| PB05 | PoC location trigger: beacon dan QR diuji **di area uji**; ambang sinyal awal dan interval stabil tercatat | HP fisik + beacon di area uji; QR cetak membuka POI yang benar | Log uji + **foto lokasi** + catatan PoC | Firda |
