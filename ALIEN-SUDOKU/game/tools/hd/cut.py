"""Cut each 4x-upscaled space scene into the three backdrops the game uses.

usage: python3 tools/hd/cut.py <dir with <name>-4x.png masters> <out dir = public/space> [quality]
  (the original photos are read from assets/original/space)

  <name>.webp       wide  2816x1536  desktops, tablets, phones held sideways
  <name>.tall.webp  tall  1728x2304  phones and tablets held upright (3:4, framed on the subject)
  <name>.card.webp  card  1500x500   campaign sector cards (subject placed right of center)
  <name>.sd.webp       1408x768   Low graphics level, wide
  <name>.tall-sd.webp  864x1152   Low graphics level, tall

FOCUS is where each scene's subject sits in the frame (0..1 from the left / top),
so the tall and card cuts keep the planet, galaxy or pillars in view."""
import sys, os
from PIL import Image, ImageFilter

FOCUS = {
    'galaxy-spiral': (0.50, 0.42),
    'moon-planet': (0.56, 0.50),
    'nebula-pink': (0.50, 0.45),
    'pillars-green': (0.49, 0.50),
    'ringed-planet': (0.56, 0.52),
    'star-cluster': (0.62, 0.50),
}
ORIGINALS = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'original', 'space')
# The upscaler sharpens edges and stars but smooths faint texture and drops the dimmest
# stars. Blending this much of the plainly enlarged original back in keeps both.
DETAIL = 0.28
src, out = sys.argv[1], sys.argv[2]
q = int(sys.argv[3]) if len(sys.argv) > 3 else 80
os.makedirs(out, exist_ok=True)

def crop_around(im, cw, ch, fx, fy, at=(0.5, 0.5)):
    """Crop cw x ch so the focus point lands at `at` inside the crop, clamped to the image."""
    W, H = im.size
    x0 = round(fx * W - at[0] * cw); y0 = round(fy * H - at[1] * ch)
    x0 = max(0, min(W - cw, x0)); y0 = max(0, min(H - ch, y0))
    return im.crop((x0, y0, x0 + cw, y0 + ch))

def finish(im, size):
    im = im.resize(size, Image.LANCZOS)
    # a light unsharp pass after the downscale keeps star points crisp
    return im.filter(ImageFilter.UnsharpMask(radius=0.8, percent=40, threshold=2))

def save(im, path):
    im.save(path, 'WEBP', quality=q, method=6)
    print(f'{os.path.basename(path):28s} {im.size[0]}x{im.size[1]}  {os.path.getsize(path) // 1024} KB')

for name, (fx, fy) in FOCUS.items():
    master = os.path.join(src, f'{name}-4x.png')
    if not os.path.exists(master):
        print(f'{name}: no master yet, skipped'); continue
    m = Image.open(master).convert('RGB')
    W, H = m.size
    plain = Image.open(os.path.join(ORIGINALS, f'{name}.webp')).convert('RGB').resize((W, H), Image.LANCZOS)
    m = Image.blend(m, plain, DETAIL)
    save(finish(m, (2816, 1536)), os.path.join(out, f'{name}.webp'))
    tall = crop_around(m, round(H * 3 / 4), H, fx, fy)
    save(finish(tall, (1728, 2304)), os.path.join(out, f'{name}.tall.webp'))
    cw = round(W * 0.78); card = crop_around(m, cw, round(cw / 3), fx, fy, at=(0.66, 0.5))
    save(finish(card, (1500, 500)), os.path.join(out, f'{name}.card.webp'))
    save(finish(m, (1408, 768)), os.path.join(out, f'{name}.sd.webp'))
    save(finish(tall, (864, 1152)), os.path.join(out, f'{name}.tall-sd.webp'))
