# Asumsi dan Hal yang Belum Pasti (ditelaah terhadap PRD)

Sumber: `PRD_JejakPOS_Kelompok8_Lengkap (1).pdf` (baseline Week 9, Approved by PMO).

**Pembaruan:** `PRD_JejakPOS_Kelompok8_Lengkap (2).pdf` (disebut **PRD v2**). Dibanding v1, hanya ada dua perubahan: (1) Tabel 4 berisi **11 POI dengan nomor baru**, dan (2) radius di tabel state 5.2 dan **PB08 berubah dari 10 m ke 5 m**. Bagian lain tidak berubah. Dampaknya dicatat sebagai tambahan pada A3, A4, A7, A10, dan A18, serta pada butir baru A23–A25. Nomor POI pada butir lama (A1–A22) masih memakai **penomoran PRD v1** kecuali disebut lain.

Arti status:
- ✅ **Terjawab PRD**: kode sudah mengikuti PRD.
- 🟡 **Sebagian**: PRD memberi arah, tetapi detailnya belum ada.
- ❌ **Belum dijawab PRD**: masih asumsi tim.
- ⚠️ **Tidak konsisten di dalam PRD**: perlu keputusan tim dan dicatat di Change Log PRD (Bagian 10).

## 1. Ringkasan

| # | Hal | Status |
|---|---|---|
| A1 | Konten sejarah tiap POI | 🟡 |
| A2 | Konten P10 Mas Soeharto | 🟡 |
| A3 | Radius trigger 5 m vs 10 m | ⚠️ |
| A4 | Radius approaching, hysteresis, debounce | 🟡 |
| A5 | Koordinat GPS POI | 🟡 |
| A6 | Geofence area museum | ❌ |
| A7 | Denah museum dan posisi POI di denah | 🟡 |
| A8 | Izin foto, logo, perangko, seragam, Mars Pos | 🟡 |
| A9 | Zona P04 dan P11 | ✅ |
| A10 | Penomoran layar UI | ✅ |
| A11 | Definisi PB01–PB05 | ✅ |
| A12 | Kapan POI dianggap dikunjungi | ✅ |
| A13 | Kapan perangko didapat | ⚠️ |
| A14 | Makna "sekali per sesi" | ✅ |
| A15 | Teknologi identifikasi POI (BLE vs computer vision) | ⚠️ |
| A16 | Format beacon dan ambang RSSI | 🟡 |
| A17 | Isi QR dan format ID POI | 🟡 |
| A18 | Aturan rekomendasi POI berikutnya | 🟡 |
| A19 | Notifikasi saat trigger | 🟡 |
| A20 | Library audio | 🟡 |
| A21 | Nama paket Android dan versi package | ❌ |
| A22 | Penyajian audio dan foto POI lewat internet | ❌ |
| A23 | Penomoran ulang POI di PRD v2 | ✅ |
| A24 | Nomor POI di teks PRD v2 yang belum ikut diperbarui | ⚠️ |
| A25 | POI yang tidak ada lagi di Tabel 4 PRD v2 | 🟡 |

## 2. Rincian

### A1. Konten sejarah tiap POI: 🟡
- **PRD:** Tabel 4 memberi nama, kategori, zona, jenis content, dan system response per POI. Isi sejarahnya belum ada. Validasi konten adalah PB06 (Sprint 2), dan R2 mewajibkan validasi sumber dengan pihak museum.
- **Di kode:** nama, kategori, zona, `contentTypes`, `systemResponse`, dan `activities` di `pois.json` kini **disalin dari Tabel 4**. Deskripsi dan fakta tetap bertanda `[PERLU VALIDASI MUSEUM]`, dengan `contentValidated: false`.
- **Satu-satunya isi yang diambil dari PRD:** nama 5 tahap P07 (desain, persiapan cetak, pencetakan, perforasi, hasil akhir) dari A04. Penjelasan tiap tahap masih placeholder.
- **Tindak lanjut:** PB06, tabel sumber 10 POI (Sprint 2).
- **Pembaruan (konten PB06):** konten **P01–P09** kini diisi dari `Dokumen Sprint 2.pdf`, **tab revisi** (hal. 25–41), dengan nomor PRD v2: ringkasan, 3–5 fakta, cerita lengkap per bagian (`sections`), dan 40 foto (`assets/images/pois/pXX_NN.jpg`). Field `contentValidated: true` dan `contentSource` diisi. Catatan draf penulis ("(nanti aku tambahin)" di P06) tidak disalin.
- **Belum ada:** **P10 Mars Pos**: kolom teks di dokumen ternyata salinan teks Brievenbus (salah tempel), jadi hanya fotonya yang dipakai dan teks tetap placeholder; rekaman Mars hanya berupa link YouTube (perlu izin, R3). **P11 Stempel Museum**: tidak ada barisnya di tab revisi. **Audio narasi** semua POI masih nada placeholder. **Gambar perangko** (`stamp_pXX.png`) masih placeholder.

### A2. Konten P10 Mas Soeharto: 🟡
- **PRD:** R2 dan A05 menyatakan isi petunjuk *hanya* memakai informasi yang telah diverifikasi museum. Wireframe UI18 memuat contoh petunjuk dengan catatan "Teks akhir akan divalidasi dari sumber museum".
- **Di kode:** tidak ada fakta tentang tokoh ini. Contoh petunjuk dari wireframe sengaja **tidak** dimasukkan ke dataset karena belum divalidasi.
- **Pembaruan (konten PB06):** biografi Mas Soeharto (P08 di PRD v2) dan tiga pertanyaan Mystery Clue diambil dari Dokumen Sprint 2 tab revisi. Petunjuk "Siapa aku?" disusun dari kalimat biografi tersebut. Pilihan jawaban yang salah (pengecoh) dibuat tim aplikasi dan bukan klaim sejarah.

### A3. Radius trigger 5 m vs 10 m: ⚠️
- **PRD:** Tabel 4 menulis "Masuk radius 5 m" untuk semua POI. Sebaliknya, wireframe UI06 ("radius trigger 10 m"), tabel state 5.2 ("Masuk radius 10 m, sinyal stabil"), dan **acceptance criteria PB08** ("POI muncul sekali saat masuk radius 10 m") memakai 10 m.
- **Di kode:** 10 m, karena itulah angka yang akan diuji (PB08). Field `radiusNeedsConfirmation: true` tetap dipasang.
- **Tindak lanjut:** catat di **Change Log PRD Bagian 10** ("Tabel 4 radius 5 m → 10 m, menyesuaikan PB08"), atau ubah PB08 jika tim memilih 5 m. Nilainya cukup diubah di `pois.json`.
- **Pembaruan PRD v2:** arah ketidakkonsistenan berbalik. Tabel 4, tabel state 5.2 (state 3 "Masuk radius 5 m"), dan **PB08** (Bagian 6 dan Sprint 2) kini memakai **5 m**. Hanya wireframe UI06 dan teks state 2 ("radius trigger 10 m") yang masih 10 m.
- **Keputusan tim (sesudah PRD v2):** kode **tetap 10 m** sampai hasil PoC PB05 tersedia. Akibatnya, acceptance PB08 v2 ("masuk radius 5 m") belum terpenuhi oleh konfigurasi saat ini. Jika hasil PoC mendukung 5 m, ubah `triggerRadiusMeters` di `pois.json` dan ekspektasi `triggerRadiusMeters, 10` di `test/data/poi_parsing_test.dart`. Jika tetap 10 m, ajukan entri Change Log (lihat bagian 3).

### A4. Radius approaching, hysteresis, debounce: 🟡
- **PRD:** state 2 "mulai mendekati POI (± 15 m)" → **15 m terjawab**. Untuk kestabilan, PRD hanya menyebut "sinyal stabil" (state 3) dan "ambang sinyal awal dan interval stabil tercatat" (PB05), tanpa angka.
- **Di kode:** approaching 15 m. Hysteresis +3 m, debounce 2 pembacaan, dan batas akurasi 50 m masih asumsi.
- **Tindak lanjut:** angka final diambil dari hasil PoC PB05 (Firda), lalu diisikan ke `AppConfig`.
- **Pembaruan PRD v2:** state 2 kini berbunyi "Mulai mendekati POI (± 5 m)", padahal state 3 (trigger) juga 5 m, sehingga radius mendekati = radius trigger. Ini kemungkinan salah ketik, karena wireframe UI06 masih menampilkan "Mendekati … ≈ 15 m". **Di kode tetap 15 m.**

### A5. Koordinat GPS POI: 🟡
- **PRD:** R5 menyatakan koordinat belum tersedia, sehingga zona dipakai sebagai lokasi POI dan survei dilakukan di Sprint 1. Bagian 4.2 menegaskan GPS **bukan** acuan utama untuk membedakan koleksi di dalam ruangan.
- **Di kode:** koordinat tetap PLACEHOLDER (`coordinatesArePlaceholder: true`). Koordinat kini **diturunkan dari posisi denah** (skala fiktif 200 m × 160 m di sekitar -6.90245, 107.61975), sehingga simulasi GPS di emulator bergerak sesuai denah. Jarak antar-POI selalu > 20 m dan diuji di `poi_parsing_test.dart`.
- **Tindak lanjut:** survei lokasi (R5). Di museum asli, identifikasi POI memakai beacon, computer vision, atau QR (lihat A15), bukan jarak GPS.

### A6. Geofence area museum: ❌
- **PRD:** GPS menentukan "apakah pengguna berada di sekitar museum" (4.2 langkah 1), tanpa titik pusat atau radius.
- **Di kode:** pusat placeholder dan radius 150 m di `AppConfig`.

### A7. Denah museum dan posisi POI: 🟡
- **PRD:** wireframe UI05–UI07 (Gambar 5.2/5.3) memuat denah **ilustratif, belum berskala**:
  - Ruang 4: P10, P04
  - Ruang 2: P03, P06, P08
  - Lorong: P05, P13
  - Ruang 3: P07, P09
  - Ruang Awal / Pintu Masuk: P01, P02, P11, P12
- **Di kode:** `mapPosition` semua POI dan gambar `assets/map/museum_floor_plan.png` kini mengikuti tata letak tersebut.
- **Tindak lanjut:** ganti dengan denah resmi museum setelah tersedia (R5).
- **Pembaruan PRD v2:** posisi fisik tiap koleksi tidak berubah, hanya nomornya. Dengan nomor PRD v2:
  - Ruang 4: P08 (Mas Soeharto), P03 (Kepemimpinan)
  - Ruang 2: P12* (Peralatan Pos), P04 (Seragam), P06 (Kode Pos)
  - Lorong: P10 (Mars Pos), P13* (Pos Kereta Api)
  - Ruang 3: P05 (Pembuatan Prangko), P07 (Lemari Geser)
  - Ruang Awal / Pintu Masuk: P01, P02, P09 (Kotak Pos), P11 (Stempel)
  - (*) kandidat tambahan, lihat A25. Wireframe denah di PRD v2 masih memakai nomor v1.

### A8. Izin foto, logo, desain perangko, seragam, Mars Pos: 🟡
- **PRD:** R3 meminta izin tertulis atau konfirmasi (PB06) dan menyiapkan alternatif teks dan ilustrasi buatan sendiri.
- **Di kode:** semua gambar adalah placeholder buatan sendiri, dan audio berupa nada 2 detik. Rekaman Mars Pos Indonesia asli tidak dimasukkan sebelum ada izin.
- **Pembaruan:** tim sudah mendapat izin untuk rekaman Mars Pos Indonesia. Audionya diambil dari link di Dokumen Sprint 2 (youtu.be/bOx76_GP0PY) dan disimpan sebagai `assets/audio/p10_mars_pos_indonesia.mp3` (3:00). Simpan bukti izinnya untuk lampiran laporan.

### A9. Zona P04 dan P11: ✅
- **PRD Tabel 4:** P04 "Zona P04 - area tangan pimpinan", P11 "Zona P11 - area kotak pos". Pada denah wireframe, P04 berada di Ruang 4 dan P11 di Ruang Awal.
- **Di kode:** deskripsi zona sudah diperbarui. Penempatan ruangnya ditandai "pada denah ilustratif".

### A10. Penomoran layar UI: ✅
**PRD 5.1:** UI01–UI23. Sprint 1 (PB04) mencakup UI01–UI12. Tebakan saya sebelumnya **salah**, dan rute sudah diperbaiki:

| UI | PRD | Rute di kode |
|---|---|---|
| UI05/UI06 | Explore Map state 1 (di luar area) / state 2 (mendekati) | `/map` (satu layar, dua state) |
| UI07 | Navigasi ke POI | `/navigate/:poiId` |
| UI08 | POI Trigger Notification (state 3) | `/trigger/:poiId` dengan tombol Lihat Info / Dengarkan / Nanti |
| UI14 | Album Perangko Digital | tab Album `/album` |
| UI21 | Progres & Rekomendasi | tab Progres `/progress`, dengan tombol "Akhiri kunjungan" |
| UI13, UI15–UI20, UI22, UI23 | Perangko terbuka, Photo Studio, kuis, dll. | Sprint 2–4, belum dibuat |

**Pembaruan PRD v2:** label POI di wireframe (Gambar 5.2–5.7) belum diperbarui dan masih memakai nomor v1. Contohnya: UI07 "Menuju P06" untuk seragam (kini P04), UI09 "P08 · Kode pos" (kini P06), UI11 "POI P05 · Mars Pos" (kini P10), dan UI18 "POI P10" untuk Mas Soeharto (kini P08). Saat mencocokkan layar dengan wireframe, gunakan tabel di A23.

### A11. Definisi PB01–PB05: ✅
**PRD Bagian 6 dan Sprint Plan Week 10:**

| PB | Isi |
|---|---|
| PB01 | Project Android + APK debug berjalan di **perangkat uji** tanpa crash (commit + rekaman layar) |
| PB02 | Layar izin lokasi berfungsi dan status deteksi terbaca (log + rekaman layar) |
| PB03 | JSON dataset 10 POI (ID, nama, kategori, zona, ID beacon/QR) terbaca aplikasi (tangkapan layar daftar POI) |
| PB04 | Prototipe UI01–UI12 bisa diklik end-to-end, minimal alur onboarding → peta → trigger → detail POI (rekaman layar) |
| PB05 | PoC beacon dan QR **di area uji**; ambang sinyal awal dan interval stabil tercatat (log uji + **foto lokasi**) |

Catatan: PB05 tidak bisa diselesaikan hanya dengan emulator. Panel simulasi berguna untuk pengembangan, tetapi evidence PB05 harus berasal dari HP fisik di area uji.

### A12. Kapan POI dianggap dikunjungi: ✅
- **PRD 4.2:** setelah POI dikenali dan belum dipicu, konten ditampilkan, lalu "sistem kemudian memperbarui progress eksplorasi".
- **Di kode:** POI ditandai dikunjungi saat terpicu (GPS, beacon, atau QR). Membuka detail juga menandainya, untuk pengunjung yang memilih POI secara manual (PRD 4.2 langkah 1: "opsi pengenalan manual").

### A13. Kapan perangko didapat: ⚠️
- **PRD:** ada dua versi.
  - Skenario 2.1: perangko "secara otomatis tersimpan" setelah mengeksplorasi informasi.
  - F08, PB13, state 4, dan wireframe UI10: perangko diperoleh **setelah aktivitas POI selesai**, lewat tombol **"Selesai & ambil perangko"**, lalu muncul popup UI13.
- **Di kode:** mengikuti F08 dan wireframe, dengan tombol "Selesai & ambil perangko" di UI10. Tombol itu menyimpan perangko ke album otomatis, tanpa duplikasi. Popup UI13 dikerjakan di PB13 (Sprint 3).
- **Tindak lanjut:** tetapkan "aktivitas selesai" per POI. Contohnya: audio didengar sampai selesai, kuis dijawab, atau cukup membuka detail.

### A14. Makna "sekali per sesi": ✅
- **PRD:** "belum dipicu pada **sesi kunjungan** tersebut" (4.2), "muncul sekali per kunjungan" (UI08), dan sesi diakhiri lewat **"Akhiri kunjungan"** (UI21) yang menuju ringkasan (UI22).
- **Di kode (diperbarui):** daftar POI yang sudah terpicu kini **disimpan** di shared_preferences. Jika aplikasi ditutup lalu dibuka lagi di tengah kunjungan, POI yang sama tidak terpicu ulang. Sesi direset hanya lewat tombol **Akhiri kunjungan** di tab Progres. Progres dan perangko tetap tersimpan.

### A15. Teknologi identifikasi POI (BLE vs computer vision): ⚠️
- **PRD:** tidak konsisten.
  - Bagian 4.2 dan Tabel 8.1 menyebut **kamera + computer vision (Google ML Kit)** dengan QR sebagai alternatif.
  - Diagram 2.2 ("beacon / QR"), UI02 ("Bluetooth & Lokasi"), UI05 ("Memindai beacon..."), UI12 ("Beacon tidak terdeteksi"), R1, **PB05**, dan **PB08** menyebut **BLE beacon** dengan QR sebagai fallback.
- **Di kode:** `BeaconScanner` (BLE, simulasi di emulator) dan QR fallback sudah ada, karena backlog yang akan diuji memakai BLE. Computer vision belum dibuat. Bentuknya bisa berupa scanner lain yang memanggil `TriggerEngine.reportIdentification(poi, source)`.
- **Tindak lanjut:** putuskan setelah PoC PB05 dan catat di Change Log. Jika PoC BLE gagal, PRD (R1 dan Blocker Plan) sudah menetapkan QR sebagai jalur utama sementara.

### A16. Format beacon dan ambang RSSI: 🟡
- **PRD:** dataset harus memuat "ID beacon/QR" (PB03), dan beacon harus "terpetakan ke POI" dengan "ambang sinyal awal tercatat" (PB05). Format dan angkanya tidak ditentukan. R1 juga mencatat izin pemasangan beacon oleh museum.
- **Di kode:** id logis `BCN-Pxx` dan ambang -75 dBm (belum dikalibrasi).
- **Tindak lanjut:** pemetaan UUID/major-minor dan RSSI dari PoC Firda; izin pemasangan dari museum.

### A17. Isi QR dan format ID POI: 🟡
- **PRD:** QR membuka POI yang benar (PB08). Format isi QR tidak ditentukan. Bagian 4.2 memakai contoh ID "POI-01", sedangkan Tabel 4 memakai "P01".
- **Di kode:** ID `P01`, mengikuti Tabel 4. Isi QR `QR-P01`, atau URL yang mengandung `QR-P01`.

### A18. Aturan rekomendasi POI berikutnya: 🟡
- **PRD:** F07 hanya mensyaratkan "rekomendasi koleksi berikutnya yang relevan". Contoh wireframe: di P06 direkomendasikan P08 (UI09); setelah P01, P02, P03, P05, P06 direkomendasikan P08 lalu P09 (UI21). Rute tematik ada di A07 (Could).
- **Di kode:** dipilih POI belum dikunjungi yang terdekat di denah dari POI terakhir. Dengan denah wireframe, aturan ini menghasilkan **P08 setelah P06**, sama dengan contoh UI21.
- **Tindak lanjut:** jika A07 dikerjakan, rekomendasi mengikuti urutan rute tematik.
- **Pembaruan PRD v2:** karena posisi denah tidak berubah, aturan yang sama kini menghasilkan **P06 (Kode Pos) setelah P04 (Seragam)**, setara dengan contoh wireframe P08 setelah P06 dalam nomor v1.

### A19. Notifikasi saat trigger: 🟡
- **PRD:** UI08 menampilkan banner bergaya notifikasi ("Jejak Pos — Kamu berada di zona P06") plus lembar tawaran. UI02 meminta izin notifikasi "saat mendekati POI".
- **Di kode:** SnackBar di dalam aplikasi ("Kamu berada di zona Pxx") lalu layar UI08. Notifikasi sistem Android (misalnya `flutter_local_notifications`) belum dibuat.
- **Tindak lanjut:** tentukan apakah notifikasi sistem diperlukan saat aplikasi berjalan di background (Sprint 2, PB08).

### A20. Library audio: 🟡
- **PRD Tabel 8.1:** "Android Media3/audioplayers".
- **Di kode:** `just_audio`, yang di Android memakai ExoPlayer (Media3). Library ini dipilih karena stream posisi, durasi, dan status lebih lengkap untuk play/pause/lanjut/seek (F04). Jika tim ingin mengikuti PRD persis, cukup ganti implementasi `AudioService`; UI tidak perlu berubah.

### A21. Nama paket Android dan versi package: ❌
- Tidak dibahas di PRD. Nama paket `id.jejakpos.jejakpos` (dari `flutter create --org id.jejakpos`).
- Versi package di `pubspec.yaml` adalah versi stabil yang dikenal saat fondasi dibuat. Jangan menjalankan `flutter pub upgrade --major-versions` tanpa mengujinya dulu.

### A22. Penyajian audio dan foto POI lewat internet: ❌
- **PRD:** Tabel 8.1 hanya menyebut "JSON lokal" untuk data. NG05 mengecualikan sinkronisasi perangko lintas perangkat, bukan penyajian media.
- **Di kode:** audio dan foto POI dicari di APK, lalu di cache HP, lalu diunduh dari Firebase Hosting. `pois.json`, denah, perangko, dan onboarding tetap di APK. Firebase Storage tidak dipakai karena mewajibkan paket berbayar Blaze.
- **Tindak lanjut:** aktifkan setelah Project ID tersedia, lihat [MEDIA_HOSTING.md](MEDIA_HOSTING.md). Kuota transfer gratis sekitar 10 GB per bulan cukup untuk demo, bukan untuk operasional museum harian. Izin penggunaan foto dan audio (R3, PB06) perlu ada sebelum diunggah karena file di Hosting bersifat publik.

### A23. Penomoran ulang POI di PRD v2: ✅
- **PRD v2 Tabel 4** memberi nomor baru P01–P11. Seluruh kode (`pois.json`, nama file aset, test, GPX, rute) kini mengikuti nomor ini.
- **Di kode:** tiap POI menyimpan nomor lamanya di field `prdV1Id` (hanya di JSON, untuk penelusuran). Beacon, QR, dan perangko ikut nomor baru (`BCN-P10`, `QR-P10`, `STP-P10`). Nama file aset juga diganti, misalnya `p05_mars_pos_indonesia.wav` → `p10_mars_pos_indonesia.wav`.

| PRD v2 | Nama | PRD v1 |
|---|---|---|
| P01 | Sejarah Komunikasi Tertulis di Nusantara | P01 |
| P02 | Sejarah Pos Indonesia | P02 |
| P03 | Sejarah Kepemimpinan Pos Indonesia | P04 |
| P04 | Sejarah Seragam Petugas Pos | P06 |
| P05 | Proses Pembuatan Prangko | P07 |
| P06 | Kode Pos di Indonesia | P08 |
| P07 | Koleksi Prangko Lemari Geser | P09 |
| P08 | Tokoh Mas Soeharto | P10 |
| P09 | Koleksi Kotak Pos | P11 |
| P10 | Mars Pos Indonesia | P05 |
| P11 | Stempel Museum | P12 |
| P12 (kandidat) | Koleksi Peralatan Pos | P03 |
| P13 (kandidat) | Tempat Pos Kereta Api | P13 |

- **Catatan untuk tim:** progres dan perangko yang sudah tersimpan di HP/emulator (shared_preferences) masih memakai ID lama. Hapus data aplikasi atau tekan **Akhiri kunjungan** sebelum menguji.

### A24. Nomor POI di teks PRD v2 yang belum ikut diperbarui: ⚠️
- **Kode zona di Tabel 4:** P07 ditulis "Zona P08", P08 "Zona P09", P09 "Zona P10", dan P10 "Zona P07". Di kode, `zone.code` disamakan dengan id POI, sedangkan teks asli PRD disimpan di `zone.prdV2ZoneText`.
- **A04** masih menulis "(POI P07)" untuk pembuatan perangko (kini P05). **A05** menulis "(POI P10)" dan **R2** menulis "konten P10" untuk Mas Soeharto (kini P08).
- **Wireframe:** lihat catatan PRD v2 di A10.
- **Tindak lanjut:** perbaiki di PRD berikutnya dan catat di Change Log (lihat bagian 3).

### A25. POI yang tidak ada lagi di Tabel 4 PRD v2: 🟡
- **PRD v2:** *Koleksi Peralatan Pos* (v1 P03) dan *Tempat Pos Kereta Api* (v1 P13) tidak lagi tercantum. NG08 masih menyebut "13 kandidat POI" dan "tiga POI tambahan … apabila konten dan waktu memungkinkan", dan G08 mensyaratkan minimal 10 POI.
- **Di kode:** keduanya **tidak dihapus**. Mereka disimpan sebagai **P12** dan **P13** dengan `"baseline": false` (`Poi.isBaseline`), dan deskripsinya diberi awalan `[KANDIDAT TAMBAHAN]`. `validateDataset()` memeriksa minimal 10 POI **baseline** dan memberi peringatan untuk kandidat. Aplikasi masih menampilkan ke-13 POI.
- **Belum dijawab PRD:** apakah kandidat tetap tampil di aplikasi, dan apakah kuis (UI17) dan Jejak Misi (UI20) yang di wireframe memakai Koleksi Peralatan Pos dipindah ke POI lain.
- **Tindak lanjut:** tim memutuskan apakah P12/P13 disembunyikan dari UI (cukup filter `isBaseline`) atau dikembalikan ke Tabel 4.
- **Keputusan tim (sesudah PRD v2):** P12 dan P13 **tidak ditampilkan** dan disimpan sebagai backlog. `PoiRepositoryImpl` (default `includeBacklog: false`) hanya mengembalikan POI baseline, sehingga P12/P13 tidak muncul di daftar, peta, album, maupun progres (total 11), dan tidak bisa terpicu lewat GPS, beacon, atau QR. Datanya tetap ada di `pois.json` dan tetap divalidasi. Untuk memunculkannya lagi, set `"baseline": true` atau `includeBacklog: true`.

## 3. Usulan entri Change Log PRD (Bagian 10)

| Version | Requirement / Backlog | Change | Reason |
|---|---|---|---|
| 1.1 | Tabel 4 (Trigger Rule) | Radius 5 m → 10 m | Konsisten dengan PB08, UI06, dan tabel state 5.2 |
| 1.1 | 4.2 / Tabel 8.1 | Identifikasi POI: BLE beacon (utama) + QR (fallback); computer vision opsional | Konsisten dengan PB05, PB08, R1, dan wireframe. Final setelah hasil PoC PB05. |
| 1.1 | Tabel 8.1 | Audio dan foto POI disajikan lewat Firebase Hosting dengan cache lokal; data POI tetap JSON lokal | Mengurangi ukuran APK saat konten asli masuk |
| 1.1 | 2.1 Skenario | Perangko diperoleh lewat "Selesai & ambil perangko" setelah aktivitas POI | Konsisten dengan F08, PB13, dan UI10/UI13 |

Usulan tambahan setelah PRD v2:

| Version | Requirement / Backlog | Change | Reason |
|---|---|---|---|
| 1.2 | Tabel 4 | 13 POI → 11 POI baseline, nomor baru P01–P11 | Sudah ada di PRD v2, tetapi belum tercatat di Change Log Bagian 10 |
| 1.2 | PB08, tabel state 5.2 | Radius trigger 10 m → 5 m | Sudah ada di PRD v2, tetapi belum tercatat. Kode masih 10 m sampai PoC PB05 (A3) |
| 1.2 | Tabel 4, A04, A05, R2, wireframe | Samakan nomor POI dengan Tabel 4 baru (zona P07–P10; A04 → P05; A05/R2 → P08) | Nomor lama masih tertinggal (A24) |
| 1.2 | 5.2 state 2 | "± 5 m" → "± 15 m" | Radius mendekati harus lebih besar dari radius trigger; sesuai wireframe UI06 (A4) |
| 1.2 | NG08 / Tabel 4 | Tetapkan status Koleksi Peralatan Pos dan Pos Kereta Api sebagai kandidat tambahan | Tidak ada lagi di Tabel 4 tetapi NG08 masih menyebut 13 kandidat (A25) |
