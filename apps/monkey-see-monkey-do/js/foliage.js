// Lush, realistic-looking jungle trees.
//  - Trunks and branches: tapered, gently curving tubes with buttress roots,
//    painted bark (with bump), moss and soft contact shadow at the base.
//  - Canopies: thousands of painted leaf-cluster cards, one draw call per leaf
//    kind. Each card is lit as part of a rounded canopy (sunny on top, deep
//    shade inside and underneath), tinted per tree, and flutters in the wind.
//  - Bushes and ferns use the same cards.
// The number of leaf cards drawn follows the graphics level (setLeafDetail).
import * as THREE from './vendor/three.module.min.js';
import { canvas, rng, WIND, mergeGeometries } from './gfx.js';

const TAU = Math.PI * 2;
const UP = new THREE.Vector3(0, 1, 0);
export const LEAF_FRACTION = { low: 0.35, medium: 0.6, high: 1, ultra: 1 };

// ---------------------------------------------------------------- textures

function wrapDraw(c, S, fn) {
  for (const dx of [-S, 0, S]) { c.save(); c.translate(dx, 0); fn(); c.restore(); }
}

let barkTex = null;
/** Bark: ridges and deep vertical fissures, lenticels and lichen. Tiles both ways. */
export function barkTexture() {
  if (barkTex) return barkTex;
  const S = 512;
  const cv = canvas(S, S);
  const c = cv.getContext('2d');
  const r = rng(21);
  c.fillStyle = '#5b4030';
  c.fillRect(0, 0, S, S);
  for (let i = 0; i < 70; i++) {
    const x = r() * S, w = 6 + r() * 34, light = r() < 0.5;
    c.fillStyle = light ? `rgba(140,112,84,${0.08 + r() * 0.14})` : `rgba(38,24,14,${0.1 + r() * 0.16})`;
    wrapDraw(c, S, () => c.fillRect(x, 0, w, S));
  }
  // fissures with a lit ridge beside each
  for (let i = 0; i < 90; i++) {
    const x0 = r() * S, w = 1.2 + r() * 3.6, a = 0.35 + r() * 0.5;
    const pts = [];
    let x = x0, y = -12;
    while (y < S + 12) { pts.push([x, y]); y += 6 + r() * 16; x += (r() - 0.5) * 5; }
    pts.push([x0, S + 12]); // end where it started so it tiles vertically
    wrapDraw(c, S, () => {
      c.beginPath();
      pts.forEach(([px, py], k) => (k ? c.lineTo(px + w * 0.9, py) : c.moveTo(px + w * 0.9, py)));
      c.strokeStyle = `rgba(176,146,112,${a * 0.35})`;
      c.lineWidth = w * 0.7;
      c.stroke();
      c.beginPath();
      pts.forEach(([px, py], k) => (k ? c.lineTo(px, py) : c.moveTo(px, py)));
      c.strokeStyle = `rgba(22,13,7,${a})`;
      c.lineWidth = w;
      c.stroke();
    });
  }
  // little horizontal lenticels
  for (let i = 0; i < 260; i++) {
    const x = r() * S, y = r() * S, w = 3 + r() * 9;
    c.fillStyle = `rgba(30,18,10,${0.25 + r() * 0.3})`;
    wrapDraw(c, S, () => c.fillRect(x, y, w, 1.4));
  }
  // lichen and moss flecks
  for (let i = 0; i < 140; i++) {
    const x = r() * S, y = r() * S, rad = 2 + r() * 9;
    const col = r() < 0.6 ? `rgba(170,182,150,${0.18 + r() * 0.25})` : `rgba(92,128,58,${0.25 + r() * 0.3})`;
    c.fillStyle = col;
    wrapDraw(c, S, () => { c.beginPath(); c.ellipse(x, y, rad, rad * (0.5 + r() * 0.6), r() * TAU, 0, TAU); c.fill(); });
  }
  barkTex = new THREE.CanvasTexture(cv);
  barkTex.colorSpace = THREE.SRGBColorSpace;
  barkTex.wrapS = barkTex.wrapT = THREE.RepeatWrapping;
  barkTex.anisotropy = 4;
  return barkTex;
}

function drawLeaf(c, x, y, ang, len, wid, col, r) {
  c.save();
  c.translate(x, y);
  c.rotate(ang);
  const bend = (r() - 0.5) * wid * 0.6;
  c.beginPath();
  c.moveTo(0, 0);
  c.bezierCurveTo(len * 0.22, -wid * 1.05 + bend, len * 0.72, -wid * 0.95 + bend, len, bend * 0.6);
  c.bezierCurveTo(len * 0.72, wid * 0.85 + bend, len * 0.22, wid * 1.0 + bend, 0, 0);
  c.closePath();
  const [h, s, l] = col;
  const g = c.createLinearGradient(0, 0, len, 0);
  g.addColorStop(0, `hsl(${h - 4},${s}%,${l - 9}%)`);
  g.addColorStop(0.45, `hsl(${h},${s + 4}%,${l}%)`);
  g.addColorStop(1, `hsl(${h - 14},${s + 8}%,${l + 9}%)`);
  c.fillStyle = g;
  c.fill();
  // fold: one half of the blade a little darker
  c.save();
  c.clip();
  const f = c.createLinearGradient(0, -wid, 0, wid);
  f.addColorStop(0, 'rgba(0,0,0,0.22)');
  f.addColorStop(0.5, 'rgba(0,0,0,0)');
  f.addColorStop(0.52, 'rgba(255,255,240,0.07)');
  f.addColorStop(1, 'rgba(0,0,0,0.05)');
  c.fillStyle = f;
  c.fillRect(0, -wid * 1.4, len, wid * 2.8);
  // side veins
  c.strokeStyle = `hsla(${h - 10},40%,${Math.min(80, l + 26)}%,0.22)`;
  c.lineWidth = Math.max(0.6, wid * 0.04);
  const nv = Math.max(3, Math.round(len / 22));
  for (let k = 1; k < nv; k++) {
    const t = k / nv;
    const mx = t * len, my = bend * t * 0.6;
    for (const sgn of [-1, 1]) {
      c.beginPath();
      c.moveTo(mx, my);
      c.quadraticCurveTo(mx + len * 0.08, my + sgn * wid * 0.45, mx + len * 0.16, my + sgn * wid * 0.85 * Math.sin(Math.PI * Math.min(1, t + 0.1)));
      c.stroke();
    }
  }
  c.restore();
  // midrib and a dark edge
  c.strokeStyle = `hsla(${h - 18},45%,${Math.min(82, l + 30)}%,0.55)`;
  c.lineWidth = Math.max(0.8, wid * 0.08);
  c.beginPath();
  c.moveTo(0, 0);
  c.quadraticCurveTo(len * 0.5, bend * 0.7, len * 0.96, bend * 0.6);
  c.stroke();
  c.strokeStyle = 'rgba(10,30,12,0.35)';
  c.lineWidth = 1;
  c.beginPath();
  c.moveTo(0, 0);
  c.bezierCurveTo(len * 0.22, -wid * 1.05 + bend, len * 0.72, -wid * 0.95 + bend, len, bend * 0.6);
  c.bezierCurveTo(len * 0.72, wid * 0.85 + bend, len * 0.22, wid * 1.0 + bend, 0, 0);
  c.stroke();
  c.restore();
}

const leafTexs = {};
/**
 * A cluster of painted leaves on transparent background, twig at the bottom
 * centre. kinds: broad (big tropical leaves), small (dense small leaves),
 * frond (a fern/palm frond).
 */
export function leafTexture(kind) {
  if (leafTexs[kind]) return leafTexs[kind];
  const S = 512;
  const cv = canvas(S, S);
  const c = cv.getContext('2d');
  const r = rng({ broad: 31, small: 37, frond: 43 }[kind] || 31);
  const green = (depth) => [100 + r() * 22, 46 + r() * 18, 24 + r() * 12 + depth * 12];
  c.lineCap = 'round';
  if (kind === 'frond') {
    // a curving rachis with leaflets either side
    const pts = [];
    for (let k = 0; k <= 30; k++) {
      const t = k / 30;
      pts.push([S / 2 + Math.sin(t * 2.2) * 26, S - 6 - t * (S - 30)]);
    }
    c.strokeStyle = '#4c6a2a';
    c.lineWidth = 5;
    c.beginPath();
    pts.forEach(([x, y], k) => (k ? c.lineTo(x, y) : c.moveTo(x, y)));
    c.stroke();
    for (let k = 2; k < 30; k++) {
      const t = k / 30;
      const [x, y] = pts[k];
      const len = 150 * Math.sin(Math.PI * Math.min(1, 0.15 + t * 0.95)) + 18;
      for (const sgn of [-1, 1]) {
        const a = -Math.PI / 2 + sgn * (1.05 - t * 0.35) + (r() - 0.5) * 0.12;
        drawLeaf(c, x, y, a, len, len * 0.13, green(t * 0.6 + r() * 0.3), r);
      }
    }
  } else {
    const leaves = [];
    const twigs = kind === 'broad' ? 1 : 3;
    for (let tw = 0; tw < twigs; tw++) {
      const tx0 = S / 2 + (tw - (twigs - 1) / 2) * 60;
      const tipX = S / 2 + (tw - (twigs - 1) / 2) * 150 + (r() - 0.5) * 40;
      const tipY = kind === 'broad' ? 110 : 90 + r() * 80;
      c.strokeStyle = '#4a3a22';
      c.lineWidth = kind === 'broad' ? 6 : 3.5;
      c.beginPath();
      c.moveTo(tx0, S - 4);
      c.quadraticCurveTo((tx0 + tipX) / 2 + (r() - 0.5) * 50, (S + tipY) / 2, tipX, tipY);
      c.stroke();
      const n = kind === 'broad' ? 15 : 22;
      for (let k = 0; k < n; k++) {
        const t = 0.12 + (k / n) * 0.9;
        const x = tx0 + (tipX - tx0) * t, y = S - 4 + (tipY - S + 4) * t;
        const sgn = k % 2 ? 1 : -1;
        const base = Math.atan2(tipY - (S - 4), tipX - tx0);
        const a = base + sgn * (0.55 + r() * 0.65) * (1 - t * 0.4);
        const len = kind === 'broad' ? 120 + r() * 95 : 48 + r() * 46;
        leaves.push({ x, y, a, len, wid: len * (kind === 'broad' ? 0.36 : 0.4), depth: r() });
      }
      if (kind === 'broad') leaves.push({ x: tipX, y: tipY + 10, a: -Math.PI / 2 + (r() - 0.5) * 0.4, len: 150, wid: 54, depth: 1 });
    }
    leaves.sort((p, q) => p.depth - q.depth); // back leaves first, a little darker
    for (const L of leaves) drawLeaf(c, L.x, L.y, L.a, L.len, L.wid, green(L.depth), r);
  }
  const t = new THREE.CanvasTexture(cv);
  t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = 4;
  leafTexs[kind] = t;
  return t;
}

// ---------------------------------------------------------------- materials

function foliageMaterial(map, a2c) {
  const m = new THREE.MeshLambertMaterial({ map, alphaTest: a2c ? 0.38 : 0.5, side: THREE.DoubleSide, alphaToCoverage: !!a2c });
  m.onBeforeCompile = (sh) => {
    sh.uniforms.uWindT = WIND.time;
    sh.vertexShader = sh.vertexShader
      .replace('#include <common>', '#include <common>\nuniform float uWindT;\nattribute vec3 aOut;')
      // canopy lighting: each card takes the normal of the rounded canopy it belongs to
      .replace('#include <defaultnormal_vertex>', 'vec3 transformedNormal = normalMatrix * normalize( aOut );')
      .replace('#include <begin_vertex>', `#include <begin_vertex>
      {
        vec3 ip = instanceMatrix[3].xyz;
        float ph = ip.x * 0.71 + ip.z * 0.53 + ip.y * 0.37;
        float f = position.y;
        transformed.z += sin(uWindT * 2.7 + ph * 3.1) * 0.08 * f;
        transformed.x += sin(uWindT * 1.15 + ph) * 0.05 * f;
      }`);
    // both faces of a card share the canopy normal (no dark backs)
    sh.fragmentShader = sh.fragmentShader.replace('#include <normal_fragment_begin>', '#include <normal_fragment_begin>\n\tnormal = normalize( vNormal );');
  };
  m.customProgramCacheKey = () => `msmd-foliage-${a2c ? 1 : 0}`;
  return m;
}

function cardGeometry() {
  // a slightly cupped card, twig at the bottom centre, y = 0..1
  const g = new THREE.PlaneGeometry(1, 1, 1, 2);
  g.translate(0, 0.5, 0);
  const p = g.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const y = p.getY(i);
    p.setZ(i, Math.sin(y * Math.PI) * 0.08 - y * y * 0.12);
  }
  g.deleteAttribute('normal');
  return g;
}

// ---------------------------------------------------------------- wood

/** Sweep a ring along a curve; radiusAt(t, theta) gives the radius. */
function sweep(points, radiusAt, colorAt, { radial = 12, rings = 16, uRepeat = 2, vScale = 2.4 } = {}) {
  const curve = new THREE.CatmullRomCurve3(points);
  const frames = curve.computeFrenetFrames(rings, false);
  const len = curve.getLength();
  const pos = [], nor = [], uv = [], col = [], idx = [];
  const P = new THREE.Vector3(), D = new THREE.Vector3();
  const C = new THREE.Color();
  for (let i = 0; i <= rings; i++) {
    const t = i / rings;
    curve.getPointAt(t, P);
    const N = frames.normals[i], B = frames.binormals[i];
    for (let j = 0; j <= radial; j++) {
      const th = (j / radial) * TAU;
      D.copy(N).multiplyScalar(Math.cos(th)).addScaledVector(B, Math.sin(th));
      const rad = radiusAt(t, th);
      pos.push(P.x + D.x * rad, P.y + D.y * rad, P.z + D.z * rad);
      nor.push(D.x, D.y, D.z);
      uv.push((j / radial) * uRepeat, (t * len) / vScale);
      colorAt(t, th, P.y, C);
      col.push(C.r, C.g, C.b);
    }
  }
  for (let i = 0; i < rings; i++) {
    for (let j = 0; j < radial; j++) {
      const a = i * (radial + 1) + j, b = a + radial + 1;
      idx.push(a, b, a + 1, b, b + 1, a + 1);
    }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute('normal', new THREE.Float32BufferAttribute(nor, 3));
  g.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
  g.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  g.setIndex(idx);
  return { geo: g, curve };
}

// ---------------------------------------------------------------- forest

const _m = new THREE.Matrix4(), _q = new THREE.Quaternion(), _q2 = new THREE.Quaternion();
const _s = new THREE.Vector3(), _d = new THREE.Vector3(), _p = new THREE.Vector3();
const MOSS = new THREE.Color('#7fa860');

export class Forest {
  /** groundY: height of the ground; a2c: smooth leaf edges (needs antialiasing). */
  constructor({ seed = 5, groundY = -0.27, a2c = true } = {}) {
    this.r = rng(seed);
    this.groundY = groundY;
    this.a2c = a2c;
    this.wood = [];
    this.cards = { broad: [], small: [], frond: [] };
  }

  /** Leaf cards spread through a rounded clump. */
  clump(kind, cx, cy, cz, R, { density = 1, size = 1.4, tint = [1, 1, 1], flat = 0.75, droop = 0.25 } = {}) {
    const r = this.r;
    const n = Math.max(3, Math.round(R * R * 9 * density));
    for (let k = 0; k < n; k++) {
      // a random direction, the clump a little flattened
      _d.set(r() * 2 - 1, (r() * 2 - 1) * flat, r() * 2 - 1);
      if (_d.lengthSq() < 0.01) _d.set(0, 1, 0);
      _d.normalize();
      const dist = R * (0.3 + 0.7 * Math.sqrt(r()));
      _p.set(cx + _d.x * dist, cy + _d.y * dist * flat, cz + _d.z * dist);
      // leaves radiate outward and droop a little
      const dir = _d.clone().add(new THREE.Vector3((r() - 0.5) * 0.6, -droop + (r() - 0.5) * 0.5, (r() - 0.5) * 0.6)).normalize();
      _q.setFromUnitVectors(UP, dir);
      _q2.setFromAxisAngle(dir, r() * TAU);
      _q.premultiply(_q2);
      const sc = size * (0.7 + r() * 0.6);
      const out = _d.clone().add(new THREE.Vector3(0, 0.55, 0)).normalize();
      // light: deep inside and low in the clump is darker
      const ao = 0.42 + 0.58 * Math.pow(dist / R, 0.8);
      const top = 0.88 + 0.22 * _d.y;
      const v = ao * top * (0.9 + r() * 0.2);
      this.cards[kind].push({
        m: _m.compose(_p, _q, _s.set(sc, sc, sc)).clone(),
        out,
        c: [tint[0] * v, tint[1] * v, tint[2] * v],
      });
    }
  }

  /** A tall jungle tree with buttress roots, branches and leafy clumps. */
  tree(x, z, h, { far = false, kinds = ['broad', 'small'], seed = 0 } = {}) {
    const r = this.r;
    if (seed) for (let i = 0; i < seed; i++) r();
    const gy = this.groundY;
    const r0 = (0.32 + r() * 0.12) * (h / 7);
    const lean = [(r() - 0.5) * 0.7, (r() - 0.5) * 0.5];
    const pts = [];
    for (let k = 0; k <= 4; k++) {
      const t = k / 4;
      pts.push(new THREE.Vector3(x + lean[0] * t * t + Math.sin(t * 3 + x) * 0.12, gy - 0.3 + t * (h + 0.3), z + lean[1] * t * t + Math.cos(t * 2.5 + z) * 0.1));
    }
    const fins = 4 + Math.floor(r() * 3), finOff = r() * TAU, flare = far ? 0.8 : 1.5 + r() * 0.6;
    const mossSide = r() * TAU;
    const radius = (t, th) => {
      const base = r0 * (1 - 0.58 * t);
      const w = t < 0.16 ? Math.pow(1 - t / 0.16, 2.2) : 0;
      const fin = Math.pow(0.5 + 0.5 * Math.cos(fins * th + finOff), 5);
      return base * (1 + flare * w * (0.25 + 1.7 * fin));
    };
    const color = (t, th, y, C) => {
      const ao = 0.5 + 0.5 * Math.min(1, (y - gy) / 1.4);
      const moss = Math.max(0, 1 - t / 0.45) * (0.45 + 0.55 * (0.5 + 0.5 * Math.cos(th - mossSide))) * 0.75;
      C.setRGB(1, 1, 1).lerp(MOSS, moss).multiplyScalar(ao * (t > 0.75 ? 0.82 : 1));
    };
    const trunk = sweep(pts, radius, color, { radial: far ? 8 : 16, rings: far ? 8 : 22, uRepeat: 2 });
    this.wood.push(trunk.geo);
    const tint = [0.85 + r() * 0.25, 0.92 + r() * 0.16, 0.7 + r() * 0.3];
    const dens = far ? 0.22 : 0.68;
    const size = far ? 2.6 : 1.5;
    // branches
    const nb = far ? 3 : 4 + Math.floor(r() * 3);
    const a0 = r() * TAU;
    for (let b = 0; b < nb; b++) {
      const t = 0.5 + (b / nb) * 0.4 + r() * 0.06;
      const start = trunk.curve.getPointAt(t);
      const a = a0 + (b / nb) * TAU + (r() - 0.5) * 0.8;
      const L = h * (0.24 + r() * 0.16);
      const rise = 0.55 + r() * 0.6;
      const dir = new THREE.Vector3(Math.cos(a), rise, Math.sin(a)).normalize();
      const end = start.clone().addScaledVector(dir, L).add(new THREE.Vector3(0, L * 0.18, 0));
      const mid = start.clone().addScaledVector(dir, L * 0.5).add(new THREE.Vector3(0, -L * 0.04, 0));
      const rb = r0 * (1 - 0.58 * t) * 0.55;
      if (!far) {
        const br = sweep([start.clone().addScaledVector(dir, -rb), mid, end], (tt) => rb * (1 - 0.78 * tt), (tt, th, y, C) => C.setRGB(0.92, 0.92, 0.9).multiplyScalar(0.85), { radial: 8, rings: 7, uRepeat: 1 });
        this.wood.push(br.geo);
      }
      const R = (far ? 2.2 : 1.35) + r() * 0.7;
      this.clump(kinds[b % kinds.length], end.x, end.y + R * 0.2, end.z, R, { density: dens, size, tint });
      if (!far && r() < 0.7) this.clump(kinds[(b + 1) % kinds.length], mid.x, mid.y + 0.2, mid.z, 0.8 + r() * 0.3, { density: dens, size: size * 0.85, tint });
    }
    // crown
    const top = trunk.curve.getPointAt(1);
    const RC = (far ? 2.8 : 1.9) + r() * 0.7;
    this.clump(kinds[0], top.x, top.y + RC * 0.25, top.z, RC, { density: dens, size: size * 1.05, tint });
  }

  /** A low leafy bush. */
  bush(x, z, R) {
    const r = this.r;
    const tint = [0.8 + r() * 0.2, 0.95 + r() * 0.1, 0.75 + r() * 0.25];
    this.clump(r() < 0.5 ? 'broad' : 'small', x, this.groundY + R * 0.55, z, R, { density: 1.1, size: 0.95, tint, flat: 0.6, droop: 0.1 });
  }

  /** A fern: fronds arching out from one spot. */
  fern(x, z, size = 1.2, n = 8) {
    const r = this.r;
    const a0 = r() * TAU;
    for (let k = 0; k < n; k++) {
      const a = a0 + (k / n) * TAU + (r() - 0.5) * 0.4;
      const dir = new THREE.Vector3(Math.cos(a), 0.75 + r() * 0.5, Math.sin(a)).normalize();
      _q.setFromUnitVectors(UP, dir);
      // lay the frond's face towards the sky
      _q2.setFromAxisAngle(dir, a + Math.PI / 2 + (r() - 0.5) * 0.5);
      _q.premultiply(_q2);
      const sc = size * (0.75 + r() * 0.5);
      _p.set(x, this.groundY, z);
      const v = 0.75 + r() * 0.3;
      this.cards.frond.push({ m: _m.compose(_p, _q, _s.set(sc * 0.7, sc, sc)).clone(), out: new THREE.Vector3(dir.x * 0.4, 1, dir.z * 0.4).normalize(), c: [v * 0.92, v, v * 0.85] });
    }
  }

  build() {
    const g = new THREE.Group();
    if (this.wood.length) {
      const bark = barkTexture();
      const mat = new THREE.MeshLambertMaterial({ map: bark, bumpMap: bark, bumpScale: 1.6, vertexColors: true });
      mat.userData.bump = bark; // bark relief only on High and Ultra (setLeafDetail)
      const m = new THREE.Mesh(mergeGeometries(this.wood), mat);
      m.name = 'trunks';
      g.add(m);
      for (const w of this.wood) w.dispose();
    }
    for (const [kind, list] of Object.entries(this.cards)) {
      if (!list.length) continue;
      const card = cardGeometry(); // each kind has its own per-card aOut
      // shuffle, so drawing fewer cards on lower graphics thins every tree evenly
      for (let i = list.length - 1; i > 0; i--) {
        const j = Math.floor(this.r() * (i + 1));
        [list[i], list[j]] = [list[j], list[i]];
      }
      const mesh = new THREE.InstancedMesh(card, foliageMaterial(leafTexture(kind), this.a2c), list.length);
      const out = new Float32Array(list.length * 3);
      const col = new THREE.Color();
      list.forEach((L, i) => {
        mesh.setMatrixAt(i, L.m);
        mesh.setColorAt(i, col.setRGB(L.c[0], L.c[1], L.c[2]));
        out[i * 3] = L.out.x; out[i * 3 + 1] = L.out.y; out[i * 3 + 2] = L.out.z;
      });
      card.setAttribute('aOut', new THREE.InstancedBufferAttribute(out, 3));
      mesh.instanceMatrix.needsUpdate = true;
      mesh.computeBoundingSphere();
      mesh.name = 'leaves-' + kind;
      mesh.userData.leafFull = list.length;
      g.add(mesh);
    }
    return g;
  }
}

/** Fewer leaf cards, and flat bark, on lower graphics levels. */
export function setLeafDetail(root, level) {
  const f = LEAF_FRACTION[level] ?? 1;
  const relief = level === 'high' || level === 'ultra';
  root.traverse((o) => {
    if (o.isInstancedMesh && o.userData.leafFull) o.count = Math.max(1, Math.round(o.userData.leafFull * f));
    const m = o.material;
    if (m && m.userData && m.userData.bump) {
      const want = relief ? m.userData.bump : null;
      if (m.bumpMap !== want) { m.bumpMap = want; m.needsUpdate = true; }
    }
  });
}
