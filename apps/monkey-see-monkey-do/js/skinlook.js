// Puts a skin (js/skins.js) on the 3D monkey: fur pattern texture, finish
// (toon, shiny metal, glow, see-through ghost), eye colours, extras (cape,
// wings, halo, horns, antenna, jetpack, mask, eyepatch, bolts, fins, tail
// tips) and a particle aura. Works on WebGL 1 phones too.
import * as THREE from './vendor/three.module.min.js';
import { patternCanvas, GLOW_PATTERNS } from './patterns.js';

const TAU = Math.PI * 2;

function canvasTexture(cv, srgb = true) {
  const t = new THREE.CanvasTexture(cv);
  if (srgb) t.colorSpace = THREE.SRGBColorSpace;
  t.wrapS = THREE.RepeatWrapping;
  t.wrapT = THREE.ClampToEdgeWrapping;
  return t;
}

/** A shiny "matcap" ball for metal finishes: highlight, body colour, dark rim. */
const matcaps = new Map();
const matcapTextures = new Set();
export function matcap(color) {
  if (matcaps.has(color)) return matcaps.get(color);
  const S = 128;
  const cv = document.createElement('canvas');
  cv.width = cv.height = S;
  const g = cv.getContext('2d');
  const c = new THREE.Color(color);
  const css = (k, add = 0) => `rgb(${[c.r, c.g, c.b].map((v) => Math.round(Math.min(1, v * k + add) * 255)).join(',')})`;
  const rad = g.createRadialGradient(S * 0.4, S * 0.35, 0, S * 0.5, S * 0.5, S * 0.5);
  rad.addColorStop(0, css(1, 0.85));
  rad.addColorStop(0.18, css(1.05, 0.35));
  rad.addColorStop(0.5, css(1));
  rad.addColorStop(0.82, css(0.55));
  rad.addColorStop(0.95, css(0.8, 0.08));
  rad.addColorStop(1, css(0.4));
  g.fillStyle = rad;
  g.fillRect(0, 0, S, S);
  // a soft second reflection
  const r2 = g.createRadialGradient(S * 0.68, S * 0.72, 0, S * 0.68, S * 0.72, S * 0.18);
  r2.addColorStop(0, 'rgba(255,255,255,0.35)');
  r2.addColorStop(1, 'rgba(255,255,255,0)');
  g.fillStyle = r2;
  g.fillRect(0, 0, S, S);
  const t = canvasTexture(cv);
  t.wrapS = THREE.ClampToEdgeWrapping;
  matcaps.set(color, t);
  matcapTextures.add(t);
  return t;
}

function remember(mat) {
  mat.userData.baseColor = mat.color.clone();
  if (mat.emissive) {
    mat.userData.baseEmissive = mat.emissive.clone();
    mat.userData.baseEI = mat.emissiveIntensity;
  }
  return mat;
}

function furMaterial(monkey, skin, map, glowMap) {
  const finish = skin.finish || 'toon';
  if (finish === 'metal') {
    return remember(new THREE.MeshMatcapMaterial({ matcap: matcap(skin.fur), map, color: 0xffffff }));
  }
  const mat = new THREE.MeshToonMaterial({ color: map ? 0xffffff : skin.fur, map, gradientMap: monkey.gradient });
  if (glowMap) {
    mat.emissive = new THREE.Color(0xffffff);
    mat.emissiveMap = glowMap;
    mat.emissiveIntensity = 0.95;
  } else if (finish === 'glow') {
    mat.emissive = new THREE.Color(skin.glowColor || skin.fur);
    mat.emissiveIntensity = 0.38;
  }
  if (finish === 'ghost') {
    mat.transparent = true;
    mat.opacity = 0.62;
    if (!glowMap) {
      mat.emissive = new THREE.Color(skin.fur);
      mat.emissiveIntensity = 0.3;
    }
  }
  return remember(mat);
}

function skinMaterial(monkey, skin) {
  const mat = new THREE.MeshToonMaterial({ color: skin.skin, gradientMap: monkey.gradient });
  if (skin.finish === 'ghost') {
    mat.transparent = true;
    mat.opacity = 0.75;
  }
  return remember(mat);
}

function disposeMat(mat) {
  if (!mat) return;
  for (const k of ['map', 'emissiveMap']) if (mat[k]) mat[k].dispose();
  mat.dispose();
}

/** Put `skin` on `m` (a Monkey). */
export function applySkin(m, skin) {
  const pat = skin.pattern;
  // fur patterns at 512 px so they stay crisp on sharp phone screens
  const map = pat && pat.type !== 'solid' ? canvasTexture(patternCanvas(pat, 512)) : null;
  const glowMap = pat && GLOW_PATTERNS.has(pat.type) ? canvasTexture(patternCanvas(pat, 512, true)) : null;
  for (const t of [map, glowMap]) if (t) t.anisotropy = 4;
  const template = furMaterial(m, skin, map, glowMap);
  const skinTemplate = skinMaterial(m, skin);
  const old = [];
  for (const [region, r] of Object.entries(m.mats)) {
    old.push(r.fur, r.skin);
    r.fur = remember(template.clone());
    r.skin = remember(skinTemplate.clone());
    m.mats[region] = r;
  }
  for (const it of m.skinnables) it.mesh.material = m.mats[it.region][it.role];
  // Clones share the textures, so dispose only the old materials' own textures once
  const oldMaps = new Set();
  for (const mat of old) for (const k of ['map', 'emissiveMap']) if (mat && mat[k]) oldMaps.add(mat[k]);
  for (const mat of old) if (mat) mat.dispose();
  for (const t of oldMaps) if (t !== map && t !== glowMap && !matcapTextures.has(t)) t.dispose();
  template.dispose();
  skinTemplate.dispose();

  m.darkMat.color.set(skin.dark || '#3a2010');
  const eyes = skin.eyes || {};
  m.eyeWhiteMat.color.set(eyes.white || '#ffffff');
  m.pupilMat.color.set(eyes.pupil || '#1b0f08');
  if (m.setEyes) m.setEyes(eyes);
  m.outlineMat.transparent = skin.finish === 'ghost';
  m.outlineMat.opacity = skin.finish === 'ghost' ? 0.3 : 1;
  m.outlineMat.needsUpdate = true;
  m.rainbow = !!skin.rainbow;
  buildExtras(m, skin.extras || [], skin);
  m.skin = skin;
  if (m.gearAura) setAura(m, m.gearAura.type, m.gearAura.color);
  else setAura(m, skin.aura || null, skin.auraColor || '#ffffff');
}

/** Light a material up in a move's colour (k: 0..1) and back. */
export function flashMaterial(mat, color, k) {
  const u = mat.userData;
  if (!u.baseColor) return;
  mat.color.copy(u.baseColor).lerp(color, 0.45 * k);
  if (mat.emissive && u.baseEmissive) {
    if (mat.emissiveMap) {
      mat.emissive.copy(u.baseEmissive).lerp(color, k);
    } else {
      mat.emissive.copy(u.baseEmissive).multiplyScalar(u.baseEI).lerp(color, 0.8 * k);
      mat.emissiveIntensity = k > 0 ? 1 : u.baseEI;
      if (k <= 0) mat.emissive.copy(u.baseEmissive);
    }
  }
}

// ---------------------------------------------------------------- extras

function toon(m, color, opts = {}) {
  return new THREE.MeshToonMaterial({ color, gradientMap: m.gradient, ...opts });
}

function outlined(m, group, geo, mat, scale = 1.08) {
  const mesh = new THREE.Mesh(geo, mat);
  group.add(mesh);
  const o = new THREE.Mesh(geo, m.outlineMat);
  o.scale.setScalar(scale);
  group.add(o);
  mesh.userData.outlineMesh = o;
  return mesh;
}

export function wingShape(kind) {
  const s = new THREE.Shape();
  if (kind === 'dragon') {
    s.moveTo(0, 0);
    s.lineTo(0.3, 0.55);
    s.lineTo(1.05, 0.62);
    s.quadraticCurveTo(0.85, 0.42, 0.92, 0.2);
    s.quadraticCurveTo(0.72, 0.15, 0.72, -0.08);
    s.quadraticCurveTo(0.5, -0.02, 0.42, -0.25);
    s.quadraticCurveTo(0.2, -0.05, 0, 0);
    return [s];
  }
  if (kind === 'fairy') {
    const a = new THREE.Shape();
    a.absellipse(0.42, 0.32, 0.4, 0.27, 0, TAU, false, 0.5);
    const b = new THREE.Shape();
    b.absellipse(0.3, -0.12, 0.24, 0.18, 0, TAU, false, -0.6);
    return [a, b];
  }
  // feathered (angel, phoenix)
  s.moveTo(0, 0);
  s.quadraticCurveTo(0.25, 0.6, 0.62, 0.62);
  s.quadraticCurveTo(0.95, 0.6, 1.05, 0.38);
  const pts = [[0.9, 0.18], [0.78, 0.0], [0.62, -0.16], [0.44, -0.28], [0.24, -0.26]];
  let prev = [1.05, 0.38];
  for (const p of pts) {
    s.quadraticCurveTo((prev[0] + p[0]) / 2 + 0.06, (prev[1] + p[1]) / 2 - 0.08, p[0], p[1]);
    prev = p;
  }
  s.quadraticCurveTo(0.1, -0.15, 0, 0);
  return [s];
}

function clearExtras(m) {
  for (const g of m.extraGroups || []) {
    if (g.parent) g.parent.remove(g);
    g.traverse((o) => {
      if (o.isMesh || o.isPoints) {
        if (o.geometry) o.geometry.dispose();
        if (o.material && o.material !== m.outlineMat) disposeMat(o.material);
      }
    });
  }
  m.extraGroups = [];
  m.skinFx = [];
}

const BACK_EXTRAS = new Set(['cape', 'wings', 'jetpack', 'fin']);

/** Rebuild the current skin's extras (after back gear is put on or taken off). */
export function refreshSkinExtras(m) {
  if (m.skin) buildExtras(m, m.skin.extras || [], m.skin);
}

function buildExtras(m, extras, skin) {
  clearExtras(m);
  const add = (parent, g) => { parent.add(g); m.extraGroups.push(g); return g; };
  const fx = (type, obj, extra = {}) => m.skinFx.push({ type, obj, ...extra });
  for (const e of extras) {
    const [name, a1, a2] = e.split(':');
    if (m.hideBackExtras && BACK_EXTRAS.has(name)) continue; // a back gear item is worn instead
    if (name === 'cape') {
      const g = add(m.chest, new THREE.Group());
      g.position.set(0, 0.86, -0.36);
      const geo = new THREE.PlaneGeometry(0.95, 1.3, 6, 10);
      geo.translate(0, -0.65, 0);
      const p = geo.attributes.position;
      for (let i = 0; i < p.count; i++) {
        const x = p.getX(i), y = p.getY(i);
        const t = -y / 1.3;
        p.setZ(i, -0.28 * t * t + 0.16 * Math.pow(x / 0.475, 2) * (1 - t * 0.5));
        p.setX(i, x * (1 + t * 0.35));
      }
      geo.computeVertexNormals();
      const mesh = new THREE.Mesh(geo, toon(m, a1 || '#c8302a', { side: THREE.DoubleSide }));
      g.add(mesh);
      fx('cape', g);
    } else if (name === 'wings') {
      const kind = a1 || 'angel';
      const color = a2 || (kind === 'angel' ? '#ffffff' : kind === 'phoenix' ? '#ff8a1a' : kind === 'fairy' ? '#ffb3e6' : '#2a6a3a');
      const g = add(m.chest, new THREE.Group());
      g.position.set(0, 0.72, -0.36);
      const geo = new THREE.ShapeGeometry(wingShape(kind), 12);
      const opts = { side: THREE.DoubleSide };
      if (kind === 'fairy') Object.assign(opts, { transparent: true, opacity: 0.72, emissive: new THREE.Color(color), emissiveIntensity: 0.35 });
      if (kind === 'phoenix') Object.assign(opts, { emissive: new THREE.Color('#ff5a10'), emissiveIntensity: 0.55 });
      const mat = toon(m, color, opts);
      for (const s of [-1, 1]) {
        const w = new THREE.Group();
        w.position.set(s * 0.16, 0, 0);
        g.add(w);
        const mesh = new THREE.Mesh(geo, mat);
        mesh.scale.set(s * 0.95, 0.95, 1);
        w.add(mesh);
        if (kind !== 'fairy') {
          const o = new THREE.Mesh(geo, m.outlineMat);
          o.scale.set(s * 0.99, 0.99, 1);
          o.position.z = -0.01;
          w.add(o);
        }
        fx('wing', w, { s });
      }
    } else if (name === 'halo') {
      const g = add(m.hatAnchor, new THREE.Group());
      g.position.y = 0.36;
      const mesh = new THREE.Mesh(new THREE.TorusGeometry(0.27, 0.035, 10, 36), new THREE.MeshBasicMaterial({ color: '#ffd23f' }));
      mesh.rotation.x = Math.PI / 2;
      g.add(mesh);
      fx('bob', g, { base: 0.36 });
    } else if (name === 'horns') {
      const g = add(m.j.head, new THREE.Group());
      for (const s of [-1, 1]) {
        const h = new THREE.Group();
        h.position.set(s * 0.27, 0.92, 0.06);
        h.rotation.z = -s * 0.5;
        g.add(h);
        const mesh = outlined(m, h, new THREE.ConeGeometry(0.075, 0.3, 12), toon(m, a1 || '#f4e4c0'));
        mesh.position.y = 0.13;
        mesh.userData.outlineMesh.position.y = 0.13;
      }
    } else if (name === 'unihorn') {
      const g = add(m.j.head, new THREE.Group());
      g.position.set(0, 0.96, 0.3);
      g.rotation.x = 0.55;
      const mesh = outlined(m, g, new THREE.ConeGeometry(0.065, 0.44, 16), toon(m, '#fff2c8', { emissive: new THREE.Color('#fff2c8'), emissiveIntensity: 0.25 }));
      mesh.position.y = 0.2;
      mesh.userData.outlineMesh.position.y = 0.2;
      for (let k = 0; k < 3; k++) {
        const ring = new THREE.Mesh(new THREE.TorusGeometry(0.05 - k * 0.012, 0.012, 6, 16), toon(m, '#ffb3e6'));
        ring.rotation.x = Math.PI / 2;
        ring.position.y = 0.06 + k * 0.1;
        g.add(ring);
      }
    } else if (name === 'mane') {
      const g = add(m.j.head, new THREE.Group());
      const cols = ['#ff6fae', '#ffd23f', '#7be0a0', '#4fd8ff', '#b07cff'];
      cols.forEach((c, i) => {
        const b = new THREE.Group();
        b.position.set(0, 1.0 - i * 0.13, -0.12 - i * 0.1);
        g.add(b);
        outlined(m, b, new THREE.SphereGeometry(0.12 - i * 0.008, 14, 10), toon(m, c));
      });
    } else if (name === 'antenna') {
      const g = add(m.j.head, new THREE.Group());
      g.position.y = 0.95;
      for (const s of [-1, 1]) {
        const a = new THREE.Group();
        a.position.set(s * 0.16, 0, 0);
        a.rotation.z = -s * 0.35;
        g.add(a);
        const stalk = new THREE.Mesh(new THREE.CylinderGeometry(0.016, 0.016, 0.36, 8), new THREE.MeshBasicMaterial({ color: '#23160c' }));
        stalk.position.y = 0.18;
        a.add(stalk);
        const ball = new THREE.Mesh(new THREE.SphereGeometry(0.06, 12, 10), new THREE.MeshBasicMaterial({ color: a1 || '#7bff5a' }));
        ball.position.y = 0.38;
        a.add(ball);
        fx('wobble', a, { s, base: -s * 0.35 });
      }
    } else if (name === 'jetpack') {
      const g = add(m.chest, new THREE.Group());
      g.position.set(0, 0.48, -0.46);
      const metal = new THREE.MeshMatcapMaterial({ matcap: matcap('#b8c0cc') });
      for (const s of [-1, 1]) {
        const tank = new THREE.Group();
        tank.position.x = s * 0.14;
        g.add(tank);
        outlined(m, tank, new THREE.CylinderGeometry(0.11, 0.11, 0.48, 16), metal, 1.1);
        const nozzle = new THREE.Mesh(new THREE.ConeGeometry(0.08, 0.12, 12), metal);
        nozzle.position.y = -0.3;
        nozzle.rotation.x = Math.PI;
        tank.add(nozzle);
        const flame = new THREE.Mesh(new THREE.ConeGeometry(0.07, 0.3, 12), new THREE.MeshBasicMaterial({ color: '#ffb020', transparent: true, opacity: 0.9, blending: THREE.AdditiveBlending, depthWrite: false }));
        flame.position.y = -0.5;
        flame.rotation.x = Math.PI;
        tank.add(flame);
        fx('flame', flame, { k: s });
      }
    } else if (name === 'mask') {
      const g = add(m.j.head, new THREE.Group());
      const mat = toon(m, a1 || '#1a1a22');
      for (const s of [-1, 1]) {
        const mesh = new THREE.Mesh(new THREE.SphereGeometry(0.2, 18, 12), mat);
        mesh.position.set(s * 0.17, 0.6, 0.42);
        mesh.scale.set(1.12, 0.92, 0.45);
        g.add(mesh);
      }
    } else if (name === 'eyepatch') {
      const g = add(m.j.head, new THREE.Group());
      const black = toon(m, '#151515');
      const patch = new THREE.Mesh(new THREE.SphereGeometry(0.16, 16, 12), black);
      patch.position.set(0.165, 0.6, 0.47);
      patch.scale.set(1.05, 1.15, 0.4);
      g.add(patch);
      const strap = new THREE.Mesh(new THREE.TorusGeometry(0.585, 0.018, 6, 48), black);
      strap.position.set(0, 0.56, -0.04);
      strap.rotation.set(Math.PI / 2 - 0.05, 0.4, 0);
      g.add(strap);
    } else if (name === 'bolts') {
      const g = add(m.chest, new THREE.Group());
      const metal = new THREE.MeshMatcapMaterial({ matcap: matcap('#9aa2ae') });
      for (const s of [-1, 1]) {
        const b = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.05, 0.2, 12), metal);
        b.rotation.z = Math.PI / 2;
        b.position.set(s * 0.33, 0.86, 0.02);
        g.add(b);
      }
    } else if (name === 'fin') {
      const g = add(m.chest, new THREE.Group());
      g.position.set(0, 0.3, -0.4);
      const shape = new THREE.Shape();
      shape.moveTo(0, 0);
      shape.quadraticCurveTo(-0.15, 0.35, -0.45, 0.42);
      shape.quadraticCurveTo(-0.3, 0.15, -0.35, -0.1);
      shape.quadraticCurveTo(-0.15, -0.05, 0, 0);
      const mesh = new THREE.Mesh(new THREE.ShapeGeometry(shape, 10), toon(m, a1 || '#1e7ab8', { side: THREE.DoubleSide }));
      mesh.rotation.y = Math.PI / 2;
      g.add(mesh);
    } else if (name === 'tailtip') {
      const tip = m.tail[m.tail.length - 1];
      const g = add(tip, new THREE.Group());
      g.position.y = 0.15;
      const kind = a1 || 'star';
      if (kind === 'flame') {
        const outer = new THREE.Mesh(new THREE.ConeGeometry(0.1, 0.32, 12), new THREE.MeshBasicMaterial({ color: '#ff6a10' }));
        outer.position.y = 0.12;
        g.add(outer);
        const inner = new THREE.Mesh(new THREE.ConeGeometry(0.055, 0.2, 10), new THREE.MeshBasicMaterial({ color: '#ffe060' }));
        inner.position.set(0, 0.08, 0.02);
        g.add(inner);
        fx('flicker', g);
      } else if (kind === 'arrow') {
        const mesh = outlined(m, g, new THREE.ConeGeometry(0.11, 0.2, 4), toon(m, a2 || '#d8302a'));
        mesh.position.y = 0.06;
        mesh.userData.outlineMesh.position.y = 0.06;
      } else if (kind === 'fin') {
        const shape = new THREE.Shape();
        shape.moveTo(0, 0);
        shape.quadraticCurveTo(0.25, 0.1, 0.3, 0.32);
        shape.quadraticCurveTo(0.1, 0.22, 0, 0.12);
        shape.quadraticCurveTo(-0.1, 0.22, -0.3, 0.32);
        shape.quadraticCurveTo(-0.25, 0.1, 0, 0);
        const mesh = new THREE.Mesh(new THREE.ShapeGeometry(shape, 8), toon(m, a2 || '#128a80', { side: THREE.DoubleSide }));
        g.add(mesh);
      } else if (kind === 'leaf') {
        const mesh = outlined(m, g, new THREE.SphereGeometry(0.1, 12, 8), toon(m, '#3fa83a'));
        mesh.scale.set(0.6, 1.4, 0.25);
        mesh.userData.outlineMesh.scale.set(0.66, 1.5, 0.3);
        mesh.position.y = 0.08;
        mesh.userData.outlineMesh.position.y = 0.08;
      }
    }
  }
  m.setOutlines(m.outlinesOn);
}

// ---------------------------------------------------------------- aura particles

const AURA = {
  sparkle: { n: 30, rise: 0.25, size: 0.6, add: true, life: [1.2, 2.6] },
  stars: { n: 26, rise: 0.3, size: 0.6, add: true, life: [1.6, 3] },
  embers: { n: 32, rise: 0.9, size: 0.38, add: true, life: [0.9, 1.8] },
  bubbles: { n: 20, rise: 0.45, size: 0.4, add: false, life: [2, 3.5] },
  snow: { n: 34, rise: -0.4, size: 0.42, add: false, life: [3, 5] },
  notes: { n: 14, rise: 0.4, size: 0.5, add: false, life: [2, 3.2] },
  leaves: { n: 14, rise: -0.25, size: 0.45, add: false, life: [3, 4.5] },
  pixels: { n: 28, rise: 0.35, size: 0.36, add: true, life: [1, 2.2] },
  smoke: { n: 16, rise: 0.2, size: 1.1, add: false, life: [2, 3.5] },
  hearts: { n: 18, rise: 0.4, size: 0.5, add: false, life: [1.8, 3] },
  confetti: { n: 30, rise: -0.5, size: 0.3, add: false, life: [2.5, 4] },
};

const sprites = new Map();
function spriteTexture(type, color) {
  const key = type + color;
  if (sprites.has(key)) return sprites.get(key);
  const S = 64;
  const cv = document.createElement('canvas');
  cv.width = cv.height = S;
  const g = cv.getContext('2d');
  g.translate(S / 2, S / 2);
  g.fillStyle = color;
  g.strokeStyle = color;
  const soft = (r, a = 1) => {
    const rad = g.createRadialGradient(0, 0, 0, 0, 0, r);
    rad.addColorStop(0, color);
    rad.addColorStop(1, 'rgba(0,0,0,0)');
    g.globalAlpha = a;
    g.fillStyle = rad;
    g.beginPath(); g.arc(0, 0, r, 0, TAU); g.fill();
    g.globalAlpha = 1;
    g.fillStyle = color;
  };
  const starPath = (r, pts, inner) => {
    g.beginPath();
    for (let k = 0; k < pts * 2; k++) {
      const rr = k % 2 ? r * inner : r;
      const a = -Math.PI / 2 + (k * Math.PI) / pts;
      g.lineTo(Math.cos(a) * rr, Math.sin(a) * rr);
    }
    g.closePath();
    g.fill();
  };
  if (type === 'sparkle') { soft(16, 0.6); starPath(30, 4, 0.18); }
  else if (type === 'hearts') { g.beginPath(); g.moveTo(0, 22); g.bezierCurveTo(-34, 0, -16, -26, 0, -9); g.bezierCurveTo(16, -26, 34, 0, 0, 22); g.fill(); }
  else if (type === 'confetti') { const cols = ['#ff4f9a', '#ffd23f', '#2e8bff', '#1fb57a']; cols.forEach((c, i) => { g.fillStyle = c; g.save(); g.rotate(i * 0.9); g.fillRect(-6 + (i % 2) * 10, -18 + i * 8, 12, 7); g.restore(); }); }
  else if (type === 'stars') { soft(14, 0.5); starPath(26, 5, 0.45); }
  else if (type === 'embers') soft(28);
  else if (type === 'bubbles') { g.lineWidth = 4; g.beginPath(); g.arc(0, 0, 24, 0, TAU); g.stroke(); g.globalAlpha = 0.8; g.beginPath(); g.arc(-9, -9, 5, 0, TAU); g.fill(); }
  else if (type === 'snow') { g.lineWidth = 4; for (let k = 0; k < 3; k++) { g.rotate(Math.PI / 3); g.beginPath(); g.moveTo(-24, 0); g.lineTo(24, 0); g.stroke(); } }
  else if (type === 'notes') { g.beginPath(); g.ellipse(-6, 14, 12, 9, -0.4, 0, TAU); g.fill(); g.fillRect(4, -24, 5, 38); g.fillRect(4, -24, 16, 7); }
  else if (type === 'leaves') { g.beginPath(); g.moveTo(0, -26); g.quadraticCurveTo(22, 0, 0, 26); g.quadraticCurveTo(-22, 0, 0, -26); g.fill(); }
  else if (type === 'pixels') g.fillRect(-16, -16, 32, 32);
  else if (type === 'smoke') soft(30, 0.55);
  const t = canvasTexture(cv);
  t.wrapS = THREE.ClampToEdgeWrapping;
  sprites.set(key, t);
  return t;
}

export function setAura(m, type, color) {
  if (m.aura) {
    m.root.remove(m.aura.points);
    m.aura.points.geometry.dispose();
    m.aura.points.material.dispose();
    m.aura = null;
  }
  if (!type || !AURA[type]) return;
  const cfg = AURA[type];
  const n = cfg.n;
  const pos = new Float32Array(n * 3);
  const col = new Float32Array(n * 4);
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.BufferAttribute(col, 4));
  const mat = new THREE.PointsMaterial({
    size: cfg.size, map: spriteTexture(type, color), transparent: true, depthWrite: false,
    vertexColors: true, blending: cfg.add ? THREE.AdditiveBlending : THREE.NormalBlending, sizeAttenuation: true,
  });
  const points = new THREE.Points(geo, mat);
  points.frustumCulled = false;
  points.renderOrder = 5;
  m.root.add(points);
  const parts = [];
  for (let i = 0; i < n; i++) parts.push({ life: 0, max: 1, x: 0, y: 0, z: 0, a: 0, r: 0 });
  m.aura = { type, cfg, points, parts };
  // place every particle, then stagger when each first appears
  parts.forEach((p, i) => { spawn(p, cfg); p.life = -(i / n) * cfg.life[1]; });
}

function spawn(p, cfg) {
  p.a = Math.random() * TAU;
  p.r = 0.55 + Math.random() * 0.75;
  p.x = Math.cos(p.a) * p.r;
  p.z = Math.sin(p.a) * p.r * 0.7;
  p.y = cfg.rise < 0 ? 3 + Math.random() * 0.8 : 0.2 + Math.random() * 2.6;
  p.max = cfg.life[0] + Math.random() * (cfg.life[1] - cfg.life[0]);
  p.life = 0;
}

/** Per-frame animation for extras and the aura. */
export function updateSkinFx(m, time, dt, energy) {
  for (const f of m.skinFx || []) {
    if (f.type === 'wing') f.obj.rotation.y = f.s * (-0.45 - 0.28 * Math.sin(time * (3 + energy * 6)));
    else if (f.type === 'cape') f.obj.rotation.x = 0.12 + 0.08 * Math.sin(time * 2.2) + energy * 0.25;
    else if (f.type === 'bob') f.obj.position.y = f.base + Math.sin(time * 2) * 0.03;
    else if (f.type === 'wobble') f.obj.rotation.z = f.base + Math.sin(time * 5 + f.s) * 0.12;
    else if (f.type === 'flame') f.obj.scale.set(1, 0.8 + 0.35 * Math.abs(Math.sin(time * 23 + f.k)) + energy * 0.6, 1);
    else if (f.type === 'flicker') f.obj.scale.set(1 + Math.sin(time * 19) * 0.1, 1 + Math.sin(time * 13) * 0.18, 1);
  }
  const au = m.aura;
  if (!au) return;
  const pos = au.points.geometry.attributes.position;
  const col = au.points.geometry.attributes.color;
  const { cfg } = au;
  for (let i = 0; i < au.parts.length; i++) {
    const p = au.parts[i];
    p.life += dt;
    if (p.life < 0) { col.setXYZW(i, 1, 1, 1, 0); continue; }
    if (p.life >= p.max) spawn(p, cfg);
    const t = p.life / p.max;
    p.y += cfg.rise * dt * (1 + energy);
    p.a += dt * (cfg.rise < 0 ? 0.3 : 0.6);
    const sway = au.type === 'bubbles' || au.type === 'snow' || au.type === 'leaves' || au.type === 'confetti' ? Math.sin(time * 2 + i) * 0.08 : 0;
    pos.setXYZ(i, Math.cos(p.a) * p.r + sway, p.y, Math.sin(p.a) * p.r * 0.7);
    const fade = Math.min(1, t * 5) * Math.min(1, (1 - t) * 3);
    col.setXYZW(i, 1, 1, 1, au.type === 'sparkle' || au.type === 'stars' ? fade * (0.6 + 0.4 * Math.sin(time * 9 + i * 2)) : fade);
  }
  pos.needsUpdate = true;
  col.needsUpdate = true;
}
