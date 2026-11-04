// The Shop screen, the buy sheet (with the grown-up check and the monthly
// limit), purchase results, and the How it works rows for the Shop.
import { PRODUCTS, GROUPS, productsIn, getProduct, bonusPercent, bestValueId, separateValue, spentThisMonth, OWNED_REFUND_GOLDEN, SPEND_LIMITS } from './store.js';
import { getSkin } from './skins.js';
import { getItem } from './shop.js';
import { Save } from './save.js';
import { GOLDEN_ICON, portraitTag, lazyPortraits, lazyGearThumbs, updateGolden } from './wardrobe.js';

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const $ = (sel, root = document) => root.querySelector(sel);
const n = (x) => x.toLocaleString();

const skinPrice = (id) => ({ golden: getSkin(id).currency === 'golden' ? getSkin(id).price : 0, bananas: getSkin(id).currency === 'banana' ? getSkin(id).price : 0 });
const itemPrice = (g) => {
  const [slot, id] = g.split(':');
  const it = getItem(slot, id);
  return { golden: it && it.currency === 'golden' ? it.price : 0, bananas: it && it.currency !== 'golden' ? it.price : 0 };
};

function stack(icon, count) {
  // a little pile of bananas: more for bigger packs
  const pos = [[18, 22], [6, 26], [30, 26], [12, 12], [26, 12], [18, 4]].slice(0, count);
  return `<span class="pile">${pos.map(([x, y]) => `<span style="left:${x}px;top:${y}px">${icon}</span>`).join('')}</span>`;
}

function contents(ui, p) {
  const bits = [];
  if (p.grants.bananas) bits.push(`<span class="chipline">${ui.icons.banana}${n(p.grants.bananas)}</span>`);
  if (p.grants.golden) bits.push(`<span class="chipline">${GOLDEN_ICON}${n(p.grants.golden)}</span>`);
  const thumbs = [
    ...p.grants.skins.map((id) => `<span class="thumb" title="${esc(getSkin(id).name)}">${portraitTag(getSkin(id), 96)}</span>`),
    ...p.grants.gear.map((g) => {
      const [slot, id] = g.split(':');
      const it = getItem(slot, id);
      return slot === 'aura' ? `<span class="thumb aura" title="${esc(it.name)}">${esc(it.name)}</span>` : `<span class="thumb" title="${esc(it ? it.name : id)}"><canvas data-gear="${slot}:${id}" width="96" height="96"></canvas></span>`;
    }),
  ];
  return `${bits.length ? `<div class="chips-row">${bits.join('')}</div>` : ''}${thumbs.length ? `<div class="thumbs">${thumbs.join('')}</div>` : ''}`;
}

function priceButton(ui, p) {
  const b = ui.app.billing;
  const owned = p.type === 'nonconsumable' && Save.data.ownedProducts.includes(p.id);
  if (owned) return '<button class="btn small" disabled>Owned</button>';
  const info = b.priceOf(p.id);
  const price = info ? info.price : `$${p.usd.toFixed(2)}`;
  if (!b.canBuy) return `<span class="price-tag">${esc(price)}</span>`;
  return `<button class="btn small primary" data-buy="${p.id}">${esc(price)}</button>`;
}

export function renderStore(ui) {
  const b = ui.app.billing;
  const body = $('#store-body');
  const banner = b.mode === 'test'
    ? '<div class="store-banner test"><b>TEST MODE.</b> No money is charged. Purchases here are pretend, for trying the Shop.</div>'
    : b.mode === 'none'
      ? '<div class="store-banner">Purchases work in the iPhone and Android apps. In the browser you can look around. Everything here can also be earned by playing.</div>'
      : `<div class="store-banner">Prices come from the ${esc(b.storeName())} in your currency. ${Save.settings.parentGate ? 'A grown-up check comes before each purchase.' : ''}</div>`;
  let html = banner;
  for (const g of GROUPS) {
    let list = productsIn(g.id);
    if (g.id === 'deals') list = list.filter((p) => !(p.once && Save.data.ownedProducts.includes(p.id)));
    if (!list.length) continue;
    html += `<h3 class="store-h">${esc(g.name)}</h3>`;
    if (g.id === 'bananas' || g.id === 'golden') {
      const best = bestValueId(g.id);
      html += `<div class="pack-grid">${list.map((p, i) => {
        const bonus = bonusPercent(p);
        const icon = g.id === 'golden' ? GOLDEN_ICON : ui.icons.banana;
        const amount = g.id === 'golden' ? p.grants.golden : p.grants.bananas;
        return `<div class="pack${p.id === best ? ' best' : ''}">${p.id === best ? '<span class="tag">Best value</span>' : ''}${stack(icon, i + 2)}<b>${n(amount)}</b><small>${esc(p.title)}</small>${bonus > 0 ? `<span class="bonus">+${bonus}% more</span>` : '<span class="bonus muted">base price</span>'}${priceButton(ui, p)}</div>`;
      }).join('')}</div>`;
    } else {
      html += list.map((p) => {
        const val = separateValue(p, skinPrice, itemPrice);
        const worth = p.grants.skins.length || p.grants.gear.length
          ? `<small class="worth">Separately: ${[val.golden ? `${n(val.golden)} golden` : '', val.bananas ? `${n(val.bananas)} bananas` : ''].filter(Boolean).join(' + ')}${p.group !== 'deals' ? ` · items you already own give +${OWNED_REFUND_GOLDEN} golden each` : ''}</small>` : '';
        const ownedCount = p.grants.skins.filter((id) => Save.owns('skin', id)).length + p.grants.gear.filter((x) => { const [s, i] = x.split(':'); return Save.owns(s, i); }).length;
        const total = p.grants.skins.length + p.grants.gear.length;
        return `<div class="offer"><div class="offer-top"><div><b>${esc(p.title)}</b><p>${esc(p.desc)}</p></div>${priceButton(ui, p)}</div>${contents(ui, p)}${worth}${total && ownedCount ? `<small class="worth">You already own ${ownedCount} of ${total}.</small>` : ''}</div>`;
      }).join('');
    }
  }
  const spent = spentThisMonth(Save.data.purchases);
  const spentTxt = Object.keys(spent).length ? Object.entries(spent).map(([c, v]) => `${v.toFixed(2)} ${c}`).join(', ') : 'nothing';
  const limit = Save.settings.spendLimit;
  html += `<div class="store-foot">
    <p>This month you've spent ${esc(spentTxt)}${limit ? ` of your ${limit} limit` : ''}. Change the limit or the grown-up check in Settings > Purchases.</p>
    <div class="btn-line"><button class="btn small" id="store-restore">Restore purchases</button><button class="btn small ghost" data-go-stats>Purchase history</button></div>
    <p class="fineprint">Payments are handled by Apple or Google; the game never sees card details. Refunds go through the store you bought from. No ads, no random boxes, no timers.</p>
  </div>`;
  body.innerHTML = html;
  lazyPortraits(body);
  lazyGearThumbs(body, { gradient: ui.app.monkey.gradient, outlineMat: ui.app.monkey.outlineMat });
  body.querySelectorAll('[data-buy]').forEach((btn) => btn.addEventListener('click', () => { ui.click(); openBuy(ui, btn.dataset.buy); }));
  $('#store-restore').addEventListener('click', async () => {
    ui.click();
    const r = await b.restore();
    ui.toast(r.ok ? (r.test ? 'Test mode: nothing to restore.' : 'Asked the store to restore your purchases.') : r.error);
  });
  body.querySelector('[data-go-stats]').addEventListener('click', () => { ui.click(); ui.show('stats'); });
  ui.updateBananas();
}

// ---------------------------------------------------------------- buying

function gateQuestion() {
  const a = 3 + Math.floor(Math.random() * 6);
  const b2 = 4 + Math.floor(Math.random() * 6);
  const right = a * b2;
  const opts = new Set([right]);
  while (opts.size < 3) opts.add(right + (Math.floor(Math.random() * 9) - 4 || 5));
  return { q: `${a} × ${b2}`, right, opts: [...opts].sort(() => Math.random() - 0.5) };
}

export function openBuy(ui, id) {
  const p = getProduct(id);
  const b = ui.app.billing;
  const info = b.priceOf(id);
  const card = $('#buy-card');
  const over = Save.overLimit(info);
  let gatePassed = !Save.settings.parentGate;
  const render = (msg = '') => {
    let gate = '';
    if (!gatePassed && !over) {
      const g = gateQuestion();
      card.dataset.right = g.right;
      gate = `<div class="gate"><b>Grown-ups only</b><p>What is ${g.q}?</p><div class="btn-row three">${g.opts.map((o) => `<button class="btn small" data-gate="${o}">${o}</button>`).join('')}</div></div>`;
    }
    card.innerHTML = `
      <div class="eyebrow">${b.mode === 'test' ? 'Test mode: no money is charged' : 'Shop'}</div>
      <h2 id="buy-title">${esc(p.title)}</h2>
      <p>${esc(p.desc)}</p>
      ${contents(ui, p)}
      ${p.type === 'nonconsumable' ? '<p class="note" style="color:var(--cream-dim);font-size:13px">Bought once, kept for good. "Restore purchases" brings it back on a new phone.</p>' : ''}
      ${over ? `<p class="warn">This would go over your monthly limit of ${Save.settings.spendLimit}. A grown-up can change it in Settings > Purchases.</p>` : ''}
      ${msg ? `<p class="warn">${esc(msg)}</p>` : ''}
      ${gate}
      <div class="actions">
        <button class="btn primary big" id="buy-go" ${gatePassed && !over ? '' : 'disabled'}>Buy for ${esc(info ? info.price : `$${p.usd.toFixed(2)}`)}</button>
        <button class="btn ghost" id="buy-cancel">Cancel</button>
      </div>
      <p class="fineprint">${b.mode === 'test' ? 'Pretend purchase for testing.' : `Charged by the ${esc(b.storeName())} to the account on this device.`}</p>`;
    lazyPortraits(card);
    lazyGearThumbs(card, { gradient: ui.app.monkey.gradient, outlineMat: ui.app.monkey.outlineMat });
    card.querySelectorAll('[data-gate]').forEach((btn) => btn.addEventListener('click', () => {
      if (Number(btn.dataset.gate) === Number(card.dataset.right)) { gatePassed = true; render(); }
      else render('Not quite. Ask a grown-up to help.');
    }));
    $('#buy-cancel').addEventListener('click', () => { ui.click(); ui.closeOverlay('ov-buy'); });
    $('#buy-go').addEventListener('click', async () => {
      const go = $('#buy-go');
      go.disabled = true;
      go.textContent = 'Waiting for the store...';
      const r = await b.buy(id);
      if (r.cancelled) { ui.closeOverlay('ov-buy'); return; }
      if (!r.ok) { render(r.error || 'The purchase did not go through.'); return; }
      if (r.pending) { go.textContent = 'Confirming...'; }
    });
  };
  render();
  ui.openOverlay('ov-buy');
}

/** Called when the store confirms a purchase (after Save.deliverPurchase). */
export function purchaseDone(ui, p, got) {
  ui.audio.sfx('buy');
  ui.updateBananas(true);
  updateGolden();
  const lines = [];
  if (got.bananas) lines.push(`${n(got.bananas)} bananas`);
  if (got.golden) lines.push(`${n(got.golden)} golden bananas`);
  if (got.skins.length) lines.push(got.skins.map((id) => `${getSkin(id).name} skin`).join(', '));
  if (got.gear.length) lines.push(got.gear.map((g) => { const [s, i] = g.split(':'); const it = getItem(s, i); return it ? it.name : i; }).join(', '));
  if (got.refunded) lines.push(`+${got.refunded * OWNED_REFUND_GOLDEN} golden for ${got.refunded} item${got.refunded === 1 ? '' : 's'} you already had`);
  const card = $('#buy-card');
  const firstSkin = got.skins[0];
  card.innerHTML = `
    <div class="eyebrow">Thank you!</div>
    <h2 id="buy-title">${esc(p.title)}</h2>
    <p>Added: ${esc(lines.join('; '))}.</p>
    <div class="actions">
      ${firstSkin ? `<button class="btn primary big" id="buy-wear">Wear ${esc(getSkin(firstSkin).name)}</button>` : ''}
      <button class="btn ${firstSkin ? 'ghost' : 'primary big'}" id="buy-done">${firstSkin ? 'Later' : 'Great!'}</button>
    </div>`;
  if (!$('#ov-buy').classList.contains('show')) ui.openOverlay('ov-buy');
  const wear = $('#buy-wear');
  if (wear) wear.addEventListener('click', () => {
    const look = { ...Save.data.equipped, skin: firstSkin };
    for (const g of got.gear) { const [s, i] = g.split(':'); look[s] = i; }
    Object.assign(Save.data.equipped, look);
    Save.persist();
    ui.app.applyLook(Save.data.equipped);
    ui.app.monkey.play('CHEER', 1.4);
    ui.closeOverlay('ov-buy');
  });
  $('#buy-done').addEventListener('click', () => { ui.click(); ui.closeOverlay('ov-buy'); if (ui.current === 'store') renderStore(ui); });
  ui.app.monkey.play('CHEER', 1.4);
  if (ui.current === 'store') setTimeout(() => renderStore(ui), 50);
  if (ui.current === 'shop') ui.renderShop();
}

/** How it works: the Shop section. */
export function storeHelp() {
  const rows = PRODUCTS.map((p) => {
    const what = [p.grants.bananas ? `${n(p.grants.bananas)} bananas` : '', p.grants.golden ? `${n(p.grants.golden)} golden` : '', ...p.grants.skins.map((id) => getSkin(id).name + ' skin'), ...p.grants.gear.map((g) => { const [s, i] = g.split(':'); const it = getItem(s, i); return it ? it.name : i; })].filter(Boolean).join(', ');
    return `<tr><td>${esc(p.title)}</td><td class="wrap">${esc(what)}</td><td>$${p.usd.toFixed(2)}</td><td>${p.type === 'consumable' ? 'Any time' : 'Once'}</td></tr>`;
  }).join('');
  return `
    <h3>The Shop (optional)</h3>
    <p>In the iPhone and Android apps you can buy bananas, golden bananas, themed bundles and premium skin sets with real money. You never have to: everything can also be earned by playing.</p>
    <ul>
      <li>Prices are $0.99 to $9.99 (US prices; Apple and Google set the price in your country). Packs can be bought again whenever you like; bundles and sets are bought once and kept.</li>
      <li>"+N% more" compares a pack with the smallest pack of the same kind, and only the pack with the most per dollar says "Best value".</li>
      <li>No random boxes, no timers, no ads. You see exactly what each item contains before you buy it.</li>
      <li>If a bundle or set has something you already own, you get ${OWNED_REFUND_GOLDEN} golden bananas for each of those instead.</li>
      <li>A grown-up check (a times-table question) comes before each purchase, and you can set a monthly limit (${SPEND_LIMITS.filter(Boolean).join(', ')} in your currency) in Settings > Purchases.</li>
      <li>Payments are handled by Apple or Google; the game never sees card details. Refunds go through the store you bought from. Every purchase is listed in Stats.</li>
    </ul>
    <div class="table-wrap"><table><thead><tr><th>Item</th><th>Contains</th><th>US price</th><th>Buy</th></tr></thead><tbody>${rows}</tbody></table></div>`;
}
