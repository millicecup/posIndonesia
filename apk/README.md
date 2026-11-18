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
