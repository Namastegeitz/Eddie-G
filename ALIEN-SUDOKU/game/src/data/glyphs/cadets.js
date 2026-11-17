/* Star Cadets lineup: nine first-year alien cadets of a deep-space decoding
   academy whose training archive is Earth's '80s and '90s broadcasts, so they
   dress like it. Big domed heads, glossy alien eyes, glowing antennae or swept
   fins; all wear the same navy cadet collar with a gold academy star pin, plus
   one signature retro item each. Light comes from the top-left; every id is
   prefixed "cad-". */
const f = (v) => +v.toFixed(2);
const rg = (id, a, b, c) => `<radialGradient id="cad-${id}" cx=".36" cy=".3" r=".85"><stop offset="0" stop-color="${a}"/><stop offset=".5" stop-color="${b}"/><stop offset="1" stop-color="${c}"/></radialGradient>`;
const lg = (id, a, b, c, x2 = '.45') => `<linearGradient id="cad-${id}" x1="0" y1="0" x2="${x2}" y2="1"><stop offset="0" stop-color="${a}"/><stop offset=".5" stop-color="${b}"/><stop offset="1" stop-color="${c}"/></linearGradient>`;
const glow = (id, a, b) => `<radialGradient id="cad-g${id}"><stop offset="0" stop-color="${a}" stop-opacity=".95"/><stop offset=".45" stop-color="${b}" stop-opacity=".45"/><stop offset="1" stop-color="${b}" stop-opacity="0"/></radialGradient>`;
const NAVY = '#0A0E2C';

// skins: light, mid, dark, ink, stalk highlight, skin-mark tone
const SK = {
  pink: ['#FFD6EC', '#FF4FAC', '#B3106A', '#6A0A3E', '#FFA6D4', '#C21876'],
  teal: ['#DDFBFF', '#3AE4FF', '#0A93B5', '#064A5E', '#9DF2FF', '#0B8FB0'],
  yel: ['#FFFDE6', '#FFE94F', '#D6A400', '#6E4E00', '#FFF39A', '#D98E00'],
  pur: ['#F0E4FF', '#B07AFF', '#6230C8', '#33137A', '#D6B8FF', '#6E36D0'],
  tan: ['#FFE6CA', '#FF9640', '#C24E06', '#6B2A04', '#FFC48E', '#C9500A'],
  lime: ['#EEFFE0', '#8CFF5E', '#3AAE1C', '#1E5E0E', '#C2FFA8', '#36A818'],
  red: ['#FFD3CF', '#FF5A5A', '#B81E28', '#6E0A12', '#FFA0A0', '#B01C2A'],
  cob: ['#D8E2FF', '#5079FF', '#1C3BB8', '#0E1E66', '#A4BAFF', '#2242C0'],
  sil: ['#FFFFFF', '#E8E2FF', '#A698D6', '#4A4078', '#FFFFFF', '#9A8AD2'],
};
const EYEGLOW = { yel: '#D99A00', lime: '#2FAE16', sil: '#8E7CD8' };
const INK = Object.fromEntries(Object.entries(SK).map(([k, v]) => [k, v[3]]));

// five-point star
const star = (cx, cy, R) => {
  let d = '';
  for (let i = 0; i < 10; i++) {
    const a = (-90 + i * 36) * Math.PI / 180, r = i % 2 ? R * .46 : R;
    d += `${i ? 'L' : 'M'}${f(cx + r * Math.cos(a))} ${f(cy + r * Math.sin(a))}`;
  }
  return d + 'Z';
};
// scale a group about (x, y)
const sc = (x, y, s, body) => `<g transform="matrix(${s} 0 0 ${s} ${f(x * (1 - s))} ${f(y * (1 - s))})">${body}</g>`;

// the shared uniform: slender neck, small navy tunic, piped collar, gold star pin
const LAPELS = 'M28 51.6L32 56.5L29.4 62.2L19.2 54.6Q22.6 52.3 28 51.6ZM36 51.6L32 56.5L34.6 62.2L44.8 54.6Q41.4 52.3 36 51.6Z';
const uniform = (k, tunic = 'navy', extra = '') =>
  `<path d="M28.6 40V52L32 56.5L35.4 52V40Z" fill="url(#cad-${k})" stroke="${INK[k]}" stroke-width="1.9"/>`
  + `<path d="M28.6 45Q32 49 35.4 45V52L32 56.5L28.6 52Z" fill="#000" opacity=".22"/>`
  + `<path d="M10.5 62.5C10.5 57.5 14.5 54 21 52.6L28 51.6L32 56.5L36 51.6L43 52.6C49.5 54 53.5 57.5 53.5 62.5Z" fill="url(#cad-${tunic})" stroke="${NAVY}" stroke-width="2.2" stroke-linejoin="round"/>`
  + `<path d="M14 60Q15 56.6 20.6 55" fill="none" stroke="#fff" stroke-width="1.5" stroke-linecap="round" opacity=".3"/>`
  + extra
  + `<path d="${LAPELS}" fill="none" stroke="${NAVY}" stroke-width="3.4" stroke-linejoin="round"/>`
  + `<path d="${LAPELS}" fill="url(#cad-collar)" stroke="#8EA6FF" stroke-width="1.25" stroke-linejoin="round"/>`
  + `<path d="${star(24.7, 57.3, 3.6)}" fill="url(#cad-gold)" stroke="#6E4A04" stroke-width="1.05" stroke-linejoin="round"/>`
  + `<circle cx="23.8" cy="56.2" r=".75" fill="#fff" opacity=".9"/>`;

// big domed alien head: wide rounded cranium tapering to a small chin
const head = (cx, cy, rx, t, b, k, chin = 6) =>
  `<path d="M${cx} ${f(cy - t)}C${f(cx + rx * .56)} ${f(cy - t)} ${f(cx + rx)} ${f(cy - t * .56)} ${f(cx + rx)} ${cy}C${f(cx + rx)} ${f(cy + b * .5)} ${f(cx + chin * 1.4)} ${f(cy + b)} ${cx} ${f(cy + b)}C${f(cx - chin * 1.4)} ${f(cy + b)} ${f(cx - rx)} ${f(cy + b * .5)} ${f(cx - rx)} ${cy}C${f(cx - rx)} ${f(cy - t * .56)} ${f(cx - rx * .56)} ${f(cy - t)} ${cx} ${f(cy - t)}Z" fill="url(#cad-${k})" stroke="${INK[k]}" stroke-width="2.3"/>`
  + `<ellipse cx="${f(cx - rx * .42)}" cy="${f(cy - t * .58)}" rx="${f(rx * .34)}" ry="${f(t * .15)}" transform="rotate(-32 ${f(cx - rx * .42)} ${f(cy - t * .58)})" fill="#fff" opacity=".55"/>`;

// big glossy alien eye, tilted so its top leans outward; highlights stay top-left
const eye = (x, y, tilt, k, w = 5.6, h = 6.9) =>
  `<ellipse cx="${x}" cy="${y}" rx="${w}" ry="${h}" transform="rotate(${tilt} ${x} ${y})" fill="url(#cad-e${k})" stroke="${INK[k]}" stroke-width="1.8"/>`
  + `<ellipse cx="${f(x - w * .34)}" cy="${f(y - h * .38)}" rx="${f(w * .4)}" ry="${f(h * .3)}" transform="rotate(-20 ${f(x - w * .34)} ${f(y - h * .38)})" fill="#fff"/>`
  + `<circle cx="${f(x + w * .36)}" cy="${f(y + h * .42)}" r="${f(w * .18)}" fill="#fff" opacity=".85"/>`;
const eyes = (cx, y, sp, k, tilt = 16, w, h) => eye(f(cx - sp), y, -tilt, k, w, h) + eye(f(cx + sp), y, tilt, k, w, h);
// tiny nostrils and a small smile
const nose = (x, y, k) => `<path d="M${f(x - 1.5)} ${y}h.01M${f(x + 1.5)} ${y}h.01" stroke="${INK[k]}" stroke-width="1.5" stroke-linecap="round" opacity=".75"/>`;
const smile = (x, y, k, w = 3.8, h = 3.6) =>
  `<path d="M${f(x - w)} ${y}Q${x} ${f(y + 1.3)} ${f(x + w)} ${y}Q${f(x + w * .8)} ${f(y + h)} ${x} ${f(y + h)}Q${f(x - w * .8)} ${f(y + h)} ${f(x - w)} ${y}Z" fill="#3A0C24" stroke="${INK[k]}" stroke-width="1.5" stroke-linejoin="round"/>`
  + `<path d="M${f(x - w * .5)} ${f(y + h - .8)}Q${x} ${f(y + h - 2.6)} ${f(x + w * .5)} ${f(y + h - .8)}Q${x} ${f(y + h + .2)} ${f(x - w * .5)} ${f(y + h - .8)}Z" fill="#FF7FA6"/>`;
const grin = (x, y, k, w = 3.6) => `<path d="M${f(x - w)} ${y}Q${x} ${f(y + 3.4)} ${f(x + w)} ${y}" fill="none" stroke="${INK[k]}" stroke-width="1.8" stroke-linecap="round"/>`;
const blush = (x, y) => `<ellipse cx="${x}" cy="${y}" rx="3" ry="1.8" fill="#FF7FB0" opacity=".5"/>`;
// skin marks: [x, y, r] dots in a tone of the cadet's own color
const dots = (pts, c, o = .75) => `<g fill="${c}" opacity="${o}">${pts.map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}"/>`).join('')}</g>`;
// a standard face: eyes, nostrils, blush, mouth
const face = (cx, ey, k, o = {}) => {
  const sp = o.sp || 9;
  return eyes(cx, ey, sp, k, o.tilt, o.w, o.h)
    + blush(f(cx - sp - 1.5), f(ey + 8.2)) + blush(f(cx + sp + 1.5), f(ey + 8.2))
    + nose(cx, f(ey + 6.2), k) + (o.mouth ?? smile(cx, f(ey + 9.6), k));
};

// long antenna: stalk from (x1,y1) bending through (qx,qy) to a glowing tip at (x2,y2)
const antenna = (x1, y1, qx, qy, x2, y2, k, r = 3) =>
  `<path d="M${x1} ${y1}Q${qx} ${qy} ${x2} ${y2}" fill="none" stroke="${INK[k]}" stroke-width="4" stroke-linecap="round"/>`
  + `<path d="M${x1} ${y1}Q${qx} ${qy} ${x2} ${y2}" fill="none" stroke="${SK[k][4]}" stroke-width="1.8" stroke-linecap="round"/>`
  + `<circle cx="${x2}" cy="${y2}" r="${f(r * 1.9)}" fill="url(#cad-g${k})"/>`
  + `<circle cx="${x2}" cy="${y2}" r="${r}" fill="url(#cad-t${k})" stroke="${INK[k]}" stroke-width="1.5"/>`
  + `<circle cx="${f(x2 - r * .35)}" cy="${f(y2 - r * .35)}" r="${f(r * .32)}" fill="#fff"/>`;
// big ear fin on the side of the head at (x,y); dir -1 = left, 1 = right.
// shapes: [c1x, c1y, tipx, tipy, c2x, c2y]: swept up, droopy, round, wing
const FINS = { up: [5, -11, 11.5, -12.5, 9.5, -2], droop: [7, -6.5, 11.5, 3, 6.5, 6.5], round: [3, -11, 8.6, -9, 9.6, .5], wing: [6, -9, 13, -8, 9, 1] };
const fin = (x, y, dir, k, s = 1, shape = 'up', lights = false) => {
  const [ax, ay, tx, ty, bx, by] = FINS[shape];
  const X = (v) => f(x + dir * v * s), Y = (v) => f(y + v * s);
  return `<path d="M${X(-1.5)} ${Y(-5.5)}Q${X(ax)} ${Y(ay)} ${X(tx)} ${Y(ty)}Q${X(bx)} ${Y(by)} ${X(-1.5)} ${Y(5.5)}Z" fill="url(#cad-${k})" stroke="${INK[k]}" stroke-width="2" stroke-linejoin="round"/>`
    + `<path d="M${X(.5)} ${Y(-2.4)}Q${X(tx * .45)} ${Y(ty * .45 - 1.4)} ${X(tx * .78)} ${Y(ty * .78 - .6)}M${X(.5)} ${Y(1.6)}Q${X(tx * .45)} ${Y(ty * .45 + 1)} ${X(tx * .7)} ${Y(ty * .7 + 1.4)}" fill="none" stroke="${INK[k]}" stroke-width="1.1" stroke-linecap="round" opacity=".5"/>`
    + (lights ? [[4, -6.6], [7.4, -9.2], [10, -11.4]].map(([a, b]) => `<circle cx="${X(a)}" cy="${Y(b)}" r="2.6" fill="url(#cad-g${k})"/><circle cx="${X(a)}" cy="${Y(b)}" r="1" fill="#fff"/>`).join('') : '');
};

// isometric 3x3 puzzle cube with its top corner at (x, y)
const cube = (x, y) => {
  const C = { r: '#FF3B3B', b: '#2E6BFF', w: '#F6F7FF', y: '#FFD92E', o: '#FF8A1F', g: '#2FD158' };
  const L = [x - 10, y + 5.8], M = [x, y + 11.6];
  const faces = [
    [L, [10, -5.8], [10, 5.8], 'wrybwogyr', 0],
    [L, [10, 5.8], [0, 11.4], 'rrgybbowb', .12],
    [M, [10, -5.8], [0, 11.4], 'gowyrgbyo', .3],
  ];
  let s = `<path d="M${x} ${y}L${x + 10} ${f(y + 5.8)}V${f(y + 17.2)}L${x} ${f(y + 23)}L${x - 10} ${f(y + 17.2)}V${f(y + 5.8)}Z" fill="#17182A" stroke="#07070F" stroke-width="2.1" stroke-linejoin="round"/>`;
  for (const [o, u, v, cols, shade] of faces) {
    for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) {
      const p = (a, b) => `${f(o[0] + u[0] * a / 3 + v[0] * b / 3)} ${f(o[1] + u[1] * a / 3 + v[1] * b / 3)}`;
      const a0 = i + .13, a1 = i + .87, b0 = j + .13, b1 = j + .87;
      s += `<path d="M${p(a0, b0)}L${p(a1, b0)}L${p(a1, b1)}L${p(a0, b1)}Z" fill="${C[cols[i * 3 + j]]}"/>`;
    }
    if (shade) s += `<path d="M${o[0]} ${o[1]}l${u[0]} ${u[1]}l${v[0]} ${v[1]}l${-u[0]} ${-u[1]}Z" fill="#000" opacity="${shade}"/>`;
  }
  return s + `<path d="M${f(x - 7.6)} ${f(y + 5.6)}L${f(x - .4)} ${f(y + 1.4)}" stroke="#fff" stroke-width="1.3" stroke-linecap="round" opacity=".7"/>`;
};
// aviator lenses centred on (cx +/- sp, y)
const lenses = (cx, sp, y) => [-1, 1].map((d) => {
  const X = (v) => f(cx + d * (sp + v));
  return `M${X(-8.4)} ${f(y - 3.6)}C${X(-8.4)} ${f(y - 6.2)} ${X(-5.2)} ${f(y - 7)} ${X(0)} ${f(y - 7)}C${X(5.2)} ${f(y - 7)} ${X(9.2)} ${f(y - 6)} ${X(9.2)} ${f(y - 2.6)}C${X(9.2)} ${f(y + 2.6)} ${X(5)} ${f(y + 6.6)} ${X(.6)} ${f(y + 6.6)}C${X(-4)} ${f(y + 6.6)} ${X(-8.4)} ${f(y + 2)} ${X(-8.4)} ${f(y - 3.6)}Z`;
}).join('');
const butterfly = (x, y, a, c) => `<g transform="translate(${x} ${y}) rotate(${a})" stroke="#4A2A00" stroke-width=".9"><ellipse cx="-2.1" cy="-1.3" rx="2.3" ry="1.9" fill="${c}"/><ellipse cx="2.1" cy="-1.3" rx="2.3" ry="1.9" fill="${c}"/><ellipse cx="-1.6" cy="1.5" rx="1.6" ry="1.3" fill="${c}"/><ellipse cx="1.6" cy="1.5" rx="1.6" ry="1.3" fill="${c}"/><path d="M0-2.6V2.8" stroke-width="1.4" stroke-linecap="round"/></g>`;
const fingers = (xs, y, k, w = 2.6, h = 5) => `<path d="${xs.map((x) => `M${f(x - w / 2)} ${f(y + h)}V${f(y + w / 2)}Q${f(x - w / 2)} ${y} ${x} ${y}Q${f(x + w / 2)} ${y} ${f(x + w / 2)} ${f(y + w / 2)}V${f(y + h)}Z`).join('')}" fill="url(#cad-${k})" stroke="${INK[k]}" stroke-width="1.4" stroke-linejoin="round"/>`;

export default {
  key: 'cadets',
  names: ['Boombox Cadet', 'High-Top Cadet', 'Scrunchie Cadet', 'Mixtape Cadet', 'Aviator Cadet', 'Puzzle-Cube Cadet', 'Aerobics Cadet', 'Handheld Cadet', 'Grunge Cadet'],
  colors: ['#FF3FA4', '#22E1FF', '#FFE53D', '#A86BFF', '#FF8A2A', '#7CFF4F', '#FF4D4D', '#3D6BFF', '#E3DCFF'],
  defs: Object.entries(SK).map(([k, v]) => rg(k, v[0], v[1], v[2])
    + `<radialGradient id="cad-t${k}" cx=".4" cy=".35" r=".7"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".45" stop-color="${v[0]}"/><stop offset="1" stop-color="${v[1]}"/></radialGradient>`
    + glow(k, v[0], v[1])
    + `<linearGradient id="cad-e${k}" x1="0" y1="0" x2=".2" y2="1"><stop offset="0" stop-color="#0A061C"/><stop offset=".52" stop-color="#1E1550"/><stop offset="1" stop-color="${EYEGLOW[k] || v[1]}"/></linearGradient>`).join('')
    + lg('navy', '#4A60B4', '#24326C', '#141C42')
    + lg('collar', '#3A4FA0', '#24326E', '#18224C')
    + lg('gold', '#FFF6B8', '#FFD640', '#C98A0E')
    + lg('chrome', '#FAFBFF', '#C3C9DA', '#767D96')
    + rg('spk', '#6A7090', '#262A3A', '#0B0C14')
    + lg('hair', '#8270C8', '#4A3A86', '#251A4C')
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
    + rg('shag', '#D8B48C', '#94704E', '#553A24')
    + `<pattern id="cad-plaid" width="7" height="7" patternUnits="userSpaceOnUse"><rect width="7" height="7" fill="#3C7452"/><path d="M0 2.5H7M2.5 0V7" stroke="#14261C" stroke-width="2.6" opacity=".8"/><path d="M0 5.8H7M5.8 0V7" stroke="#E6D46A" stroke-width=".7" opacity=".8"/></pattern>`,
  symbols: [
    // 1. Boombox Cadet: glowing antennae, a big silver boombox held up on the shoulder
    `<g transform="translate(-4 0)">${uniform('pink')}</g>`
    + `<g transform="rotate(5 28 46)">`
    + antenna(20.5, 12, 13.5, 10.5, 8.4, 6.4, 'pink') + antenna(33, 10, 37, 5.5, 42.4, 5, 'pink')
    + head(27, 25, 18.5, 17.5, 21, 'pink')
    + dots([[21.4, 13, 1.2], [25, 11.2, 1], [28.6, 12.4, 1.2], [25.4, 15.4, .9], [31.8, 14.8, .9]], SK.pink[5], .6)
    + face(27, 28.5, 'pink', { sp: 8.4 }) + `</g>`
    + `<g transform="translate(-1.6 0) rotate(-6 51 42)">`
    + `<path d="M45 33.5V30Q45 28 47 28H55.5Q57.5 28 57.5 30V33.5" fill="none" stroke="#232838" stroke-width="4.6" stroke-linecap="round"/>`
    + `<path d="M45 33.5V30Q45 28 47 28H55.5Q57.5 28 57.5 30V33.5" fill="none" stroke="#A9B0C6" stroke-width="1.9" stroke-linecap="round"/>`
    + `<rect x="40" y="33" width="22.5" height="18.5" rx="3.4" fill="url(#cad-chrome)" stroke="#232838" stroke-width="2.1"/>`
    + `<rect x="46.6" y="35.3" width="9.2" height="4.2" rx="1" fill="#1D2233"/><rect x="47.7" y="36.2" width="7" height="2.4" rx=".6" fill="#7FE9FF"/>`
    + `<circle cx="43.4" cy="37.4" r="1" fill="#FF3FA4"/><circle cx="59.1" cy="37.4" r="1" fill="#22E1FF"/><path d="M42.4 35.2H45.6" stroke="#fff" stroke-width="1.2" stroke-linecap="round" opacity=".85"/>`
    + `<circle cx="45.6" cy="45" r="4.9" fill="#2A2F40" stroke="#232838" stroke-width="1.3"/><circle cx="56.9" cy="45" r="4.9" fill="#2A2F40" stroke="#232838" stroke-width="1.3"/>`
    + `<circle cx="45.6" cy="45" r="3.6" fill="url(#cad-spk)"/><circle cx="56.9" cy="45" r="3.6" fill="url(#cad-spk)"/>`
    + `<circle cx="45.6" cy="45" r="1.4" fill="#8C93AE"/><circle cx="56.9" cy="45" r="1.4" fill="#8C93AE"/>`
    + `<path d="M43.2 43.2Q44.1 41.9 45.6 41.8M54.5 43.2Q55.4 41.9 56.9 41.8" fill="none" stroke="#fff" stroke-width="1" stroke-linecap="round" opacity=".6"/>`
    + `<ellipse cx="46" cy="53.2" rx="4.4" ry="2" fill="url(#cad-pink)" stroke="${INK.pink}" stroke-width="1.5"/>`
    + fingers([42.2, 44.7, 47.2, 49.7], 48.6, 'pink', 2.5, 4.6)
    + `</g>`,

    // 2. High-Top Cadet: tall flat-top on a big dome, swept fins with glowing dots
    uniform('teal')
    + fin(14.4, 33, -1, 'teal', .98, 'up', true) + fin(49.6, 33, 1, 'teal', .98, 'up', true)
    + head(32, 31, 19, 16.5, 17.5, 'teal')
    + `<g transform="matrix(1.1 0 0 1.04 -3.2 -.4)">` + `<path d="M21.2 19.5V6.2Q21.2 3.6 23.4 3.4Q24.8 1.8 26.4 3.2Q27.9 1.6 29.4 3.1Q30.9 1.5 32.4 3.1Q33.9 1.6 35.4 3.2Q37 1.8 38.4 3.4Q42.8 3.6 42.8 6.2V19.5Q32 13.6 21.2 19.5Z" fill="url(#cad-hair)" stroke="#0C0718" stroke-width="2.2" stroke-linejoin="round"/>` + `<path d="M25.4 6.6V10.6M29 6V9.6M32.6 6.4V11.4M36.2 6V9.6M39.4 6.6V10.6M27.2 12.6V15.2M31 12.2V14.8M34.8 12.4V15" stroke="#A898E0" stroke-width="1.15" stroke-linecap="round" opacity=".55"/>` + `<path d="M23.6 16.6V7.6" stroke="#B4A6EC" stroke-width="1.9" stroke-linecap="round" opacity=".6"/>` + `</g>`
    + dots([[27.6, 21.4, 1], [32, 20.4, 1.2], [36.4, 21.4, 1]], SK.teal[5], .7)
    + `<path d="M15.4 34.4l3 1.2M15.8 37.4l2.6.6M48.6 34.4l-3 1.2M48.2 37.4l-2.6.6" stroke="${SK.teal[5]}" stroke-width="1.3" stroke-linecap="round" opacity=".7"/>`
    + face(32, 31.5, 'teal', { mouth: smile(32, 40.6, 'teal', 3.8, 3.4) }),

    // 3. Scrunchie Cadet: a big ponytail sprouting from the dome, scrunchie, butterfly clips
    uniform('yel')
    + fin(13.4, 30, -1, 'yel', .92) + fin(46.6, 30, 1, 'yel', .92)
    + head(30, 26, 19, 18.5, 20.5, 'yel')
    + `<path d="M43 11.5C49 3 60.5 4 61.3 14C62 23 56.5 30.5 58.6 40C52.8 36.4 50.2 29 50.8 22.8C51.2 18.4 49.2 16 46.4 15.8Z" fill="url(#cad-amber)" stroke="#7A4600" stroke-width="2.1" stroke-linejoin="round"/>`
    + `<path d="M51 8.4Q58.2 9 57.6 19M54.6 23.6Q53 30 55.6 35.6" fill="none" stroke="#FFF2B8" stroke-width="1.5" stroke-linecap="round" opacity=".75"/>`
    + `<path d="M41.8 7.8Q44.1 6.8 46 8.9Q48.4 9 48.2 11.7Q50 13.5 48.1 15.6Q48.3 18.3 45.6 18.3Q43.8 20.1 41.6 18.5Q39 18.7 39.2 16Q37.4 14.1 39.3 12.1Q39.2 9.3 41.8 7.8Z" fill="url(#cad-scr)" stroke="#7A0E44" stroke-width="1.7" stroke-linejoin="round"/>`
    + `<circle cx="41.8" cy="11.5" r=".9" fill="#fff"/><circle cx="45.6" cy="15" r=".9" fill="#fff"/><circle cx="41.3" cy="15.7" r=".8" fill="#fff" opacity=".85"/><circle cx="45.4" cy="10.7" r=".8" fill="#fff" opacity=".85"/>`
    + butterfly(55.5, 8.6, 20, '#3FE6FF') + butterfly(57.6, 25.4, -15, '#C59BFF')
    + dots([[16.4, 33.8, .9], [18.6, 35.6, .9], [15.8, 36.8, .8], [43.6, 33.8, .9], [41.4, 35.6, .9], [44.2, 36.8, .8]], SK.yel[5], .8)
    + dots([[23, 12.6, 1.3], [27.4, 10.8, 1.1], [24.6, 16.2, .9]], SK.yel[5], .55)
    + face(30, 28.5, 'yel')
    + `<path d="M17.2 23.6L15.4 22.2M16.4 26L14.4 25.4M42.8 23.6L44.6 22.2M43.6 26L45.6 25.4" stroke="${INK.yel}" stroke-width="1.4" stroke-linecap="round"/>`,

    // 4. Mixtape Cadet: foam headphones over the dome, a little third eye, cassette player on the collar
    uniform('pur')
    + fin(14.2, 27, -1, 'pur', 1.02) + fin(49.8, 27, 1, 'pur', 1.02)
    + head(32, 27, 19.5, 17.5, 20, 'pur')
    + `<path d="M25.4 12.6Q28 11.2 30 12.4M34 12.4Q36 11.2 38.6 12.6" fill="none" stroke="${SK.pur[5]}" stroke-width="1.2" stroke-linecap="round" opacity=".6"/>`
    + dots([[24.4, 17.6, 1], [39.6, 17.6, 1], [22.6, 20.6, .8], [41.4, 20.6, .8]], SK.pur[5], .7)
    + `<ellipse cx="32" cy="18.2" rx="2.7" ry="3.2" fill="url(#cad-epur)" stroke="${INK.pur}" stroke-width="1.4"/><circle cx="31.1" cy="17.1" r="1" fill="#fff"/>`
    + `<path d="M12.6 26.5C11 14 20 8.6 32 8.6C44 8.6 53 14 51.4 26.5" fill="none" stroke="#1A1240" stroke-width="5.2" stroke-linecap="round"/>`
    + `<path d="M12.6 26.5C11 14 20 8.6 32 8.6C44 8.6 53 14 51.4 26.5" fill="none" stroke="#C3CAE0" stroke-width="2.5" stroke-linecap="round"/>`
    + `<path d="M15 17Q19.6 11 27 9.8" fill="none" stroke="#fff" stroke-width="1.1" stroke-linecap="round" opacity=".8"/>`
    + `<circle cx="11.6" cy="29.5" r="7" fill="url(#cad-foam)" stroke="#6E3204" stroke-width="2.1"/><circle cx="52.4" cy="29.5" r="7" fill="url(#cad-foam)" stroke="#6E3204" stroke-width="2.1"/>`
    + `<g fill="#C9600A" opacity=".5"><circle cx="9.4" cy="30.4" r=".8"/><circle cx="12.6" cy="32.8" r=".8"/><circle cx="14" cy="28.6" r=".8"/><circle cx="10.2" cy="34" r=".7"/><circle cx="50.2" cy="30.4" r=".8"/><circle cx="53.4" cy="32.8" r=".8"/><circle cx="54.8" cy="28.6" r=".8"/><circle cx="51" cy="34" r=".7"/></g>`
    + `<ellipse cx="9.4" cy="26.4" rx="2.4" ry="1.5" transform="rotate(-35 9.4 26.4)" fill="#fff" opacity=".7"/><ellipse cx="50.2" cy="26.4" rx="2.4" ry="1.5" transform="rotate(-35 50.2 26.4)" fill="#fff" opacity=".7"/>`
    + face(32, 29.6, 'pur', { sp: 8.6, w: 5.3, h: 6.6 })
    + `<path d="M48.6 51Q56.6 46 53.6 36.4" fill="none" stroke="#1A1240" stroke-width="1.5" stroke-linecap="round"/>`
    + `<rect x="35.6" y="50.6" width="15.4" height="11.4" rx="2" fill="url(#cad-chrome)" stroke="#1A1240" stroke-width="1.9"/>`
    + `<rect x="37.7" y="52.9" width="11.2" height="6.3" rx="1.2" fill="#1A1430"/>`
    + `<circle cx="40.8" cy="56" r="1.8" fill="#E9ECF8"/><circle cx="45.9" cy="56" r="1.8" fill="#E9ECF8"/><circle cx="40.8" cy="56" r=".7" fill="#1A1430"/><circle cx="45.9" cy="56" r=".7" fill="#1A1430"/>`
    + `<rect x="38.4" y="48.6" width="4" height="2.2" rx=".6" fill="#FF8A2A" stroke="#1A1240" stroke-width=".9"/><path d="M37.2 52H40.8" stroke="#fff" stroke-width="1" stroke-linecap="round" opacity=".8"/>`,

    // 5. Aviator Cadet: big swept fins, mirrored aviators over glossy alien eyes, shearling collar
    uniform('tan', 'leather',
      `<path d="M27.6 51Q23 49.8 20.6 51.8Q17.4 50.8 15.2 53.4Q11.8 53.4 11.4 56.6Q9 58.6 11.6 60.4Q11.8 62.8 14.8 62.4Q16.6 63.6 19 62.6L20.6 55.6Q23 53 28.4 52.4ZM36.4 51Q41 49.8 43.4 51.8Q46.6 50.8 48.8 53.4Q52.2 53.4 52.6 56.6Q55 58.6 52.4 60.4Q52.2 62.8 49.2 62.4Q47.4 63.6 45 62.6L43.4 55.6Q41 53 35.6 52.4Z" fill="url(#cad-fleece)" stroke="#7A5530" stroke-width="1.7" stroke-linejoin="round"/>`
      + `<path d="M13.4 57.8q.9-1.1 2 0M16.6 54.6q.9-1.1 2 0M48.6 57.8q.9-1.1 2 0M45.4 54.6q.9-1.1 2 0" fill="none" stroke="#C9A06C" stroke-width=".9" stroke-linecap="round"/>`)
    + fin(14.4, 29, -1, 'tan', .9, 'wing') + fin(49.6, 29, 1, 'tan', .9, 'wing')
    + head(32, 26, 19.5, 18.5, 20.5, 'tan')
    + `<path d="M32 9.5V20" stroke="${SK.tan[5]}" stroke-width="2.6" stroke-linecap="round" opacity=".45"/>`
    + dots([[25.4, 12.4, 1.2], [38.6, 12.4, 1.2], [22.6, 16, .9], [41.4, 16, .9]], SK.tan[5], .6)
    + eyes(32, 28.6, 9.4, 'tan', 16, 5.4, 6.4)
    + `<path d="${lenses(32, 9.4, 28.6)}" fill="url(#cad-lens)" opacity=".72"/>`
    + `<path d="${lenses(32, 9.4, 28.6)}" fill="none" stroke="#3A1A00" stroke-width="3" stroke-linejoin="round"/><path d="${lenses(32, 9.4, 28.6)}" fill="none" stroke="#FFD23F" stroke-width="1.2" stroke-linejoin="round"/>`
    + `<path d="M23.4 21.8H40.6M29.8 25.2Q32 23.6 34.2 25.2" fill="none" stroke="#3A1A00" stroke-width="2.9" stroke-linecap="round"/><path d="M23.4 21.8H40.6M29.8 25.2Q32 23.6 34.2 25.2" fill="none" stroke="#FFD23F" stroke-width="1.15" stroke-linecap="round"/>`
    + `<path d="M17 31.2L21.8 25.6M37.6 31.2L42.4 25.6" stroke="#fff" stroke-width="1.5" stroke-linecap="round" opacity=".7"/>`
    + nose(32, 36.4, 'tan') + blush(19.6, 38) + blush(44.4, 38) + smile(32, 39.2, 'tan', 4.2, 3.8),

    // 6. Puzzle-Cube Cadet: two long and two little antennae, holding a puzzle cube
    `<g transform="translate(-4 0)">${uniform('lime')}</g>`
    + antenna(20, 12, 13, 10, 8.4, 5.6, 'lime') + antenna(36, 12, 43, 10, 47.6, 5.6, 'lime')
    + antenna(24.6, 10, 23.6, 7.6, 22.8, 5.6, 'lime', 1.9) + antenna(31.4, 10, 32.4, 7.6, 33.2, 5.6, 'lime', 1.9)
    + head(28, 25, 18.5, 17.5, 21, 'lime')
    + dots([[17.4, 18.6, 1.1], [15.6, 21.6, .9], [38.6, 18.6, 1.1], [40.4, 21.6, .9]], SK.lime[5], .7)
    + face(28, 28.5, 'lime', { sp: 8.4 })
    + `<ellipse cx="38.4" cy="52.6" rx="3.2" ry="4.4" fill="url(#cad-lime)" stroke="${INK.lime}" stroke-width="1.7"/><ellipse cx="58.8" cy="51" rx="2.8" ry="4.2" fill="url(#cad-lime)" stroke="${INK.lime}" stroke-width="1.7"/>`
    + cube(49.5, 38)
    + `<rect x="36.6" y="49" width="5.6" height="2.8" rx="1.4" fill="url(#cad-lime)" stroke="${INK.lime}" stroke-width="1.3"/><rect x="36.6" y="52.4" width="5.6" height="2.8" rx="1.4" fill="url(#cad-lime)" stroke="${INK.lime}" stroke-width="1.3"/>`
    + `<rect x="56.6" y="46" width="5.2" height="2.8" rx="1.4" fill="url(#cad-lime)" stroke="${INK.lime}" stroke-width="1.3"/>`,

    // 7. Aerobics Cadet: striped sweatband on the dome, glowing antennae, a waving hand with a wristband
    uniform('red')
    + `<path d="M13.6 57L12.6 35" stroke="${NAVY}" stroke-width="9" stroke-linecap="round"/><path d="M13.6 57L12.6 35" stroke="#2A3A7A" stroke-width="6.1" stroke-linecap="round"/>`
    + `<path d="M7.6 30C6.1 25 6.6 20 7.8 17.5C8.4 15.7 10.6 15.9 10.6 17.8L10.9 14.9C11.1 12.9 13.6 12.9 13.8 14.9L14 14.3C14.3 12.3 16.8 12.5 16.9 14.5L17 18.9C18 17.3 20.2 17.9 19.7 20.1C19 23.5 18.4 27 17.6 30Z" fill="url(#cad-red)" stroke="${INK.red}" stroke-width="1.7" stroke-linejoin="round"/>`
    + `<rect x="6.8" y="29" width="11.6" height="5.8" rx="2" fill="url(#cad-band)" stroke="${INK.red}" stroke-width="1.7"/><path d="M7.8 31H17.4M7.8 33H17.4" stroke="#22C8EE" stroke-width="1"/><path d="M7.8 32H17.4" stroke="#FFC81A" stroke-width="1"/>`
    + antenna(29.5, 12, 24, 8.5, 21, 4.8, 'red') + antenna(42.5, 12, 48, 8.5, 52, 5.2, 'red')
    + head(36, 26, 18.5, 17.5, 21, 'red')
    + `<path d="M18.6 19.4Q36 8.8 53.4 19.4L53.6 25Q36 14.6 18.4 25Z" fill="url(#cad-band)" stroke="${INK.red}" stroke-width="1.8" stroke-linejoin="round"/>`
    + `<path d="M18.6 21.3Q36 10.8 53.4 21.3" fill="none" stroke="#22C8EE" stroke-width="1.3"/><path d="M18.6 23.1Q36 12.6 53.4 23.1" fill="none" stroke="#FFC81A" stroke-width="1.3"/>`
    + dots([[22.2, 34.6, 1.2], [24.4, 37.4, .9], [49.8, 34.6, 1.2], [47.6, 37.4, .9]], '#FFC4BC', .9)
    + face(36, 29.6, 'red', { sp: 8.6 }),

    // 8. Handheld Cadet: a backwards cap perched on the dome, antennae through the strap, a handheld game
    uniform('cob')
    + fin(14, 31, -1, 'cob', 1, 'round') + fin(50, 31, 1, 'cob', 1, 'round')
    + `<path d="M21.6 13.6Q13.6 6.6 8.4 9Q5.8 11.6 9.6 14.6Q13.6 17.4 19.4 18.4Z" fill="#2B4BC8" stroke="${INK.cob}" stroke-width="1.9" stroke-linejoin="round"/>`
    + head(32, 29, 19.5, 17.5, 19, 'cob')
    + `<path d="M19 20.4C18.6 12.4 24.4 8 32 8C39.6 8 45.4 12.4 45 20.4C40.6 18.6 36.4 18 32 18C27.6 18 23.4 18.6 19 20.4Z" fill="url(#cad-cap)" stroke="${INK.cob}" stroke-width="2.1" stroke-linejoin="round"/>`
    + `<path d="M27.8 18.4Q27.8 13.4 32 13.4Q36.2 13.4 36.2 18.4Z" fill="url(#cad-cob)" stroke="${INK.cob}" stroke-width="1.5" stroke-linejoin="round"/>`
    + antenna(30.2, 18, 28.8, 12, 25.4, 5.2, 'cob', 2.5) + antenna(33.8, 18, 35.2, 12, 38.6, 5.2, 'cob', 2.5)
    + `<path d="M28 16.4H36" stroke="#2B4BC8" stroke-width="2"/><path d="M29.6 16.4h.01M32 16.4h.01M34.4 16.4h.01" stroke="#fff" stroke-width="1" stroke-linecap="round"/>`
    + `<path d="M24 10.6Q22.6 14.4 22.8 19M40 10.6Q41.4 14.4 41.2 19" fill="none" stroke="#9EAEDA" stroke-width="1.1" stroke-linecap="round"/>`
    + `<ellipse cx="24.6" cy="11.6" rx="3" ry="1.3" transform="rotate(-30 24.6 11.6)" fill="#fff" opacity=".85"/>`
    + dots([[22, 23.6, 1], [19.8, 26.4, .8], [42, 23.6, 1], [44.2, 26.4, .8]], SK.cob[5], .8)
    + face(32, 30.6, 'cob', { sp: 8.8, mouth: grin(32, 40, 'cob', 3.4) + `<path d="M33.4 41.8Q33.8 44.6 35.6 44.3Q37.2 43.8 36.2 41.2" fill="#FF7FA6" stroke="${INK.cob}" stroke-width="1.2" stroke-linejoin="round"/>` })
    + `<ellipse cx="34" cy="56" rx="3.2" ry="4" fill="url(#cad-cob)" stroke="${INK.cob}" stroke-width="1.7"/><ellipse cx="59.4" cy="56" rx="3" ry="4" fill="url(#cad-cob)" stroke="${INK.cob}" stroke-width="1.7"/>`
    + `<rect x="33" y="47.4" width="28" height="14.8" rx="5" fill="url(#cad-dev)" stroke="#232838" stroke-width="2.1"/>`
    + `<rect x="40.4" y="49.5" width="13.2" height="10.4" rx="1.6" fill="#2A2E44"/><rect x="41.8" y="50.9" width="10.4" height="7.6" rx=".8" fill="url(#cad-scrn)"/>`
    + `<path d="M43.5 56.6h2v-2h2v2h2M48 52.8h1.6" fill="none" stroke="#2C5A1E" stroke-width="1.3"/>`
    + `<path d="M35.2 54.8H39.6M37.4 52.6V57" stroke="#2A2E44" stroke-width="1.8" stroke-linecap="round"/>`
    + `<circle cx="56.4" cy="56.2" r="1.6" fill="#FF3FA4" stroke="#2A2E44" stroke-width=".9"/><circle cx="58.8" cy="53" r="1.6" fill="#FFD23F" stroke="#2A2E44" stroke-width=".9"/>`
    + `<path d="M36 49.2H48" stroke="#fff" stroke-width="1.2" stroke-linecap="round" opacity=".8"/>`,

    // 9. Grunge Cadet: bucket hat on the dome with antennae poking through, shaggy hair, flannel
    uniform('sil', 'plaid',
      `<path d="M27.4 51.6L14.8 54.6L20.8 62ZM36.6 51.6L49.2 54.6L43.2 62Z" fill="url(#cad-plaid)" stroke="${NAVY}" stroke-width="1.9" stroke-linejoin="round"/>`)
    + fin(14.6, 33.5, -1, 'sil', .95, 'droop') + fin(49.4, 33.5, 1, 'sil', .95, 'droop')
    + head(32, 31, 19.5, 17, 18.5, 'sil')
    + `<path d="M15.4 27.6Q32 23.8 48.6 27.6L48.4 31Q32 27.2 15.6 31Z" fill="#4A4078" opacity=".2"/>`
    + `<path d="M15.8 25.4Q13 33.6 15.2 42.4Q16.8 37.6 18.4 34.2Q18.8 38.6 20.6 41Q21 33.4 22.8 26.6ZM48.2 25.4Q51 33.6 48.8 42.4Q47.2 37.6 45.6 34.2Q45.2 38.6 43.4 41Q43 33.4 41.2 26.6Z" fill="url(#cad-shag)" stroke="#3A2414" stroke-width="1.5" stroke-linejoin="round"/>`
    + antenna(26, 10, 20.5, 7, 16, 5.6, 'sil', 2.7) + antenna(38, 10, 43.5, 7, 48, 5.6, 'sil', 2.7)
    + `<path d="M22 20C22 12.6 25.8 8.4 32 8.4C38.2 8.4 42 12.6 42 20Z" fill="url(#cad-hat)" stroke="#2C2456" stroke-width="2.1" stroke-linejoin="round"/>`
    + `<ellipse cx="26" cy="11.4" rx="1.7" ry="1.1" fill="#2C2456"/><ellipse cx="38" cy="11.4" rx="1.7" ry="1.1" fill="#2C2456"/>`
    + `<path d="M24.4 15.6Q32 14.2 39.6 15.6" fill="none" stroke="#2C2456" stroke-width=".95" stroke-dasharray="1.5 1.3" opacity=".7"/>`
    + `<path d="M22 18.6Q32 16.8 42 18.6L50.6 26Q51.2 28 48.8 27.8Q32 24.2 15.2 27.8Q12.8 28 13.4 26Z" fill="url(#cad-hat)" stroke="#2C2456" stroke-width="2.1" stroke-linejoin="round"/>`
    + `<path d="M18.4 23.8Q32 20.8 45.6 23.8" fill="none" stroke="#2C2456" stroke-width=".95" stroke-dasharray="1.5 1.3" opacity=".7"/>`
    + `<path d="M25.6 16.4Q26 12.4 28.8 11.2M16.4 25L20.8 21" fill="none" stroke="#fff" stroke-width="1.5" stroke-linecap="round" opacity=".6"/>`
    + dots([[21.6, 39.4, .8], [23.4, 41, .8], [21, 41.8, .7], [42.4, 39.4, .8], [40.6, 41, .8], [43, 41.8, .7]], SK.sil[5], .85)
    + face(32, 32.4, 'sil', { sp: 8.6, mouth: grin(32, 41.2, 'sil', 3.4) }),
  ],
};
