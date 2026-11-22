# JejakPOS computer vision semua foto

Unduh [JejakPOS-computer-vision-arm64.apk](JejakPOS-computer-vision-arm64.apk). Versi **3.6.2-cv**, nomor build **7**, ARM64. Seluruh **36 foto** pada folder POI001–POI011 diaktifkan sebagai referensi, termasuk foto arsip, potret, prangko dan ruangan. QR P01–P11 dan desain terbaru tetap tergabung.

Tanda tangan sama dengan APK CV versi sebelumnya (nomor 6), sehingga dapat memperbarui pemasangan versi CV tersebut. Kuncinya tetap berbeda dari APK v3.6 asli. Jangan menghapus data kunjungan untuk memaksa pembaruan.

36/36 referensi lolos uji sintetis perspektif/pencahayaan; 3 negatif sintetis ditolak. Kamera museum belum diuji langsung. APK ini untuk uji internal, shrinking dimatikan dan lint vital dilewati pada build distribusi uji.

Ukuran 97762074 byte. SHA-256: `fb658c52913580a8a9c086186cbbf0ec3dac85c575cb8097bbd4f38db910f71c`.

Lihat [panduan CV](../docs/COMPUTER_VISION.md) dan [panduan menambah referensi](../docs/PANDUAN_TAMBAH_REFERENSI_CV.md).

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
