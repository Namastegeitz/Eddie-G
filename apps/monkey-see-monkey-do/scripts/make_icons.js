// Renders assets/icons/icon.svg into the PNG sizes the manifest and iOS need.
//   node scripts/make_icons.js
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const dir = path.join(__dirname, '..', 'assets', 'icons');
const svg = fs.readFileSync(path.join(dir, 'icon.svg'), 'utf8');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const shots = [
    ['icon-192.png', 192, 0, 'transparent'],
    ['icon-512.png', 512, 0, 'transparent'],
    ['apple-touch-icon.png', 180, 0, '#0e3527'],
    ['favicon-32.png', 32, 0, 'transparent'],
    ['icon-maskable-512.png', 512, 0.12, '#0e3527'],
  ];
  for (const [name, size, pad, bg] of shots) {
    const inner = Math.round(size * (1 - pad * 2));
    await page.setViewportSize({ width: size, height: size });
    await page.setContent(`<html><body style="margin:0;background:${bg};width:${size}px;height:${size}px;display:grid;place-items:center">${svg.replace('<svg ', `<svg width="${inner}" height="${inner}" `)}</body></html>`);
    await page.screenshot({ path: path.join(dir, name), omitBackground: bg === 'transparent' });
    console.log('wrote', name);
  }
  await browser.close();
})();
