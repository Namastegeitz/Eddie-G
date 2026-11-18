# HD backdrops

The six space scenes in `public/space/` are made from the originals in
`assets/original/space/` (1408x768) in two steps.

1. **Upscale 4x** with Real-ESRGAN x4plus (BSD-3-Clause, by Xintao Wang and others),
   run on the CPU through ONNX Runtime, so neither PyTorch nor a GPU is needed.

   ```bash
   pip install onnx onnxruntime numpy pillow
   curl -L -o RealESRGAN_x4plus.pth https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth
   python3 tools/hd/pth2onnx.py RealESRGAN_x4plus.pth x4plus.onnx
   for n in galaxy-spiral moon-planet nebula-pink pillars-green ringed-planet star-cluster; do
     python3 tools/hd/upscale.py x4plus.onnx assets/original/space/$n.webp masters/$n-4x.png
   done
   ```

   `pth2onnx.py` reads the checkpoint with a locked-down unpickler (only plain
   tensors are accepted). Each scene takes about 2.5 minutes on 4 CPU cores.
   The 5632x3072 masters are not kept in the repository.

2. **Cut** each master into the three files the game loads:

   ```bash
   python3 tools/hd/cut.py masters public/space 80
   ```

   | File | Size | Used for |
   |---|---|---|
   | `<name>.webp` | 2816x1536 | backdrops on desktops, tablets and phones held sideways |
   | `<name>.tall.webp` | 1728x2304 | backdrops on phones and tablets held upright, framed on the subject |
   | `<name>.card.webp` | 1500x500 | the campaign star chart's sector cards |

   `cut.py` blends 28% of the plainly enlarged original back in, because the
   upscaler smooths faint nebula texture and drops the dimmest stars. The
   subject of each scene (`FOCUS` in the script) keeps the tall and card cuts
   framed on the planet, galaxy or pillars.

`src/ui/background.js` picks the cut (`assetUrl(path, variant)`) and swaps it
when the device is turned.
