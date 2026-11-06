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
  await expect(page.locator('.enc-question')).toHaveAttribute('aria-label', 'Who are you?', { timeout: 15000 });
  await page.locator('.enc-input').fill('Eddie');
  await page.getByRole('button', { name: 'Answer', exact: true }).click();
  await expect(page.locator('.enc-reply')).toHaveAttribute('aria-label', /Eddie/, { timeout: 10000 });
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

test('campaign levels bring the aliens of their difficulty', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  await page.locator('.menu-campaign').click();
  await page.locator('.sector-card').first().click();
  await expect(page.locator('.level-node').first().locator('.level-diff')).toHaveText('Easy');
  await expect(page.locator('.level-node').first().locator('use')).toHaveAttribute('href', /^#gl-softies-/);
  await page.locator('.level-node').first().click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'softies');
  const i = await page.evaluate(() => window.__alienSession.board.findIndex((v) => v !== 0));
  await expect(page.locator(`.cell[data-i="${i}"] use`)).toHaveAttribute('href', /^#gl-softies-/);
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

test('each difficulty brings its own aliens and theme, soft to gnarly', async ({ page }) => {
  const errors = errorsOf(page);
  await openMenu(page);
  const expected = { easy: 'softies', medium: 'creatures', hard: 'hostile', alien: 'gnarly' };
  for (const [diff, lineup] of Object.entries(expected)) {
    await startQuick(page, diff);
    await expect(page.locator('html')).toHaveAttribute('data-theme', lineup);
    const i = await page.evaluate(() => window.__alienSession.board.findIndex((v) => v !== 0));
    await expect(page.locator(`.cell[data-i="${i}"] use`)).toHaveAttribute('href', new RegExp(`^#gl-${lineup}-`));
    await page.locator('.topbar .icon-btn[aria-label="Back to menu"]').click();
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'encounters');
    await page.evaluate(() => localStorage.removeItem('alien-sudoku:saved-game'));
    await page.reload();
  }
  // Turning the setting off uses the player's own lineup again.
  await page.locator('.icon-tile', { hasText: 'Settings' }).click();
  await page.locator('.set-row', { hasText: 'Each difficulty brings its own aliens' }).locator('input').uncheck();
  await page.locator('.topbar .icon-btn[aria-label="Back"]').click();
  await startQuick(page, 'alien');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'encounters');
  expect(errors).toEqual([]);
});
