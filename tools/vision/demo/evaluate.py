"""Synthetic robustness checks only; not an independent accuracy benchmark."""
import json
import cv2,numpy as np
from recognizer import Recognizer,ROOT,DEMO_ROOT,load,resize
model=Recognizer(); rows=[]
for ref in model.refs:
    im=resize(load(ROOT/ref['reference'])); h,w=im.shape[:2]
    src=np.float32([[0,0],[w-1,0],[w-1,h-1],[0,h-1]])
    dst=np.float32([[w*.07,h*.04],[w*.91,h*.08],[w*.96,h*.91],[w*.04,h*.96]])
    warped=cv2.warpPerspective(im,cv2.getPerspectiveTransform(src,dst),(w,h))
    warped=cv2.convertScaleAbs(warped,alpha=.8,beta=8)
    out=model.predict(warped); got=out['match']['poi_id'] if out['match'] else None
    rows.append(dict(reference=ref['reference'],expected=ref['poi_id'],predicted=got,passed=got==ref['poi_id'],elapsed_ms=out['elapsed_ms']))
    print(ref['reference'],got,flush=True)
rng=np.random.default_rng(42); negatives=[]
for name,im in [('blank',np.zeros((600,800,3),np.uint8)),('noise',rng.integers(0,256,(600,800,3),dtype=np.uint8)),('gradient',np.repeat(np.tile(np.arange(256,dtype=np.uint8),(600,4))[:,:800,None],3,axis=2))]:
    result=model.predict(im);negatives.append(dict(name=name,status=result['status'],passed=result['status']=='unknown'))
report=dict(kind='synthetic transforms of reference images, NOT held-out real camera accuracy',references=len(rows),passed=sum(r['passed'] for r in rows),negatives=negatives,results=rows)
(DEMO_ROOT/'evaluation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in report.items() if k!='results'},indent=2))
