# JejakPos computer vision

Branch `computer-vision` menggabungkan source main v3.6, branch QR P01–P11 beserta desain terbarunya, dan pengenalan SIFT pada fitur **Kenali**.

## Aplikasi terbaru

APK uji ARM64 ada di [JejakPOS-computer-vision-arm64.apk](../apk/JejakPOS-computer-vision-arm64.apk). Versi semua foto adalah **3.6.3-cv**, nomor build **8**. Buka aplikasi → Kenali → izinkan kamera → arahkan ke gambar, panel, atau ruangan POI → tiga hasil konsisten → informasi POI. Foto contoh dan pilihan POI manual tidak ditampilkan di halaman Kenali.

## Sumber referensi dari assets aplikasi

CV langsung memakai **`assets/images/pois/`**. Saat ini ada **70 foto koleksi** dari P01–P11 dan **13 gambar placeholder**. Semua foto koleksi menjadi referensi. File placeholder `pNN_1.png` dikecualikan karena bukan foto koleksi; sebagian labelnya juga memakai penomoran lama.

Pemetaan pada `assets/data/pois.json` menjadi acuan utama. Foto tambahan yang belum tercantum di data dipetakan berdasarkan awalan nama file, seperti `p07_12.jpg` ke P07. Metadata gambar yang dipakai oleh lebih dari satu POI ditolak agar label tidak salah. P12 dan P13 tetap nonaktif dalam data aplikasi.

Folder ZIP lama `tools/vision/demo/data/POIxxx` tidak lagi digunakan untuk pengenalan. File `reference_selection.json` sudah dihapus. Foto yang ditambahkan langsung ke assets akan ikut saat indeks diekspor ulang.

## Android offline

`SiftVision.java` menjalankan OpenCV pada worker thread native. Indeks berada di `android/app/src/main/assets/jejakpos_sift/`. Format JPSIFT02 menyimpan descriptor integer SIFT secara lossless dalam byte, lalu Android mengembalikannya ke float32 yang identik. Loader juga tetap menerima format JPSIFT01 lama. Flutter mengirim bidang luminans kamera tanpa crop embedding 224px. Ratio test, RANSAC, jumlah/sebaran inlier dan bentuk proyeksi memverifikasi kandidat. Hasil ambigu/tidak dikenal tidak memicu POI. Tiga frame yang diterima berurutan diteruskan lewat `TriggerSource.vision` ke alur informasi dan narasi aplikasi.

Android tidak memerlukan server Python atau internet untuk pengenalan SIFT. Jalur embedding lama dipertahankan untuk platform non-Android yang mendukungnya.

Bangun ulang indeks setelah menambah foto:

```powershell
python -m pip install -r tools/vision/demo/requirements.txt
python tools/vision/export_sift_android.py
```

Lalu build APK baru; mengganti foto atau indeks pada GitHub tidak memperbarui APK yang sudah terpasang. Ikuti [panduan lengkap untuk anggota tim](PANDUAN_TAMBAH_REFERENSI_CV.md).

## Build APK uji

Konfigurasi yang dipakai: Flutter 3.47.9, JDK 21, Android SDK 36, Gradle 8.14.3, AGP 8.11.1. JDK 25 tidak kompatibel dengan wrapper Gradle branch ini.

```powershell
flutter pub get
flutter build apk --config-only --release --target-platform android-arm64 --build-name=3.6.3-cv --build-number=8
```

Dengan JAVA_HOME menunjuk JDK 21:

```powershell
.\android\gradlew.bat -p android :app:assembleRelease --no-daemon "-Ptarget-platform=android-arm64" "-Ptarget=lib/main.dart" "-Ptree-shake-icons=true" "-Pdisable-abi-filtering=true" "-Pshrink=false" -x lintVitalRelease -x lintVitalAnalyzeRelease -x lintVitalReportRelease
```

Hasil: `build/app/outputs/apk/release/app-release.apk`. Distribusi uji ini mematikan shrinking dan melewati lint vital; kompilasi dan penandatanganan APK tetap berjalan. APK ini untuk pengujian internal, bukan rilis Play Store.

Gunakan kunci yang sama untuk memperbarui APK yang sudah terpasang. Kunci APK CV berbeda dari APK v3.6 asli pada repo. Jangan menghapus data kunjungan untuk memaksa pembaruan.

## Pratinjau laptop

```powershell
flutter build web --no-web-resources-cdn --no-wasm-dry-run
python -m pip install -r tools/vision/demo/requirements.txt
python tools/vision/serve_local_app.py
```

Buka http://127.0.0.1:8787/. Bingkai HP memuat aplikasi Flutter web lengkap. Kenali memakai kamera browser dan backend CV lokal pada origin yang sama. Kamera membutuhkan izin browser. Ini bukan emulator APK; server hanya mendengarkan loopback dan tidak dirancang sebagai server publik.

## Validasi

- Seluruh 70/70 foto assets lolos uji transformasi perspektif dan pencahayaan; tiga negatif sintetis ditolak. Laporan: `tools/vision/demo/evaluation.json`. Enam tes pemetaan, cakupan galeri dan format indeks pada `tools/vision/test_reference_assets.py` juga lulus.
- Pengujian tersebut memakai transformasi dari referensi yang sama, bukan foto kamera independen atau ukuran akurasi di museum.
- Tes integrasi controller memeriksa ID P01–P11, tiga frame, penolakan hasil ambigu/tidak dikenal, serta pencegahan trigger ulang. Suite gabungan sebelumnya berisi 148 tes yang lulus setelah dua tes tutorial diperbarui.
- Kamera Android fisik, latensi SIFT pada HP, dan akurasi museum tetap perlu diuji langsung. Gunakan foto baru dari sudut, jarak, dan sesi pengambilan berbeda; uji juga objek yang bukan POI.
