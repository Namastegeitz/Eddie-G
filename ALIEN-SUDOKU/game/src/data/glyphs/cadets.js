/* Star Cadets lineup: nine first-year cadets of a deep-space decoding academy
   whose training archive is Earth's '80s and '90s broadcasts, so they dress
   like it. Head-and-shoulders portraits, all in the same navy cadet collar
   with a gold academy star pin; each wears one signature retro item.
   Light comes from the top-left; every id is prefixed "cad-". */
const f = (v) => +v.toFixed(2);
const rg = (id, a, b, c) => `<radialGradient id="cad-${id}" cx=".36" cy=".3" r=".85"><stop offset="0" stop-color="${a}"/><stop offset=".5" stop-color="${b}"/><stop offset="1" stop-color="${c}"/></radialGradient>`;
const lg = (id, a, b, c, x2 = '.45') => `<linearGradient id="cad-${id}" x1="0" y1="0" x2="${x2}" y2="1"><stop offset="0" stop-color="${a}"/><stop offset=".5" stop-color="${b}"/><stop offset="1" stop-color="${c}"/></linearGradient>`;
const NAVY = '#0A0E2C';

// five-point star
const star = (cx, cy, R) => {
  let d = '';
  for (let k = 0; k < 10; k++) {
    const a = (-90 + k * 36) * Math.PI / 180, r = k % 2 ? R * .46 : R;
    d += `${k ? 'L' : 'M'}${f(cx + r * Math.cos(a))} ${f(cy + r * Math.sin(a))}`;
  }
  return d + 'Z';
};

// the shared uniform: neck, navy tunic, piped collar, gold star pin
const uniform = (skin, ink, tunic = 'navy', extra = '') =>
  `<path d="M26.5 38V49L32 55L37.5 49V38Z" fill="url(#cad-${skin})" stroke="${ink}" stroke-width="2"/>`
  + `<path d="M26.5 41Q32 47 37.5 41V49L32 55L26.5 49Z" fill="#000" opacity=".22"/>`
  + `<path d="M6 62.5C6 55.5 11 51.5 19.5 49.5L26 48.3L32 55L38 48.3L44.5 49.5C53 51.5 58 55.5 58 62.5Z" fill="url(#cad-${tunic})" stroke="${NAVY}" stroke-width="2.2" stroke-linejoin="round"/>`
  + `<path d="M9.8 59Q11.2 54 18.5 52" fill="none" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".3"/>`
  + extra + collar() + pin();
const LAPELS = 'M26 48.3L32 55L28.6 61.6L16.8 52.2Q20.6 49.2 26 48.3ZM38 48.3L32 55L35.4 61.6L47.2 52.2Q43.4 49.2 38 48.3Z';
const collar = () => `<path d="${LAPELS}" fill="none" stroke="${NAVY}" stroke-width="3.6" stroke-linejoin="round"/>`
  + `<path d="${LAPELS}" fill="url(#cad-collar)" stroke="#8EA6FF" stroke-width="1.3" stroke-linejoin="round"/>`;
const pin = (x = 22.8, y = 54.3) => `<path d="${star(x, y, 3.9)}" fill="url(#cad-gold)" stroke="#6E4A04" stroke-width="1.1" stroke-linejoin="round"/>`
  + `<circle cx="${f(x - 1)}" cy="${f(y - 1.2)}" r=".8" fill="#fff" opacity=".9"/>`;

// scale a group about (x, y)
const sc = (x, y, k, body) => `<g transform="matrix(${k} 0 0 ${k} ${f(x * (1 - k))} ${f(y * (1 - k))})">${body}</g>`;
// head: slightly wider at the temples than the chin
const head = (cx, cy, rx, t, b, skin, ink) => {
  const k = .56;
  return `<path d="M${cx} ${cy - t}C${f(cx + rx * k)} ${cy - t} ${cx + rx} ${f(cy - t * k)} ${cx + rx} ${cy}C${cx + rx} ${f(cy + b * k)} ${f(cx + rx * .48)} ${cy + b} ${cx} ${cy + b}C${f(cx - rx * .48)} ${cy + b} ${cx - rx} ${f(cy + b * k)} ${cx - rx} ${cy}C${cx - rx} ${f(cy - t * k)} ${f(cx - rx * k)} ${cy - t} ${cx} ${cy - t}Z" fill="url(#cad-${skin})" stroke="${ink}" stroke-width="2.3"/>`
    + `<ellipse cx="${f(cx - rx * .45)}" cy="${f(cy - t * .58)}" rx="${f(rx * .36)}" ry="${f(t * .17)}" transform="rotate(-30 ${f(cx - rx * .45)} ${f(cy - t * .58)})" fill="#fff" opacity=".55"/>`;
};
// big friendly eye; (lx, ly) nudges where it looks
const eye = (x, y, ink, lx = .5, ly = .8, s = 1) =>
  `<ellipse cx="${x}" cy="${y}" rx="${f(4.4 * s)}" ry="${f(5.4 * s)}" fill="#fff" stroke="${ink}" stroke-width="1.7"/>`
  + `<ellipse cx="${f(x + lx)}" cy="${f(y + ly)}" rx="${f(3.1 * s)}" ry="${f(3.9 * s)}" fill="url(#cad-iris)"/>`
  + `<circle cx="${f(x + lx - 1 * s)}" cy="${f(y + ly - 1.5 * s)}" r="${f(1.45 * s)}" fill="#fff"/>`
  + `<circle cx="${f(x + lx + 1.3 * s)}" cy="${f(y + ly + 1.7 * s)}" r="${f(.65 * s)}" fill="#fff" opacity=".85"/>`;
const smile = (x, y, w, ink, h = 5.2) =>
  `<path d="M${f(x - w)} ${y}Q${x} ${f(y + 1.8)} ${f(x + w)} ${y}Q${f(x + w * .8)} ${f(y + h)} ${x} ${f(y + h)}Q${f(x - w * .8)} ${f(y + h)} ${f(x - w)} ${y}Z" fill="#3A0C24" stroke="${ink}" stroke-width="1.6" stroke-linejoin="round"/>`
  + `<path d="M${f(x - w * .55)} ${f(y + h - 1.2)}Q${x} ${f(y + h - 3.4)} ${f(x + w * .55)} ${f(y + h - 1.2)}Q${x} ${f(y + h + .3)} ${f(x - w * .55)} ${f(y + h - 1.2)}Z" fill="#FF7FA6"/>`;
const blush = (x, y) => `<ellipse cx="${x}" cy="${y}" rx="3.3" ry="2" fill="#FF7FB0" opacity=".5"/>`;
const face = (cx, cy, ink, o = {}) => {
  const sp = o.sp || 6.6, ey = cy + (o.ey || 0), lx = o.lx ?? .5, ly = o.ly ?? .8;
  return eye(f(cx - sp), ey, ink, lx, ly) + eye(f(cx + sp), ey, ink, lx, ly)
    + blush(f(cx - sp - 4.6), f(ey + 6.4)) + blush(f(cx + sp + 4.6), f(ey + 6.4))
    + (o.mouth ?? smile(cx, f(ey + 7), 5, ink));
};
// antenna: stalk from (x1,y1) bending through (qx,qy) to a ball at (x2,y2)
const antenna = (x1, y1, qx, qy, x2, y2, ink, lite, tip) =>
  `<path d="M${x1} ${y1}Q${qx} ${qy} ${x2} ${y2}" fill="none" stroke="${ink}" stroke-width="4.4" stroke-linecap="round"/>`
  + `<path d="M${x1} ${y1}Q${qx} ${qy} ${x2} ${y2}" fill="none" stroke="${lite}" stroke-width="2" stroke-linecap="round"/>`
  + `<circle cx="${x2}" cy="${y2}" r="3.3" fill="url(#cad-${tip})" stroke="${ink}" stroke-width="1.8"/><circle cx="${f(x2 - 1.1)}" cy="${f(y2 - 1.1)}" r="1.1" fill="#fff"/>`;
// ear fin on the side of the head at (x,y); dir -1 = left, 1 = right
const fin = (x, y, dir, skin, ink) => {
  const X = (v) => f(x - dir * v);
  return `<path d="M${X(1)} ${f(y - 5)}Q${X(-5.6)} ${f(y - 10)} ${X(-9)} ${f(y - 6.2)}Q${X(-7.6)} ${f(y + 1.6)} ${X(1)} ${f(y + 4.6)}Z" fill="url(#cad-${skin})" stroke="${ink}" stroke-width="2" stroke-linejoin="round"/>`
    + `<path d="M${X(-1)} ${f(y - 2)}Q${X(-4.2)} ${f(y - 4.6)} ${X(-6.4)} ${f(y - 4.8)}M${X(-1)} ${f(y + 1.4)}Q${X(-4.2)} ${f(y - .4)} ${X(-6.2)} ${f(y - .2)}" fill="none" stroke="${ink}" stroke-width="1.2" stroke-linecap="round" opacity=".55"/>`;
};

// skins: [gradient id, light, mid, dark, ink, antenna-stalk highlight]
const SK = {
  pink: ['#FFD6EC', '#FF4FAC', '#B3106A', '#6A0A3E', '#FFA6D4'],
  teal: ['#DDFBFF', '#3AE4FF', '#0A93B5', '#064A5E', '#9DF2FF'],
  yel: ['#FFFDE6', '#FFE94F', '#D6A400', '#6E4E00', '#FFF39A'],
  pur: ['#F0E4FF', '#B07AFF', '#6230C8', '#33137A', '#D6B8FF'],
  tan: ['#FFE6CA', '#FF9640', '#C24E06', '#6B2A04', '#FFC48E'],
  lime: ['#EEFFE0', '#8CFF5E', '#3AAE1C', '#1E5E0E', '#C2FFA8'],
  red: ['#FFD3CF', '#FF5A5A', '#B81E28', '#6E0A12', '#FFA0A0'],
  cob: ['#D8E2FF', '#5079FF', '#1C3BB8', '#0E1E66', '#A4BAFF'],
  sil: ['#FFFFFF', '#E8E2FF', '#A698D6', '#4A4078', '#FFFFFF'],
};
const INK = Object.fromEntries(Object.entries(SK).map(([k, v]) => [k, v[3]]));
const LITE = Object.fromEntries(Object.entries(SK).map(([k, v]) => [k, v[4]]));

// isometric 3x3 puzzle cube: faces given as [origin, u, v, colors[9], shade]
const cube = () => {
  const C = { r: '#FF3B3B', b: '#2E6BFF', w: '#F6F7FF', y: '#FFD92E', o: '#FF8A1F', g: '#2FD158' };
  const T = [44.5, 35], L = [34, 41], M = [44.5, 47], R = [55, 41];
  const faces = [
    [L, [10.5, -6], [10.5, 6], 'wrybwogyr', 0],
    [L, [10.5, 6], [0, 12], 'rrgybbowb', .12],
    [M, [10.5, -6], [0, 12], 'gowyrgbyo', .3],
  ];
  let s = `<path d="M${T[0]} ${T[1]}L${R[0]} ${R[1]}V53L${M[0]} 59L${L[0]} 53V${L[1]}Z" fill="#17182A" stroke="#07070F" stroke-width="2.2" stroke-linejoin="round"/>`;
  for (const [o, u, v, cols, shade] of faces) {
    for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) {
      const p = (a, b) => `${f(o[0] + u[0] * a / 3 + v[0] * b / 3)} ${f(o[1] + u[1] * a / 3 + v[1] * b / 3)}`;
      const a0 = i + .13, a1 = i + .87, b0 = j + .13, b1 = j + .87;
      s += `<path d="M${p(a0, b0)}L${p(a1, b0)}L${p(a1, b1)}L${p(a0, b1)}Z" fill="${C[cols[i * 3 + j]]}"/>`;
    }
    if (shade) s += `<path d="M${o[0]} ${o[1]}l${u[0]} ${u[1]}l${v[0]} ${v[1]}l${-u[0]} ${-u[1]}Z" fill="#000" opacity="${shade}"/>`;
  }
  return s + `<path d="M36.5 41L44.5 36.4" stroke="#fff" stroke-width="1.4" stroke-linecap="round" opacity=".7"/>`;
};

const LENS = 'M30.3 24.5C30.3 22 27.3 21.2 22.3 21.2C17.3 21.2 13.2 22.2 13.2 25.6C13.2 30.6 17.3 34.6 21.5 34.6C26 34.6 30.3 30 30.3 24.5ZM33.7 24.5C33.7 22 36.7 21.2 41.7 21.2C46.7 21.2 50.8 22.2 50.8 25.6C50.8 30.6 46.7 34.6 42.5 34.6C38 34.6 33.7 30 33.7 24.5Z';
const butterfly = (x, y, a, c) => `<g transform="translate(${x} ${y}) rotate(${a})" stroke="#4A2A00" stroke-width=".9"><ellipse cx="-2.1" cy="-1.3" rx="2.3" ry="1.9" fill="${c}"/><ellipse cx="2.1" cy="-1.3" rx="2.3" ry="1.9" fill="${c}"/><ellipse cx="-1.6" cy="1.5" rx="1.6" ry="1.3" fill="${c}"/><ellipse cx="1.6" cy="1.5" rx="1.6" ry="1.3" fill="${c}"/><path d="M0-2.6V2.8" stroke-width="1.4" stroke-linecap="round"/></g>`;

export default {
  key: 'cadets',
  names: ['Boombox Cadet', 'High-Top Cadet', 'Scrunchie Cadet', 'Mixtape Cadet', 'Aviator Cadet', 'Puzzle-Cube Cadet', 'Aerobics Cadet', 'Handheld Cadet', 'Grunge Cadet'],
  colors: ['#FF3FA4', '#22E1FF', '#FFE53D', '#A86BFF', '#FF8A2A', '#7CFF4F', '#FF4D4D', '#3D6BFF', '#E3DCFF'],
  defs: Object.entries(SK).map(([k, v]) => rg(k, v[0], v[1], v[2])).join('')
    + lg('navy', '#4A60B4', '#24326C', '#141C42')
    + lg('collar', '#3A4FA0', '#24326E', '#18224C')
    + lg('gold', '#FFF6B8', '#FFD640', '#C98A0E')
    + `<linearGradient id="cad-iris" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0722"/><stop offset=".55" stop-color="#221650"/><stop offset="1" stop-color="#5646AA"/></linearGradient>`
    + lg('chrome', '#FAFBFF', '#C3C9DA', '#767D96')
    + rg('spk', '#6A7090', '#262A3A', '#0B0C14')
    + lg('hair', '#8270C8', '#4A3A86', '#251A4C')
    + rg('brown', '#FFB070', '#D45A12', '#7A2A04')
    + rg('shag', '#D8B48C', '#94704E', '#553A24')
    + rg('amber', '#FFF2B8', '#FFC21A', '#C47400')
    + rg('scr', '#FFD3EC', '#FF4FAA', '#B3146A')
    + rg('foam', '#FFE2B6', '#FFA548', '#C9600A')
    + `<linearGradient id="cad-lens" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#170F3C"/><stop offset=".38" stop-color="#5A2C9E"/><stop offset=".72" stop-color="#FF4FA0"/><stop offset="1" stop-color="#FFD57A"/></linearGradient>`
    + rg('leather', '#E09A5E', '#A8562A', '#5A280E')
    + rg('fleece', '#FFFFFF', '#FFF0DA', '#DDBF94')
    + lg('band', '#FFFFFF', '#F1F3FA', '#C9CFE2')
    + rg('cap', '#FFFFFF', '#E6ECFA', '#9EAEDA')
    + lg('dev', '#F4F5FA', '#CDD1DE', '#8F95AC')
    + lg('scrn', '#D6FFA8', '#8EDB62', '#4A9A34')
    + rg('hat', '#D2CBF2', '#9488C8', '#51468A')
    + `<pattern id="cad-plaid" width="7" height="7" patternUnits="userSpaceOnUse"><rect width="7" height="7" fill="#3C7452"/><path d="M0 2.5H7M2.5 0V7" stroke="#14261C" stroke-width="2.6" opacity=".8"/><path d="M0 5.8H7M5.8 0V7" stroke="#E6D46A" stroke-width=".7" opacity=".8"/></pattern>`,
  symbols: [
    // 1. Boombox Cadet: a big silver boombox held up on the shoulder
    `<g transform="translate(-3 0)">${uniform('pink', INK.pink)}</g>`
    + `<g transform="translate(-1.5 0) rotate(7 27 44)">` + sc(27, 44, 1.08,
      antenna(21.5, 13.5, 18.5, 11.5, 14.2, 10.2, INK.pink, LITE.pink, 'pink') + antenna(32.5, 13.5, 35.5, 11.5, 39, 10.8, INK.pink, LITE.pink, 'pink')
      + head(27, 27.5, 14.5, 15.5, 14.5, 'pink', INK.pink) + face(27, 27.5, INK.pink, { sp: 6 })) + `</g>`
    + `<g transform="translate(-1.2 .6) rotate(-5 50 36)">`
    + `<path d="M42.5 26V22.5Q42.5 20 45 20H55Q57.5 20 57.5 22.5V26" fill="none" stroke="#232838" stroke-width="4.8" stroke-linecap="round"/>`
    + `<path d="M42.5 26V22.5Q42.5 20 45 20H55Q57.5 20 57.5 22.5V26" fill="none" stroke="#A9B0C6" stroke-width="2" stroke-linecap="round"/>`
    + `<rect x="37.5" y="25.5" width="25" height="20.5" rx="3.6" fill="url(#cad-chrome)" stroke="#232838" stroke-width="2.2"/>`
    + `<rect x="45" y="28" width="10" height="4.6" rx="1" fill="#1D2233"/><rect x="46.2" y="29" width="7.6" height="2.6" rx=".6" fill="#7FE9FF"/>`
    + `<circle cx="41.2" cy="30.3" r="1.1" fill="#FF3FA4"/><circle cx="58.8" cy="30.3" r="1.1" fill="#22E1FF"/><path d="M40 27.9H44" stroke="#fff" stroke-width="1.3" stroke-linecap="round" opacity=".85"/>`
    + `<circle cx="43.6" cy="39" r="5.3" fill="#2A2F40" stroke="#232838" stroke-width="1.4"/><circle cx="56.4" cy="39" r="5.3" fill="#2A2F40" stroke="#232838" stroke-width="1.4"/>`
    + `<circle cx="43.6" cy="39" r="3.9" fill="url(#cad-spk)"/><circle cx="56.4" cy="39" r="3.9" fill="url(#cad-spk)"/>`
    + `<circle cx="43.6" cy="39" r="1.5" fill="#8C93AE"/><circle cx="56.4" cy="39" r="1.5" fill="#8C93AE"/>`
    + `<path d="M41 37Q42 35.6 43.6 35.5M53.8 37Q54.8 35.6 56.4 35.5" fill="none" stroke="#fff" stroke-width="1" stroke-linecap="round" opacity=".6"/>`
    + `<ellipse cx="44.6" cy="47.9" rx="4.8" ry="2.2" fill="url(#cad-pink)" stroke="${INK.pink}" stroke-width="1.6"/>`
    + `<path d="M39.4 47.6V44Q39.4 42.6 40.7 42.6Q42 42.6 42 44V47.6ZM42 47.6V43.8Q42 42.4 43.3 42.4Q44.6 42.4 44.6 43.8V47.6ZM44.6 47.6V43.8Q44.6 42.4 45.9 42.4Q47.2 42.4 47.2 43.8V47.6ZM47.2 47.6V44Q47.2 42.6 48.5 42.6Q49.8 42.6 49.8 44V47.6Z" fill="url(#cad-pink)" stroke="${INK.pink}" stroke-width="1.4" stroke-linejoin="round"/>`
    + `</g>`,

    // 2. High-Top Cadet: a tall flat-top fade
    uniform('teal', INK.teal)
    + sc(32, 48, 1.04,
      fin(17, 36, -1, 'teal', INK.teal) + fin(47, 36, 1, 'teal', INK.teal)
      + head(32, 33, 15.5, 15, 14, 'teal', INK.teal)
      + `<path d="M19.4 25V8.6Q19.4 5.6 22 5.3Q23.6 3.5 25.3 5Q26.9 3.3 28.6 4.9Q30.3 3.2 32 4.8Q33.7 3.2 35.4 4.9Q37.1 3.3 38.7 5Q40.4 3.5 42 5.3Q44.6 5.6 44.6 8.6V25Q42.2 21.9 38.6 21.7Q32 23.2 25.4 21.7Q21.8 21.9 19.4 25Z" fill="url(#cad-hair)" stroke="#0C0718" stroke-width="2.3" stroke-linejoin="round"/>`
      + `<path d="M24 8.5V13.5M28 8V12M32 8.2V14.5M36 8V12M40 8.5V13.5M26 15.5V19M30 16.5V20M34 16.5V20M38 15.5V19" stroke="#A898E0" stroke-width="1.2" stroke-linecap="round" opacity=".55"/>`
      + `<path d="M22 21.5V9.5" stroke="#B4A6EC" stroke-width="2" stroke-linecap="round" opacity=".6"/>`
      + `<path d="M21.5 26.4Q25 24.2 28.5 25.8M35.5 25.8Q39 24.2 42.5 26.4" fill="none" stroke="${INK.teal}" stroke-width="1.9" stroke-linecap="round"/>`
      + face(32, 33, INK.teal, { mouth: smile(32, 39.8, 5, INK.teal, 4.8) })),

    // 3. Scrunchie Cadet: big side ponytail with a scrunchie, butterfly clips
    uniform('yel', INK.yel)
    + sc(31, 46, 1.04,
      fin(15.5, 31, -1, 'yel', INK.yel)
      + `<path d="M44.5 13C51 5.5 61 7.5 61.5 17C62 25.5 56.5 32.5 58.5 41C53 37.5 50 30.5 50.8 24.5C51.3 20.5 49 18.5 46 18.5Z" fill="url(#cad-amber)" stroke="#7A4600" stroke-width="2.2" stroke-linejoin="round"/>`
      + `<path d="M52 11Q58.5 12 57.5 21.5M54.5 25Q53 31 55.5 36" fill="none" stroke="#FFF2B8" stroke-width="1.5" stroke-linecap="round" opacity=".75"/>`
      + head(30.5, 28, 15, 16, 14.5, 'yel', INK.yel)
      + `<path d="M15.5 26C14.5 15.5 21.5 10.5 30.5 10.5C39.5 10.5 46.5 15.5 46 24.5C42.5 20.5 38.5 19.5 35.5 22C33 18.8 28 18.8 25.5 22C22.5 19.8 18 21.5 15.5 26Z" fill="url(#cad-amber)" stroke="#7A4600" stroke-width="2.2" stroke-linejoin="round"/>`
      + `<path d="M20 17Q24 13.5 29.5 13.5" fill="none" stroke="#FFF6CC" stroke-width="1.8" stroke-linecap="round" opacity=".8"/>`
      + `<path d="M46 9.5Q48.3 8.5 50.2 10.6Q52.6 10.7 52.4 13.4Q54.2 15.2 52.3 17.3Q52.5 20 49.8 20Q48 21.8 45.8 20.2Q43.2 20.4 43.4 17.7Q41.6 15.8 43.5 13.8Q43.4 11 46 9.5Z" fill="url(#cad-scr)" stroke="#7A0E44" stroke-width="1.8" stroke-linejoin="round"/>`
      + `<circle cx="46" cy="13.2" r=".9" fill="#fff"/><circle cx="49.8" cy="16.7" r=".9" fill="#fff"/><circle cx="45.5" cy="17.4" r=".8" fill="#fff" opacity=".85"/><circle cx="49.6" cy="12.4" r=".8" fill="#fff" opacity=".85"/>`
      + butterfly(19.5, 18, -25, '#3FE6FF') + butterfly(26.5, 13.8, -10, '#C59BFF')
      + face(30.5, 29.5, INK.yel)
      + `<path d="M19.5 25.8L18 24.2M41.5 25.8L43 24.2" stroke="${INK.yel}" stroke-width="1.5" stroke-linecap="round"/>`),

    // 4. Mixtape Cadet: foam headphones, a cassette player clipped to the collar
    uniform('pur', INK.pur)
    + sc(32, 44, 1.06,
      antenna(27, 13, 25.8, 10, 24, 7.6, INK.pur, LITE.pur, 'pur') + antenna(37, 13, 38.2, 10, 40, 7.6, INK.pur, LITE.pur, 'pur')
      + head(32, 27, 15, 15.5, 14.5, 'pur', INK.pur)
      + `<path d="M13.5 26C12.5 13 21 7 32 7C43 7 51.5 13 50.5 26" fill="none" stroke="#1A1240" stroke-width="5.4" stroke-linecap="round"/>`
      + `<path d="M13.5 26C12.5 13 21 7 32 7C43 7 51.5 13 50.5 26" fill="none" stroke="#C3CAE0" stroke-width="2.6" stroke-linecap="round"/>`
      + `<path d="M16 17Q20.5 10 28 8.8" fill="none" stroke="#fff" stroke-width="1.1" stroke-linecap="round" opacity=".8"/>`
      + `<circle cx="13.5" cy="29" r="7.6" fill="url(#cad-foam)" stroke="#6E3204" stroke-width="2.2"/><circle cx="50.5" cy="29" r="7.6" fill="url(#cad-foam)" stroke="#6E3204" stroke-width="2.2"/>`
      + `<g fill="#C9600A" opacity=".5"><circle cx="11" cy="30" r=".8"/><circle cx="14.5" cy="32.5" r=".8"/><circle cx="16" cy="28" r=".8"/><circle cx="12" cy="34" r=".7"/><circle cx="48" cy="30" r=".8"/><circle cx="51.5" cy="32.5" r=".8"/><circle cx="53" cy="28" r=".8"/><circle cx="49" cy="34" r=".7"/></g>`
      + `<ellipse cx="11.2" cy="25.6" rx="2.6" ry="1.6" transform="rotate(-35 11.2 25.6)" fill="#fff" opacity=".7"/><ellipse cx="48.2" cy="25.6" rx="2.6" ry="1.6" transform="rotate(-35 48.2 25.6)" fill="#fff" opacity=".7"/>`
      + face(32, 27.5, INK.pur, { sp: 6.4 }))
    + `<path d="M50.5 48.5Q57 44 52.5 37" fill="none" stroke="#1A1240" stroke-width="1.6" stroke-linecap="round"/>`
    + `<rect x="35" y="48.5" width="17.5" height="12.8" rx="2.2" fill="url(#cad-chrome)" stroke="#1A1240" stroke-width="2"/>`
    + `<rect x="37.4" y="51" width="12.7" height="7" rx="1.3" fill="#1A1430"/>`
    + `<circle cx="40.9" cy="54.5" r="2" fill="#E9ECF8"/><circle cx="46.6" cy="54.5" r="2" fill="#E9ECF8"/><circle cx="40.9" cy="54.5" r=".8" fill="#1A1430"/><circle cx="46.6" cy="54.5" r=".8" fill="#1A1430"/>`
    + `<rect x="38" y="46.4" width="4.4" height="2.4" rx=".6" fill="#FF8A2A" stroke="#1A1240" stroke-width="1"/><path d="M36.5 50.1H40.5" stroke="#fff" stroke-width="1.1" stroke-linecap="round" opacity=".8"/>`,

    // 5. Aviator Cadet: wide mirrored aviators, shearling bomber collar
    uniform('tan', INK.tan, 'leather',
      `<path d="M26.2 47.6Q22 46.2 19.4 48.4Q16 47.2 13.6 50Q10 50 9.4 53.4Q7 55.6 9.6 57.6Q9.6 60.6 13 60.4Q14.8 62.6 17.6 61.2Q19.6 62.4 20.6 60.4L19 53Q21.8 49.8 27 48.8ZM37.8 47.6Q42 46.2 44.6 48.4Q48 47.2 50.4 50Q54 50 54.6 53.4Q57 55.6 54.4 57.6Q54.4 60.6 51 60.4Q49.2 62.6 46.4 61.2Q44.4 62.4 43.4 60.4L45 53Q42.2 49.8 37 48.8Z" fill="url(#cad-fleece)" stroke="#7A5530" stroke-width="1.8" stroke-linejoin="round"/>`
      + `<path d="M12 55.6q1-1.2 2.2 0M15.4 52.4q1-1.2 2.2 0M14.6 58.4q1-1.2 2.2 0M46.4 52.4q1-1.2 2.2 0M49.8 55.6q1-1.2 2.2 0M47.2 58.4q1-1.2 2.2 0" fill="none" stroke="#C9A06C" stroke-width="1" stroke-linecap="round"/>`)
    + sc(32, 44, 1.05,
      fin(18.6, 35, -1, 'tan', INK.tan) + fin(45.4, 35, 1, 'tan', INK.tan)
      + head(32, 26.5, 15.5, 15.5, 15, 'tan', INK.tan)
      + `<path d="M20.5 15.5C19 8.5 25.5 4.5 33 5.2C40 5.8 45.5 9.5 44 15.5C41.5 12 37.5 11 34 12.5C30.5 10.5 24.5 11.5 20.5 15.5Z" fill="url(#cad-brown)" stroke="#5A1E02" stroke-width="2" stroke-linejoin="round"/>`
      + `<path d="M24.5 9.5Q28.5 6.8 33.5 7.2" fill="none" stroke="#FFE0B8" stroke-width="1.5" stroke-linecap="round" opacity=".8"/>`
      + `<path d="M19 18.2Q22.5 16.2 26.5 17.6M37.5 17.6Q41.5 16.2 45 18.2" fill="none" stroke="${INK.tan}" stroke-width="1.9" stroke-linecap="round"/>`
      + `<path d="${LENS}" fill="url(#cad-lens)" stroke="#3A1A00" stroke-width="3.2" stroke-linejoin="round"/><path d="${LENS}" fill="none" stroke="#FFD23F" stroke-width="1.2" stroke-linejoin="round"/>`
      + `<path d="M22 21.4H42M29.8 24.6Q32 23 34.2 24.6" fill="none" stroke="#3A1A00" stroke-width="3" stroke-linecap="round"/><path d="M22 21.4H42M29.8 24.6Q32 23 34.2 24.6" fill="none" stroke="#FFD23F" stroke-width="1.2" stroke-linecap="round"/>`
      + `<path d="M16.5 29L21.5 23.8M19.5 31.5L24.5 26.2M37.5 29L42.5 23.8M40.5 31.5L45.5 26.2" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".75"/>`
      + blush(18.5, 37.5) + blush(45.5, 37.5)
      + smile(32, 37, 5.5, INK.tan)),

    // 6. Puzzle-Cube Cadet: proudly holding up a colored puzzle cube
    uniform('lime', INK.lime)
    + sc(29, 42, 1.06,
      antenna(23.5, 12.5, 21, 8.5, 17.5, 7.8, INK.lime, LITE.lime, 'lime') + antenna(34.5, 12.5, 37, 8.5, 40.5, 7.8, INK.lime, LITE.lime, 'lime')
      + head(29, 26, 15, 15.5, 14.5, 'lime', INK.lime) + face(29, 26, INK.lime, { sp: 6.2, lx: 1.1, ly: 1.4 }))
    + `<ellipse cx="33.2" cy="51.5" rx="3.6" ry="4.8" fill="url(#cad-lime)" stroke="${INK.lime}" stroke-width="1.8"/><ellipse cx="56" cy="50" rx="3.4" ry="4.8" fill="url(#cad-lime)" stroke="${INK.lime}" stroke-width="1.8"/>`
    + cube()
    + `<rect x="31.4" y="47.6" width="6" height="3" rx="1.5" fill="url(#cad-lime)" stroke="${INK.lime}" stroke-width="1.4"/><rect x="31.4" y="51.2" width="6" height="3" rx="1.5" fill="url(#cad-lime)" stroke="${INK.lime}" stroke-width="1.4"/>`
    + `<rect x="52.6" y="44.6" width="5.6" height="3" rx="1.5" fill="url(#cad-lime)" stroke="${INK.lime}" stroke-width="1.4"/>`,

    // 7. Aerobics Cadet: striped sweatband, a waving hand with a wristband
    uniform('red', INK.red)
    + `<g transform="translate(1.4 .8)">` + `<path d="M11.5 55L10.5 33" stroke="${NAVY}" stroke-width="9.6" stroke-linecap="round"/><path d="M11.5 55L10.5 33" stroke="#2A3A7A" stroke-width="6.6" stroke-linecap="round"/>`
    + `<path d="M5 27.5C3.5 22.5 4 17.5 5.2 15C5.8 13.2 8 13.4 8 15.3L8.3 12.4C8.5 10.4 11 10.4 11.2 12.4L11.4 11.8C11.7 9.8 14.2 10 14.3 12L14.4 16.4C15.4 14.8 17.6 15.4 17.1 17.6C16.4 21 15.8 24.5 15 27.5Z" fill="url(#cad-red)" stroke="${INK.red}" stroke-width="1.8" stroke-linejoin="round"/>`
    + `<rect x="4.2" y="26.5" width="11.8" height="6" rx="2" fill="url(#cad-band)" stroke="${INK.red}" stroke-width="1.8"/><path d="M5.2 28.6H15M5.2 30.6H15" stroke="#22C8EE" stroke-width="1"/><path d="M5.2 29.6H15" stroke="#FFC81A" stroke-width="1"/>`
    + `<path d="M19 12.5Q21 15 20.5 18.5M21.6 10.5Q24.6 14.6 23.6 19.6" fill="none" stroke="#FFD0CC" stroke-width="1.4" stroke-linecap="round" opacity=".8"/>` + `</g>`
    + sc(35, 44, 1.05,
      antenna(29.5, 14, 27.5, 9.5, 25, 7.8, INK.red, LITE.red, 'red') + antenna(40.5, 14, 42.5, 9.5, 45, 7.8, INK.red, LITE.red, 'red')
      + head(35, 28, 15, 15.5, 14.5, 'red', INK.red)
      + `<path d="M20.2 21.6Q35 13.4 49.8 21.6L50.2 27.4Q35 19.2 19.8 27.4Z" fill="url(#cad-band)" stroke="${INK.red}" stroke-width="1.9" stroke-linejoin="round"/>`
      + `<path d="M20.4 23.6Q35 15.5 49.6 23.6" fill="none" stroke="#22C8EE" stroke-width="1.3"/><path d="M20.4 25.4Q35 17.3 49.6 25.4" fill="none" stroke="#FFC81A" stroke-width="1.3"/>`
      + face(35, 31, INK.red, { sp: 6.4 })),

    // 8. Handheld Cadet: backwards cap, eyes on a handheld game
    uniform('cob', INK.cob)
    + sc(32, 44, 1.06,
      `<path d="M20 16Q11.5 9.5 6.5 12Q3.8 14.8 8 17.6Q12.5 20.2 18.5 20.5Z" fill="#2B4BC8" stroke="${INK.cob}" stroke-width="2" stroke-linejoin="round"/><path d="M7.5 15.8Q12.5 18 18 18.5" fill="none" stroke="${INK.cob}" stroke-width="1.1" opacity=".6"/>`
      + fin(17, 30, -1, 'cob', INK.cob) + fin(47, 30, 1, 'cob', INK.cob)
      + head(32, 29, 15, 15, 14, 'cob', INK.cob)
      + `<path d="M16.6 24.5C16.2 14.5 23 9.2 32 9.2C41 9.2 47.8 14.5 47.4 24.5C42 22.2 37 21.5 32 21.5C27 21.5 22 22.2 16.6 24.5Z" fill="url(#cad-cap)" stroke="${INK.cob}" stroke-width="2.2" stroke-linejoin="round"/>`
      + `<path d="M27.2 22Q27.2 16.6 32 16.6Q36.8 16.6 36.8 22Z" fill="url(#cad-cob)" stroke="${INK.cob}" stroke-width="1.6" stroke-linejoin="round"/>`
      + `<path d="M27.5 19.8H36.5" stroke="#2B4BC8" stroke-width="2.2"/><path d="M29.5 19.8h.01M32 19.8h.01M34.5 19.8h.01" stroke="#fff" stroke-width="1.1" stroke-linecap="round"/>`
      + `<path d="M32 9.5V16.5M24 11.5Q22.5 16 22.5 22.5M40 11.5Q41.5 16 41.5 22.5" fill="none" stroke="#9EAEDA" stroke-width="1.2" stroke-linecap="round"/>`
      + `<ellipse cx="32" cy="9.4" rx="2.4" ry="1.4" fill="#2B4BC8" stroke="${INK.cob}" stroke-width="1.2"/><ellipse cx="23.5" cy="13.2" rx="3.6" ry="1.6" transform="rotate(-30 23.5 13.2)" fill="#fff" opacity=".8"/>`
      + face(32, 30.5, INK.cob, { sp: 6.4, lx: 1, ly: 1.6, mouth: `<path d="M27.5 37.8Q32 40.6 36.5 37.8" fill="none" stroke="${INK.cob}" stroke-width="1.8" stroke-linecap="round"/><path d="M34 39.2Q34.6 42.4 36.6 42Q38.4 41.4 37.2 38.4" fill="#FF7FA6" stroke="${INK.cob}" stroke-width="1.3" stroke-linejoin="round"/>` }))
    + `<ellipse cx="32.5" cy="55" rx="3.4" ry="4.2" fill="url(#cad-cob)" stroke="${INK.cob}" stroke-width="1.8"/><ellipse cx="58" cy="55" rx="3.2" ry="4.2" fill="url(#cad-cob)" stroke="${INK.cob}" stroke-width="1.8"/>`
    + `<rect x="31" y="46" width="28" height="15.5" rx="5" fill="url(#cad-dev)" stroke="#232838" stroke-width="2.2"/>`
    + `<rect x="38.4" y="48.2" width="13.2" height="10.6" rx="1.6" fill="#2A2E44"/><rect x="39.8" y="49.6" width="10.4" height="7.8" rx=".8" fill="url(#cad-scrn)"/>`
    + `<path d="M41.5 55.5h2v-2h2v2h2M46 51.5h1.6" fill="none" stroke="#2C5A1E" stroke-width="1.3"/>`
    + `<path d="M33.2 53.6H37.6M35.4 51.4V55.8" stroke="#2A2E44" stroke-width="1.8" stroke-linecap="round"/>`
    + `<circle cx="54.4" cy="55" r="1.6" fill="#FF3FA4" stroke="#2A2E44" stroke-width=".9"/><circle cx="56.8" cy="51.8" r="1.6" fill="#FFD23F" stroke="#2A2E44" stroke-width=".9"/>`
    + `<path d="M34 47.8H46" stroke="#fff" stroke-width="1.2" stroke-linecap="round" opacity=".8"/>`,

    // 9. Grunge Cadet: bucket hat, shaggy hair, flannel over the uniform
    uniform('sil', INK.sil, 'plaid',
      `<path d="M25.2 48.4L11.8 51.8L18.6 60.4ZM38.8 48.4L52.2 51.8L45.4 60.4Z" fill="url(#cad-plaid)" stroke="${NAVY}" stroke-width="2" stroke-linejoin="round"/>`)
    + sc(32, 46, 1.04,
      fin(18, 37, -1, 'sil', INK.sil) + fin(46, 37, 1, 'sil', INK.sil)
      + head(32, 31, 15, 15, 14, 'sil', INK.sil)
      + `<path d="M17.4 27.6Q32 24.4 46.6 27.6L46.2 31Q32 27.8 17.8 31Z" fill="#4A4078" opacity=".22"/>`
      + `<path d="M18.6 26Q15.6 33.5 17.6 42Q19 37.5 20.5 34Q20.8 38.3 22.5 40.5Q23 33 24.5 27ZM45.4 26Q48.4 33.5 46.4 42Q45 37.5 43.5 34Q43.2 38.3 41.5 40.5Q41 33 39.5 27Z" fill="url(#cad-shag)" stroke="#3A2414" stroke-width="1.6" stroke-linejoin="round"/>`
      + `<path d="M21 21C21 13 25 9.2 32 9.2C39 9.2 43 13 43 21Z" fill="url(#cad-hat)" stroke="#2C2456" stroke-width="2.2" stroke-linejoin="round"/>`
      + `<path d="M23.6 16.4Q32 14.8 40.4 16.4" fill="none" stroke="#2C2456" stroke-width="1" stroke-dasharray="1.6 1.4" opacity=".7"/>`
      + `<path d="M21 19.4Q32 17.4 43 19.4L52.6 27.4Q53.2 29.6 50.6 29.4Q32 25.6 13.4 29.4Q10.8 29.6 11.4 27.4Z" fill="url(#cad-hat)" stroke="#2C2456" stroke-width="2.2" stroke-linejoin="round"/>`
      + `<path d="M16.8 25Q32 21.8 47.2 25" fill="none" stroke="#2C2456" stroke-width="1" stroke-dasharray="1.6 1.4" opacity=".7"/>`
      + `<path d="M25 16Q25.4 12 28.5 10.8M14.5 26.5L19.5 22" fill="none" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".6"/>`
      + face(32, 33.6, INK.sil, { sp: 6.4, mouth: `<path d="M27.5 40.6Q32 44 36.5 40.6" fill="none" stroke="${INK.sil}" stroke-width="1.9" stroke-linecap="round"/>` })),
  ],
};
