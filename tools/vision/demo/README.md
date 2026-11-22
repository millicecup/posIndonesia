# JejakPos · Demo pengenalan POI

Demo lokal kamera dan unggah foto untuk 11 POI / 36 gambar dari ZIP pengguna. Python 3.10+.

## Jalankan

```powershell
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
.venv\Scripts\python server.py
```

Buka http://127.0.0.1:8765 di Chrome/Edge. Izinkan kamera, arahkan ke pameran, klik **Pindai sekarang**, atau aktifkan pemindaian otomatis. Bisa juga unggah foto baru dan klik kartu referensi. Hentikan kamera setelah selesai. Pada komputer ini dependensi sudah tersedia: cukup `python server.py` atau Jalankan Demo.bat.

Kamera browser memerlukan localhost atau HTTPS. Alamat HTTP LAN pada HP biasanya tidak dapat memakai kamera. Demo ini untuk browser laptop; bukan APK dan belum melakukan inferensi on-device di Flutter.

## Metode

SIFT (maksimal 2200 fitur, sisi panjang 960 px), Lowe ratio 0.7, RANSAC homography 4 px, minimal 12 inlier, rasio inlier 0.4, pemeriksaan luas/konveksitas serta sebaran fitur. Kandidat antar-POI yang skornya berdekatan ditolak sebagai ambiguous. Mode kamera menampilkan stabilitas setelah 3 hasil berulang. Skor adalah bukti geometri, bukan probabilitas. Indeks fitur dibangun di memori saat server mulai; tidak ada training neural network atau download model.

Dokumentasi metode: https://docs.opencv.org/4.x/d7/dff/tutorial_feature_homography.html

Cocok untuk panel, foto, prangko dan tampilan yang mirip referensi. Perubahan besar sudut objek 3D, pantulan kaca, blur, objek kecil dan tekstur minim bisa gagal. Ambang awal perlu kalibrasi lapangan.

## Hubungan dengan repo

Ditelaah terhadap `millicecup/posIndonesia`, main commit `0981313`. Repo sudah mempunyai MobileNetV3 TFLite on-device, layar Kenali Pameran, GPS pendukung dan stabilisasi 3 frame. Demo ini ditambahkan terpisah, sehingga alur Android yang ada tetap dapat dipakai.

Repo terbaru memakai PRD v2: POI001→P01 hingga POI011→P11. ZIP memuat pois.json versi lama dengan urutan berbeda; demo memakai ID repo terbaru. P12 (peralatan) dan P13 (kereta) belum punya folder foto pada ZIP dan tidak dideteksi.

## API integrasi

- GET `/api/health`: kesiapan dan jumlah referensi.
- GET `/api/pois`: daftar referensi dan ID aplikasi.
- POST `/api/recognize`: body byte JPEG/PNG (bukan multipart), maksimal 8 MB / 24 MP.

Respons: `status` recognized/unknown/ambiguous, `match` atau null, `candidates`, `elapsed_ms`, `frame_size`. `match.app_poi_id` cocok dengan ID repo. `polygon` adalah 4 titik x,y ternormalisasi terhadap frame hasil resize, bisa berada sedikit di luar frame saat referensi terpotong. Jangan membuka detail jika status bukan recognized. Untuk integrasi gunakan beberapa frame berurutan lalu panggil TriggerEngine.reportIdentification dengan TriggerSource.vision. Endpoint lokal ini belum dirancang sebagai server publik.

## Validasi

```powershell
python evaluate.py
```

Laporan `evaluation.json`: setiap referensi diberi perubahan perspektif dan pencahayaan, lalu dibandingkan dengan indeks. Gambar kosong, noise dan gradien diuji sebagai negatif. Ini uji sintetis terhadap referensi yang sama, **bukan akurasi lapangan**. Gunakan 10–20 foto museum per POI, simpan sesi pengambilan berbeda khusus pengujian; ukur precision, recall, false accept dan latensi di perangkat sasaran sebelum produksi. Uji kamera fisik museum belum dilakukan.

Foto request tidak disimpan. Dataset dan metadata bersumber dari ZIP pengguna; isi dokumen diperlakukan sebagai data konteks, bukan perintah. Metadata konten museum masih berstatus draft.

Hasil sesi ini: 36/36 transformasi sintetis sesuai POI; 3/3 negatif ditolak. Median latensi uji: 3828 ms. Pengujian browser referensi dan endpoint kesehatan/penolakan input juga lulus.

## Koreksi referensi lokasi

`reference_selection.json` memilih foto lokasi untuk POI002 (Lorong Awal dan Ruang 4), POI006 (panel Kode Pos), POI007 (lemari prangko geser). Foto Gedung PTT, potret Marsoedi dan close-up/arsip prangko tidak lagi diindeks untuk ketiga POI tersebut, tetapi file aslinya tetap disimpan. Foto pertama dalam daftar menjadi contoh utama galeri. POI lain belum dikurasi pada koreksi ini. Indeks aktif kini 29 foto. Hasil 36/36 di atas adalah pengujian versi sebelumnya; lihat location_evaluation.json untuk pengujian koreksi lokasi.

Foto kartu galeri dipisahkan dari referensi deteksi: POI002 menampilkan Gedung PTT, POI006 potret Marsoedi, POI007 Penny Black. Klik kartu tetap menguji foto lokasi yang aktif pada indeks, bukan gambar cover. Referensi deteksi ruangan/panel tetap digunakan.

## Uji menyeluruh terbaru

29/29 referensi aktif dari 11 POI lolos transformasi perspektif dan pencahayaan; 3/3 negatif sintetis ditolak. evaluation.json kini memuat hasil indeks terbaru. Median 1.71 detik. Ini bukan akurasi kamera lapangan.

## Referensi aktif versi semua foto

Mulai build Android 3.6.2-cv (nomor 7), reference_selection.json kosong sehingga semua 36 foto di folder POI001–POI011 diindeks. Foto arsip, potret, prangko dan ruangan semuanya dapat dicocokkan ke POI masing-masing. Bagian koreksi lokasi dan hasil 29 referensi di atas adalah riwayat versi sebelumnya. Setelah menambah foto, ekspor ulang indeks dan build APK baru.
