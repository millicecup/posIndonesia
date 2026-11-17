"""Bangun indeks pengenalan pameran (computer vision) untuk JejakPOS.

Setiap foto referensi diubah menjadi embedding 1024 dimensi oleh model
assets/models/mobilenet_v3_small_embedder.tflite, lalu disimpan (int8) di
assets/models/poi_vision_index.json. Aplikasi membandingkan embedding frame
kamera dengan indeks ini (cosine similarity) untuk menebak POI yang dilihat.

Sumber foto referensi:
  1. assets/images/pois/pNN_XX.jpg  (foto konten; placeholder pNN_1.png dilewati)
  2. tools/vision/references/PNN/*.jpg|png  (foto pameran yang diambil tim
     langsung di museum dari sudut pandang pengunjung - INI YANG PALING PENTING
     untuk akurasi; tidak ikut dibundel ke APK, hanya embedding-nya)

Pemakaian (sekali saja):
  python -m venv .venv-vision
  .venv-vision/Scripts/python -m pip install ai-edge-litert pillow numpy
  .venv-vision/Scripts/python tools/vision/build_vision_index.py

Jalankan dari root repo. Pra-proses harus sama dengan lib/services/vision/frame_converter.dart:
potong persegi di tengah -> 224x224 bilinear -> RGB float 0..1.
"""

from __future__ import annotations

import base64
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps
from ai_edge_litert.interpreter import Interpreter

ROOT = Path(__file__).resolve().parents[2]
MODEL = ROOT / "assets/models/mobilenet_v3_small_embedder.tflite"
OUT = ROOT / "assets/models/poi_vision_index.json"
CONTENT_DIR = ROOT / "assets/images/pois"
EXTRA_DIR = ROOT / "tools/vision/references"
SIZE = 224

CONTENT_RE = re.compile(r"^p(\d{2})_(\d+)\.(jpg|jpeg|png)$", re.I)
PLACEHOLDER_RE = re.compile(r"^p\d{2}_1\.png$", re.I)


def center_square(img: Image.Image, keep: float = 1.0) -> Image.Image:
    w, h = img.size
    side = min(w, h) * keep
    left, top = (w - side) / 2, (h - side) / 2
    return img.crop((round(left), round(top), round(left + side), round(top + side)))


def views(img: Image.Image) -> list[Image.Image]:
    """Variasi sudut pandang: utuh, persegi tengah, dan zoom 70%."""
    return [img, center_square(img), center_square(img, 0.7)]


class Embedder:
    def __init__(self) -> None:
        self.it = Interpreter(model_path=str(MODEL))
        self.it.allocate_tensors()
        self.inp = self.it.get_input_details()[0]["index"]
        self.out = self.it.get_output_details()[0]["index"]

    def __call__(self, img: Image.Image) -> np.ndarray:
        arr = np.asarray(img.convert("RGB").resize((SIZE, SIZE), Image.BILINEAR), dtype=np.float32) / 255.0
        self.it.set_tensor(self.inp, arr[None])
        self.it.invoke()
        v = self.it.get_tensor(self.out)[0].astype(np.float32)
        return v / (np.linalg.norm(v) + 1e-12)


def collect() -> list[tuple[str, Path]]:
    refs: list[tuple[str, Path]] = []
    for f in sorted(CONTENT_DIR.iterdir()):
        m = CONTENT_RE.match(f.name)
        if m and not PLACEHOLDER_RE.match(f.name):
            refs.append((f"P{m.group(1)}", f))
    if EXTRA_DIR.exists():
        for d in sorted(p for p in EXTRA_DIR.iterdir() if p.is_dir()):
            for f in sorted(d.iterdir()):
                if f.suffix.lower() in {".jpg", ".jpeg", ".png"}:
                    refs.append((d.name.upper(), f))
    return refs


def quantize(v: np.ndarray) -> tuple[str, float]:
    scale = float(np.abs(v).max()) / 127.0 or 1.0
    q = np.clip(np.round(v / scale), -127, 127).astype(np.int8)
    return base64.b64encode(q.tobytes()).decode("ascii"), scale


def main() -> int:
    embed = Embedder()
    refs = collect()
    entries = []
    per_image: list[tuple[str, int, np.ndarray]] = []
    for idx, (poi_id, path) in enumerate(refs):
        img = ImageOps.exif_transpose(Image.open(path))
        for v in views(img):
            e = embed(v)
            q, s = quantize(e)
            entries.append({"poiId": poi_id, "source": path.relative_to(ROOT).as_posix(), "q": q, "s": round(s, 8)})
            per_image.append((poi_id, idx, e))

    # Evaluasi kasar: tiap foto (zoom 70%) dicocokkan ke foto LAIN (leave-one-image-out).
    mat = np.stack([e for _, _, e in per_image])
    correct = total = 0
    for poi_id, idx, e in per_image[2::3]:
        sims = mat @ e
        mask = np.array([i != idx for _, i, _ in per_image])
        best = int(np.argmax(np.where(mask, sims, -2)))
        total += 1
        correct += per_image[best][0] == poi_id

    OUT.write_text(json.dumps({
        "model": MODEL.name,
        "dimension": int(mat.shape[1]),
        "inputSize": SIZE,
        "preprocess": "center-square crop, bilinear 224x224, RGB float 0..1",
        "imageCount": len(refs),
        "leaveOneOutTop1": round(correct / max(total, 1), 3),
        "entries": entries,
    }, separators=(",", ":")), encoding="utf-8")
    pois = sorted({p for p, _ in refs})
    print(f"{len(refs)} foto, {len(entries)} embedding, POI: {', '.join(pois)}")
    print(f"Akurasi leave-one-out (foto lain): {correct}/{total} = {correct / max(total, 1):.0%}")
    print(f"Ditulis: {OUT.relative_to(ROOT)} ({OUT.stat().st_size / 1024:.0f} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
