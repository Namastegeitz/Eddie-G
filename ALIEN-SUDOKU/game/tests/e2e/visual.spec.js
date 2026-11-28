/* Visual regression: key screens at three screen sizes, compared with the saved
   pictures in visual.spec.js-snapshots/. The animated space background is random by
   design, so it is hidden; everything players read and tap is compared.
   After an intended change: npx playwright test visual --update-snapshots
   (the pictures depend on the machine's fonts; make them on the machine that checks them). */
import { test, expect, devices } from '@playwright/test';

const SIZES = {
  'small-phone': { viewport: { width: 360, height: 640 }, isMobile: true, hasTouch: true, deviceScaleFactor: 1 },
  phone: { ...devices['Pixel 7'], deviceScaleFactor: 1 },
  desktop: { viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 },
};
const PROFILE = {
  settings: { seenTutorial: true, graphics: 'high', textSize: 1 },
  campaign: { levels: { '0-0': { stars: 3, bestMs: 180000 }, '0-1': { stars: 2, bestMs: 221000 } } },
};
const HIDE_BACKGROUND = '.starfield { visibility: hidden !important; } .cosmic-bg { display: none !important; } * { caret-color: transparent !important; }';

for (const [size, device] of Object.entries(SIZES)) {
  test.describe(`visual · ${size}`, () => {
    test(`${size}: menu, settings, campaign map and a puzzle look as saved`, async ({ browser }) => {
      test.skip(test.info().project.name !== 'desktop', 'runs once, in the desktop project');
      const ctx = await browser.newContext({ ...device, reducedMotion: 'reduce' });
      const page = await ctx.newPage();
      await page.clock.setFixedTime(new Date('2026-11-14T15:30:00'));
      await page.addInitScript((p) => { if (!localStorage.getItem('alien-sudoku:profile')) localStorage.setItem('alien-sudoku:profile', JSON.stringify(p)); }, PROFILE);
      await page.goto('/#e2e');
      await page.waitForSelector('.screen-menu');
      await page.addStyleTag({ content: HIDE_BACKGROUND });
      await page.evaluate(() => document.fonts.ready);
      const shot = (name) => expect(page).toHaveScreenshot(`${size}-${name}.png`, { animations: 'disabled', maxDiffPixelRatio: 0.01 });

      await shot('menu');
      await page.locator('.icon-tile', { hasText: 'Settings' }).click();
      await page.waitForSelector('.settings');
      await shot('settings');
      await page.locator('.topbar .icon-btn[aria-label="Back"]').click();
      await page.locator('.menu-campaign').click();
      await page.locator('.sector-card').first().click();
      await page.waitForSelector('.level-map');
      await shot('campaign-map');
      await page.locator('.level-node').nth(2).click();
      await page.waitForSelector('.screen-play');
      await page.evaluate(() => { if (window.__alienSession) window.__alienSession.elapsedMs = 0; });
      await page.waitForTimeout(300);
      await shot('puzzle');
      await ctx.close();
    });
  });
}
