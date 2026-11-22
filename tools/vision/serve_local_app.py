"""Serve the complete Flutter app and its local CV backend on one origin."""
from pathlib import Path
import sys,os
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from threading import Lock
from urllib.parse import urlsplit,unquote
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/vision/demo'))
import server
from recognizer import Recognizer
class AppHandler(server.Handler):
    recognition_lock=Lock()
    def do_POST(self):
        with self.recognition_lock:
            return super().do_POST()
    def end_headers(self):
        self.send_header("Cache-Control","no-store")
        super().end_headers()
    def translate_path(self,path):
        clean=unquote(urlsplit(path).path)
        if clean.startswith('/assets/images/pois/'):
            base=ROOT/'assets/images/pois'
            clean=clean[len('/assets/images/pois'):]
        else:
            base=ROOT/'build/web'
            if clean.startswith('/app/'):
                clean=clean[4:]
        target=(base/clean.lstrip('/')).resolve()
        if not target.is_relative_to(base.resolve()):return str(base/'not-found')
        return str(target)
    def do_GET(self):
        path=unquote(urlsplit(self.path).path)
        if path == '/':
            body=(ROOT/'tools/vision/mobile_preview.html').read_bytes()
            self.send_response(200);self.send_header('Content-Type','text/html; charset=utf-8');self.send_header('Content-Length',str(len(body)));self.end_headers();self.wfile.write(body);return
        if path in ('/app/','/app/index.html'):
            body=(ROOT/'build/web/index.html').read_text(encoding='utf8').replace('<base href="/">','<base href="/app/">').encode()
            self.send_response(200);self.send_header('Content-Type','text/html; charset=utf-8');self.send_header('Content-Length',str(len(body)));self.end_headers();self.wfile.write(body);return
        if path.startswith('/api/'):return super().do_GET()
        return SimpleHTTPRequestHandler.do_GET(self)
if __name__=='__main__':
    print('Menyiapkan CV untuk aplikasi JejakPos...',flush=True)
    server.model=Recognizer()
    print('Aplikasi lengkap: http://127.0.0.1:8787',flush=True)
    ThreadingHTTPServer(('127.0.0.1',8787),AppHandler).serve_forever()
