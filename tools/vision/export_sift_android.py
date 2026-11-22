"""Export exact desktop SIFT features into an Android-readable, big-endian index."""
import sys,struct,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/vision/demo'))
from recognizer import Recognizer
model=Recognizer()
output=ROOT/'android/app/src/main/assets/jejakpos_sift/index.bin'
output.parent.mkdir(parents=True,exist_ok=True)
with output.open('wb') as f:
    f.write(b'JPSIFT01'); f.write(struct.pack('>i',len(model.refs)))
    for ref in model.refs:
        identifier=ref['app_poi_id'].encode('utf8'); f.write(struct.pack('>H',len(identifier))); f.write(identifier)
        h,w=ref['size']; pts=ref['points']; des=ref['des']
        if des is None: raise ValueError('No descriptor: '+ref['reference'])
        f.write(struct.pack('>iii',w,h,len(pts)))
        f.write(pts.astype('>f4').tobytes()); f.write(des.astype('>f4').tobytes())
summary={'format':'JPSIFT01','references':len(model.refs),'poiIds':sorted(set(x['app_poi_id'] for x in model.refs)),'sources':model.catalog()}
(output.parent/'manifest.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf8')
print(f'Exported {len(model.refs)} reference images; {output.stat().st_size} bytes',flush=True)
