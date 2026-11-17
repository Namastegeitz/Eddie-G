import { test, expect } from '@playwright/test';

const errorsOf = (page) => {
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  return errors;
};

async function openMenu(page) {
  await page.goto('/#e2e');
  await expect(page.locator('.screen-menu')).toBeVisible();
}

async function startQuick(page, diff = 'easy') {
  await page.locator('.menu-quick').click();
  await page.locator(`.diff-option.diff-${diff}`).click();
  await expect(page.locator('.screen-play')).toBeVisible();
}

async function startZen(page, diff = 'easy') {
  await page.locator('.menu-zen').click();
  await page.locator(`.diff-option.diff-${diff}`).click();
  await expect(page.locator('.screen-play')).toBeVisible();
}

/** Glyph set (lineup key) drawn in the first given cell. */
async function boardLineup(page) {
  const i = await page.evaluate(() => window.__alienSession.board.findIndex((v) => v !== 0));
  const href = await page.locator(`.cell[data-i="${i}"] use`).getAttribute('href');
  return /^#gl-([a-z]+)-/.exec(href)[1];
}

/** Fill every empty cell with the right glyph through the UI. */
async function solveAll(page, { leave = 0 } = {}) {
  const { board, solution } = await page.evaluate(() => ({ board: window.__alienSession.board.slice(), solution: window.__alienSession.solution.slice() }));
  const empties = board.map((v, i) => (v ? -1 : i)).filter((i) => i >= 0);
  for (const i of empties.slice(0, empties.length - leave)) {
    await page.locator(`.cell[data-i="${i}"]`).dispatchEvent('pointerdown');
    await page.locator(`.glyph-btn[data-v="${solution[i]}"]`).click();
  }
  return empties.slice(empties.length - leave).map((i) => [i, solution[i]]);
}

test('quick play: solve a puzzle, see the win card, stats update', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await startQuick(page, 'easy');
  await solveAll(page);
  await expect(page.locator('.win-modal')).toBeVisible({ timeout: 5000 });
  await expect(page.locator('.win-modal .modal-title')).toHaveText(/decoded/i);
  await expect(page.locator('.win-modal .ach-row')).toContainText(['First Contact']);
  // The Easy theme song plays through the whole puzzle, win card included.
  expect(await page.evaluate(() => ({ song: window.__alienMusic.current, audio: window.__alienAudioStatus() }))).toEqual({ song: 'lofi', audio: 'running' });
  await page.getByRole('button', { name: 'Menu', exact: true }).click();
  await expect(page.locator('.menu-continue')).toHaveCount(0);
  await page.locator('.icon-tile', { hasText: 'Stats' }).click();
  await page.getByRole('tab', { name: 'Easy' }).click();
  await expect(page.locator('.stat-cell', { hasText: 'Won' }).locator('b')).toHaveText('1');
  expect(errors).toEqual([]);
});

test('out of tries: the visitors ask who you are, remember the name, and give more tries', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await startQuick(page, 'medium');
  const [i, wrong, max] = await page.evaluate(() => {
    const s = window.__alienSession;
    const idx = s.board.findIndex((v) => v === 0);
    return [idx, (s.solution[idx] % 9) + 1, s.maxMistakes];
  });
  expect(max).toBe(25);
  await expect(page.locator('.tries-num')).toHaveText('25');
  await page.locator(`.cell[data-i="${i}"]`).dispatchEvent('pointerdown');
  for (let k = 0; k < 25; k++) await page.locator(`.glyph-btn[data-v="${wrong}"]`).click();
  await expect(page.locator('.encounter')).toBeVisible({ timeout: 5000 });
  // Medium in Quick Play brings the Star Cadets, and their own lines.
  await expect(page.locator('.encounter')).toHaveClass(/tone-cadet/);
  await expect(page.locator('.enc-question')).toHaveAttribute('aria-label', 'Who are you?', { timeout: 15000 });
  await page.locator('.enc-input').fill('Eddie');
  await page.getByRole('button', { name: 'Answer', exact: true }).click();
  await expect(page.locator('.enc-reply')).toHaveAttribute('aria-label', 'Eddie. Excellent name. Logging it in the academy files.', { timeout: 10000 });
  await expect(page.locator('.enc-offer')).toHaveText(/Regulation says we can share a few tries/, { timeout: 15000 });
  await page.getByRole('button', { name: /Accept the gift/ }).click({ timeout: 15000 });
  await expect(page.locator('.encounter')).toHaveCount(0, { timeout: 5000 });
  await expect(page.locator('.tries-num')).toHaveText('5');
  await page.locator('.topbar .icon-btn[aria-label="Back to menu"]').click();
  await expect(page.locator('.greeting')).toContainText('Eddie');
  expect(errors).toEqual([]);
});

test('classic 3 tries still works, and Skip jumps to the question', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('alien-sudoku:profile', JSON.stringify({ settings: { tries: 3, seenTutorial: true } })));
  await openMenu(page);
  await startQuick(page, 'medium');
  const [i, wrong] = await page.evaluate(() => {
    const s = window.__alienSession;
    const idx = s.board.findIndex((v) => v === 0);
    return [idx, (s.solution[idx] % 9) + 1];
  });
  await expect(page.locator('.life:not(.lost)')).toHaveCount(3);
  await page.locator(`.cell[data-i="${i}"]`).dispatchEvent('pointerdown');
  for (let k = 0; k < 3; k++) await page.locator(`.glyph-btn[data-v="${wrong}"]`).click();
  await page.locator('.enc-skip').click({ timeout: 5000 });
  await page.locator('.enc-chip', { hasText: 'A friend from Earth' }).click({ timeout: 8000 });
  await page.getByRole('button', { name: /Accept the gift/ }).click({ timeout: 15000 });
  await expect(page.locator('.life:not(.lost)')).toHaveCount(1);
});

test('game resumes after reload from the menu', async ({ page }) => {
  await openMenu(page);
  await startQuick(page, 'hard');
  await solveAll(page, { leave: 40 });
  const before = await page.evaluate(() => window.__alienSession.board.join(''));
  await page.waitForTimeout(600); // autosave debounce
  await page.reload();
  await expect(page.locator('.menu-continue')).toBeVisible();
  await page.locator('.menu-continue').click();
  await expect(page.locator('.screen-play')).toBeVisible();
  const after = await page.evaluate(() => window.__alienSession.board.join(''));
  expect(after).toBe(before);
});

test('daily: finishing today starts a streak', async ({ page }) => {
  await openMenu(page);
  await page.locator('.menu-daily').click();
  await page.locator('.daily-card .btn-primary').click();
  await solveAll(page);
  await expect(page.locator('.win-modal .result-streak')).toContainText('1-day streak');
  await page.getByRole('button', { name: 'Daily calendar', exact: true }).click();
  await expect(page.locator('.cal-day.today.done')).toBeVisible();
});

test('campaign: level 1 win unlocks level 2 and Next works', async ({ page }) => {
  await openMenu(page);
  await page.locator('.menu-campaign').click();
  await page.locator('.sector-card').first().click();
  await page.locator('.level-node').first().click();
  await solveAll(page);
  await expect(page.locator('.win-modal .big-star.on')).toHaveCount(3);
  await page.getByRole('button', { name: 'Next transmission', exact: true }).click();
  await expect(page.locator('.topbar-h1')).toHaveText('Transmission 2 / 9');
});

test('phone: the first tap switches sound on and the tier song keeps playing', async ({ page, isMobile }) => {
  test.skip(!isMobile, 'touch only');
  // The browser runs with strict autoplay rules (playwright.config), like an iPhone:
  // only a real tap may start sound.
  const errors = errorsOf(page);
  await openMenu(page);
  const state = () => page.evaluate(() => ({ song: window.__alienMusic.current, audio: window.__alienAudioStatus() }));
  await page.tap('.menu-quick');
  await expect.poll(state).toEqual({ song: 'lofi', audio: 'running' });
  await page.tap('.diff-option.diff-alien');
  await expect(page.locator('.screen-play')).toBeVisible();
  await expect.poll(state).toEqual({ song: 'wardrums', audio: 'running' });
  await page.waitForTimeout(10000); // longer than a song section: it loops on
  expect(await state()).toEqual({ song: 'wardrums', audio: 'running' });
  expect(errors).toEqual([]);
});

test('alien duel: customize a rival, beat it, and see it in stats', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await page.locator('.menu-duel').click();
  await expect(page.locator('.screen-duel')).toBeVisible();
  await page.locator('.rival-card', { hasText: 'Commander Vex' }).click();
  await expect(page.locator('.rival-card.on')).toContainText('Commander Vex');
  await page.locator('#duel-name').fill('Zappo');
  await page.locator('#duel-name').press('Enter');
  await page.locator('#duel-name').blur();
  await expect(page.locator('.duel-summary')).toContainText('You vs Zappo');
  await page.locator('.duel-diff.diff-easy').click();
  await page.locator('#duel-style').selectOption('streaky');
  await page.locator('.look-current').click();
  await page.locator('.look-tab', { hasText: 'Gnarly' }).click();
  await page.locator('.look-opt').nth(3).click();
  await expect(page.locator('.duel-summary')).toContainText('Streaky');
  await page.locator('.duel-start').click();
  await expect(page.locator('.screen-play .rival')).toBeVisible();
  await expect(page.locator('.rival-name')).toHaveText('Zappo');
  await expect(page.locator('.topbar-h1')).toHaveText('vs Zappo');
  expect(await page.evaluate(() => window.__alienRival.config.style)).toBe('streaky');
  // The rival moves on its own clock; the race bars and mini board follow.
  await page.evaluate(() => window.__alienDuelAdvance(60_000));
  const them = await page.evaluate(() => window.__alienRival.filled);
  expect(them).toBeGreaterThan(0);
  await expect(page.locator('.race-them .race-num')).toContainText(`${them}/`);
  await expect(page.locator('.rival-mini i.f')).toHaveCount(them);
  await solveAll(page);
  await expect(page.locator('.duel-modal .modal-title')).toHaveText('You beat Zappo!');
  await expect(page.locator('.duel-modal .ach-row')).toContainText(['First Rival']);
  await page.getByRole('button', { name: 'Menu', exact: true }).click();
  await page.locator('.icon-tile', { hasText: 'Stats' }).click();
  await page.getByRole('tab', { name: 'Duel' }).click();
  await expect(page.locator('.stat-cell', { hasText: 'Duels won' }).locator('b')).toHaveText('1');
  expect(errors).toEqual([]);
});

test('alien duel: the rival finishes first, you can keep solving, and a duel resumes', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await page.locator('.menu-duel').click();
  await page.locator('.rival-card', { hasText: 'Cadet Xel' }).click();
  await page.locator('.duel-start').click();
  await expect(page.locator('.screen-play .rival')).toBeVisible();
  // Some rival progress survives a reload.
  await page.evaluate(() => window.__alienDuelAdvance(120_000));
  const before = await page.evaluate(() => window.__alienRival.filled);
  await page.locator('.topbar .icon-btn[aria-label="Back to menu"]').click();
  await page.reload();
  await page.locator('.menu-continue').click();
  await expect(page.locator('.screen-play .rival')).toBeVisible();
  expect(await page.evaluate(() => window.__alienRival.filled)).toBe(before);
  // Fast-forward to the end of the rival's game.
  await page.evaluate(() => window.__alienDuelAdvance(60 * 60_000));
  await expect(page.locator('.duel-modal .modal-title')).toHaveText('Cadet Xel finished first');
  await page.getByRole('button', { name: 'Keep solving' }).click();
  await solveAll(page);
  await expect(page.locator('.duel-modal .modal-title')).toHaveText('Puzzle decoded');
  await page.getByRole('button', { name: 'Rematch' }).click();
  await expect(page.locator('.screen-play .rival')).toBeVisible();
  expect(await page.evaluate(() => window.__alienRival.filled)).toBe(0);
  expect(errors).toEqual([]);
});

test('easy colors: six neutral schemes, saved, applied to Zen Easy puzzles', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await page.locator('.icon-tile', { hasText: 'Settings' }).click();
  await expect(page.locator('.easy-swatch')).toHaveCount(6);
  await expect(page.locator('.easy-swatch[aria-checked="true"]')).toContainText('Moonstone');
  await page.locator('.easy-swatch', { hasText: 'Sand' }).click();
  await expect(page.locator('.easy-swatch[aria-checked="true"]')).toContainText('Sand');
  await page.locator('.topbar .icon-btn[aria-label="Back"]').click();
  await startZen(page, 'easy');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'softies');
  await expect(page.locator('html')).toHaveAttribute('data-tone', 'light');
  expect(await page.evaluate(() => getComputedStyle(document.documentElement).getPropertyValue('--c1-rgb').trim())).toBe('150, 112, 62');
  // No trace of the old pastel pink.
  expect(await page.evaluate(() => getComputedStyle(document.documentElement).getPropertyValue('--bg-deep').trim())).not.toBe('#f6eaff');
  expect(errors).toEqual([]);
});

test('star cadets: tapping a glyph names it, and Zen and Duel keep their lineups', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await startQuick(page, 'medium');
  const i = await page.evaluate(() => window.__alienSession.board.findIndex((v) => v !== 0));
  await page.locator(`.cell[data-i="${i}"]`).dispatchEvent('pointerdown');
  await expect(page.locator('.status-line')).toContainText(/(Boombox|High-Top|Scrunchie|Mixtape|Aviator|Puzzle-Cube|Aerobics|Handheld|Grunge) Cadet/);
  await page.locator('.topbar .icon-btn[aria-label="Back to menu"]').click();
  // Zen keeps the original map: Soft Visitors on Easy, Alien Creatures on Medium.
  await startZen(page, 'easy');
  expect(await boardLineup(page)).toBe('softies');
  await page.locator('.topbar .icon-btn[aria-label="Back to menu"]').click();
  await page.evaluate(() => localStorage.removeItem('alien-sudoku:saved-game'));
  await startZen(page, 'medium');
  expect(await boardLineup(page)).toBe('creatures');
  await page.locator('.topbar .icon-btn[aria-label="Back to menu"]').click();
  await page.evaluate(() => localStorage.removeItem('alien-sudoku:saved-game'));
  // Alien Duel is untouched: four rivals, five look families, Medium still Alien Creatures.
  await page.locator('.menu-duel').click();
  await expect(page.locator('.rival-card')).toHaveCount(4);
  await page.locator('.look-current').click();
  await expect(page.locator('.look-tab')).toHaveText(['Classic', 'Soft', 'Creature', 'Hostile', 'Gnarly']);
  await page.locator('.duel-diff.diff-medium').click();
  await page.locator('.duel-start').click();
  await expect(page.locator('.screen-play .rival')).toBeVisible();
  expect(await boardLineup(page)).toBe('creatures');
  expect(errors).toEqual([]);
});

test('daily: a Monday (Easy) brings Creatures, a Tuesday (Medium) brings Star Cadets', async ({ page }) => {
  const errors = errorsOf(page);
  await page.clock.setFixedTime(new Date('2026-11-18T12:00:00'));
  await openMenu(page);
  await page.locator('.menu-daily').click();
  await page.getByRole('button', { name: /Monday, November 16/ }).click();
  await expect(page.locator('.screen-play')).toBeVisible();
  expect(await boardLineup(page)).toBe('creatures');
  await page.locator('.topbar .icon-btn[aria-label="Back to menu"]').click();
  await page.locator('.menu-daily').click();
  await page.getByRole('button', { name: /Tuesday, November 17/ }).click();
  await expect(page.locator('.screen-play')).toBeVisible();
  expect(await boardLineup(page)).toBe('cadets');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'cadets');
  expect(errors).toEqual([]);
});

test('campaign: Ring Belt, Pink Nebula and Emerald Pillars show Creatures and Star Cadets as planned', async ({ page }) => {
  const errors = errorsOf(page);
  // A returning player who has cleared the first three sectors.
  await page.addInitScript(() => {
    if (localStorage.getItem('alien-sudoku:profile')) return;
    const levels = {};
    for (let s = 0; s < 3; s++) for (let l = 0; l < 9; l++) levels[`${s}-${l}`] = { stars: 3, bestMs: 200000 };
    localStorage.setItem('alien-sudoku:profile', JSON.stringify({ settings: { seenTutorial: true }, campaign: { levels } }));
  });
  await openMenu(page);
  await page.locator('.menu-campaign').click();
  const sectorLineups = async (n) => {
    await page.locator('.sector-card').nth(n).click();
    await expect(page.locator('.level-node')).toHaveCount(9);
    const titles = await page.locator('.level-node').evaluateAll((els) => els.map((e) => e.getAttribute('title')));
    await page.locator('.topbar .icon-btn[aria-label="Back"]').click();
    return titles.map((t) => (t.includes('Star Cadets') ? 'cadets' : t.includes('Alien Creatures') ? 'creatures' : t.split(' · ')[1]));
  };
  expect(await sectorLineups(1)).toEqual([...Array(4).fill('creatures'), ...Array(5).fill('cadets')]);
  expect(await sectorLineups(2)).toEqual(Array(9).fill('cadets'));
  expect((await sectorLineups(3)).slice(0, 4)).toEqual(Array(4).fill('cadets'));
  // A Ring Belt level 5 board draws the cadets.
  await page.locator('.sector-card').nth(1).click();
  await page.locator('.level-node').nth(4).click();
  expect(await boardLineup(page)).toBe('cadets');
  expect(errors).toEqual([]);
});

test('continue: a game saved before the update resumes with the new lineup', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await startQuick(page, 'medium');
  await page.locator('.topbar .icon-btn[aria-label="Back to menu"]').click();
  // Make the save look like one from version 1.0 (no duel field), then reload.
  await page.evaluate(() => {
    const snap = JSON.parse(localStorage.getItem('alien-sudoku:saved-game'));
    delete snap.duel;
    localStorage.setItem('alien-sudoku:saved-game', JSON.stringify(snap));
  });
  await page.reload();
  await page.locator('.menu-continue').click();
  await expect(page.locator('.screen-play')).toBeVisible();
  expect(await boardLineup(page)).toBe('cadets');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'cadets');
  expect(errors).toEqual([]);
});

test('settings: the privacy policy opens inside the game (store requirement)', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await page.locator('.icon-tile', { hasText: 'Settings' }).click();
  await page.getByRole('button', { name: 'Privacy policy' }).click();
  await expect(page.locator('.policy-modal .policy-text')).toContainText('stored only on your device');
  await expect(page.locator('.policy-modal .policy-text')).not.toContainText('{{');
  await page.locator('.policy-modal .modal-actions').getByRole('button', { name: 'Close' }).click();
  await expect(page.locator('.policy-modal')).toHaveCount(0);
  expect(errors).toEqual([]);
});

test('settings: every theme song plays from the song list', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await page.locator('.icon-tile', { hasText: 'Settings' }).click();
  const playing = () => page.evaluate(() => window.__alienMusic.current);
  await expect.poll(playing).toBe('lofi');
  const row = (label) => page.locator('.song-row').filter({ has: page.locator('small', { hasText: new RegExp(`^${label}$`) }) });
  for (const [label, song] of [['Medium', 'cadet'], ['Medium · Zen & Duel', 'oracle'], ['Hard', 'synthwave'], ['Alien', 'wardrums'], ['Easy', 'lofi']]) {
    await row(label).click();
    await expect.poll(playing).toBe(song);
    await expect(row(label)).toHaveAttribute('aria-pressed', 'true');
  }
  // Let a song run so its notes are built and played without errors.
  await page.waitForTimeout(2500);
  await page.getByRole('button', { name: 'Test sound' }).click();
  await expect(page.locator('.sound-check .set-note')).toContainText('Sound is');
  expect(errors).toEqual([]);
});

test('campaign levels bring the aliens of their difficulty', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await page.locator('.menu-campaign').click();
  await page.locator('.sector-card').first().click();
  await expect(page.locator('.level-node').first().locator('.level-diff')).toHaveText('Easy');
  await expect(page.locator('.level-node').first().locator('use')).toHaveAttribute('href', /^#gl-creatures-/);
  await page.locator('.level-node').first().click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'creatures');
  expect(await boardLineup(page)).toBe('creatures');
  expect(errors).toEqual([]);
});

test('hint, notes, undo and pause work from the keyboard', async ({ page, isMobile }) => {
  test.skip(isMobile, 'keyboard test runs on desktop');
  await openMenu(page);
  await startQuick(page, 'easy');
  await page.keyboard.press('h');
  await expect(page.locator('.status-line')).not.toHaveText('');
  expect(await page.evaluate(() => window.__alienSession.hints)).toBe(1);
  const empty = await page.evaluate(() => window.__alienSession.board.findIndex((v) => v === 0));
  await page.locator(`.cell[data-i="${empty}"]`).dispatchEvent('pointerdown');
  await page.keyboard.press('n');
  await page.keyboard.press('3');
  await expect(page.locator(`.cell[data-i="${empty}"] .notes-grid`)).toBeVisible();
  await page.keyboard.press('u');
  await expect(page.locator(`.cell[data-i="${empty}"] .notes-grid`)).toHaveCount(0);
  await page.keyboard.press('p');
  await expect(page.locator('.pause-menu')).toBeVisible();
  await expect(page.locator('.pause-cover')).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(page.locator('.pause-cover')).toBeHidden();
});

test('settings persist and every screen opens cleanly', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await page.locator('.icon-tile', { hasText: 'Settings' }).click();
  await page.locator('.set-card', { hasText: 'Planets' }).click();
  await page.locator('.set-row', { hasText: 'Show timer' }).locator('input').uncheck();
  await page.reload();
  await page.locator('.icon-tile', { hasText: 'Settings' }).click();
  await expect(page.locator('.set-card.active')).toContainText('Planets');
  await expect(page.locator('.set-row', { hasText: 'Show timer' }).locator('input')).not.toBeChecked();
  for (const tile of ['Achievements', 'Stats', 'How to play']) {
    await page.goBack().catch(() => {});
    await openMenu(page);
    await page.locator('.icon-tile', { hasText: tile }).click();
    await expect(page.locator('.page .topbar-h1')).toBeVisible();
  }
  expect(errors).toEqual([]);
});

test('lineups: themes switch, every glyph exists, correct moves score points', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  const missing = await page.evaluate(() => {
    const out = [];
    for (const k of ['encounters', 'fleet', 'planets', 'cosmos', 'creatures', 'ancient', 'softies', 'hostile', 'gnarly']) {
      for (let i = 1; i <= 9; i++) if (!document.getElementById(`gl-${k}-${i}`)) out.push(`${k}-${i}`);
    }
    return out;
  });
  expect(missing).toEqual([]);
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'encounters');
  await page.locator('.icon-tile', { hasText: 'Settings' }).click();
  await page.locator('.set-card', { hasText: 'Space Fleet' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'fleet');
  // Use the chosen lineup in quick play (otherwise each difficulty brings its own aliens).
  await page.locator('.set-row', { hasText: 'Each difficulty brings its own aliens' }).locator('input').uncheck();
  await page.locator('.topbar .icon-btn[aria-label="Back"]').click();
  await expect(page.locator('.lineup-chip')).toContainText('Space Fleet');
  await startQuick(page, 'easy');
  const [i, v] = await page.evaluate(() => {
    const s = window.__alienSession;
    const idx = s.board.findIndex((x) => x === 0);
    return [idx, s.solution[idx]];
  });
  await page.locator(`.cell[data-i="${i}"]`).dispatchEvent('pointerdown');
  await page.locator(`.glyph-btn[data-v="${v}"]`).click();
  await expect(page.locator('.hud-score b')).not.toHaveText('0');
  await expect(page.locator(`.cell[data-i="${i}"] use`)).toHaveAttribute('href', `#gl-fleet-${v}`);
  expect(errors).toEqual([]);
});

test('quick play lineup: Creatures, Star Cadets, Hostile, Gnarly, each playing to a win', async ({ page }) => {
  const errors = errorsOf(page);
  test.setTimeout(240_000); // four full solves
  await openMenu(page);
  const expected = { easy: 'creatures', medium: 'cadets', hard: 'hostile', alien: 'gnarly' };
  const songs = { easy: 'lofi', medium: 'cadet', hard: 'synthwave', alien: 'wardrums' };
  const playing = () => page.evaluate(() => window.__alienMusic.current);
  for (const [diff, lineup] of Object.entries(expected)) {
    await startQuick(page, diff);
    await expect(page.locator('html')).toHaveAttribute('data-theme', lineup);
    await expect.poll(playing).toBe(songs[diff]);
    expect(await boardLineup(page)).toBe(lineup);
    await solveAll(page);
    await expect(page.locator('.win-modal')).toBeVisible({ timeout: 5000 });
    await page.getByRole('button', { name: 'Menu', exact: true }).click();
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'encounters');
  }
  // Turning the setting off uses the player's own lineup again.
  await page.locator('.icon-tile', { hasText: 'Settings' }).click();
  await page.locator('.set-row', { hasText: 'Each difficulty brings its own aliens' }).locator('input').uncheck();
  await page.locator('.topbar .icon-btn[aria-label="Back"]').click();
  await startQuick(page, 'alien');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'encounters');
  expect(errors).toEqual([]);
});
