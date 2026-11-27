# JejakPOS v3.8 — perbaikan defek DF-01 s.d. DF-11

`JejakPOS-arm64-v3.8.apk` (versionName 3.8, versionCode 10, ARM64) berisi perbaikan semua defek dari "Rangkuman Defek dan Retest". Rincian akar masalah, solusi (RP-01 s.d. RP-11), dan skenario retest ada di [docs/PERBAIKAN_DEFEK.md](../docs/PERBAIKAN_DEFEK.md).

Ringkas: sambutan otomatis saat masuk area museum (DF-01), pesan "koleksi belum dikenali" + Pindai QR di Kenali (DF-02), jeda/lanjutkan pemandu suara (DF-03), pesan & tombol minta izin kamera di Photo Studio (DF-04), riwayat & ringkasan tiap kunjungan tersimpan permanen (DF-05), tombol dialog prangko langsung merespons (DF-06), saran pemandu yang sama di semua layar + chat "Tanya pemandu" di Detail POI (DF-07), kartu paspor dengan animasi stempel karya Diva (DF-08), kamera QR langsung aktif (DF-09), kanvas Photo Studio mengikuti rasio kamera (DF-10), tombol "Petunjuk lain" yang menonjol (DF-11).

Tanda tangan sama dengan v3.7 (debug key repo), jadi bisa dipasang sebagai pembaruan di atas v3.7 tanpa menghapus data kunjungan.

Build dengan JDK 21 (perintah sama seperti v3.7, `--build-name=3.8 --build-number=10`).

Validasi: `flutter analyze` tanpa error (4 info gaya kode lama), `flutter test` 186 tes lulus (termasuk 38 tes retest di `test/defect_retest_test.dart`), `flutter build web` sukses. Ukuran 101571593 byte. SHA-256: `aefaedd7fdfd707d5238ecb381a48562b76554f0edb0bb2158f82f295d50f4f3`. Belum diuji langsung di perangkat fisik.

---

# JejakPOS v3.7 — gabungan semua branch

`JejakPOS-arm64-v3.7.apk` (versionName 3.7, versionCode 9, ARM64) dibangun dari `main` setelah semua branch digabung: `computer-vision`, `codex/fix-map-zoom`, `codex/add-qr-poi-7-11`, `firebase`, dan `content/poi-dataset`. Isinya fitur CV (SIFT), QR POI 7–11, perbaikan peta/Photo Studio, pemandu suara bahasa Indonesia, dan aset dataset POI.

Konflik `museumMapImage` diselesaikan dengan tetap memakai `assets/map/denah_museum.jpg` (denah asli 1737x2413, sama dengan `Denah2D_Real.jpg`).

Tanda tangan **sama dengan APK v3.6** (debug key repo, SHA-256 sertifikat `1a5bfe38…ff3a2`), jadi bisa dipasang sebagai pembaruan di atas v3.6. Kuncinya **berbeda** dari `JejakPOS-computer-vision-arm64.apk`, jadi tidak bisa memperbarui pemasangan APK CV secara langsung.

Build (JDK 21, karena JDK 25 tidak kompatibel dengan Gradle 8.14.3):

```powershell
flutter build apk --config-only --release --target-platform android-arm64 --build-name=3.7 --build-number=9
.\android\gradlew.bat -p android :app:assembleRelease --no-daemon "-Ptarget-platform=android-arm64" "-Ptarget=lib/main.dart" "-Ptree-shake-icons=true" "-Pdisable-abi-filtering=true" "-Pshrink=false" -x lintVitalRelease -x lintVitalAnalyzeRelease -x lintVitalReportRelease
```

Validasi: `flutter analyze` tanpa error (5 info gaya kode), `flutter test` 148 tes lolos. Ukuran 101439785 byte. SHA-256: `37289b9e12bbf23fa21c1a0faa0beef0c3dcaa689d5ab9d39c11ee271a61764c`. Belum diuji langsung di perangkat fisik.

---

# JejakPOS CV dari assets aplikasi

Unduh [JejakPOS-computer-vision-arm64.apk](JejakPOS-computer-vision-arm64.apk). Versi **3.6.3-cv**, nomor build **8**, ARM64. Sumber CV langsung dari **assets/images/pois/**: seluruh 70 foto koleksi P01–P11 menjadi referensi, sedangkan 13 placeholder dikecualikan. Label mengikuti data aplikasi dan awalan nama file pNN.

Tanda tangan sama dengan APK CV sebelumnya (nomor 6 dan 7), sehingga dapat memperbarui pemasangan versi CV tersebut. Kuncinya berbeda dari APK v3.6 asli. Jangan menghapus data kunjungan untuk memaksa pembaruan.

70/70 referensi lolos uji sintetis perspektif/pencahayaan; 3 negatif sintetis ditolak. Enam tes pemetaan assets dan format indeks juga lulus. Kamera museum belum diuji langsung. Indeks JPSIFT02 menyimpan descriptor secara lossless agar ukuran paket tetap ringkas. Metode pengenalan tetap SIFT dan verifikasi geometri.

APK ini untuk uji internal, shrinking dimatikan dan lint vital dilewati pada build distribusi uji. Ukuran 100976614 byte. SHA-256: `e6e4f1076ca1ae2067e38c91c9cefb16607c9f55413814038eeac435d66441b6`.

Lihat [panduan CV](../docs/COMPUTER_VISION.md) dan [panduan menambah foto assets](../docs/PANDUAN_TAMBAH_REFERENSI_CV.md).

---

# JejakPOS v3.6 — pemandu suara bahasa Indonesia

`JejakPOS-maps-arm64-v3.6.apk` (versionName 3.6, versionCode 5) = seluruh perubahan di bawah ditambah perbaikan pemandu suara:
- Narasi tidak lagi kadang terdengar dengan suara bahasa Inggris. Semua narasi menunggu sampai bahasa Indonesia selesai diset di TTS (sebelumnya narasi yang datang bersamaan langsung bicara dengan suara bawaan HP).
- Suara Indonesia dipilih secara eksplisit (kode `id-ID`, `id`, `in-ID`, `ind-IDN`). Bila engine bawaan HP tidak punya suara Indonesia, aplikasi beralih ke Google TTS. Bila TTS belum siap, pengaturan dicoba lagi pada narasi berikutnya.
- Istilah "Photo Studio" pada narasi diganti "studio foto".

Version code 5 lebih tinggi dari build sebelumnya (4), jadi bisa dipasang sebagai pembaruan di atas `JejakPOS-maps-arm64.apk`.

```sh
flutter build apk --release --no-pub --target-platform android-arm64 --build-name=3.6 --build-number=5
```

Validasi: `flutter analyze` bersih, `flutter test` 111 tes lolos (termasuk `test/narration_voice_test.dart`). Suara TTS di perangkat fisik belum diuji langsung.

---

# JejakPOS — perbaikan peta dan Photo Studio

`JejakPOS-maps-arm64.apk` adalah build release untuk perangkat Android ARM64.

Perubahan:
- Denah menyesuaikan ukuran layar ketika peta dibuka.
- Zoom dibatasi hingga empat kali ukuran tampilan awal.
- Tombol perbesar, perkecil, dan tampilkan seluruh denah tersedia pada peta dan petunjuk arah.
- Rotasi serta zoom melalui ketukan ganda dinonaktifkan.
- Photo Studio langsung dibuka tanpa syarat lokasi atau pindai QR.
- Kamera depan tampil langsung bersama overlay seragam/topi sebagai panduan pose. Setelah dijepret, posisi dan ukuran overlay masih bisa disesuaikan. Tidak ada impor dari galeri.
- Seragam dan topi dipasangkan menurut warna Coklat Tua, Hijau, dan Khaki, memakai enam PNG asli dari `POI004/images/Photo Studio ...` di branch `content/poi-dataset`.
- Kamera dilepas ketika aplikasi masuk latar belakang dan dibuka kembali saat aplikasi aktif.
- Hasil PNG disimpan ke `Pictures/JejakPOS` melalui MediaStore Android. Setelah berhasil, aplikasi kembali ke editor dengan notifikasi “Foto sudah tersimpan di galeri HP.”
- Header memakai gradasi oranye, maskot prangko diperbesar dengan bubble chat, dan informasi internal sumber konten disembunyikan.
- Foto koleksi P07 dirapikan agar tidak berulang dan gambar ditampilkan utuh.

Build menggunakan konfigurasi penandatanganan debug yang saat ini dipakai project, sehingga ditujukan untuk pengujian internal. Jika APK lama ditandatangani dengan kunci berbeda, Android tidak dapat memperbaruinya langsung. Jangan menghapus aplikasi lama sebelum memastikan data kunjungan yang diperlukan sudah disimpan.

Perintah build:

```sh
flutter build apk --release --no-pub --target-platform android-arm64 --build-number=4
```

Validasi: pemeriksaan kode maps/Photo Studio dan tes `test/museum_map_view_test.dart`, `test/photo_studio_test.dart`, serta `test/studio_gallery_test.dart`. Tes meliputi preview dengan kamera tiruan, jepret/edit/ekspor PNG, konfirmasi penyimpanan, serta izin ditolak. Kamera dan galeri perangkat fisik belum diuji langsung.
