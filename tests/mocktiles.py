# Mock XYZ map tiles + Terrarium elevation tiles with CORS, for the offline acceptance test.
# Usage: python3 tests/mocktiles.py 8790   (needs Pillow)
import io, sys, re
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from PIL import Image, ImageDraw
HITS = {'n': 0}
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        dm = re.match(r'^/dem/(\d+)/(\d+)/(\d+)\.png$', self.path)
        if dm:
            import math
            z, x, y = map(int, dm.groups()); n = 2 ** z
            im = Image.new('RGB', (256, 256)); px = im.load()
            for j in range(256):
                lat = math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * (y + (j + .5) / 256) / n))))
                for i in range(256):
                    lon = (x + (i + .5) / 256) / n * 360 - 180
                    e = 300 + 250 * math.sin(lat * 60) * math.cos(lon * 45) + (lat - 40) * 400
                    v = e + 32768
                    px[i, j] = (int(v // 256), int(v) % 256, int((v - int(v)) * 256))
            buf = io.BytesIO(); im.save(buf, 'PNG'); b = buf.getvalue()
            self.send_response(200); self.send_header('Content-Type', 'image/png'); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers(); self.wfile.write(b); return
        m = re.match(r'^/(\d+)/(\d+)/(\d+)\.png$', self.path)
        if self.path == '/hits':
            b = str(HITS['n']).encode(); self.send_response(200); self.send_header('Content-Type','text/plain'); self.send_header('Access-Control-Allow-Origin','*'); self.end_headers(); self.wfile.write(b); return
        if not m: self.send_response(404); self.end_headers(); return
        HITS['n'] += 1
        z, x, y = map(int, m.groups())
        im = Image.new('RGB', (256, 256), ((x * 40) % 200 + 40, (y * 70) % 200 + 40, (z * 50) % 200 + 40))
        d = ImageDraw.Draw(im); d.rectangle([0, 0, 255, 255], outline=(0, 0, 0)); d.text((10, 10), '%d/%d/%d' % (z, x, y), fill=(255, 255, 255))
        buf = io.BytesIO(); im.save(buf, 'PNG'); b = buf.getvalue()
        self.send_response(200); self.send_header('Content-Type', 'image/png'); self.send_header('Content-Length', str(len(b)))
        self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers(); self.wfile.write(b)
ThreadingHTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
