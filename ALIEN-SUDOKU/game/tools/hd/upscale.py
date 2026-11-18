"""4x upscale with the RRDBNet ONNX model, in overlapping tiles.
usage: upscale.py model.onnx in.(webp|png) out.png [--crop x,y,w,h] [--tile N]"""
import sys, time
import numpy as np
from PIL import Image
import onnxruntime as ort

model, src, dst = sys.argv[1:4]
args = sys.argv[4:]
tile, pad = 256, 16
crop = None
for i, a in enumerate(args):
    if a == '--crop': crop = tuple(int(v) for v in args[i + 1].split(','))
    if a == '--tile': tile = int(args[i + 1])
so = ort.SessionOptions(); so.intra_op_num_threads = 4
sess = ort.InferenceSession(model, so, providers=['CPUExecutionProvider'])
im = Image.open(src).convert('RGB')
if crop: im = im.crop((crop[0], crop[1], crop[0] + crop[2], crop[1] + crop[3]))
a = np.asarray(im, dtype=np.float32) / 255.0
H, W, _ = a.shape
# reflect-pad the whole picture so edge tiles have real context
ap = np.pad(a, ((pad, pad), (pad, pad), (0, 0)), mode='reflect')
out = np.zeros((H * 4, W * 4, 3), dtype=np.float32)
t0 = time.time(); n = 0
ys = list(range(0, H, tile)); xs = list(range(0, W, tile))
for y in ys:
    for x in xs:
        h = min(tile, H - y); w = min(tile, W - x)
        t = ap[y: y + h + 2 * pad, x: x + w + 2 * pad]
        r = sess.run(None, {'input': t.transpose(2, 0, 1)[None]})[0][0].transpose(1, 2, 0)
        out[y * 4: (y + h) * 4, x * 4: (x + w) * 4] = r[pad * 4: (pad + h) * 4, pad * 4: (pad + w) * 4]
        n += 1
        print(f'{src.split("/")[-1]} tile {n}/{len(ys) * len(xs)} {time.time() - t0:.0f}s', flush=True)
Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)).save(dst)
print('done', dst, out.shape, f'{time.time() - t0:.0f}s')
