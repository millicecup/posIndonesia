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

## 3 Simpan foto pada folder POI

Contoh foto tambahan untuk lemari prangko POI007:

```text
tools/vision/demo/data/POI007/images/
  Prangko Geser.jpg
  poi007_lemari_depan_01.jpg
  poi007_lemari_kiri_01.jpg
```

| Folder referensi | ID aplikasi | Isi POI |
| --- | --- | --- |
| POI001 | P01 | Komunikasi tertulis di Nusantara |
| POI002 | P02 | Sejarah Pos Indonesia |
| POI003 | P03 | Sejarah kepemimpinan Pos |
| POI004 | P04 | Seragam petugas pos |
| POI005 | P05 | Pembuatan prangko |
| POI006 | P06 | Kode Pos Indonesia |
| POI007 | P07 | Koleksi prangko lemari geser |
| POI008 | P08 | Mas Soeharto |
| POI009 | P09 | Kotak pos |
| POI010 | P10 | Mars Pos Indonesia |
| POI011 | P11 | Stempel museum |

Gunakan folder `POI007`, bukan `P07`. P12 dan P13 belum didukung oleh daftar referensi SIFT saat ini; menambah POI baru memerlukan perubahan kode dan data aplikasi, bukan sekadar folder tambahan.

Pilih foto JPG, JPEG, atau PNG yang menampilkan ruangan, lemari, atau panel seperti dilihat pengunjung. Ambil beberapa sudut dan jarak, dengan objek utama tetap jelas dan pencahayaan museum. Untuk pengenalan lokasi, prioritaskan foto lokasi dibanding potret tokoh, gambar arsip, atau gambar seragam untuk studio foto. Tambahkan bertahap karena jumlah referensi memengaruhi ukuran indeks dan waktu pencocokan.

`assets/images/pois/` berisi gambar tampilan koleksi. Menambah gambar di sana tidak otomatis menambah referensi SIFT. Mengubah referensi CV juga tidak otomatis mengganti foto kartu koleksi.

## 4 Pastikan semua foto ikut dipakai

Buka `tools/vision/demo/reference_selection.json`. Bawaan branch sekarang adalah:

```json
{}
```

Dengan konfigurasi kosong tersebut, semua JPG/JPEG/PNG pada setiap folder `POIxxx/images` otomatis masuk sebagai referensi. Untuk menambah foto, cukup salin gambar ke folder POI yang benar, lalu lanjutkan pemeriksaan dan ekspor indeks. Tidak perlu menulis nama setiap foto di JSON.

Jika file ini berisi entri suatu POI dengan daftar nama foto, hanya file dalam daftar itu yang akan dipakai untuk POI tersebut. Hapus entri POI itu bila ingin kembali memakai semua fotonya. Nama file, spasi, dan ekstensi harus sesuai jika tim sengaja menggunakan daftar pilihan. JSON tidak boleh memakai komentar atau koma setelah elemen terakhir.

## 5 Periksa foto sebelum ekspor

Perintah berikut memuat referensi yang aktif dan mencari foto yang tidak mempunyai cukup fitur SIFT:

```powershell
.\.venv-vision\Scripts\python.exe -c "import sys; sys.path.insert(0,'tools/vision/demo'); from recognizer import Recognizer; m=Recognizer(); bad=[r['reference'] for r in m.refs if r['des'] is None or len(r['des'])<12]; print('Foto aktif:',len(m.refs)); print('Foto perlu diganti:',bad); sys.exit(bool(bad))"
```

Lanjutkan jika daftar `Foto perlu diganti` kosong. Bila ada foto di daftar itu, ganti dengan foto yang lebih jelas dan memiliki detail visual, atau keluarkan dari referensi aktif. Pemuat indeks Android menolak referensi dengan kurang dari 12 fitur. Foto rusak atau nama file yang salah juga harus diperbaiki sebelum ekspor.

## 6 Bangun ulang indeks SIFT Android

```powershell
.\.venv-vision\Scripts\python.exe tools/vision/export_sift_android.py
```

Perintah ini menghasilkan ulang:

```text
android/app/src/main/assets/jejakpos_sift/index.bin
android/app/src/main/assets/jejakpos_sift/manifest.json
```

Terminal akan menampilkan `Exported ... reference images`. Periksa daftar sumber dan jumlah referensi dalam manifest:

```powershell
Get-Content android/app/src/main/assets/jejakpos_sift/manifest.json -Raw |
  ConvertFrom-Json |
  Select-Object references, poiIds
```

Sebelum penambahan, indeks branch ini mempunyai 36 foto aktif. Jika hanya dua foto POI007 dalam contoh tadi yang ditambahkan, jumlahnya menjadi 38. Pastikan nama kedua foto muncul di bagian `sources` pada `manifest.json`.

Gunakan `export_sift_android.py` untuk SIFT Android. Script `build_vision_index.py` di folder yang sama membuat indeks embedding untuk jalur pengenalan lama dan tidak memperbarui `jejakpos_sift/index.bin`.

Jika ekspor gagal, jangan commit atau distribusikan `index.bin` hasil percobaan yang gagal. Perbaiki sumber foto, lalu ekspor ulang sampai selesai. Tidak perlu mengedit isi `index.bin` secara manual.

## 7 Jalankan pemeriksaan aplikasi

```powershell
flutter test
```

Untuk memeriksa ketahanan referensi terhadap perubahan perspektif dan pencahayaan, jalankan juga:

```powershell
.\.venv-vision\Scripts\python.exe tools/vision/demo/evaluate.py
```

Hasilnya disimpan pada `tools/vision/demo/evaluation.json`. Pengujian ini menggunakan transformasi dari foto referensi yang sama, sehingga bukan ukuran akurasi kamera museum. Sisihkan foto baru dari sesi pengambilan berbeda untuk pengujian langsung dan uji juga objek yang tidak termasuk POI agar tidak terjadi pengenalan keliru.

## 8 Bangun APK uji ARM64

Koordinasikan dahulu kunci penandatanganan yang akan dipakai. Konfigurasi branch ini memakai `signingConfigs.getByName("debug")`; laptop lain dapat mempunyai debug keystore yang berbeda. Untuk memperbarui pemasangan yang sudah ada, gunakan kunci yang sama dengan APK yang terpasang. Keystore APK v3.6 berbeda dari APK CV pertama yang dibagikan. Jangan mengunggah keystore atau kata sandinya ke GitHub. Penjelasan penandatanganan tersedia di [dokumentasi Android](https://developer.android.com/studio/publish/app-signing).

Contoh berikut membuat versi `3.6.3-cv`, nomor build `8`, setelah APK semua foto bernomor `7`. Jika tim sudah menerbitkan nomor yang lebih tinggi, naikkan nomor tersebut lagi. Flutter memetakan `--build-name` ke `versionName` dan `--build-number` ke `versionCode`; lihat [dokumentasi build Android Flutter](https://docs.flutter.dev/deployment/android).

Siapkan file konfigurasi dan wrapper melalui Flutter:

```powershell
flutter build apk --config-only --release --target-platform android-arm64 --build-name=3.6.3-cv --build-number=8
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
git add tools/vision/demo/data tools/vision/demo/reference_selection.json
git add android/app/src/main/assets/jejakpos_sift/index.bin android/app/src/main/assets/jejakpos_sift/manifest.json
git add -f apk/JejakPOS-computer-vision-arm64.apk apk/JejakPOS-computer-vision-arm64.apk.sha256
git diff --cached --stat
git commit -m "feat: add location references and rebuild CV APK"
git push origin computer-vision
```

Perbarui pula keterangan versi dan hasil uji pada `apk/README.md` jika membagikan APK baru. Jika APK dibagikan lewat Releases, cukup commit foto, daftar pilihan, indeks, dan dokumentasi tautan rilisnya; lewati perintah `git add` untuk APK.

Jika push ditolak karena branch sudah diperbarui teman lain, ambil dan gabungkan perubahan terbaru terlebih dahulu, lalu ekspor ulang indeks dan build ulang APK agar semua referensi tim ikut terbawa. Jangan menyelesaikan konflik `index.bin` dengan menggabungkan byte secara manual.

## Masalah yang sering muncul

| Gejala | Yang perlu diperiksa |
| --- | --- |
| Foto baru tidak muncul di manifest | Folder POI, ekstensi gambar, dan entri `reference_selection.json` |
| `Referensi lokasi tidak ditemukan` | Ejaan, spasi, ekstensi, dan keberadaan file yang disebut JSON |
| Foto kurang dari 12 fitur atau `No descriptor` | Gunakan foto lebih jelas dan bertekstur, lalu ulangi pemeriksaan foto dan ekspor |
| Indeks baru sudah dibuat tetapi APK tidak berubah | Build ulang APK, salin hasil build terbaru, lalu pasang APK yang benar |
| Java 25 tidak kompatibel | Arahkan Flutter dan `JAVA_HOME` ke JDK 21 |
| Android menolak pembaruan | Kunci penandatanganan harus sesuai dengan pemasangan sebelumnya |
| Push mendapat penolakan akses | Pastikan akun memiliki akses tulis ke repo atau gunakan alur pull request tim |

Panduan arsitektur dan batas pengenalan ada di [COMPUTER_VISION.md](COMPUTER_VISION.md).
