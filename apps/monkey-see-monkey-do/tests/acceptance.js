// Monkey See, Monkey Do: end-to-end acceptance test (Playwright + Chromium).
// Plays the real game in a phone-sized browser: tutorial, a full level by
// tapping the pad, mistakes and retries, a timeout, combos, Endless, Free
// Dance (pad, keyboard, swipe, tapping the monkey), the wardrobe, settings,
// How it works, saving across reloads, and playing offline.
//
// Run (from the app folder):
//   python3 -m http.server 8765 --bind 127.0.0.1 &
//   node tests/acceptance.js          (screenshots go to tests/output/)
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const OUT = path.join(__dirname, 'output');
fs.mkdirSync(OUT, { recursive: true });
const BASE = process.env.BASE || 'http://127.0.0.1:8765/';
let failures = 0;
let passes = 0;

(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, serviceWorkers: 'allow' });
  const page = await ctx.newPage();
  const errors = [];
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', (e) => errors.push('PAGEERROR ' + e.message));
  const step = async (name, fn) => {
    try {
      await fn();
      passes++;
      console.log('✓', name);
    } catch (e) {
      failures++;
      console.log('✗', name, '-', e.message.split('\n')[0]);
      await page.screenshot({ path: path.join(OUT, 'FAIL-' + name.replace(/\W+/g, '_') + '.png') }).catch(() => {});
    }
  };
  const shot = (name) => page.screenshot({ path: path.join(OUT, name + '.png') });
  const ev = (fn, arg) => page.evaluate(fn, arg);
  const waitPhase = (phase, timeout = 15000) => page.waitForFunction((p) => MSMD.game.phase === p, phase, { timeout });
  const expect = (cond, msg) => { if (!cond) throw new Error(msg); };
  const keyFor = { LA: 'q', HD: 'w', RA: 'e', LL: 'a', FL: 's', RL: 'd' };

  // Copy the current routine. via: 'pad' (tap buttons), 'keys'
  async function playRoutine(via = 'pad') {
    await waitPhase('respond');
    const expected = await ev(() => MSMD.game.run.expected);
    for (const st of expected) {
      if (st.length > 1) {
        // a combo: both keys down together
        await page.keyboard.down(keyFor[st[0]]);
        await page.keyboard.down(keyFor[st[1]]);
        await page.keyboard.up(keyFor[st[0]]);
        await page.keyboard.up(keyFor[st[1]]);
      } else if (via === 'pad') {
        await page.click(`#pad [data-move="${st[0]}"]`);
      } else {
        await page.keyboard.press(keyFor[st[0]]);
      }
      await page.waitForTimeout(60);
    }
    return expected;
  }

  await page.goto(BASE);
  await step('game boots and shows the title', async () => {
    await page.waitForSelector('html[data-ready="1"]', { timeout: 20000 });
    await page.waitForSelector('#scr-title.show');
    await page.waitForTimeout(800);
    await shot('01-title');
  });

  await step('first Play shows the 3-card how-to, then Level 1 card', async () => {
    await page.click('#btn-play');
    await page.waitForSelector('#ov-howto.show');
    await shot('02-howto');
    await page.click('#howto-next');
    await page.click('#howto-next');
    expect(await page.textContent('#howto-next') === 'Start Level 1', 'last card button');
    await page.click('#howto-next');
    await page.waitForSelector('#ov-intro.show');
    const txt = await page.textContent('#intro-card');
    expect(txt.includes('First Steps') && txt.includes('80 BPM') && txt.includes('NEW'), 'intro card facts: ' + txt.slice(0, 120));
    await page.waitForTimeout(1200);
    await shot('03-intro');
  });

  await step('Level 1: watch phase lights up the moves', async () => {
    await page.click('#intro-go');
    await page.waitForFunction(() => MSMD.game.phase === 'watch');
    await page.waitForTimeout(250);
    const cls = await page.getAttribute('#phase', 'class');
    expect(cls.includes('watch'), 'phase badge is WATCH');
    await shot('04-watch');
  });

  await step('Level 1: guided first round glows the right button', async () => {
    await waitPhase('respond');
    const expected = await ev(() => MSMD.game.run.expected);
    const hinted = await page.$$eval('#pad .pad-btn.hint', (b) => b.map((x) => x.dataset.move));
    expect(hinted.length === 1 && hinted[0] === expected[0][0], `hint ${hinted} vs ${expected[0]}`);
    await shot('05-your-turn');
  });

  await step('Level 1: tapping the pad clears all 3 rounds', async () => {
    const before = await ev(() => MSMD.Save.data.bananas);
    for (let r = 0; r < 3; r++) await playRoutine('pad');
    await page.waitForSelector('#ov-result.show', { timeout: 15000 });
    const after = await ev(() => MSMD.Save.data.bananas);
    const info = await ev(() => MSMD.Save.levelInfo(1));
    expect(info.clears === 1 && info.stars >= 2, 'level 1 recorded ' + JSON.stringify(info));
    expect(after > before, `bananas ${before} -> ${after}`);
    const card = await page.textContent('#result-card');
    expect(card.includes('cleared') && card.includes('Bananas earned'), 'result card');
    await page.waitForTimeout(1500);
    await shot('06-level-clear');
  });

  await step('result total matches the banana ledger', async () => {
    const total = Number((await page.textContent('#result-card tr.total td:last-child')).replace(/\D/g, ''));
    const ledger = await ev(() => MSMD.Save.data.ledger.filter((e) => e.reason.startsWith('Level 1')).reduce((s, e) => s + e.amount, 0));
    expect(total === ledger, `card says ${total}, ledger ${ledger}`);
    expect(await ev(() => MSMD.Save.data.tutorialDone), 'tutorial marked done');
  });

  await step('Level 2: a wrong move costs a life and replays the SAME routine', async () => {
    await page.click('#res-next');
    await page.waitForSelector('#ov-intro.show');
    await page.click('#intro-go');
    await waitPhase('respond');
    const first = await ev(() => JSON.stringify(MSMD.game.run.steps));
    const right = await ev(() => MSMD.game.run.expected[0][0]);
    const wrong = ['LA', 'RA', 'LL', 'RL'].find((m) => m !== right);
    await page.click(`#pad [data-move="${wrong}"]`);
    await page.waitForSelector('#mistake:not([hidden])');
    const lives = await ev(() => MSMD.game.run.lives);
    expect(lives === 2, 'lives now ' + lives);
    const m = await page.textContent('#mistake');
    expect(m.includes('Oops') && m.includes('You tapped'), 'mistake card text');
    await shot('07-mistake');
    await page.click('#mistake-go');
    await waitPhase('respond');
    const again = await ev(() => JSON.stringify(MSMD.game.run.steps));
    expect(first === again, 'same routine after a mistake');
    const mix = await ev(() => MSMD.Save.data.stats.mixups);
    expect(Object.keys(mix).length >= 1, 'mix-up recorded');
  });

  await step('running out of time counts as a mistake', async () => {
    const lim = await ev(() => MSMD.game.run.limit);
    await page.waitForFunction(() => MSMD.game.phase === 'oops', null, { timeout: (lim + 3) * 1000 });
    const t = await page.textContent('#mistake');
    expect(t.includes("Time's up"), 'timeout card');
    expect(await ev(() => MSMD.game.run.lives) === 1, 'one life left');
  });

  await step('losing the last life shows Out of lives with an honest continue', async () => {
    await page.click('#mistake-go');
    await waitPhase('respond');
    const right = await ev(() => MSMD.game.run.expected[0][0]);
    await page.keyboard.press(keyFor[['LA', 'RA', 'LL', 'RL'].find((m) => m !== right)]);
    await page.waitForSelector('#ov-result.show', { timeout: 8000 });
    const txt = await page.textContent('#result-card');
    expect(txt.includes('Out of lives') && txt.includes('Continue'), 'fail card');
    await page.waitForTimeout(600);
    await shot('08-out-of-lives');
  });

  await step('continue spends 15 bananas and gives 1 life', async () => {
    const before = await ev(() => MSMD.Save.data.bananas);
    if (before < 15) await ev(() => MSMD.Save.addBananas(20, 'test top-up'));
    const b2 = await ev(() => MSMD.Save.data.bananas);
    await ev(() => MSMD.ui.showFail({ level: MSMD.game.run.level, round: 1, rounds: 3, score: 0, canContinue: true, cost: 15, bananas: MSMD.Save.data.bananas }));
    await page.click('#fail-cont');
    await waitPhase('respond');
    expect(await ev(() => MSMD.game.run.lives) === 1, 'one life');
    expect(await ev(() => MSMD.Save.data.bananas) === b2 - 15, 'spent 15');
  });

  await step('keyboard play clears Level 2', async () => {
    for (let r = await ev(() => MSMD.game.run.round); r < 3; r++) await playRoutine('keys');
    await page.waitForSelector('#ov-result.show', { timeout: 15000 });
    expect((await ev(() => MSMD.Save.levelInfo(2))).clears === 1, 'level 2 cleared');
  });

  await step('combos: Level 4 needs both arms together', async () => {
    await ev(() => { for (let i = 1; i <= 3; i++) MSMD.Save.data.levels[i] = { stars: 3, best: 1000, clears: 1 }; MSMD.Save.persist(); });
    await ev(() => { MSMD.ui.closeOverlay('ov-result'); MSMD.game.openLevel(4); });
    await page.click('#intro-go');
    let sawCombo = false;
    for (let r = 0; r < 3; r++) {
      const exp = await playRoutine('keys');
      if (exp.some((s) => s.length > 1)) sawCombo = true;
    }
    await page.waitForSelector('#ov-result.show', { timeout: 15000 });
    expect(sawCombo, 'level 4 introduces the Hooray! combo in round 1');
    expect((await ev(() => MSMD.Save.levelInfo(4))).clears === 1, 'level 4 cleared');
  });

  await step('a combo with only one half is a mistake', async () => {
    await ev(() => { MSMD.ui.closeOverlay('ov-result'); MSMD.game.openLevel(4); });
    await page.click('#intro-go');
    await waitPhase('respond');
    // Force a combo first so the test is deterministic
    await ev(() => { const r = MSMD.game.run; r.expected = [['LA', 'RA'], ['LL']]; MSMD.ui.setSteps(2); });
    await page.keyboard.press('q');
    await page.waitForFunction(() => MSMD.game.phase === 'oops', null, { timeout: 3000 });
    expect((await page.textContent('#mistake')).includes('Both at once'), 'combo card');
    await ev(() => MSMD.game.quit());
    await ev(() => MSMD.ui.show('title'));
  });

  await step('Endless: rounds grow by one move, one mistake ends it, best is saved', async () => {
    await page.click('#btn-endless');
    const a = await playRoutine('keys');
    const b = await playRoutine('keys');
    expect(a.length === 2 && b.length === 3, `lengths ${a.length}, ${b.length}`);
    expect(JSON.stringify(b.slice(0, 2)) === JSON.stringify(a), 'round 2 repeats round 1 and adds one');
    await waitPhase('respond');
    const right = await ev(() => MSMD.game.run.expected[0][0]);
    await page.keyboard.press(keyFor[Object.keys(keyFor).find((m) => m !== right)]);
    await page.waitForSelector('#ov-result.show', { timeout: 8000 });
    expect(await ev(() => MSMD.Save.data.endless.bestRounds) === 2, 'best rounds 2');
    await shot('09-endless-over');
    await page.click('#end-menu');
  });

  await step('Free Dance: pad, keyboard, swipe and tapping the monkey all dance', async () => {
    await page.click('#btn-free');
    await page.waitForSelector('#hud.show');
    await page.click('#pad [data-move="FL"]');
    await page.keyboard.press('w');
    // swipe up-left on the stage = Left Arm
    await page.mouse.move(200, 400);
    await page.mouse.down();
    await page.mouse.move(150, 340, { steps: 4 });
    await page.mouse.up();
    // tap the monkey's right foot
    const foot = await ev(() => {
      const { monkey, stage, app } = MSMD;
      const v = monkey.anchorWorld('RL', new app.THREE.Vector3()).project(stage.camera);
      return { x: (v.x * 0.5 + 0.5) * stage.width, y: (-v.y * 0.5 + 0.5) * stage.height };
    });
    await page.mouse.click(foot.x, foot.y);
    await page.waitForTimeout(200);
    const n = await ev(() => MSMD.game.run.moves);
    expect(n === 4, 'moves counted ' + n);
    await page.waitForTimeout(150);
    await shot('10-free-dance');
    await page.click('#btn-pause');
    await page.click('#p-quit');
  });

  await step('Wardrobe: try on, buy and wear a hat; bananas go down by the price', async () => {
    await ev(() => MSMD.Save.addBananas(300, 'test top-up'));
    await page.click('#scr-title .mini[data-go="shop"]');
    await page.click('#shop-tabs [data-cat="hat"]');
    await page.click('#shop-grid [data-id="party"]');
    const before = await ev(() => MSMD.Save.data.bananas);
    await page.click('#shop-buy');
    expect(await ev(() => MSMD.Save.owns('hat', 'party')), 'owned');
    expect(await ev(() => MSMD.Save.data.equipped.hat) === 'party', 'equipped');
    expect(await ev(() => MSMD.Save.data.bananas) === before - 40, 'price 40');
    await page.click('#shop-tabs [data-cat="eyes"]');
    await page.click('#shop-grid [data-id="shades"]');
    await page.click('#shop-buy');
    await page.click('#shop-tabs [data-cat="fur"]');
    await page.click('#shop-grid [data-id="golden"]');
    await page.click('#shop-buy');
    await page.waitForTimeout(900);
    await shot('11-wardrobe');
  });

  await step('Wardrobe: leaving undoes a try-on you did not buy', async () => {
    await page.click('#shop-tabs [data-cat="neck"]');
    await page.click('#shop-grid [data-id="chain"]');
    await page.click('#scr-shop .back');
    expect(await ev(() => MSMD.Save.data.equipped.neck) === 'none', 'not equipped');
    expect(await ev(() => MSMD.monkey.accessories.neck === null), 'chain removed from monkey');
  });

  await step('Settings: naming by the monkey\'s own sides relabels the pad', async () => {
    await page.click('#scr-title .mini[data-go="settings"]');
    await page.click('.seg button[data-key="naming"][data-val="monkey"]');
    const label = await page.textContent('#pad [data-move="LA"] .pad-label');
    expect(label === 'Right Arm', 'label ' + label);
    await page.click('.seg button[data-key="naming"][data-val="screen"]');
    await shot('12-settings');
    await page.click('#scr-settings .back');
  });

  await step('How it works lists every level and the real numbers', async () => {
    await page.click('#scr-title .mini[data-go="help"]');
    const rows = await page.$$eval('#help-body table', (t) => t.map((x) => x.querySelectorAll('tbody tr').length));
    expect(rows.includes(30), 'level table rows ' + rows);
    const text = await page.textContent('#help-body');
    expect(text.includes('90 ms') && text.includes("can't be bought"), 'rules text');
    await shot('13-how-it-works');
    await page.click('#scr-help .back');
  });

  await step('Stats show accuracy, mix-ups and banana history', async () => {
    await page.click('#scr-title .mini[data-go="stats"]');
    const t = await page.textContent('#stats-body');
    expect(t.includes('Banana history') && t.includes('Expected'), 'stats text');
    await shot('14-stats');
    await page.click('#scr-stats .back');
  });

  await step('level map shows stars, the next level and locked worlds', async () => {
    await page.click('#btn-play');
    await page.waitForSelector('#scr-map.show');
    const next = await page.$eval('#level-grid .level.next', (b) => b.dataset.level);
    expect(next === '5', 'next level ' + next);
    const locked = await page.$$eval('#world-tabs .tab[aria-disabled="true"]', (b) => b.length);
    expect(locked === 2, 'locked worlds ' + locked);
    await shot('15-map');
  });

  await step('progress survives a reload', async () => {
    const before = await ev(() => ({ b: MSMD.Save.data.bananas, hat: MSMD.Save.data.equipped.hat }));
    await page.reload();
    await page.waitForSelector('html[data-ready="1"]');
    const after = await ev(() => ({ b: MSMD.Save.data.bananas, hat: MSMD.Save.data.equipped.hat, l1: MSMD.Save.levelInfo(1).clears }));
    expect(after.b === before.b && after.hat === 'party' && after.l1 >= 1, JSON.stringify(after));
  });

  await step('works offline after the first visit', async () => {
    await page.waitForFunction(() => navigator.serviceWorker && navigator.serviceWorker.controller, null, { timeout: 15000 }).catch(() => {});
    await page.reload();
    await page.waitForSelector('html[data-ready="1"]');
    await page.waitForFunction(() => navigator.serviceWorker.controller !== null, null, { timeout: 10000 });
    await ctx.setOffline(true);
    await page.reload();
    await page.waitForSelector('html[data-ready="1"]', { timeout: 20000 });
    await ctx.setOffline(false);
  });

  await step('landscape / desktop layout', async () => {
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.waitForTimeout(600);
    await shot('16-desktop-title');
    await ev(() => MSMD.game.openLevel(5));
    await page.waitForTimeout(500);
    await page.click('#intro-go');
    await page.waitForFunction(() => MSMD.game.phase === 'watch');
    await page.waitForTimeout(300);
    await shot('17-desktop-watch');
  });

  await step('no errors in the console', async () => {
    const real = errors.filter((e) => !/favicon|net::ERR_INTERNET_DISCONNECTED/.test(e));
    expect(real.length === 0, real.join(' | '));
  });

  console.log(`\n${passes} passed, ${failures} failed`);
  await browser.close();
  process.exit(failures ? 1 : 0);
})();
