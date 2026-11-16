# JejakPOS — perbaikan peta dan Photo Studio

`JejakPOS-maps-arm64.apk` adalah build release untuk perangkat Android ARM64.

Perubahan:
- Denah menyesuaikan ukuran layar ketika peta dibuka.
- Zoom dibatasi hingga empat kali ukuran tampilan awal.
- Tombol perbesar, perkecil, dan tampilkan seluruh denah tersedia pada peta dan petunjuk arah.
- Rotasi serta zoom melalui ketukan ganda dinonaktifkan.
- Photo Studio langsung dibuka tanpa syarat lokasi atau pindai QR.
- Foto diambil dari kamera depan; tidak ada pilihan impor dari galeri.
- Seragam dan topi dipasangkan menurut warna Coklat Tua, Hijau, dan Khaki, memakai enam PNG asli dari `POI004/images/Photo Studio ...` di branch `content/poi-dataset`.
- Penanganan izin kamera, pemulihan foto setelah aplikasi ditutup Android, dan pembuatan hasil foto diperbaiki.

Build menggunakan konfigurasi penandatanganan debug yang saat ini dipakai project, sehingga ditujukan untuk pengujian internal. Jika APK lama ditandatangani dengan kunci berbeda, Android tidak dapat memperbaruinya langsung. Jangan menghapus aplikasi lama sebelum memastikan data kunjungan yang diperlukan sudah disimpan.

Perintah build:

```sh
flutter build apk --release --no-pub --target-platform android-arm64 --build-number=2
```

Validasi: pemeriksaan kode maps/Photo Studio dan tes `test/museum_map_view_test.dart` serta `test/photo_studio_test.dart`. Kamera perangkat fisik belum diuji langsung.
