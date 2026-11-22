from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlsplit,unquote
import argparse,json,os
import cv2,numpy as np
from recognizer import Recognizer,ROOT,DEMO_ROOT
class Handler(SimpleHTTPRequestHandler):
    def translate_path(self,path):
        clean=unquote(urlsplit(path).path)
        base=DEMO_ROOT
        if clean.startswith('/assets/images/pois/'):
            base=ROOT/'assets/images/pois'
            clean=clean[len('/assets/images/pois'):]
        target=(base/clean.lstrip('/')).resolve()
        return str(target) if target.is_relative_to(base.resolve()) else str(base/'not-found')
    def reply(self,status,data):
        body=json.dumps(data,ensure_ascii=False).encode(); self.send_response(status); self.send_header('Content-Type','application/json; charset=utf-8'); self.send_header('Content-Length',str(len(body))); self.send_header('Cache-Control','no-store'); self.end_headers(); self.wfile.write(body)
    def do_GET(self):
        path=unquote(urlsplit(self.path).path)
        if path=='/api/pois': return self.reply(200,model.catalog())
        if path=='/api/health': return self.reply(200,dict(ready=True,references=len(model.refs),pois=len(set(r['poi_id'] for r in model.refs))))
        if path=='/': self.path='/web/index.html'
        elif not (path.startswith('/web/') or path.startswith('/assets/images/pois/')) or '..' in path.split('/'): return self.reply(404,dict(error='Not found'))
        super().do_GET()
    def do_POST(self):
        if self.path!='/api/recognize': return self.reply(404,dict(error='Not found'))
        try:
            size=int(self.headers.get('Content-Length','0'))
            if not 0<size<=8*1024*1024: return self.reply(413,dict(error='Maksimal 8 MB'))
            raw=self.rfile.read(size)
            # Check compressed image dimensions before allocating decoded pixels.
            from PIL import Image
            import io
            with Image.open(io.BytesIO(raw)) as probe:
                if probe.width*probe.height>24000000: return self.reply(413,dict(error='Maksimal 24 megapiksel'))
            image=cv2.imdecode(np.frombuffer(raw,np.uint8),cv2.IMREAD_COLOR)
            if image is None: raise ValueError('Gambar tidak valid')
            return self.reply(200,model.predict(image))
        except Exception as error: return self.reply(400,dict(error=str(error)))
if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--host',default='127.0.0.1'); parser.add_argument('--port',default=8765,type=int); args=parser.parse_args()
    print('Menyiapkan referensi SIFT...',flush=True); model=Recognizer(); os.chdir(ROOT)
    print(f'JejakPos siap: http://{args.host}:{args.port} ({len(model.refs)} referensi)',flush=True)
    HTTPServer((args.host,args.port),Handler).serve_forever()
