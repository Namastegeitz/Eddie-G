// Draws the iOS and Android app icons and splash screens from
// assets/icons/icon.svg, at every size the two projects use.
//   node scripts/make_app_icons.js        (after `npx cap add` in mobile/)
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const svg = fs.readFileSync(path.join(root, 'assets/icons/icon.svg'), 'utf8');
const BG = '#0e3527';
const font = fs.readFileSync(path.join(root, 'assets/fonts/lilita-one.woff2')).toString('base64');
const res = path.join(root, 'mobile/android/app/src/main/res');
const ios = path.join(root, 'mobile/ios/App/App/Assets.xcassets');

// full-bleed square (iOS masks it; no transparency allowed)
const full = svg.replace('rx="112"', 'rx="0"');
// just the monkey (no background square) for adaptive icons and splash screens
const face = svg.replace(/<rect width="512" height="512" rx="112" fill="#0e3527"\/>/, '');

function page(inner, size, bg, extra = '') {
  return `<html><head><style>@font-face{font-family:L;src:url(data:font/woff2;base64,${font})}
  html,body{margin:0;width:${size[0]}px;height:${size[1]}px;background:${bg};overflow:hidden}
  .c{width:100%;height:100%;display:flex;flex-direction:column;align-items:center;justify-content:center}
  </style></head><body><div class="c">${inner}${extra}</div></body></html>`;
}
const sized = (s, px) => s.replace('<svg ', `<svg width="${px}" height="${px}" `);

(async () => {
  const browser = await chromium.launch();
  const pg = await browser.newPage();
  const shot = async (file, w, h, html, transparent) => {
    await pg.setViewportSize({ width: w, height: h });
    await pg.setContent(html);
    await pg.evaluate(() => document.fonts.ready);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    await pg.screenshot({ path: file, omitBackground: !!transparent });
  };
  const dens = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
  for (const [d, k] of Object.entries(dens)) {
    const icon = Math.round(48 * k);
    await shot(`${res}/mipmap-${d}/ic_launcher.png`, icon, icon, page(sized(svg, icon), [icon, icon], 'transparent'), true);
    await shot(`${res}/mipmap-${d}/ic_launcher_round.png`, icon, icon, page(`<div style="width:${icon}px;height:${icon}px;border-radius:50%;overflow:hidden">${sized(full, icon)}</div>`, [icon, icon], 'transparent'), true);
    const fg = Math.round(108 * k);
    // adaptive icons: keep the art inside the middle 66% safe zone
    await shot(`${res}/mipmap-${d}/ic_launcher_foreground.png`, fg, fg, page(sized(face, Math.round(fg * 0.64)), [fg, fg], 'transparent'), true);
  }
  // splash screens (portrait and landscape)
  const splash = (w, h) => {
    const m = Math.min(w, h);
    const title = `<div style="margin-top:${Math.round(m * 0.03)}px;font-family:L;font-size:${Math.round(m * 0.075)}px;line-height:1;color:#ffd23f;text-align:center;-webkit-text-stroke:${Math.max(1, Math.round(m * 0.004))}px #23160c;paint-order:stroke fill">Monkey See,<br>Monkey Do</div>`;
    return page(sized(face, Math.round(m * 0.42)), [w, h], BG, title);
  };
  for (const f of fs.readdirSync(res)) {
    const p = `${res}/${f}/splash.png`;
    if (!fs.existsSync(p)) continue;
    const { w, h } = JSON.parse(await pg.evaluate(async (b64) => {
      const img = new Image();
      img.src = 'data:image/png;base64,' + b64;
      await img.decode();
      return JSON.stringify({ w: img.naturalWidth, h: img.naturalHeight });
    }, fs.readFileSync(p).toString('base64')));
    await shot(p, w, h, splash(w, h));
  }
  // iOS
  await shot(`${ios}/AppIcon.appiconset/AppIcon-512@2x.png`, 1024, 1024, page(sized(full, 1024), [1024, 1024], BG));
  for (const n of ['splash-2732x2732.png', 'splash-2732x2732-1.png', 'splash-2732x2732-2.png']) {
    await shot(`${ios}/Splash.imageset/${n}`, 2732, 2732, splash(2732, 2732).replace(/Math/, ''));
  }
  await browser.close();
  console.log('icons and splash screens written');
})();
