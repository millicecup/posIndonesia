# JejakPOS: Museum POS Indonesia

**Explore, Discover, Collect.** Aplikasi pendamping Museum POS Indonesia berbasis lokasi (Flutter, Android). Proyek Kelompok 8.

> Status: **Sprint 1 (Week 10)**. Fondasi backend lokal, dataset 13 POI (konten placeholder), dan skeleton UI01–UI12.

## Setup dan run

```bash
# 1. Clone
git clone <url-repo> posIndonesia && cd posIndonesia
git checkout develop

# 2. Buat file platform Android (sekali saja; file yang sudah ada TIDAK ditimpa,
#    termasuk AndroidManifest.xml dan test/widget_test.dart)
flutter create . --project-name jejakpos --org id.jejakpos --platforms android

# 3. Dependency
flutter pub get

# 4. Cek kualitas
flutter analyze
flutter test

# 5. Jalankan di Android Emulator (AVD API 34 Google APIs)
flutter run
flutter run --dart-define=SIMULATION=true   # lokasi & beacon palsu sejak start

# 6. APK debug
flutter build apk --debug
```

## Dokumen

| Dokumen | Isi |
|---|---|
| [docs/ARSITEKTUR.md](docs/ARSITEKTUR.md) | Pilihan teknologi, diagram lapisan, alur data dan trigger, pohon folder + PIC, peta rute |
| [docs/PANDUAN_EMULATOR.md](docs/PANDUAN_EMULATOR.md) | AVD, izin, simulasi lokasi/GPX, keterbatasan emulator, membaca log, build APK |
| [docs/TUGAS_SPRINT1.md](docs/TUGAS_SPRINT1.md) | Tugas per anggota, git workflow, urutan kerja, checklist PB01–PB05 |
| [docs/MEDIA_HOSTING.md](docs/MEDIA_HOSTING.md) | Audio dan foto POI di Firebase Hosting: cara mengaktifkan, mengganti file, dan batas kuota |
| [docs/ASUMSI.md](docs/ASUMSI.md) | Asumsi yang sudah ditelaah terhadap PRD: terjawab, sebagian, belum, atau tidak konsisten |
| [docs/ASUMSI.md](docs/ASUMSI.md) bagian 3 | Usulan entri Change Log PRD |
| [docs/gpx/jalan_masuk_p12_p02_p01.gpx](docs/gpx/jalan_masuk_p12_p02_p01.gpx) | Rute uji emulator |
| [PRD_JejakPOS_Kelompok8_Lengkap (1).pdf](<PRD_JejakPOS_Kelompok8_Lengkap (1).pdf>) | PRD baseline Week 9 (acuan utama) |

## Tim

| Nama | Peran |
|---|---|
| Matilda | Backend & Data |
| Farella | Frontend & PM |
| Denaya | Frontend: POI List / Explorer |
| Belinda | Frontend: POI Detail & Audio |
| Firda | Frontend & Location |

## Catatan penting

- Semua konten POI bertanda **[PERLU VALIDASI MUSEUM]** dan semua koordinat adalah **placeholder**. Lihat [docs/ASUMSI.md](docs/ASUMSI.md).
- Penyimpanan hanya lokal (shared_preferences). Tidak ada sinkronisasi cloud.
