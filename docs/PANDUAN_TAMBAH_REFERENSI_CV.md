# Panduan menambah foto referensi CV JejakPos

Untuk anggota tim yang akan menambah foto ruangan atau panel POI pada branch `computer-vision`, membangun ulang indeks SIFT, lalu membuat APK Android baru. Jalankan semua perintah dari folder utama repo menggunakan PowerShell di Windows.

Alurnya: **tambahkan foto → perbarui daftar referensi bila diperlukan → periksa foto → ekspor indeks → build APK → uji di HP → commit dan push**. Mengunggah foto ke GitHub saja tidak memperbarui pengenalan pada APK yang sudah terpasang.

## 1 Ambil branch yang benar

Untuk clone baru:

```powershell
git clone --branch computer-vision --single-branch https://github.com/millicecup/posIndonesia.git
cd posIndonesia
```

Jika repo sudah ada, pastikan pekerjaan sebelumnya sudah disimpan sebelum berpindah branch:

```powershell
git status
git fetch origin
git switch computer-vision
git pull --ff-only origin computer-vision
```

Pastikan `git branch --show-current` menampilkan `computer-vision`.

## 2 Siapkan alat

Konfigurasi yang sudah dipakai membangun APK branch ini adalah Flutter 3.47.9, Python 3.12, JDK 21, Android SDK 36, dan NDK 28.2.13676358. Wrapper repo memakai Gradle 8.14.3, AGP 8.11.1, dan Kotlin 2.2.20. Gunakan JDK 21; JDK 25 tidak kompatibel dengan wrapper Gradle tersebut.

Instal Git, Flutter, Python, JDK 21, serta Android Studio dengan SDK Android. Sesuaikan contoh lokasi JDK di bawah dengan folder JDK 21 di laptopmu. `flutter config --jdk-dir` mengatur JDK yang digunakan Flutter pada laptop itu.

```powershell
$jejakposJdk = "C:\Program Files\Eclipse Adoptium\jdk-21"
$env:JAVA_HOME = $jejakposJdk
flutter config --jdk-dir "$jejakposJdk"
flutter doctor -v
flutter pub get

python -m venv .venv-vision
.\.venv-vision\Scripts\python.exe -m pip install -r tools/vision/demo/requirements.txt
```

Selesaikan masalah Android SDK yang dilaporkan `flutter doctor`. Jika lisensi SDK belum diterima, jalankan `flutter doctor --android-licenses` dan baca ketentuannya. Tidak perlu mengaktifkan virtual environment melalui `Activate.ps1`; perintah di panduan ini langsung memakai Python di `.venv-vision`.

## 3 Tambahkan foto langsung ke assets

Sumber referensi CV sekarang langsung dari **`assets/images/pois/`**. Folder ini berisi 70 foto koleksi aktif dan 13 gambar placeholder. Gambar placeholder `pNN_1.png` tidak dipakai untuk pengenalan.

Contoh penambahan foto untuk P07:

```text
assets/images/pois/
  p07_01.jpg
  ...
  p07_11.jpg
  p07_12.jpg
  p07_13.jpg
```

Gunakan JPG, JPEG, atau PNG dan ikuti awalan ID POI: `p01_...` untuk P01 sampai `p11_...` untuk P11. Pilih nomor yang belum ada agar foto lama tidak tertimpa. Jangan menamai foto baru `p07_1.png`, karena pola `pNN_1.png` dipakai oleh placeholder lama.

Pemetaan yang tercantum pada `assets/data/pois.json` menjadi acuan utama. Untuk foto tambahan yang belum tercantum di JSON, ID diambil dari awalan nama file. Contohnya `p07_12.jpg` masuk P07. Jika nama file tidak punya ID dan tidak terdaftar dalam data POI, ekspor ditolak supaya foto tidak salah dipetakan.

P12 dan P13 masih berstatus `baseline: false` dan hanya mempunyai placeholder pada folder ini. Menambah POI aktif baru perlu penyesuaian data dan alur aplikasi, bukan sekadar menyalin gambar.

## 4 Tampilkan foto baru di galeri bila diperlukan

Semua foto asli dalam folder assets tersebut ikut menjadi referensi CV ketika indeks dibangun ulang. Untuk menampilkan foto baru juga di galeri atau cerita aplikasi, tambahkan path-nya pada POI yang sesuai dalam `assets/data/pois.json`, misalnya ke daftar `images` atau `sections[n].images`:

```json
"images": [
  "assets/images/pois/p07_06.jpg",
  "assets/images/pois/p07_12.jpg"
]
```

Cuplikan itu hanya contoh sebuah field; pertahankan foto dan field lain yang sudah ada. Jangan menempatkan foto yang sama pada dua POI berbeda. Gunakan nama file, spasi, ekstensi dan huruf besar/kecil yang sesuai.

Folder `tools/vision/demo/data/POIxxx` dari ZIP lama tidak lagi menjadi sumber CV. File `reference_selection.json` juga sudah dihapus; tidak ada daftar pilihan foto terpisah yang perlu diperbarui.

## 5 Periksa foto sebelum ekspor

```powershell
.\.venv-vision\Scripts\python.exe -c "import sys; sys.path.insert(0,'tools/vision/demo'); from recognizer import Recognizer; m=Recognizer(); print('Foto siap:',len(m.refs)); print('Dikecualikan:',m.excluded)"
```

Pemeriksaan memuat seluruh foto aktif, memastikan pemetaan POI, dan menolak foto rusak atau foto dengan kurang dari 12 fitur SIFT. Ganti foto yang gagal dengan foto yang lebih jelas dan memiliki detail visual, lalu jalankan kembali. Placeholder tampil sebagai pengecualian yang disengaja.

Untuk pemakaian kamera di museum, tambahkan variasi sudut, jarak dan pencahayaan nyata. Semua foto koleksi pada assets dipakai; gambar dekorasi, ikon dan maskot di folder lain tidak dipakai.

## 6 Bangun ulang indeks SIFT Android

```powershell
.\.venv-vision\Scripts\python.exe tools/vision/export_sift_android.py
```

Hasilnya:

```text
android/app/src/main/assets/jejakpos_sift/index.bin
android/app/src/main/assets/jejakpos_sift/manifest.json
```

Periksa sumber dan jumlah fotonya:

```powershell
Get-Content android/app/src/main/assets/jejakpos_sift/manifest.json -Raw |
  ConvertFrom-Json |
  Select-Object sourceDirectory, references, poiIds
```

`sourceDirectory` harus `assets/images/pois`. Indeks saat ini berisi 70 foto; setelah menambah dua foto tanpa mengubah yang lain, jumlahnya menjadi 72. Bagian `sources` mencantumkan setiap foto aktif; `excluded` menjelaskan placeholder atau POI nonaktif yang tidak diindeks.

Indeks baru memakai format JPSIFT02 yang menyimpan descriptor SIFT secara ringkas tanpa kehilangan nilai. Android merekonstruksi descriptor yang sama saat indeks dimuat. Tidak perlu mengedit isi `index.bin` secara manual.

Ekspor menggunakan file sementara, sehingga pemeriksaan yang gagal tidak mengganti indeks sebelumnya. Perbaiki foto lalu ulangi ekspor sampai terminal menampilkan jumlah foto yang sesuai.

## 7 Jalankan pemeriksaan aplikasi

```powershell
.\.venv-vision\Scripts\python.exe -m unittest discover -s tools/vision -p test_reference_assets.py
flutter test
```

Untuk memeriksa ketahanan referensi terhadap perubahan perspektif dan pencahayaan, jalankan juga:

```powershell
.\.venv-vision\Scripts\python.exe tools/vision/demo/evaluate.py
```

Hasilnya disimpan pada `tools/vision/demo/evaluation.json`. Pengujian ini menggunakan transformasi dari foto referensi yang sama, sehingga bukan ukuran akurasi kamera museum. Sisihkan foto baru dari sesi pengambilan berbeda untuk pengujian langsung dan uji juga objek yang tidak termasuk POI agar tidak terjadi pengenalan keliru.

## 8 Bangun APK uji ARM64

Koordinasikan dahulu kunci penandatanganan yang akan dipakai. Konfigurasi branch ini memakai `signingConfigs.getByName("debug")`; laptop lain dapat mempunyai debug keystore yang berbeda. Untuk memperbarui pemasangan yang sudah ada, gunakan kunci yang sama dengan APK yang terpasang. Keystore APK v3.6 berbeda dari APK CV pertama yang dibagikan. Jangan mengunggah keystore atau kata sandinya ke GitHub. Penjelasan penandatanganan tersedia di [dokumentasi Android](https://developer.android.com/studio/publish/app-signing).

Contoh berikut membuat versi `3.6.4-cv`, nomor build `9`, setelah APK berbasis assets bernomor `8`. Jika tim sudah menerbitkan nomor yang lebih tinggi, naikkan nomor tersebut lagi. Flutter memetakan `--build-name` ke `versionName` dan `--build-number` ke `versionCode`; lihat [dokumentasi build Android Flutter](https://docs.flutter.dev/deployment/android).

Siapkan file konfigurasi dan wrapper melalui Flutter:

```powershell
flutter build apk --config-only --release --target-platform android-arm64 --build-name=3.6.4-cv --build-number=9
```

Lalu bangun APK uji dengan pengaturan yang digunakan untuk distribusi uji branch ini. Pastikan `JAVA_HOME` masih menunjuk JDK 21.

```powershell
.\android\gradlew.bat -p android :app:assembleRelease --no-daemon "-Ptarget-platform=android-arm64" "-Ptarget=lib/main.dart" "-Ptree-shake-icons=true" "-Pdisable-abi-filtering=true" "-Pshrink=false" -x lintVitalRelease -x lintVitalAnalyzeRelease -x lintVitalReportRelease
```

Build ini menonaktifkan shrinking dan melewati lint vital; ini pengaturan untuk APK uji internal, bukan panduan rilis Play Store. Kompilasi aplikasi dan penandatanganan APK tetap berjalan. Pengaturan ARM64 ada di `android/app/build.gradle.kts`.

Hasil yang dipakai:

```text
build/app/outputs/apk/release/app-release.apk
```

File tersebut memuat indeks SIFT baru. APK lama yang masih ada di folder `apk/` tidak berubah sampai hasil build disalin ke sana.

## 9 Uji pada HP

Pasang APK baru pada HP Android ARM64, buka aplikasi, lalu pilih **Kenali** dan izinkan kamera. Arahkan kamera ke ruangan atau panel yang difoto. Identifikasi diteruskan ke alur POI setelah tiga hasil pemindaian yang konsisten. Coba juga panel dari POI lain dan objek di luar dataset.

Jika Android menolak pembaruan karena tanda tangan berbeda, gunakan keystore yang sesuai dan tanda tangani ulang APK. Jangan menghapus aplikasi lama jika data kunjungannya masih diperlukan. Untuk referensi baru, uji dari sudut, jarak, dan pencahayaan yang tidak persis sama dengan foto referensi.

## 10 Simpan dan unggah perubahan

Salin APK hasil build dan buat checksum baru:

```powershell
Copy-Item build/app/outputs/apk/release/app-release.apk apk/JejakPOS-computer-vision-arm64.apk
$jejakposApk = "apk/JejakPOS-computer-vision-arm64.apk"
$jejakposHash = (Get-FileHash $jejakposApk -Algorithm SHA256).Hash.ToLower()
"$jejakposHash  JejakPOS-computer-vision-arm64.apk" |
  Set-Content "$jejakposApk.sha256" -Encoding ascii
Get-Item $jejakposApk | Select-Object Name, Length
```

APK pertama sebelum seluruh foto diaktifkan berukuran sekitar 96 MB. Penambahan referensi bisa membuat ukuran APK bertambah. GitHub memblokir file Git yang lebih besar dari 100 MiB; periksa juga ukuran `index.bin`. Jika APK melewati batas tersebut, bagikan melalui GitHub Releases dan perbarui tautan unduh, jangan memaksakan commit APK ke Git. Lihat [batas file dan distribusi binary GitHub](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github).

Jika ukuran APK masih di bawah batas, siapkan commit:

```powershell
git add assets/images/pois assets/data/pois.json
git add android/app/src/main/assets/jejakpos_sift/index.bin android/app/src/main/assets/jejakpos_sift/manifest.json
git add -f apk/JejakPOS-computer-vision-arm64.apk apk/JejakPOS-computer-vision-arm64.apk.sha256
git diff --cached --stat
git commit -m "feat: add location references and rebuild CV APK"
git push origin computer-vision
```

Perbarui pula keterangan versi dan hasil uji pada `apk/README.md` jika membagikan APK baru. Jika APK dibagikan lewat Releases, cukup commit foto assets, data POI, indeks, dan dokumentasi tautan rilisnya; lewati perintah `git add` untuk APK.

Jika push ditolak karena branch sudah diperbarui teman lain, ambil dan gabungkan perubahan terbaru terlebih dahulu, lalu ekspor ulang indeks dan build ulang APK agar semua referensi tim ikut terbawa. Jangan menyelesaikan konflik `index.bin` dengan menggabungkan byte secara manual.

## Masalah yang sering muncul

| Gejala | Yang perlu diperiksa |
| --- | --- |
| Foto baru tidak muncul di manifest | Folder assets, ekstensi gambar, awalan pNN, dan pemetaan pada pois.json |
| `Asset koleksi tidak ditemukan` | Ejaan, spasi, ekstensi, dan keberadaan file yang disebut JSON |
| Foto kurang dari 12 fitur atau `No descriptor` | Gunakan foto lebih jelas dan bertekstur, lalu ulangi pemeriksaan foto dan ekspor |
| Indeks baru sudah dibuat tetapi APK tidak berubah | Build ulang APK, salin hasil build terbaru, lalu pasang APK yang benar |
| Java 25 tidak kompatibel | Arahkan Flutter dan `JAVA_HOME` ke JDK 21 |
| Android menolak pembaruan | Kunci penandatanganan harus sesuai dengan pemasangan sebelumnya |
| Push mendapat penolakan akses | Pastikan akun memiliki akses tulis ke repo atau gunakan alur pull request tim |

Panduan arsitektur dan batas pengenalan ada di [COMPUTER_VISION.md](COMPUTER_VISION.md).
