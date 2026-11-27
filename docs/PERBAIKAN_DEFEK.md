# Perbaikan Defek & Retest (v3.8)

Sumber defek: `Rangkuman Defek dan Retest.pdf` (DF-01 s.d. DF-11).
Semua perbaikan diuji ulang otomatis di `test/defect_retest_test.dart`
(jalankan: `flutter test test/defect_retest_test.dart`).

## Tabel 2. Rencana Perbaikan (terisi)

| ID Defect | ID Perbaikan | Akar masalah | Solusi | Status |
|---|---|---|---|---|
| DF-01 | RP-01 | `TriggerEngine` hanya menulis log "Masuk area museum"; tidak ada event ke UI. GPS di dalam gedung juga terlalu kasar untuk memicu POI (radius 3 m). | Event baru `MuseumEvent` (masuk/keluar geofence 150 m, hysteresis 10 m). Saat pertama kali masuk dalam satu kunjungan muncul dialog **"Selamat datang di Museum Pos Indonesia!"** dengan pilihan *Mulai tur terpandu / Kenali pameran / Pindai QR koleksi / Nanti saja*, plus sambutan suara. Status "sudah disambut" disimpan per sesi (tidak muncul ulang saat app dibuka lagi, muncul lagi pada kunjungan baru). Bila masih di splash/onboarding, sambutan ditunda sampai keluar. | Selesai, lulus retest |
| DF-02 | RP-02 | Layar Kenali hanya menampilkan "Arahkan kamera..." terus-menerus saat objek bukan POI. | Hitung frame berturut-turut yang tidak dikenali (`visionNoMatchHintFrames` = 6, ±4–6 detik). Setelah itu panel berubah menjadi **"Koleksi ini belum dikenali"** + penjelasan bahwa objek kemungkinan bukan koleksi POI, tombol **Pindai QR**, **Daftar POI**, dan **Coba koleksi lain**. Reset otomatis saat POI mulai dikenali. | Selesai, lulus retest |
| DF-03 | RP-03 | Pemandu suara (TTS) hanya punya Ulangi & Stop. | Narasi dipecah per kalimat (`ResumableSpeechQueue`). Bar pemandu suara punya tombol **Jeda** dan **Lanjutkan**; lanjutkan memutar dari kalimat yang terpotong, bukan dari awal. Narasi "mendekati POI" tidak menimpa narasi yang sedang dijeda. | Selesai, lulus retest |
| DF-04 | RP-04 | Setelah izin ditolak, dialog izin membuat app "inactive"; error kamera dibuang karena generasi kamera berubah, sehingga layar tertahan di "Menyiapkan kamera...". | Izin kamera dicek dulu lewat `permission_handler` sebelum kamera dibuka. Bila ditolak: tampil **"Izin kamera dibutuhkan"** + tombol **Izinkan kamera** (minta ulang). Bila ditolak permanen: tombol **Buka Pengaturan**, lalu izin dicek ulang otomatis saat kembali ke aplikasi. Error `CameraAccessDenied` dari plugin juga diarahkan ke pesan yang sama. | Selesai, lulus retest |
| DF-05 | RP-05 | Hanya tanggal cap yang tersimpan; tidak ada ringkasan per kunjungan, dan riwayat baru tampil jika sudah ≥2 kunjungan. | Model `VisitRecord` disimpan permanen (SharedPreferences, JSON): tanggal, POI baru, prangko baru, kuis, foto, dan total. Riwayat tampil di **Ringkasan kunjungan** dan tab **Progres** sejak kunjungan pertama. Data cap versi lama tetap tampil; data rusak tidak membuat crash; "Hapus progres" ikut menghapus riwayat. | Selesai, lulus retest |
| DF-06 | RP-06 | Setelah prangko disimpan, detail POI dimuat ulang (spinner) sehingga `context` tombol pemanggil tidak aktif; `context.go()` dari dialog gagal di tekanan pertama. | Dialog prangko memakai `GoRouter` yang diambil saat dialog dibuka. `AsyncValueView` memakai `skipLoadingOnReload` sehingga layar tidak dibongkar saat data diperbarui. | Selesai, lulus retest |
| DF-07 | RP-07 | Rekomendasi tampil di 3 tempat dengan tampilan berbeda; pemandu hanya satu arah. | Satu komponen **"Saran pemandu"** (`GuideNextStopCard`) dari satu sumber data dipakai di Jelajah (menyatu dengan tombol tur), Pemandu tur, dan Progres. Detail POI punya tombol **Tanya pemandu**: chat dua arah dengan maskot (ceritakan singkat, fakta menarik, aktivitas, lokasi, ke mana setelah ini, bacakan). Jawaban diambil dari `pois.json`. | Selesai, lulus retest |
| DF-08 | RP-08 | `passport_postmark_card.dart` di branch `computer-vision` tidak bisa dikompilasi (kelas `_DashedRoundedRectPainter` tidak ada) dan `visit_summary_screen.dart` di branch itu kosong. | Kartu dipindah ke `lib/features/visit_summary/widgets/`, kelas yang hilang ditambahkan, tanggal cap contoh (14.08.2026 dst.) diganti tanggal kunjungan asli, dan kartu dipasang di Ringkasan kunjungan. Animasi stempel hanya diputar tepat setelah **Akhiri kunjungan**; nama penjelajah tersimpan. | Selesai, lulus retest |
| DF-09 | RP-09 | Layar QR menunggu tombol "Aktifkan kamera". | Kamera QR langsung aktif saat layar dibuka (sama seperti Kenali). Tombol tetap ada untuk mematikan. Pesan khusus bila izin kamera ditolak. | Selesai, lulus retest |
| DF-10 | RP-10 | Kanvas 3:4 memotong preview kamera 9:16 (`BoxFit.cover`) sehingga terlihat zoom. | Kanvas mengikuti rasio preview kamera (tidak ada pemotongan), zoom kamera diset ke minimum, dan ukuran awal topi/seragam sedikit diperkecil. | Selesai, lulus retest |
| DF-11 | RP-11 | Tombol "Petunjuk lain" berada di bawah pilihan tebakan. | Panel oranye tepat di bawah petunjuk: **"Masih ada N petunjuk lagi. Buka dulu sebelum menebak!"** + tombol **Petunjuk lain** yang menonjol. | Selesai, lulus retest |

## Skenario retest otomatis

`test/defect_retest_test.dart` (38 tes) mencakup, antara lain:

- DF-01: masuk/keluar/masuk ulang museum, kunjungan baru, sesi dipulihkan, GPS tidak akurat, serta **tes aplikasi utuh** (`JejakPosApp`) dari posisi bukti defek (82 m dari pusat) sampai dialog sambutan dan pindah ke layar QR.
- DF-02: objek bukan POI (unknown/ambiguous), ID tak terdaftar, reset saat POI dikenali, dan tombol di layar Kenali.
- DF-03: jeda di tengah kalimat lalu lanjut, stop, dan tombol di bar pemandu suara.
- DF-04: ditolak → diizinkan, ditolak permanen → Pengaturan → kembali, error plugin, izin sudah ada.
- DF-05: app ditutup & dibuka lagi (dua kunjungan), data lama, data rusak, hapus progres, tampilan Progres & Ringkasan.
- DF-06: ketiga tombol dialog prangko berpindah pada tekanan pertama.
- DF-07: chat pemandu di Detail POI dan saran yang sama di Pemandu tur & Progres.
- DF-08: animasi berjalan setelah Akhiri kunjungan, tanpa animasi dari riwayat, belum ada kunjungan.
- DF-09, DF-10, DF-11: kamera QR otomatis, rasio kanvas 9:16 & 3:4, posisi tombol petunjuk.
- Semua layar baru di lebar 320 & 412 px dengan skala huruf 1,0 dan 1,3 (tanpa overflow).

Hasil: `flutter test` 186 tes lulus; `flutter analyze` tanpa error (4 info gaya kode lama).

## Yang tetap perlu dicek di HP

Tes otomatis memakai kamera, GPS, dan TTS tiruan. Mohon retest manual di perangkat:
GPS palsu ke area museum (DF-01), kamera ke objek bukan POI (DF-02), suara TTS jeda/lanjut (DF-03),
tolak izin kamera di Photo Studio (DF-04), tutup paksa app setelah Akhiri kunjungan (DF-05),
dan rasio kamera depan di Photo Studio (DF-10).
