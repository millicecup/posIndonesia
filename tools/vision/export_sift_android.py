"""Export SIFT from application assets. Integer descriptors are stored losslessly."""
import sys,struct,json,os
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/vision/demo'))
from recognizer import Recognizer

def export():
    model=Recognizer()
    output=ROOT/'android/app/src/main/assets/jejakpos_sift/index.bin'
    output.parent.mkdir(parents=True,exist_ok=True)
    temporary=output.with_suffix('.bin.tmp')
    try:
        with temporary.open('wb') as f:
            f.write(b'JPSIFT02'); f.write(struct.pack('>i',len(model.refs)))
            for ref in model.refs:
                des=ref['des'];packed=des.astype(np.uint8)
                if not np.array_equal(packed.astype(np.float32),des):
                    raise ValueError('Descriptor cannot be stored losslessly: '+ref['reference'])
                identifier=ref['app_poi_id'].encode('utf8')
                f.write(struct.pack('>H',len(identifier)));f.write(identifier)
                h,w=ref['size'];pts=ref['points']
                f.write(struct.pack('>iii',w,h,len(pts)))
                f.write(pts.astype('>f4').tobytes());f.write(packed.tobytes())
        summary=dict(format='JPSIFT02',descriptorEncoding='uint8-lossless-to-float32',
            sourceDirectory='assets/images/pois',references=len(model.refs),
            poiIds=sorted(set(r['app_poi_id'] for r in model.refs)),
            excluded=model.excluded,sources=model.catalog())
        manifest=output.parent/'manifest.json'
        temp_manifest=manifest.with_suffix('.json.tmp')
        temp_manifest.write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf8')
        os.replace(temporary,output);os.replace(temp_manifest,manifest)
    finally:
        if temporary.exists():temporary.unlink()
    print(f'Exported {len(model.refs)} asset photos; {len(model.excluded)} exclusions; {output.stat().st_size} bytes',flush=True)
if __name__=='__main__':export()
