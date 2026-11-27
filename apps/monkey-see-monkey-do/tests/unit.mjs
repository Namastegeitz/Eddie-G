// Unit checks for the pure game rules (no browser needed):
//   node tests/unit.mjs
import { LEVELS, WORLDS, ENDLESS, TWISTS, STAGE_ORDER, generateRound, generateSteps, extendEndless, expectedSteps, watchSchedule, makeRng, twistFor, endlessBpm, tradeMove, tradeCopies, stageForLevel } from '../js/levels.js';
import { RULES, timeLimit, starsFor, levelBananas, endlessBananas, gradeTiming, streakMult, stepPoints } from '../js/rules.js';
import { MOVES, CHORDS, sameStep, moveName, chordFor, normStep } from '../js/moves.js';
import { ITEMS, CATEGORIES, DEFAULT_OWNED, DEFAULT_EQUIPPED, getItem } from '../js/shop.js';
import { SKINS, SETS, GOALS, RARITY, getSkin, goalContext, goalProgress, newlyEarned, setProgress } from '../js/skins.js';
import { PATTERN_TYPES } from '../js/patterns.js';
import { migrateRaw } from '../js/save.js';
import { endlessGolden } from '../js/rules.js';

let pass = 0;
let fail = 0;
function check(name, cond, info = '') {
  if (cond) pass++;
  else { fail++; console.log('✗', name, info); }
}

// ---- level table matches the design brief
check('40 levels', LEVELS.length === 40);
LEVELS.forEach((l, i) => check(`level ${i + 1} id`, l.id === i + 1));
check('4 worlds', WORLDS.length === 4);
check('World 4 is on the moon', WORLDS[3].stage === 'moon');
for (const l of LEVELS) {
  check(`L${l.id} world`, l.world === Math.ceil(l.id / 10));
  check(`L${l.id} moves known`, l.moves.every((m) => MOVES[m]));
  check(`L${l.id} chords known`, l.chords.every((c) => CHORDS[c]));
  check(`L${l.id} chords use allowed moves`, l.chords.every((c) => CHORDS[c].parts.every((p) => l.moves.includes(p))));
  check(`L${l.id} 3-4 rounds`, l.rounds.length >= 3 && l.rounds.length <= 4);
  const tw = Array.isArray(l.twist) ? l.twist : [l.twist];
  check(`L${l.id} twists known`, tw.every((t) => t === null || TWISTS[t]));
}
for (const l of LEVELS.slice(0, 3)) {
  check(`L${l.id}: 2-3 steps`, l.rounds.every((n) => n >= 2 && n <= 3), l.rounds);
  check(`L${l.id}: slow tempo`, l.bpm <= 90);
  check(`L${l.id}: no combos`, l.chords.length === 0);
}
for (const l of LEVELS.slice(3, 10)) {
  check(`L${l.id}: 4-6 steps`, l.rounds.every((n) => n >= 4 && n <= 6), l.rounds);
  check(`L${l.id}: faster than level 3`, l.bpm > LEVELS[2].bpm);
  check(`L${l.id}: has combos (simultaneous moves)`, l.chords.length > 0);
}
for (let i = 1; i < 10; i++) check(`tempo rises in world 1 (${i + 1})`, LEVELS[i].bpm >= LEVELS[i - 1].bpm);
check('boss levels', [10, 20, 30, 40].every((id) => LEVELS[id - 1].boss));
check('only the showdowns are bosses', LEVELS.filter((l) => l.boss).length === 4);
// World 4 is the hardest
const avgBpm = (w) => { const ls = LEVELS.filter((l) => l.world === w); return ls.reduce((s, l) => s + l.bpm, 0) / ls.length; };
check('World 4 is faster than World 3', avgBpm(4) > avgBpm(3), [avgBpm(3), avgBpm(4)]);
check('World 4 has the longest routine', Math.max(...LEVELS[39].rounds) >= Math.max(...LEVELS.slice(0, 30).flatMap((l) => l.rounds)));

// ---- maps: 1-3 jungle, then a new map every level, showdowns at home
check('levels 1-3 in the jungle', [1, 2, 3].every((id) => LEVELS[id - 1].stage === 'jungle'));
for (const l of LEVELS) {
  check(`L${l.id} has a known map`, STAGE_ORDER.includes(l.stage), l.stage);
  check(`L${l.id} map matches stageForLevel`, l.stage === stageForLevel(l));
  if (l.boss) check(`L${l.id} showdown on its home map`, l.stage === WORLDS[l.world - 1].stage);
  if (l.id > 3 && !l.boss && l.id > 1) {
    const prev = LEVELS[l.id - 2];
    check(`L${l.id} map differs from L${prev.id}`, l.stage !== prev.stage || prev.boss, `${prev.stage} -> ${l.stage}`);
  }
}
check('World 1 visits all four maps', new Set(LEVELS.slice(0, 10).map((l) => l.stage)).size === 4);
check('level 4 is the first new map', LEVELS[3].stage !== 'jungle');
for (const w of WORLDS) check(`World ${w.id} starts on its home map`, LEVELS[(w.id - 1) * 10 + (w.id === 1 ? 0 : 0)].stage === w.stage);

// ---- take turns is out of the main game (its code is kept for the coming mini game)
const tradeIn = (l) => (Array.isArray(l.twist) ? l.twist : [l.twist]).includes('trade');
check('no level takes turns', LEVELS.every((l) => !tradeIn(l) && !l.tradeStart));
check('levels 2 and 3 are plain copy levels again', LEVELS[1].twist === null && LEVELS[2].twist === null && JSON.stringify(LEVELS[1].rounds) === '[2,3,3]' && JSON.stringify(LEVELS[2].rounds) === '[3,3,3]');
check('level 3 brings in Head Bob in round 1', generateRound(LEVELS[2], 0, 4242).steps.some((st) => st.includes('HD')));
{
  // the kept take-turns code still works, on a pretend take-turns level
  const l = { ...LEVELS[36], rounds: [7, 9, 9], twist: 'trade', tradeStart: 5 };
  for (const [r, n] of l.rounds.entries()) {
    const g = generateRound(l, r, 777 + r);
    check(`take-turns code r${r + 1}: monkey opens with 5`, g.steps.length === 5 && g.target === n, `${g.steps.length}/${g.target}`);
    const copies = tradeCopies(5, n);
    check(`take-turns code r${r + 1}: you copy ${copies.join(', ')}`, copies[0] === 5 && copies[copies.length - 1] === n);
  }
  const rng = makeRng(99);
  let chain = generateRound(l, 0, 5).steps;
  let bad = 0;
  for (let i = 0; i < 400; i++) {
    chain = [...chain, ['LA'], tradeMove(rng, l, [...chain, ['LA']])];
    const n = chain.length;
    const st = chain[n - 1];
    if (n >= 3 && JSON.stringify(st) === JSON.stringify(chain[n - 2]) && JSON.stringify(st) === JSON.stringify(chain[n - 3])) bad++;
    if (st.length > 1 && !l.chords.some((c) => CHORDS[c].parts.slice().sort().join() === st.slice().sort().join())) bad++;
    if (chain.length > 40) chain = chain.slice(-6);
  }
  check('take-turns code: monkey moves never 3 in a row, only allowed combos', bad === 0, bad);
}
check('Take turns twist kept and explained (for the mini game)', !!TWISTS.trade && TWISTS.trade.text.length > 40);

// ---- generator rules, over many seeds
let triples = 0, doubleChords = 0, outside = 0;
for (let seed = 1; seed < 4000; seed++) {
  const l = LEVELS[seed % LEVELS.length];
  const rng = makeRng(seed * 2654435761);
  const steps = generateSteps(rng, 12, l.moves, l.chords, { chordChance: 0.4 });
  for (let i = 0; i < steps.length; i++) {
    const s = steps[i];
    if (s.length === 1 && !l.moves.includes(s[0])) outside++;
    if (s.length > 1 && !chordFor(s)) outside++;
    if (i >= 2 && sameStep(s, steps[i - 1]) && sameStep(s, steps[i - 2])) triples++;
    if (i >= 1 && s.length > 1 && steps[i - 1].length > 1) doubleChords++;
  }
}
check('never three of the same step in a row', triples === 0, triples);
check('never two combos in a row', doubleChords === 0, doubleChords);
check('steps only use the level\'s moves and combos', outside === 0, outside);

// determinism
const a = generateRound(LEVELS[8], 1, 12345);
const b = generateRound(LEVELS[8], 1, 12345);
check('same seed, same routine', JSON.stringify(a) === JSON.stringify(b));
const c = generateRound(LEVELS[8], 1, 54321);
check('different seed, (almost always) different routine', JSON.stringify(a.steps) !== JSON.stringify(c.steps));

// round lengths
for (const l of LEVELS) {
  let prev = null;
  l.rounds.forEach((n, r) => {
    const g = generateRound(l, r, 1000 + r * 7, prev);
    check(`L${l.id} r${r + 1} length`, g.steps.length === n, `${g.steps.length} vs ${n}`);
    if (twistFor(l, r) === 'buildup' && prev) check(`L${l.id} r${r + 1} builds on the last round`, JSON.stringify(g.steps.slice(0, prev.length)) === JSON.stringify(prev));
    prev = g.steps;
  });
}

// new things show up in round 1 (except level 1, which introduces 4 moves in 2 steps)
for (const l of LEVELS.filter((x) => x.id > 1 && x.intro.some((i) => MOVES[i] || CHORDS[i]))) {
  for (let seed = 0; seed < 200; seed++) {
    const g = generateRound(l, 0, seed * 97 + 1);
    for (const id of l.intro.filter((i) => MOVES[i] || CHORDS[i])) {
      const want = MOVES[id] ? [id] : normStep(CHORDS[id].parts);
      if (!g.steps.some((s) => sameStep(s, want))) { check(`L${l.id} round 1 includes new ${id}`, false, `seed ${seed}`); break; }
    }
  }
}
check('intro check ran', true);

// twists
check('reverse twist reverses', JSON.stringify(expectedSteps([['LA'], ['RL'], ['HD']], 'reverse')) === JSON.stringify([['HD'], ['RL'], ['LA']]));
check('no twist keeps order', JSON.stringify(expectedSteps([['LA'], ['RL']], null)) === JSON.stringify([['LA'], ['RL']]));
const sp = watchSchedule(10, 'speedup');
const gaps = sp.offsets.slice(1).map((o, i) => o - sp.offsets[i]);
check('speed-up gaps shrink', gaps.every((g, i) => i === 0 || g <= gaps[i - 1] + 1e-9));
check('speed-up never below 0.55 beats', gaps.every((g) => g >= 0.55 - 1e-9));
check('normal schedule is one beat per move', JSON.stringify(watchSchedule(4, null).offsets) === '[0,1,2,3]');

// endless
const rng = makeRng(7);
let seq = [];
for (let r = 0; r < 20; r++) {
  const next = extendEndless(rng, seq, r);
  check(`endless round ${r + 1} keeps the old routine`, JSON.stringify(next.slice(0, seq.length)) === JSON.stringify(seq));
  check(`endless round ${r + 1} length`, next.length === ENDLESS.startLength + r * ENDLESS.addPerRound);
  if (r < ENDLESS.chordsFromRound) check(`endless round ${r + 1} has no combos yet`, next.slice(seq.length).every((s) => s.length === 1));
  seq = next;
}
check('endless tempo capped', endlessBpm(1000) === ENDLESS.maxBpm);

// ---- rules
check('timer formula', timeLimit(2, 80) === Math.round((RULES.timerBase + 2 * RULES.timerPerStep * 1.25) * 10) / 10);
check('relaxed doubles', Math.abs(timeLimit(5, 100, 'relaxed') - 2 * timeLimit(5, 100)) < 0.11);
check('timer off', timeLimit(5, 100, 'off') === Infinity);
check('perfect', gradeTiming(0.05) === 'perfect' && gradeTiming(-0.09) === 'perfect');
check('great', gradeTiming(0.12) === 'great');
check('good', gradeTiming(0.25) === 'good');
check('streak tiers', streakMult(0) === 1 && streakMult(9) === 1 && streakMult(10) === 2 && streakMult(25) === 3);
check('step points', stepPoints('perfect', 10) === (RULES.pointsPerStep + RULES.perfectBonus) * 2);
check('3 stars', starsFor({ livesLost: 0, onBeat: 5, steps: 10 }) === 3);
check('2 stars when off-beat', starsFor({ livesLost: 0, onBeat: 4, steps: 10 }) === 2);
check('2 stars with one life lost', starsFor({ livesLost: 1, onBeat: 10, steps: 10 }) === 2);
check('1 star', starsFor({ livesLost: 2, onBeat: 10, steps: 10 }) === 1);
const lb = levelBananas({ stepsCleared: 7, stars: 3, firstClear: true });
check('level bananas add up', lb.total === 7 + 15 + 10 && lb.items.length === 3);
check('no first-clear bonus on replay', levelBananas({ stepsCleared: 7, stars: 3, firstClear: false }).total === 22);
const eb = endlessBananas({ rounds: 12, newBest: true });
check('endless bananas', eb.total === 12 + 20 + 10, eb.total);

// ---- moves + wardrobe
check('screen naming', moveName('LA') === 'Left Arm');
check('monkey naming swaps sides', moveName('LA', 'monkey') === 'Right Arm' && moveName('HD', 'monkey') === 'Head Bob');
check('chord lookup ignores order', chordFor(['RA', 'LA']).id === 'BA');
for (const cat of CATEGORIES.filter((c) => c.id !== 'skin' && c.id !== 'outfits')) {
  const ids = ITEMS.filter((i) => i.cat === cat.id).map((i) => i.id);
  check(`${cat.id}: unique ids`, new Set(ids).size === ids.length);
  check(`${cat.id}: default owned exists`, DEFAULT_OWNED[cat.id].every((id) => getItem(cat.id, id)));
}
check('prices are whole, non-negative numbers', ITEMS.every((i) => Number.isInteger(i.price) && i.price >= 0));
check('gear: every slot has a free "none"', ['hat', 'eyes', 'neck', 'back', 'hands', 'feet', 'face', 'aura'].every((c) => getItem(c, 'none') && getItem(c, 'none').price === 0));
check('gear: at least 80 items to wear', ITEMS.filter((i) => !['flair', 'stage'].includes(i.cat) && i.id !== 'none').length >= 80, ITEMS.length);
check('gear: currencies are bananas or golden', ITEMS.every((i) => i.currency === 'banana' || i.currency === 'golden'));
check('gear: golden prices are small, banana prices sane', ITEMS.every((i) => (i.currency === 'golden' ? i.price > 0 && i.price <= 40 : i.price <= 300)));
check('gear: auras have a colour', ITEMS.filter((i) => i.cat === 'aura' && i.id !== 'none').every((i) => /^#/.test(i.auraColor)));
check('default look is free', Object.entries(DEFAULT_EQUIPPED).every(([cat, id]) => id === 'auto' || (cat === 'skin' ? getSkin(id).price === 0 : getItem(cat, id).price === 0)));

// ---- skins
check('100 skins', SKINS.length === 100, SKINS.length);
const premium = SKINS.filter((x) => x.tier === 'premium');
const standard = SKINS.filter((x) => x.tier === 'standard');
check('50 premium skins', premium.length === 50, premium.length);
check('50 standard skins', standard.length === 50, standard.length);
check('skin ids unique', new Set(SKINS.map((x) => x.id)).size === 100);
check('every skin in a known set', SKINS.every((x) => SETS.some((st) => st.id === x.set)));
check('every set has skins of one tier', SETS.every((st) => SKINS.filter((x) => x.set === st.id).every((x) => x.tier === st.tier)));
check('rarities known', SKINS.every((x) => RARITY[x.rarity]));
check('standard skins are common/rare, cost bananas', standard.every((x) => ['common', 'rare'].includes(x.rarity) && x.currency === 'banana' && Number.isInteger(x.price)));
check('premium skins are epic/legendary, cost golden bananas', premium.every((x) => ['epic', 'legendary'].includes(x.rarity) && x.currency === 'golden' && x.price > 0));
check('every premium skin has a goal', premium.every((x) => GOALS[x.goal]));
check('each goal used by exactly one skin', new Set(premium.map((x) => x.goal)).size === 50);
check('legendary costs more than epic', Math.min(...premium.filter((x) => x.rarity === 'legendary').map((x) => x.price)) >= Math.max(...premium.filter((x) => x.rarity === 'epic').map((x) => x.price)) - 0);
check('patterns are known types', SKINS.every((x) => !x.pattern || PATTERN_TYPES.includes(x.pattern.type)));
check('colours are #rrggbb', SKINS.every((x) => [x.fur, x.skin, x.dark].every((c) => /^#[0-9a-f]{3,6}$/i.test(c))));
const EXTRAS = ['cape', 'wings', 'halo', 'horns', 'unihorn', 'mane', 'antenna', 'jetpack', 'mask', 'eyepatch', 'bolts', 'fin', 'tailtip'];
check('extras are known', SKINS.every((x) => (x.extras || []).every((e) => EXTRAS.includes(e.split(':')[0]))));
check('old fur ids are still skins', ['cocoa', 'golden', 'snowy', 'midnight', 'bubblegum', 'mossy', 'rainbow'].every((id) => getSkin(id).id === id));

// goals
const fresh = { levels: {}, endless: { bestRounds: 0 }, stats: { days: [] }, owned: { skin: ['cocoa'] } };
check('nothing earned on a fresh save', newlyEarned(fresh).length === 0);
const ctx0 = goalContext(fresh);
check('every goal starts at 0 progress (owning Cocoa counts 1 skin)', premium.every((x) => goalProgress(x, ctx0).have === (x.goal === 'skins25' ? 1 : 0)));
const lv = {};
for (let i = 1; i <= 10; i++) lv[i] = { stars: 3, best: 1, clears: 1 };
const w1 = { levels: lv, endless: { bestRounds: 12 }, stats: { days: ['a', 'b', 'c'], perfects: 60, bestStreak: 16, roundsCleared: 55, flawless: 6, combos: 10 }, owned: { skin: ['cocoa'] } };
const earned = newlyEarned(w1).map((x) => x.goal).sort();
const expectGoals = ['allstars1', 'boss10', 'days3', 'endless10', 'endless5', 'flawless5', 'perfect50', 'rounds50', 'stars15', 'stars30', 'streak15', 'world1'].sort();
check('goals reached after a perfect World 1', JSON.stringify(earned) === JSON.stringify(expectGoals), earned.join(','));
check('progress is capped at the goal', goalProgress(getSkin('galaxy'), goalContext({ ...w1, endless: { bestRounds: 99 } })).have === 30);
check('set progress', JSON.stringify(setProgress('metals', ['bronze', 'gold'])) === JSON.stringify({ have: 2, total: 5 }));

// golden + save migration
check('endless golden: 1 per 10 rounds', endlessGolden(9) === 0 && endlessGolden(10) === 1 && endlessGolden(35) === 3);
const mig = migrateRaw({ owned: { fur: ['cocoa', 'rainbow'], hat: ['none'] }, equipped: { fur: 'rainbow', hat: 'none' } });
check('old fur saves move to skins', JSON.stringify(mig.owned.skin) === JSON.stringify(['cocoa', 'rainbow']) && mig.equipped.skin === 'rainbow' && !('fur' in mig.owned));


// ---- shop (real money)
const { PRODUCTS, PRODUCT_PREFIX, GROUPS, bonusPercent, bestValueId, spentThisMonth, getProduct, OWNED_REFUND_GOLDEN } = await import('../js/store.js');
const { Save } = await import('../js/save.js');
const { skinsInSet } = await import('../js/skins.js');
check('product ids unique', new Set(PRODUCTS.map((p) => p.id)).size === PRODUCTS.length);
check('store ids are valid', PRODUCTS.every((p) => /^[a-z0-9._]+$/.test(PRODUCT_PREFIX + p.id)));
check('prices $0.99-$9.99 ending in .99', PRODUCTS.every((p) => p.usd >= 0.99 && p.usd <= 9.99 && Math.round(p.usd * 100) % 100 === 99));
check('every product is in a group', PRODUCTS.every((p) => GROUPS.some((g) => g.id === p.group)));
check('packs you can buy again only hold currency', PRODUCTS.filter((p) => p.type === 'consumable').every((p) => !p.grants.skins.length && !p.grants.gear.length));
check('bundles and sets hold real skins', PRODUCTS.every((p) => p.grants.skins.every((id) => getSkin(id).id === id)));
check('bundle gear exists in the wardrobe', PRODUCTS.every((p) => p.grants.gear.every((g) => { const [c, i] = g.split(':'); return getItem(c, i) && getItem(c, i).price > 0; })));
check('each set product holds exactly its skin set', PRODUCTS.filter((p) => p.group === 'sets').every((p) => { const set = SETS.find((st) => p.title.startsWith(st.name)); return set && JSON.stringify(skinsInSet(set.id).map((x) => x.id).sort()) === JSON.stringify([...p.grants.skins].sort()); }));
check('8 premium set products', PRODUCTS.filter((p) => p.group === 'sets').length === SETS.filter((st) => st.tier === 'premium').length);
check('nothing is only for money: every skin in the shop also has a play goal or banana price', PRODUCTS.every((p) => p.grants.skins.every((id) => getSkin(id).goal || getSkin(id).currency === 'banana')));
for (const g of ['bananas', 'golden']) {
  const list = PRODUCTS.filter((p) => p.group === g).sort((a, b) => a.usd - b.usd);
  check(`${g}: smallest pack is the base price`, bonusPercent(list[0]) === 0);
  check(`${g}: bigger packs give more per dollar`, list.every((p, i) => i === 0 || bonusPercent(p) > bonusPercent(list[i - 1])));
  check(`${g}: best value is the biggest pack`, bestValueId(g) === list[list.length - 1].id);
  check(`${g}: bonuses stay modest (under 70%)`, list.every((p) => bonusPercent(p) < 70));
}
const now = new Date(2026, 10, 15);
check('monthly spend counts this month only', JSON.stringify(spentThisMonth([{ t: new Date(2026, 10, 2).getTime(), micros: 1990000, currency: 'USD' }, { t: new Date(2026, 9, 30).getTime(), micros: 9990000, currency: 'USD' }, { t: new Date(2026, 10, 3).getTime(), micros: 990000, currency: 'EUR' }], now)) === JSON.stringify({ USD: 1.99, EUR: 0.99 }));
// delivery: never twice, refunds for things already owned
Save.data.bananas = 0;
Save.data.golden = 0;
const pack = getProduct('bananas_1200');
check('pack delivers', Save.deliverPurchase(pack, 'tx1', null).bananas === 1200 && Save.data.bananas === 1200);
check('same transaction never delivers twice', Save.deliverPurchase(pack, 'tx1', null) === null && Save.data.bananas === 1200);
check('packs can be bought again', Save.deliverPurchase(pack, 'tx2', null) !== null && Save.data.bananas === 2400);
Save.data.owned.skin.push('pirate');
const pirate = getProduct('bundle_pirate');
const got = Save.deliverPurchase(pirate, 'tx3', null);
check('bundle gives its items', got.gear.length === 4 && Save.owns('back', 'parrot') && Save.data.equipped.back === 'none');
check('already-owned skin gives golden instead', got.refunded === 1 && Save.data.golden === OWNED_REFUND_GOLDEN);
check('one-time product is not given twice (restore)', Save.deliverPurchase(pirate, 'tx4', null) === null);
check('purchases are logged', Save.data.purchases.length === 3);
Save.data.settings.spendLimit = 5;
check('monthly limit blocks going over', Save.overLimit({ micros: 9990000, currency: 'USD' }) === true);
Save.data.purchases = [];
check('monthly limit allows within it', Save.overLimit({ micros: 4990000, currency: 'USD' }) === false);

// ---- 1.1.0: old saves still load, with the new settings at their defaults
{
  const fs = await import('node:fs');
  const old = JSON.parse(fs.readFileSync(new URL('./fixtures/save-first-release.json', import.meta.url), 'utf8'));
  const code = Buffer.from(JSON.stringify(old), 'utf8').toString('base64');
  Save.importCode(code);
  const d = Save.data;
  check('old save: bananas kept', d.bananas === 1234 && d.earned === 1500 && d.spent === 266);
  check('old save: stars and best scores kept', d.levels[1].stars === 3 && d.levels[2].best === 3900 && d.levels[3].clears === 1);
  check('old save: Endless record kept', d.endless.bestRounds === 7 && d.endless.bestScore === 9100);
  check('old save: fur colours become skins', d.owned.skin.includes('rainbow') && d.equipped.skin === 'rainbow' && !('fur' in d.owned));
  check('old save: gear kept', d.owned.hat.includes('party') && d.equipped.hat === 'party');
  check('old save: settings kept', d.settings.music === 0.4 && d.settings.naming === 'monkey' && d.settings.timer === 'relaxed' && d.settings.quality === 'low' && d.settings.latencyMs === 40 && d.settings.reduceMotion === true);
  check('old save: new settings start at their no-change defaults', d.settings.prepareMaps === true && d.settings.fpsCap === 0 && d.settings.renderScale === 1 && d.settings.keys === null && d.settings.gamepad === true && d.settings.crashReports === true && d.settings.askRating === true);
  check('old save: stats kept', d.stats.mixups['LA>RA'] === 2 && d.tutorialDone === true);
  check('old save: level unlocks follow the stars', Save.unlockedLevel() === 4);
  const again = JSON.parse(Buffer.from(Save.exportCode(), 'base64').toString('utf8'));
  check('old save: survives a save-code round trip', again.bananas === 1234 && again.levels[1].stars === 3 && again.settings.fpsCap === 0);
}

// ---- 1.1.0: keyboard keys
{
  const { keyFor, keyMap, checkKey, keySummary } = await import('../js/keys.js');
  check('default keys Q W E / A S D', keySummary({}) === 'Q W E / A S D' && keyFor('LA', {}) === 'q');
  check('custom key wins', keyFor('LA', { keys: { LA: 'j' } }) === 'j' && keyMap({ keys: { LA: 'j' } }).j === 'LA');
  check('old key freed when changed', keyMap({ keys: { LA: 'j' } }).q === undefined);
  check('number row still works', keyMap({ keys: { LA: 'j' } })['7'] === 'LA');
  check('duplicate key refused', checkKey('w', 'LA', {}) !== '' && checkKey('w', 'HD', {}) === '');
  check('pause and browser keys refused', checkKey('p', 'LA', {}) !== '' && checkKey('escape', 'LA', {}) !== '' && checkKey('tab', 'LA', {}) !== '');
  check('a free letter is fine', checkKey('j', 'LA', {}) === '');
}

// ---- 1.1.0: game controllers
{
  const { PLAY_BUTTONS, padFamily, glyphFor, nearestInDirection } = await import('../js/gamepad.js');
  check('shoulders are arms, triggers legs', PLAY_BUTTONS[4] === 'LA' && PLAY_BUTTONS[5] === 'RA' && PLAY_BUTTONS[6] === 'LL' && PLAY_BUTTONS[7] === 'RL');
  check('Y is Head Bob, A is Flair, D-pad plays', PLAY_BUTTONS[3] === 'HD' && PLAY_BUTTONS[0] === 'FL' && PLAY_BUTTONS[12] === 'HD' && PLAY_BUTTONS[14] === 'LA');
  check('every move has a controller button', ['LA', 'HD', 'RA', 'LL', 'FL', 'RL'].every((m) => Object.values(PLAY_BUTTONS).includes(m)));
  check('controller families', padFamily('DualSense Wireless Controller (STANDARD GAMEPAD Vendor: 054c)') === 'playstation' && padFamily('Pro Controller (Vendor: 057e)') === 'nintendo' && padFamily('Xbox 360 Controller') === 'xbox' && padFamily('') === 'xbox');
  check('button names per family', glyphFor('LA', 'xbox') === 'LB' && glyphFor('FL', 'playstation') === '✕' && glyphFor('RL', 'nintendo') === 'ZR');
  const box = (x, y) => ({ rect: { left: x, top: y, width: 10, height: 10 } });
  const a = box(0, 0), right = box(100, 0), below = box(0, 100), diag = box(100, 100);
  check('menu navigation goes the right way', nearestInDirection(a.rect, [right, below, diag], 'right') === right && nearestInDirection(a.rect, [right, below, diag], 'down') === below && nearestInDirection(a.rect, [right, below], 'up') === null);
}

// ---- Your Move! mini game (rules)
{
  const { yourMoveBananas, yourMoveBpm, RULES: R } = await import('../js/rules.js');
  check('Your Move!: nothing for no copied dance', yourMoveBananas({ moves: 0, newBest: true }).total === 0);
  check('Your Move!: 1 banana a move', yourMoveBananas({ moves: 3, newBest: false }).total === 3);
  check('Your Move!: milestone every 5 moves and a best bonus', yourMoveBananas({ moves: 11, newBest: true }).total === 11 + 2 * R.yourMoveMilestoneBananas + R.yourMoveBestBonus);
  check('Your Move!: itemised total adds up', (() => { const b = yourMoveBananas({ moves: 17, newBest: true }); return b.items.reduce((t, i) => t + i.amount, 0) === b.total; })());
  check('Your Move!: tempo starts gentle and rises', yourMoveBpm(1) === R.yourMoveStartBpm && yourMoveBpm(9) > yourMoveBpm(3));
  check('Your Move!: tempo has a ceiling', yourMoveBpm(500) === R.yourMoveMaxBpm);
  check('Your Move!: old saves get an empty record', Save.data.yourMove && Save.data.yourMove.best === 0 && Save.data.yourMove.plays === 0);
}

console.log(`${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
