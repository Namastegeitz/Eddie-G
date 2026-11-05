// Wardrobe > Skins: the 100-skin collection, premium goals, golden bananas,
// the banana swap, and the "unlocked!" celebration. Used by ui.js.
import { SKINS, SETS, RARITY, GOALS, getSkin, goalContext, goalProgress, setProgress } from './skins.js';
import { drawPortrait } from './patterns.js';
import { RULES } from './rules.js';
import { Save } from './save.js';
import { getItem } from './shop.js';
import { gearThumb } from './gear.js';

export const GOLDEN_ICON = '<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M6 9c1 9 7 16 18 15 2 0 3-1 3-2-9 0-14-6-16-14-.4-2-5.4-1-5 1z" fill="#ffbf1a" stroke="#5a3a00" stroke-width="2" stroke-linejoin="round"/><path d="M8.3 10.5c1.6 5.6 5.4 9.6 11.6 11" fill="none" stroke="#fff3a6" stroke-width="2.2" stroke-linecap="round"/><path d="M5 9l1-3 3 1" fill="#8a5a10" stroke="#5a3a00" stroke-width="1.6" stroke-linejoin="round"/><path d="M24 2.5l1.3 3.2 3.2 1.3-3.2 1.3L24 11.5l-1.3-3.2L19.5 7l3.2-1.3z" fill="#fff" stroke="#c88a00" stroke-width=".8"/></svg>';
const LOCK = '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="5" y="10" width="14" height="11" rx="3" fill="currentColor"/><path d="M8 10V7a4 4 0 0 1 8 0v3" fill="none" stroke="currentColor" stroke-width="2.4"/></svg>';

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

const portraits = new Map();
const drawn = new Map();

/** A drawn portrait canvas (cached), for painting into card canvases. */
function portraitCanvas(skin, size) {
  const key = skin.id + size;
  if (drawn.has(key)) return drawn.get(key);
  const cv = document.createElement('canvas');
  cv.width = cv.height = size;
  drawPortrait(cv, skin, RARITY[skin.rarity].color);
  drawn.set(key, cv);
  return cv;
}

function paintPortrait(el) {
  const skin = getSkin(el.dataset.portrait);
  el.getContext('2d').drawImage(portraitCanvas(skin, el.width), 0, 0);
}

let observer = null;
/** Paint card portraits only when they scroll into view (100 at once is slow on phones). */
export function lazyPortraits(root) {
  const els = [...root.querySelectorAll('canvas[data-portrait]')];
  if (!('IntersectionObserver' in window)) { els.forEach(paintPortrait); return; }
  if (!observer) {
    observer = new IntersectionObserver((entries) => {
      for (const e of entries) {
        if (!e.isIntersecting) continue;
        paintPortrait(e.target);
        observer.unobserve(e.target);
      }
    }, { rootMargin: '160px' });
  }
  els.forEach((el) => observer.observe(el));
}

/** Pixels per CSS pixel for small canvases: sharp on 3x phone screens. */
export function hiDpi() {
  return Math.min(3, Math.max(2, Math.ceil(window.devicePixelRatio || 1)));
}

/** Markup for a lazily painted portrait. size is for a 2x screen; sharper screens get more pixels. */
export function portraitTag(skin, size = 144, cls = '') {
  const px = Math.round((size / 2) * hiDpi());
  return `<canvas data-portrait="${skin.id}" width="${px}" height="${px}" class="${cls}" aria-hidden="true"></canvas>`;
}
/** A data-URL portrait of a skin (cached). */
export function portrait(skin, size = 144) {
  const key = skin.id + size;
  if (portraits.has(key)) return portraits.get(key);
  const cv = document.createElement('canvas');
  cv.width = cv.height = size;
  drawPortrait(cv, skin, RARITY[skin.rarity].color);
  const url = cv.toDataURL('image/png');
  portraits.set(key, url);
  return url;
}

/** What a skin adds beyond its fur, in plain words. */
export function perks(skin) {
  const out = [];
  if (skin.finish === 'metal') out.push('shiny metal');
  if (skin.finish === 'glow') out.push('glow');
  if (skin.finish === 'ghost') out.push('see-through');
  if (skin.pattern && ['galaxy', 'lava', 'circuit', 'scanlines', 'lightning', 'flames', 'bones'].includes(skin.pattern.type)) out.push('glows in the dark');
  if (skin.eyes && skin.eyes.glow) out.push('glowing eyes');
  if (skin.rainbow) out.push('colour-changing');
  const names = { cape: 'cape', wings: 'wings', halo: 'halo', horns: 'horns', unihorn: 'horn', mane: 'rainbow mane', antenna: 'antennae', jetpack: 'jetpack', mask: 'mask', eyepatch: 'eyepatch', bolts: 'bolts', fin: 'fin', tailtip: 'tail tip' };
  for (const e of skin.extras || []) {
    const n = names[e.split(':')[0]];
    if (n && !out.includes(n)) out.push(n);
  }
  if (skin.aura) out.push(`${skin.aura} aura`);
  return out;
}

export function updateGolden() {
  for (const el of $$('.golden-count')) el.textContent = Save.data.golden;
  const dot = $('#mini-wardrobe .new-dot');
  if (dot) dot.hidden = !Save.data.newSkins.length;
}

/** The Skins tab of the Wardrobe. */
export function renderSkins(ui) {
  const grid = $('#shop-grid');
  grid.classList.add('skins');
  const d = Save.data;
  const owned = new Set(d.owned.skin);
  const ctx = goalContext(d);
  const filter = ui.skinFilter || 'all';
  const pv = ui.preview && ui.preview.cat === 'skin' ? ui.preview.id : null;
  const filters = [['all', 'All'], ['standard', 'Standard'], ['premium', 'Premium'], ['owned', 'Owned'], ['locked', 'Not yet']];
  let html = `<div class="skin-head"><span class="count">${owned.size}/${SKINS.length} skins</span><div class="filters" role="group" aria-label="Show">${filters.map(([k, t]) => `<button class="filter" data-filter="${k}" aria-pressed="${filter === k}">${t}</button>`).join('')}</div></div>`;
  for (const set of SETS) {
    let list = SKINS.filter((s) => s.set === set.id);
    if (filter === 'standard') list = list.filter((s) => s.tier === 'standard');
    if (filter === 'premium') list = list.filter((s) => s.tier === 'premium');
    if (filter === 'owned') list = list.filter((s) => owned.has(s.id));
    if (filter === 'locked') list = list.filter((s) => !owned.has(s.id));
    if (!list.length) continue;
    const sp = setProgress(set.id, d.owned.skin);
    const bonus = d.goldOnce.sets[set.id] ? 'set complete' : `complete it: +${RULES.goldSetComplete} golden`;
    html += `<div class="set-head"><b>${esc(set.name)}${set.tier === 'premium' ? '<span class="premium-tag">PREMIUM</span>' : ''}</b><span>${sp.have}/${sp.total} · ${bonus}</span></div>`;
    for (const s of list) {
      const own = owned.has(s.id);
      const wearing = d.equipped.skin === s.id;
      const rc = RARITY[s.rarity].color;
      let st;
      if (wearing) st = '<span class="st">Wearing</span>';
      else if (own) st = '<span class="st">Owned</span>';
      else if (s.tier === 'premium') {
        const g = goalProgress(s, ctx);
        st = `<span class="st price">${GOLDEN_ICON}${s.price}</span><span class="goalbar" title="${esc(g.text)}"><i style="width:${Math.round((g.have / g.need) * 100)}%"></i></span>`;
      } else st = `<span class="st price"><span class="i-ban"></span>${s.price}</span>`;
      const cls = ['skin-card', s.rarity, own ? '' : 'locked', wearing ? 'equipped' : '', pv === s.id ? 'previewing' : ''].filter(Boolean).join(' ');
      html += `<button class="${cls}" data-skin="${s.id}" style="--rc:${rc}" aria-label="${esc(s.name)}, ${RARITY[s.rarity].name}${own ? ', owned' : ''}">
        ${d.newSkins.includes(s.id) ? '<span class="newbadge">NEW</span>' : ''}${own ? '' : `<span class="lockbadge">${LOCK}</span>`}
        ${portraitTag(s)}
        <span class="nm">${esc(s.name)}</span><span class="rar">${RARITY[s.rarity].name}</span>${st}</button>`;
    }
  }
  grid.innerHTML = html;
  lazyPortraits(grid);
  $$('.i-ban', grid).forEach((el) => { el.outerHTML = ui.icons.banana; });
  $$('.filter', grid).forEach((b) => b.addEventListener('click', () => { ui.click(); ui.skinFilter = b.dataset.filter; renderSkins(ui); }));
  $$('.skin-card', grid).forEach((b) => b.addEventListener('click', () => {
    ui.click();
    const id = b.dataset.skin;
    const i = Save.data.newSkins.indexOf(id);
    if (i >= 0) { Save.data.newSkins.splice(i, 1); Save.persist(); b.querySelector('.newbadge')?.remove(); updateGolden(); }
    ui.tryOn('skin', id);
  }));
}

/** The bar above the grid for the skin being tried on. */
export function renderSkinAction(ui, bar, id) {
  const s = getSkin(id);
  const d = Save.data;
  const own = Save.owns('skin', id);
  const wearing = d.equipped.skin === id;
  const p = perks(s);
  const head = `<b>${esc(s.name)}</b> · ${RARITY[s.rarity].name}${s.tier === 'premium' ? ' premium' : ''}. ${esc(s.desc || '')}${p.length ? `<span class="perks">Includes: ${esc(p.join(', '))}</span>` : ''}`;
  let goal = '';
  let btns = '';
  if (wearing) btns = '<button class="btn small" disabled>Wearing</button>';
  else if (own) btns = '<button class="btn small primary" id="skin-wear">Wear it</button>';
  else if (s.tier === 'premium') {
    const g = goalProgress(s, goalContext(d));
    goal = `<span class="goal">Free when you ${esc(g.text.charAt(0).toLowerCase() + g.text.slice(1))}: ${g.have.toLocaleString()}/${g.need.toLocaleString()}</span>`;
    const can = d.golden >= s.price;
    btns = `<button class="btn small ${can ? 'primary' : ''}" id="skin-buy" ${can ? '' : 'disabled'}>Unlock now <span class="cost">${GOLDEN_ICON}${s.price}</span></button>`;
    if (!can) goal += `<span class="goal">You have ${d.golden} golden bananas. Tap the golden chip to swap bananas for more.</span>`;
  } else {
    const can = d.bananas >= s.price;
    btns = `<button class="btn small ${can ? 'primary' : ''}" id="skin-buy" ${can ? '' : 'disabled'}>Buy <span class="cost">${ui.icons.banana}${s.price}</span></button>`;
    goal = `<span class="goal">${can ? `You have ${d.bananas}; ${d.bananas - s.price} left after.` : `You need ${s.price - d.bananas} more bananas.`}</span>`;
  }
  bar.innerHTML = `<p>${head}${goal}</p><div class="btns">${btns}</div>`;
  const wear = $('#skin-wear');
  if (wear) wear.addEventListener('click', () => {
    ui.click();
    Save.equip('skin', id);
    ui.preview = null;
    ui.app.applyLook(d.equipped);
    ui.renderShop();
    ui.toast(`Now wearing ${s.name}.`);
  });
  const buy = $('#skin-buy');
  if (buy) buy.addEventListener('click', () => {
    if (!Save.buySkin(id)) return;
    Save.equip('skin', id);
    ui.audio.sfx('buy');
    ui.preview = null;
    ui.app.applyLook(d.equipped);
    ui.app.monkey.play('CHEER', 1.4);
    ui.toast(s.currency === 'golden' ? `Unlocked ${s.name} for ${s.price} golden bananas.` : `Bought ${s.name} for ${s.price} bananas.`);
    const res = Save.checkSkinGoals();
    ui.renderShop();
    ui.updateBananas(true);
    if (res.skins.length || res.golden) showUnlocks(ui, res);
  });
}

/** Swap bananas for golden bananas. */
export function showExchange(ui) {
  const render = () => {
    const d = Save.data;
    const rate = RULES.exchangeRate;
    const opts = [1, 5, 10];
    $('#exchange-card').innerHTML = `
      <div class="eyebrow">Golden bananas</div>
      <h2 id="exchange-title">Swap bananas</h2>
      <p>Golden bananas unlock premium skins and gear early. You earn them by playing (see How it works) or swap bananas for them here${ui.app.billing && ui.app.billing.mode === 'native' ? ', and the Shop sells packs' : ''}.</p>
      <div class="exchange-rate">${ui.icons.banana} ${rate} = 1 ${GOLDEN_ICON}</div>
      <p class="note" style="color:var(--cream-dim);font-size:14px">You have ${d.bananas} bananas and ${d.golden} golden bananas.</p>
      <div class="actions">
        ${opts.map((n) => `<button class="btn ${d.bananas >= n * rate ? 'primary' : ''}" data-swap="${n}" ${d.bananas >= n * rate ? '' : 'disabled'}>Swap ${(n * rate).toLocaleString()} for ${n} ${GOLDEN_ICON.replace('<svg ', '<svg style="width:22px;height:22px" ')}</button>`).join('')}
        ${ui.app.billing && ui.app.billing.mode !== 'none' ? '<button class="btn" id="exchange-shop">More in the Shop</button>' : ''}
        <button class="btn ghost" id="exchange-close">Close</button>
      </div>`;
    $$('[data-swap]', $('#exchange-card')).forEach((b) => b.addEventListener('click', () => {
      const n = Number(b.dataset.swap);
      if (Save.exchange(n)) {
        ui.audio.sfx('coin');
        ui.toast(`Swapped ${n * rate} bananas for ${n} golden banana${n === 1 ? '' : 's'}.`);
        ui.updateBananas(true);
        render();
        if (ui.current === 'shop') ui.renderShopAction();
      }
    }));
    $('#exchange-close').addEventListener('click', () => { ui.click(); ui.closeOverlay('ov-exchange'); });
    const shopBtn = $('#exchange-shop');
    if (shopBtn) shopBtn.addEventListener('click', () => { ui.click(); ui.closeOverlay('ov-exchange'); ui.show('store'); });
  };
  render();
  ui.openOverlay('ov-exchange');
}

/** "New skin unlocked!" card. res = { skins, golden, sets } from Save.checkSkinGoals(). */
export function showUnlocks(ui, res) {
  if (!res || (!res.skins.length && !res.golden)) return;
  const first = res.skins[0];
  const ctx = goalContext(Save.data);
  $('#unlock-card').innerHTML = `
    <div class="eyebrow">${res.skins.length ? 'Earned by playing' : 'Set complete'}</div>
    <h2 id="unlock-title">${res.skins.length === 1 ? 'New skin unlocked!' : res.skins.length > 1 ? `${res.skins.length} new skins unlocked!` : 'Bonus golden bananas!'}</h2>
    ${res.skins.length ? `<div class="unlock-list">${res.skins.map((s) => `<figure><img src="${portrait(s)}" alt=""><figcaption>${esc(s.name)}</figcaption><small>${esc(GOALS[s.goal] ? GOALS[s.goal].text : '')}</small></figure>`).join('')}</div>` : ''}
    ${res.golden ? `<p>Completed ${res.sets.map((x) => esc(x.name)).join(', ')}: +${res.golden} golden bananas.</p>` : ''}
    <div class="actions">
      ${first ? `<button class="btn primary big" id="unlock-wear">Wear ${esc(first.name)}</button>` : ''}
      <button class="btn ghost" id="unlock-close">${first ? 'Later' : 'Nice!'}</button>
    </div>`;
  void ctx;
  ui.openOverlay('ov-unlock');
  ui.audio.sfx('level');
  const wear = $('#unlock-wear');
  if (wear) wear.addEventListener('click', () => {
    Save.equip('skin', first.id);
    const i = Save.data.newSkins.indexOf(first.id);
    if (i >= 0) Save.data.newSkins.splice(i, 1);
    Save.persist();
    ui.app.applyLook(Save.data.equipped);
    ui.app.monkey.play('CHEER', 1.4);
    ui.closeOverlay('ov-unlock');
    if (ui.current === 'shop') ui.renderShop();
    updateGolden();
  });
  $('#unlock-close').addEventListener('click', () => { ui.click(); ui.closeOverlay('ov-unlock'); updateGolden(); });
}

/** Rows for How it works. */
export function skinsHelp(ui) {
  const prem = SKINS.filter((s) => s.tier === 'premium');
  const std = SKINS.filter((s) => s.tier === 'standard');
  const rows = prem.map((s) => `<tr><td><div class="move-cell">${portraitTag(s, 72, 'help-portrait')}${esc(s.name)}</div></td><td>${RARITY[s.rarity].name}</td><td class="wrap">${esc(GOALS[s.goal].text)}</td><td>${s.price}</td></tr>`).join('');
  const minStd = Math.min(...std.filter((s) => s.price > 0).map((s) => s.price));
  const maxStd = Math.max(...std.map((s) => s.price));
  return `
    <h3>Skins</h3>
    <p>There are ${SKINS.length} skins in ${SETS.length} sets. Skins are looks only: no skin changes timing, scoring or difficulty, and you can try any skin on before you get it.</p>
    <ul>
      <li><b>${std.length} standard skins</b> (Common and Rare) cost ${minStd}-${maxStd} bananas. Cocoa is free.</li>
      <li><b>${prem.length} premium skins</b> (Epic and Legendary) add things like shiny metal, glow-in-the-dark patterns, wings, capes, halos and particle auras. Each one unlocks <b>for free</b> when you reach its goal, or <b>early</b> with golden bananas.</li>
      <li>Own every skin in a set to get +${RULES.goldSetComplete} golden bananas (once per set).</li>
    </ul>
    <h3>Golden bananas</h3>
    <ul>
      <li>+${RULES.goldFirstThreeStar} the first time each level gets 3 stars.</li>
      <li>+${RULES.goldWorldClear} the first time you clear each world's showdown (level 10, 20, 30 and 40).</li>
      <li>+1 for every ${RULES.goldEndlessEvery} rounds you clear in one Endless run.</li>
      <li>+${RULES.goldSetComplete} for each completed skin set.</li>
      <li>Swap ${RULES.exchangeRate} bananas for 1 golden banana in the Wardrobe (tap the golden chip).</li>
      <li>In the iPhone and Android apps the Shop also sells golden banana packs. You never need them: every premium skin keeps its free play goal. Every golden banana earned, bought or spent is in Stats > Banana history.</li>
    </ul>
    <h3>All premium skins</h3>
    <div class="table-wrap"><table><thead><tr><th>Skin</th><th>Rarity</th><th>Free when you...</th><th>Or golden</th></tr></thead><tbody>${rows}</tbody></table></div>`;
}

// ---------------------------------------------------------------- gear thumbnails

let gearObserver = null;
/** Paint 3D gear thumbnails when their cards scroll into view. */
export function lazyGearThumbs(root, kit) {
  const els = [...root.querySelectorAll('canvas[data-gear]')];
  if (!els.length) return;
  const paint = (el) => {
    const [slot, id] = el.dataset.gear.split(':');
    gearThumb(el, slot, id, kit);
  };
  if (!('IntersectionObserver' in window)) { els.forEach(paint); return; }
  if (gearObserver) gearObserver.disconnect();
  gearObserver = new IntersectionObserver((entries) => {
    for (const e of entries) {
      if (!e.isIntersecting) continue;
      paint(e.target);
      gearObserver.unobserve(e.target);
    }
  }, { rootMargin: '120px' });
  els.forEach((el) => gearObserver.observe(el));
}

// ---------------------------------------------------------------- outfits

export const OUTFIT_SLOTS = 6;

function outfitName(look) {
  const skin = getSkin(look.skin).name;
  for (const k of ['hat', 'back', 'eyes', 'hands', 'neck', 'feet', 'face', 'aura']) {
    const v = look[k];
    if (v && v !== 'none') {
      const it = getItem(k, v);
      return `${skin} + ${it ? it.name : v}`;
    }
  }
  return skin;
}

/** Wardrobe > Outfits: save and switch complete looks. */
export function renderOutfits(ui) {
  const grid = $('#shop-grid');
  grid.classList.remove('skins');
  const list = Save.data.outfits;
  let html = '<div class="skin-head"><span class="count">Outfits</span><span class="note" style="font-size:13px;color:var(--cream-dim)">Save your whole look (skin and every item) and put it back on with one tap.</span></div>';
  for (let i = 0; i < OUTFIT_SLOTS; i++) {
    const o = list[i];
    if (o) {
      const items = Object.entries(o.look).filter(([k, v]) => !['skin', 'flair', 'stage'].includes(k) && v && v !== 'none').length;
      const wearing = JSON.stringify(o.look) === JSON.stringify(Save.data.equipped);
      html += `<div class="outfit${wearing ? ' equipped' : ''}">${portraitTag(getSkin(o.look.skin), 144)}<div class="o-text"><b>${esc(o.name)}</b><small>${esc(getSkin(o.look.skin).name)} skin · ${items} item${items === 1 ? '' : 's'}</small></div>
        <div class="o-btns"><button class="btn small primary" data-wear="${i}" ${wearing ? 'disabled' : ''}>${wearing ? 'Wearing' : 'Wear'}</button><button class="btn small" data-save="${i}">Save here</button><button class="btn small ghost" data-del="${i}" aria-label="Delete outfit ${i + 1}">Delete</button></div></div>`;
    } else {
      html += `<div class="outfit empty"><div class="o-text"><b>Empty slot ${i + 1}</b><small>Saves what the monkey is wearing now.</small></div><div class="o-btns"><button class="btn small primary" data-save="${i}">Save current look</button></div></div>`;
    }
  }
  grid.innerHTML = html;
  lazyPortraits(grid);
  grid.querySelectorAll('[data-save]').forEach((b) => b.addEventListener('click', () => {
    ui.click();
    const i = Number(b.dataset.save);
    const look = { ...Save.data.equipped };
    Save.data.outfits[i] = { name: outfitName(look), look, t: Date.now() };
    Save.persist();
    ui.toast(`Saved as outfit ${i + 1}.`);
    renderOutfits(ui);
  }));
  grid.querySelectorAll('[data-wear]').forEach((b) => b.addEventListener('click', () => {
    ui.click();
    const o = Save.data.outfits[Number(b.dataset.wear)];
    let missing = 0;
    for (const [slot, id] of Object.entries(o.look)) {
      if (slot === 'stage' && id === 'auto') { Save.data.equipped.stage = 'auto'; continue; }
      if (Save.owns(slot, id)) Save.data.equipped[slot] = id;
      else missing++;
    }
    Save.persist();
    ui.preview = null;
    ui.app.applyLook(Save.data.equipped);
    ui.app.monkey.play('CHEER', 1.4);
    ui.toast(missing ? `Put on what you own (${missing} item${missing === 1 ? '' : 's'} not owned).` : `Wearing ${o.name}.`);
    renderOutfits(ui);
  }));
  grid.querySelectorAll('[data-del]').forEach((b) => b.addEventListener('click', async () => {
    const i = Number(b.dataset.del);
    const ok = await ui.confirm({ title: 'Delete this outfit?', text: 'Only the saved outfit is removed. You keep every item.', ok: 'Delete', danger: true });
    if (!ok) return;
    Save.data.outfits[i] = null;
    Save.persist();
    renderOutfits(ui);
  }));
}
