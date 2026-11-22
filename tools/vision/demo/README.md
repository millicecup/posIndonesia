# JejakPos CV dari assets aplikasi

Mesin SIFT untuk backend pratinjau laptop dan pembuatan indeks Android. Sumber foto aktif langsung dari `assets/images/pois/`, Salinan folder ZIP lama sudah dihapus; versi lamanya tetap tersedia di Git history.

Semua 70 foto koleksi diindeks. Sebanyak 13 placeholder `pNN_1.png` dikecualikan. Label diambil dari data aplikasi `assets/data/pois.json`, dengan awalan pNN sebagai pemetaan tambahan. Gambar galeri, referensi ekspor dan pengujian memakai sumber assets yang sama.

Dari root repo:

```powershell
python -m pip install -r tools/vision/demo/requirements.txt
python tools/vision/demo/server.py
```

Demo teknis pada http://127.0.0.1:8765 menyediakan kamera, unggah gambar dan galeri untuk pengujian. Fitur **Kenali pada aplikasi lengkap** tetap kamera otomatis tanpa pilihan foto uji. Untuk aplikasi lengkap gunakan `python tools/vision/serve_local_app.py`, lalu buka http://127.0.0.1:8787/.

```powershell
python tools/vision/export_sift_android.py
python -m unittest discover -s tools/vision -p test_reference_assets.py
python tools/vision/demo/evaluate.py
```

Ekspor menghasilkan format JPSIFT02 lossless dan manifest sumber. Evaluasi memakai transformasi perspektif/pencahayaan dari referensi yang sama serta negatif sintetis; ini bukan akurasi kamera museum independen. Endpoint POST `/api/recognize` menerima byte JPEG/PNG, bukan multipart. Foto request tidak disimpan.

Panduan tim: `docs/PANDUAN_TAMBAH_REFERENSI_CV.md`. Setelah mengganti assets, ekspor indeks dan build APK baru; APK terpasang tidak mengambil referensi baru dari GitHub secara otomatis.
