# JejakPos computer vision

Branch `computer-vision` menggabungkan source `main` v3.6, seluruh perubahan `codex/add-qr-poi-7-11` (sampai commit 8e5fea6), dan pengenalan SIFT pada fitur **Kenali**.

## Aplikasi

APK ARM64 hasil integrasi tersedia di `apk/JejakPOS-computer-vision-arm64.apk` setelah build selesai. APK untuk uji internal, menggunakan penandatanganan debug sesuai konfigurasi proyek. Cek kecocokan tanda tangan sebelum memperbarui pemasangan lama; jangan hapus data kunjungan untuk memaksa pembaruan.

Alur: buka aplikasi → Kenali → berikan izin kamera → arahkan kamera ke panel/ruangan POI → tiga hasil konsisten → informasi POI. Layar Kenali tidak menyediakan pilihan POI manual maupun foto contoh. QR tetap fitur terpisah dan mendukung P01–P11.

## Android offline

`SiftVision.java` menjalankan OpenCV pada worker thread native. Indeks SIFT 29 referensi untuk P01–P11 dibundel di `android/app/src/main/assets/jejakpos_sift/`. Flutter mengirim bidang luminans kamera tanpa crop embedding 224px. Ratio test, RANSAC, jumlah/sebaran inlier dan bentuk proyeksi memverifikasi kandidat; hasil ambigu/tidak dikenal tidak memicu POI. Tiga frame yang diterima berurutan diteruskan melalui `TriggerSource.vision` ke alur informasi dan narasi aplikasi. Android tidak memerlukan server Python atau internet untuk pengenalan ini. Jalur embedding lama dipertahankan untuk platform non-Android yang mendukungnya.

Sumber referensi ada di `tools/vision/demo/data`. Foto tampilan koleksi dipisahkan dari referensi deteksi. POI002 memakai Lorong Awal dan Ruang 4; POI006 memakai panel Kode Pos; POI007 memakai lemari prangko geser. POI lain masih mencakup foto konten dalam foldernya. P12 dan P13 belum memiliki referensi pada dataset ZIP.

Bangun ulang indeks:

```powershell
python -m pip install -r tools/vision/demo/requirements.txt
python tools/vision/export_sift_android.py
```

## Build

Gunakan Flutter, Android SDK, serta JDK 21 dengan Gradle 8.14.3 / AGP 8.11.1 yang dikonfigurasi branch ini. JDK 25 tidak kompatibel dengan wrapper tersebut. Konfigurasikan JDK Flutter ke JDK 21 pada mesin build sebelum menjalankan:

```powershell
flutter pub get
flutter test
flutter build apk --release --target-platform android-arm64 --build-name=3.6.1-local-cv --build-number=6
```

Build lokal sesi pengembangan menjalankan `android/gradlew.bat assembleRelease --no-daemon -Ptarget-platform=android-arm64 -Ptarget=lib/main.dart -Ptree-shake-icons=true` dengan JAVA_HOME menunjuk JDK 21. Hasil Gradle ada di `build/app/outputs/apk/release/app-release.apk`.

## Pratinjau laptop

```powershell
flutter build web --no-web-resources-cdn --no-wasm-dry-run
python -m pip install -r tools/vision/demo/requirements.txt
python tools/vision/serve_local_app.py
```

Buka http://127.0.0.1:8787/. Bingkai HP memuat Flutter web aplikasi lengkap. Pada browser, Kenali memakai kamera browser dan backend CV lokal pada origin yang sama. Izinkan kamera; tidak ada pilihan foto contoh. Ini bukan emulator APK. Server hanya mendengarkan loopback dan tidak dirancang untuk deployment publik.

## Validasi dan batas

- 29/29 transformasi perspektif/pencahayaan dari referensi dikenali pada pengujian desktop; 3 negatif sintetis ditolak. Ini bukan akurasi foto kamera independen.
- Tes integrasi controller memeriksa ID P01–P11, tiga frame, penolakan hasil ambigu/tidak dikenal, serta pencegahan trigger ulang.
- Suite gabungan berisi 148 tes: 146 lolos pada suite utama dan dua tes tutorial lolos setelah penyesuaian ke 11 langkah.
- Gambar QR P07–P11 didekode dan sesuai ID dataset.
- Kamera Android fisik, latensi SIFT pada HP, dan akurasi museum belum diuji langsung. Emulator lokal tidak dapat dijalankan karena akselerasi virtualisasi tidak tersedia.

Uji museum tetap diperlukan: ambil foto baru dari sudut/jarak pengunjung, sisihkan sesi pengambilan untuk evaluasi, ukur false accept/recall dan latensi, serta tambah referensi lokasi terutama pada POI yang masih memakai foto konten.

## APK uji yang dibagikan

Paket ARM64 memakai versionName 3.6.1-local-cv / versionCode 6 dan kunci debug proyek. Build distribusi uji mematikan shrinking (`-Pshrink=false`) serta tidak menjalankan lint vital; kompilasi Kotlin/Java/Dart dan pengemasan tetap dijalankan. Ini paket pengujian internal, bukan build untuk Play Store. Perintah tepatnya:

```powershell
android/gradlew.bat -p android assembleRelease --no-daemon -Ptarget-platform=android-arm64 -Ptarget=lib/main.dart -Ptree-shake-icons=true -Pdisable-abi-filtering=true -Pshrink=false -x lintVitalRelease -x lintVitalAnalyzeRelease -x lintVitalReportRelease
```

Verifikasi APK: tanda tangan valid; hanya ARM64; indeks SIFT 29 referensi dan QR P01–P11 terbundel. Ukuran 96.404.410 byte. Tanda tangan berbeda dari APK v3.6 pada repo, sehingga bukan pembaruan langsung untuk pemasangan v3.6. Jangan menghapus data kunjungan untuk memaksa pembaruan. Kamera fisik museum belum diuji.
