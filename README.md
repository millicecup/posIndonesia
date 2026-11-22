# JejakPOS: Museum POS Indonesia

**Explore, Discover, Collect.** Aplikasi pendamping Museum POS Indonesia berbasis lokasi (Flutter, Android). Proyek Kelompok 8.

> Status: **Sprint 1 (Week 10)**. Fondasi backend lokal, dataset 13 POI (konten placeholder), dan skeleton UI01–UI12.
>
> **Pembaruan PRD v2:** nomor POI mengikuti Tabel 4 PRD v2. P01–P11 adalah POI baseline; P12 (Koleksi Peralatan Pos) dan P13 (Pos Kereta Api) disimpan sebagai kandidat tambahan. Radius trigger tetap 10 m sampai hasil PoC PB05. Lihat [docs/ASUMSI.md](docs/ASUMSI.md) A3 dan A23–A25.

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

## APK

APK siap pasang ada di [apk/JejakPOS-v0.1.0-arm64-v8a.apk](apk/JejakPOS-v0.1.0-arm64-v8a.apk) (HP Android 64-bit, hampir semua HP sejak 2017). Untuk HP lama 32-bit atau emulator x86_64, build sendiri dengan `--split-per-abi`.

Konten P01–P11 (teks, foto, kuis, perangko album, overlay Photo Studio, denah asli) diambil dari branch `content/poi-dataset`.

```bash
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

APK release masih ditandatangani dengan debug key (bawaan template Flutter): bisa dipasang langsung di HP untuk demo, tetapi tidak untuk Play Store.

## Dokumen

| Dokumen | Isi |
|---|---|
| [docs/ARSITEKTUR.md](docs/ARSITEKTUR.md) | Pilihan teknologi, diagram lapisan, alur data dan trigger, pohon folder + PIC, peta rute |
| [docs/PANDUAN_EMULATOR.md](docs/PANDUAN_EMULATOR.md) | AVD, izin, simulasi lokasi/GPX, keterbatasan emulator, membaca log, build APK |
| [docs/TUGAS_SPRINT1.md](docs/TUGAS_SPRINT1.md) | Tugas per anggota, git workflow, urutan kerja, checklist PB01–PB05 |
| [docs/MEDIA_HOSTING.md](docs/MEDIA_HOSTING.md) | Audio dan foto POI di Firebase Hosting: cara mengaktifkan, mengganti file, dan batas kuota |
| [docs/ASUMSI.md](docs/ASUMSI.md) | Asumsi yang sudah ditelaah terhadap PRD: terjawab, sebagian, belum, atau tidak konsisten |
| [docs/ASUMSI.md](docs/ASUMSI.md) bagian 3 | Usulan entri Change Log PRD |
| [docs/gpx/jalan_masuk_p11_p02_p01.gpx](docs/gpx/jalan_masuk_p11_p02_p01.gpx) | Rute uji emulator (dulu `jalan_masuk_p12_p02_p01.gpx`) |
| [PRD_JejakPOS_Kelompok8_Lengkap (1).pdf](<PRD_JejakPOS_Kelompok8_Lengkap (1).pdf>) | PRD baseline Week 9 (acuan utama) |
| [PRD_JejakPOS_Kelompok8_Lengkap (2).pdf](<PRD_JejakPOS_Kelompok8_Lengkap (2).pdf>) | **PRD v2** (acuan terbaru): Tabel 4 menjadi 11 POI bernomor baru, PB08 radius 5 m |

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

## Computer vision (branch integrasi)

Fitur Kenali memakai SIFT offline Android, digabung dengan branch QR P01–P11 dan desain terbaru. Lihat [panduan CV, APK dan build lokal](docs/COMPUTER_VISION.md).
