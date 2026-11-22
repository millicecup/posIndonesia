# JejakPOS: Museum POS Indonesia

Aplikasi Flutter pendamping Museum POS Indonesia. Branch `computer-vision` berisi integrasi fitur Kenali melalui kamera Android, QR P01–P11, dan aplikasi lengkap.

## Mulai dari sini

- [APK dan riwayat build](apk/README.md): unduh APK CV terbaru; APK versi sebelumnya tetap disimpan di folder `apk/` sebagai riwayat build.
- [Cara kerja CV, pengujian, dan build](docs/COMPUTER_VISION.md).
- [Panduan menambah foto referensi dan membangun ulang APK](docs/PANDUAN_TAMBAH_REFERENSI_CV.md).

## Menjalankan aplikasi

```powershell
git clone --branch computer-vision https://github.com/millicecup/posIndonesia.git
cd posIndonesia
flutter pub get
flutter run
```

Gunakan JDK 21 untuk build Android. Konfigurasi build APK CV selengkapnya ada di panduan di atas. APK demo masih memakai debug signing key.

## Sumber foto dan pengenalan

Foto referensi berasal dari `assets/images/pois/`. Saat ini 70 foto koleksi masuk indeks, sementara 13 placeholder dikecualikan. Pemetaan POI memakai `assets/data/pois.json` dan awalan nama berkas pNN. Setelah menambah foto, ekspor ulang indeks dan bangun APK baru.

Android memakai SIFT dan verifikasi geometri OpenCV secara offline. MobileNetV3 masih tersedia untuk jalur fallback non-Android; bukan mesin utama Kenali Android. Hasil uji transformasi sintetis bukan ukuran akurasi kamera di museum; pengujian langsung tetap diperlukan.

## Peta folder

| Folder | Isi |
|---|---|
| `lib/` | Antarmuka Flutter, fitur, dan layanan aplikasi |
| `assets/images/pois/` | Foto koleksi dan referensi CV |
| `assets/data/` | Metadata POI dan konten aplikasi |
| `android/` | Integrasi Android, mesin SIFT, dan indeks native |
| `tools/vision/` | Ekspor indeks, pengujian, dan pratinjau laptop |
| `test/` | Pengujian Flutter |
| `docs/` | Panduan CV serta dokumen arsitektur dan proyek |
| `apk/` | APK terbaru, checksum, dan riwayat APK sebelumnya |

Dokumen sprint dan PRD lama tetap tersedia sebagai konteks proyek; panduan CV di atas menjadi titik awal untuk branch ini. Salinan dataset ZIP lama di tools sudah dihapus karena sumber aktif berada di assets. Git history menyimpan versi sebelumnya.

## Tim

| Nama | Peran |
|---|---|
| Matilda | Backend & Data |
| Farella | Frontend & PM |
| Denaya | Frontend: POI List / Explorer |
| Belinda | Frontend: POI Detail & Audio |
| Firda | Frontend & Location |
