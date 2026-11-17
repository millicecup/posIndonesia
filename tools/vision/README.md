# Kenali Pameran (computer vision)

Saat tur, POI dikenali dari **kamera**, bukan dari GPS. GPS di dalam gedung
meleset 5–20 m, sedangkan jarak antar-POI hanya 1–10 m (lihat `Koordinat POI.pdf`).

## Cara kerja

1. Kamera mengambil frame setiap 0,5 detik. Area yang dianalisis adalah bingkai persegi di tengah.
2. Model on-device `assets/models/mobilenet_v3_small_embedder.tflite` (MobileNetV3,
   MediaPipe Image Embedder, ±4 MB, tanpa internet) mengubah frame menjadi vektor 1024 angka.
3. Vektor itu dibandingkan dengan foto referensi tiap POI di `assets/models/poi_vision_index.json`.
4. **Penggabungan dengan koordinat:** POI yang jauh dari posisi GPS (lebih dari akurasi + 8 m)
   mendapat penalti skor, maksimal 0,15. GPS hanya membantu memecah keraguan dan tidak
   pernah mencoret POI, karena GPS di dalam gedung bisa meleset.
5. POI dikonfirmasi kalau menang **3 frame berturut-turut** dengan skor ≥ 0,5 dan
   selisih ≥ 0,05 dari POI kedua. Setelah itu POI dicatat lewat `TriggerEngine` dengan sumber `vision`,
   UI08 terbuka, dan pemandu suara berjalan.

Semua ambang ada di `lib/core/config/app_config.dart` (`vision*`).

GPS asli sekarang hanya **memicu** POI kalau akurasinya ≤ 5 m (`gpsTriggerMaxAccuracyMeters`).
Kalau akurasinya lebih buruk, GPS hanya memberi status "mendekati".

## Menambah foto referensi (PENTING untuk akurasi)

Indeks awal dibangun dari foto konten di `assets/images/pois/` (akurasi leave-one-out 87%).
Sebagian foto itu berupa arsip atau close-up, bukan pameran seperti yang dilihat pengunjung. Supaya
akurasi di museum tinggi:

1. Ambil **10–20 foto per POI** langsung di museum dengan HP: dari jarak dan sudut pengunjung
   (depan, kiri, kanan, dekat, jauh), dengan cahaya museum yang sebenarnya.
2. Simpan di `tools/vision/references/P01/`, `.../P02/`, dan seterusnya (jpg/png). Folder ini tidak masuk APK.
3. Bangun ulang indeks:

```bash
python -m venv .venv-vision
.venv-vision/Scripts/python -m pip install ai-edge-litert pillow numpy
.venv-vision/Scripts/python tools/vision/build_vision_index.py
```

4. Commit `assets/models/poi_vision_index.json` yang baru, lalu build ulang APK.

Di mode debug, panel bawah layar "Kenali Pameran" menampilkan skor 2 POI teratas.
Pakai panel ini untuk menyetel `visionMinSimilarity` / `visionMinMargin` saat uji coba di museum.
