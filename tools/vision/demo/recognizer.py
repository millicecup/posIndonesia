"""Reference-image recognition. Scores are geometric evidence, not probabilities."""
from pathlib import Path
import json, time
import cv2
import numpy as np
DEMO_ROOT = Path(__file__).resolve().parent
ROOT = DEMO_ROOT.parents[2]

def collect_asset_references(root=ROOT):
    """Use current POI metadata, then the pNN filename for additional asset photos."""
    import re
    root = Path(root)
    asset_dir = root / 'assets/images/pois'
    dataset = json.loads((root / 'assets/data/pois.json').read_text(encoding='utf8'))
    pois = {p['id']: p for p in dataset['pois'] if p.get('baseline', True)}
    owners = {}
    for poi in pois.values():
        paths = list(poi.get('images', []))
        paths += [path for section in poi.get('sections', []) for path in section.get('images', [])]
        for path in paths:
            if not path.startswith('assets/images/pois/'):
                continue
            if not (root / path).is_file():
                raise ValueError(f'Asset koleksi tidak ditemukan: {path}')
            if path in owners and owners[path] != poi['id']:
                raise ValueError(f'Asset dipakai oleh lebih dari satu POI: {path}')
            owners[path] = poi['id']
    references, excluded = [], []
    for path in sorted(asset_dir.iterdir()):
        if path.suffix.lower() not in ('.jpg', '.jpeg', '.png'):
            continue
        relative = path.relative_to(root).as_posix()
        if re.fullmatch(r'p\d{2}_1\.png', path.name, re.I):
            excluded.append({'reference': relative, 'reason': 'placeholder'})
            continue
        match = re.match(r'p(\d{2})_', path.name, re.I)
        poi_id = owners.get(relative) or (f'P{match.group(1)}' if match else None)
        if poi_id is None:
            raise ValueError(f'Asset belum memiliki ID POI: {relative}')
        if poi_id not in pois:
            excluded.append({'reference': relative, 'reason': 'inactive_poi'})
            continue
        poi = pois[poi_id]
        references.append(dict(poi_id=f"POI{int(poi_id[1:]):03d}",
            app_poi_id=poi_id, name=poi['name'], reference=relative))
    references.sort(key=lambda r: (r['app_poi_id'],
        r['reference'] != (pois[r['app_poi_id']].get('images') or [None])[0], r['reference']))
    return references, excluded

def resize(image):
    h,w=image.shape[:2]
    return cv2.resize(image,(round(w*min(1,960/max(h,w))),round(h*min(1,960/max(h,w)))))
def load(path):
    return cv2.imdecode(np.fromfile(str(path),np.uint8),cv2.IMREAD_COLOR)
class Recognizer:
    def __init__(self):
        self.sift=cv2.SIFT_create(nfeatures=2200)
        self.refs=[]
        catalog, self.excluded = collect_asset_references()
        for ref in catalog:
            path = ROOT / ref['reference']
            im = load(path)
            if im is None:
                raise ValueError(f'Gambar rusak: {path}')
            im = resize(im)
            kp, des = self.sift.detectAndCompute(cv2.cvtColor(im, cv2.COLOR_BGR2GRAY), None)
            if des is None or len(kp) < 12:
                raise ValueError(f'Foto kurang dari 12 fitur SIFT: {path}')
            self.refs.append(dict(ref, size=im.shape[:2],
                points=np.float32([k.pt for k in kp]), des=des))
    def catalog(self):
        return [{k:v for k,v in r.items() if k not in ('points','des','size')} for r in self.refs]
    def predict(self,image):
        start=time.perf_counter(); image=resize(image); h,w=image.shape[:2]
        kp,des=self.sift.detectAndCompute(cv2.cvtColor(image,cv2.COLOR_BGR2GRAY),None)
        candidates=[]
        if des is not None and len(des)>=12:
            points=np.float32([k.pt for k in kp])
            matcher=cv2.FlannBasedMatcher(dict(algorithm=1,trees=4),dict(checks=64))
            for ref in self.refs:
                if ref['des'] is None or len(ref['des'])<12: continue
                pairs=matcher.knnMatch(ref['des'],des,k=2)
                good=[p[0] for p in pairs if len(p)==2 and p[0].distance<0.7*p[1].distance]
                # A query feature may support only one reference keypoint.
                good=list({m.trainIdx:m for m in sorted(good,key=lambda m:m.distance,reverse=True)}.values())
                if len(good)<12: continue
                src=np.float32([ref['points'][m.queryIdx] for m in good]); dst=np.float32([points[m.trainIdx] for m in good])
                H,mask=cv2.findHomography(src,dst,cv2.RANSAC,4.0)
                if H is None or mask is None: continue
                inside=mask.ravel().astype(bool); n=int(inside.sum()); ratio=n/len(good)
                if n<12 or ratio<0.4: continue
                rh,rw=ref['size']; corners=np.float32([[0,0],[rw,0],[rw,rh],[0,rh]]).reshape(-1,1,2)
                quad=cv2.perspectiveTransform(corners,H).reshape(4,2)
                if not np.isfinite(quad).all() or not cv2.isContourConvex(quad.astype(np.float32)): continue
                area=abs(cv2.contourArea(quad)); coverage=abs(cv2.contourArea(cv2.convexHull(src[inside])))/(rw*rh)
                if area<0.008*w*h or area>2*w*h or coverage<0.015: continue
                if (quad[:,0]<-w).any() or (quad[:,0]>2*w).any() or (quad[:,1]<-h).any() or (quad[:,1]>2*h).any(): continue
                candidates.append(dict(poi_id=ref['poi_id'],app_poi_id=ref['app_poi_id'],name=ref['name'],reference=ref['reference'],inliers=n,inlier_ratio=round(ratio,3),score=round(n*ratio,2),polygon=(quad/np.float32([w,h])).tolist()))
        candidates.sort(key=lambda x:x['score'],reverse=True)
        best=candidates[0] if candidates else None
        rival=next((c for c in candidates if best and c['poi_id']!=best['poi_id']),None)
        ambiguous=bool(best and rival and rival['score']>=best['score']*0.8)
        return dict(status='ambiguous' if ambiguous else 'recognized' if best else 'unknown',match=None if ambiguous else best,candidates=candidates[:3],elapsed_ms=round((time.perf_counter()-start)*1000),frame_size=[w,h])
