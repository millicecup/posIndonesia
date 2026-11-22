# Peralatan computer vision JejakPOS

Mesin utama Kenali Android adalah SIFT dengan verifikasi geometri OpenCV. Foto referensi berasal dari `assets/images/pois/`, dengan pemetaan POI dari metadata aplikasi dan awalan pNN. Placeholder tidak diindeks.

## Panduan utama

- [Cara kerja dan konfigurasi CV](../../docs/COMPUTER_VISION.md)
- [Menambah foto, ekspor indeks, dan build APK](../../docs/PANDUAN_TAMBAH_REFERENSI_CV.md)

Jalankan dari root repository:

```powershell
python -m pip install -r tools/vision/demo/requirements.txt
python tools/vision/export_sift_android.py
python -m unittest discover -s tools/vision -p test_reference_assets.py
python tools/vision/demo/evaluate.py
```

## Berkas yang dipakai

| Berkas | Kegunaan |
|---|---|
| `export_sift_android.py` | Mengekspor indeks SIFT native Android |
| `test_reference_assets.py` | Memeriksa sumber foto, label, placeholder, dan indeks |
| `demo/recognizer.py` | Pengenalan SIFT Python dan pemetaan referensi assets |
| `demo/evaluate.py` | Uji transformasi seluruh referensi dan gambar negatif |
| `demo/evaluation.json` | Hasil evaluasi sintetis terakhir |
| `demo/server.py` | API pengenalan untuk pratinjau browser |
| `serve_local_app.py` | Menyajikan hasil build Flutter web untuk pratinjau aplikasi |
| `mobile_preview.html` | Bingkai tampilan ponsel untuk pratinjau laptop |
| `demo/web/` | Demo teknis kamera, unggah gambar, dan galeri |
| `build_vision_index.py` | Builder embedding MobileNetV3 untuk fallback non-Android |

Evaluasi sintetis memakai turunan foto referensi, sehingga tidak menggantikan uji kamera langsung di museum. Demo laptop membutuhkan server Python; APK Android mengenali secara offline melalui mesin native.

Untuk detail demo teknis, lihat [demo/README.md](demo/README.md). APK dan riwayat build ada di [apk/](../../apk/README.md).
