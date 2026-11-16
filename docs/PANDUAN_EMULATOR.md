# Panduan Android Studio & Emulator

## 1. Persiapan sekali saja

1. Install **Flutter SDK stable** (https://docs.flutter.dev/get-started/install/windows), lalu tambahkan `C:\src\flutter\bin` (atau lokasi instalasi kamu) ke PATH.
2. Di Android Studio: **Settings → Plugins**, install **Flutter** (plugin Dart ikut terpasang).
3. **Settings → Languages & Frameworks → Android SDK → SDK Tools**: centang *Android SDK Command-line Tools*.
4. Jalankan di terminal:
   ```bash
   flutter doctor
   flutter doctor --android-licenses
   ```
   Semua baris Android harus centang hijau.

## 2. Membuat AVD

1. **Device Manager → Create Virtual Device**.
2. Pilih **Pixel 7** (atau Pixel 6).
3. System image yang disarankan: **API 34 (Android 14), "Google APIs" x86_64**. Image *Google APIs* diperlukan agar layanan lokasi dan kamera virtual berfungsi. API 33+ juga menguji izin notifikasi Android 13.
4. **Show Advanced Settings → Camera**: *Back = VirtualScene*, *Front = Emulated*.
5. Finish, lalu jalankan emulator (▶).

## 3. Menjalankan aplikasi

```bash
# di folder proyek
flutter pub get
flutter run                              # mode normal (GPS dari emulator)
flutter run --dart-define=SIMULATION=true # mode simulasi aktif sejak start
```
Bisa juga lewat Android Studio: pilih emulator di toolbar, lalu klik **Run 'main.dart'**. Untuk menambahkan flag simulasi: **Run → Edit Configurations → Additional run args**: `--dart-define=SIMULATION=true`.

## 4. Memberi izin lokasi di emulator

- Di aplikasi: buka **UI02 (ikon lokasi di AppBar Jelajah)**, lalu tekan **Izinkan Semua** dan pilih *While using the app*.
- Jika terlanjur ditolak permanen: tombol **Pengaturan** di UI02, atau dari emulator **Settings → Apps → JejakPOS → Permissions → Location → Allow only while using the app**.
- Pastikan lokasi emulator aktif: tarik *quick settings*, lalu nyalakan **Location**.
- Lewat terminal (opsional):
  ```bash
  adb shell pm grant id.jejakpos.jejakpos android.permission.ACCESS_FINE_LOCATION
  ```
  (sesuaikan nama paket jika `--org` saat `flutter create` berbeda).

## 5. Simulasi lokasi (Extended Controls)

Buka **⋯ (Extended Controls) → Location** di panel emulator.

**a. Titik tunggal**: pada tab *Single points*, cari atau klik peta, lalu tekan **Set Location**. Koordinat placeholder POI (diturunkan dari posisi denah wireframe PRD, skala fiktif 200 m × 160 m):

Penomoran mengikuti **PRD v2 Tabel 4** (P01–P11 baseline, P12–P13 kandidat tambahan). Kolom *Nomor PRD v1* menunjukkan nomor lama. Koordinat tidak berubah, hanya nomornya.

| POI (PRD v2) | Nama | Nomor PRD v1 | Latitude | Longitude | Posisi denah (x, y) | Ruang (denah ilustratif) |
|---|---|---|---|---|---|---|
| P01 | Sejarah Komunikasi Tertulis di Nusantara | P01 | -6.902882 | 107.619134 | 0.16, 0.80 | Ruang Awal |
| P02 | Sejarah Pos Indonesia | P02 | -6.902867 | 107.619750 | 0.50, 0.79 | Ruang Awal (lorong pintu masuk) |
| P03 | Sejarah Kepemimpinan Pos Indonesia | P04 | -6.901932 | 107.620167 | 0.73, 0.14 | Ruang 4 |
| P04 | Sejarah Seragam Petugas Pos | P06 | -6.902522 | 107.619297 | 0.25, 0.55 | Ruang 2 |
| P05 | Proses Pembuatan Prangko | P07 | -6.902565 | 107.620058 | 0.67, 0.58 | Ruang 3 |
| P06 | Kode Pos di Indonesia | P08 | -6.902306 | 107.619496 | 0.36, 0.40 | Ruang 2 |
| P07 | Koleksi Prangko Lemari Geser | P09 | -6.902321 | 107.620348 | 0.83, 0.41 | Ruang 3 |
| P08 | Tokoh Mas Soeharto | P10 | -6.901932 | 107.619388 | 0.30, 0.14 | Ruang 4 |
| P09 | Koleksi Kotak Pos | P11 | -6.902882 | 107.620348 | 0.83, 0.80 | Ruang Awal |
| P10 | Mars Pos Indonesia | P05 | -6.902364 | 107.619750 | 0.50, 0.44 | Lorong |
| P11 | Stempel Museum | P12 | -6.903069 | 107.619750 | 0.50, 0.93 | Pintu masuk |
| P12 *(kandidat)* | Koleksi Peralatan Pos | P03 | -6.902436 | 107.619080 | 0.13, 0.49 | Ruang 2 |
| P13 *(kandidat)* | Tempat Pos Kereta Api | P13 | -6.902608 | 107.619750 | 0.50, 0.61 | Lorong |
| *Luar pintu masuk* | – | – | -6.903390 | 107.619750 | – | titik awal uji |

Jarak antar-POI minimal ±22 m (P02–P11; PRD v1: P02–P12), sehingga radius trigger 10 m tidak tumpang tindih (diuji di `poi_parsing_test.dart`). **Semua koordinat ini PLACEHOLDER.**

**b. Rute / GPX**: pada tab *Routes*, tekan **Import GPX/KML**, pilih [docs/gpx/jalan_masuk_p11_p02_p01.gpx](gpx/jalan_masuk_p11_p02_p01.gpx) (dulu `jalan_masuk_p12_p02_p01.gpx`), lalu **Play Route** (kecepatan 1x–4x). Rute dimulai di luar pintu masuk, berjalan ke P11 (stempel; PRD v1: P12), P02 (lorong pintu masuk), lalu P01 (ruang awal), dengan jeda singkat di tiap POI. Hasil yang diharapkan:
- Log `Masuk area museum`.
- Log `approaching` P11 saat jarak ±15 m (state 2 / UI06).
- Log `triggered` P11 **satu kali**, disertai SnackBar "Kamu berada di zona P11 …" dan tombol **LIHAT** ke UI08.
- Berjalan ke P02: `triggered` P02, lalu `exited` P11. Kemudian ke P01: `triggered` P01.
- Putar ulang rute: **tidak ada** `triggered` lagi ("sudah terpicu sesi ini"), walaupun aplikasi ditutup dan dibuka ulang. Tekan **Akhiri kunjungan** di tab Progres untuk memulai kunjungan baru.

Cuplikan format GPX:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="JejakPOS" xmlns="http://www.topografix.com/GPX/1/1">
  <trk><trkseg>
    <trkpt lat="-6.903390" lon="107.619750"><time>2026-11-03T08:00:00Z</time></trkpt>
    <trkpt lat="-6.903350" lon="107.619750"><time>2026-11-03T08:00:03Z</time></trkpt>
    <!-- ... tiap ±5 m, 3 detik ... -->
  </trkseg></trk>
</gpx>
```

## 6. Keterbatasan emulator dan cara mengatasinya

| Keterbatasan | Dampak | Solusi di JejakPOS |
|---|---|---|
| **Tidak ada Bluetooth/BLE** | Beacon tidak bisa dipindai | `SimulationService.emitBeacon("BCN-Pxx")` melalui **Panel Simulasi → ikon bluetooth**. Scanner asli (`flutter_blue_plus`) hanya bisa diuji di HP fisik. **Evidence PB05 menurut PRD harus dari area uji: log uji + foto lokasi**, jadi emulator hanya untuk pengembangan. |
| Kamera hanya virtual (VirtualScene) | QR sulit dipindai | **UI12 → Input kode manual** (`QR-P01` … `QR-P13`). Alternatifnya, tampilkan gambar QR di layar laptop di depan webcam (Camera = Webcam0). |
| GPS terlalu "sempurna" | Hysteresis dan debounce jarang teruji | Unit test `trigger_engine_test.dart` menguji sinyal berkedip dan pembacaan liar. |
| Lompat lokasi via Single point | Trigger perlu 2 pembacaan | Emulator mengirim update berkala. Mode simulasi mengirim ulang posisi tiap 1 detik. |

**Panel Simulasi** (`/debug/simulation`, ikon 🐞 di AppBar Jelajah saat debug):
- Toggle **Mode simulasi**: aktif berarti posisi dan beacon berasal dari aplikasi, nonaktif berarti GPS dari Extended Controls.
- **Pindah ke Pxx** (ikon pin): posisi diset tepat di POI.
- **Kirim beacon** (ikon bluetooth): menyimulasikan beacon BCN-Pxx terdeteksi dengan RSSI -60.
- **Ke pintu masuk** dan **Reset sesi trigger** (sama dengan "Akhiri kunjungan"): untuk mengulang pengujian.

## 7. Membaca log (bukti PB02 dan trigger)

- Android Studio: tab **Run** atau **Logcat**. Filter dengan kata kunci `JejakPOS`.
- Terminal `flutter run`: log tampil langsung.
- Format log:
  ```
  JejakPOS [08:00:30][LOKASI] Lokasi terbaca: -6.903206, 107.619750 (±5.0 m, gps)
  JejakPOS [08:00:30][TRIGGER] TriggerEvent(P11, approaching, gps, 15.0 m)
  JejakPOS [08:00:36][TRIGGER] TriggerEvent(P11, triggered, gps, 9.8 m)
  JejakPOS [08:01:40][TRIGGER] P11 dimasuki lagi, sudah terpicu sesi ini (tidak diulang)
  JejakPOS [08:00:01][DATA] 13 POI dimuat dari assets/data/pois.json
  ```
- Log yang sama tampil di **UI02 → Log Deteksi**. Rekam layar bagian ini untuk evidence PB02.

## 8. Membangun APK debug

```bash
flutter build apk --debug
# hasil: build/app/outputs/flutter-apk/app-debug.apk
adb install -r build/app/outputs/flutter-apk/app-debug.apk   # pasang ke emulator/HP
```
APK debug bisa dibagikan ke anggota tim untuk dicoba di HP fisik (aktifkan *Install unknown apps*).

## 9. Masalah umum

| Gejala | Solusi |
|---|---|
| `flutter: command not found` | PATH belum berisi `flutter\bin`. Restart terminal atau Android Studio. |
| Lokasi "Menunggu GPS..." terus | Izin belum diberikan, Location emulator mati, atau belum *Set Location*. Tekan refresh di UI02. |
| Gradle gagal *minSdk* | Pastikan `minSdk` di `android/app/build.gradle(.kts)` ≥ 21 (default Flutter terbaru sudah memenuhi). |
| Audio tidak berbunyi | Volume emulator (Extended Controls) atau aset WAV belum ada. Jalankan `flutter pub get` ulang. |
