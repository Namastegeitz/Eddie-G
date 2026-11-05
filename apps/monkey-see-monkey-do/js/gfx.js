// Shared graphics helpers: geometry merging (fewer draw calls, so phones can
// afford more detail), painted canvas textures (sky, grass, sand, moon dust,
// bark, leaves), a soft glow sprite, and the cartoon rim light added to every
// toon material. Everything here works on WebGL 1 phones.
import * as THREE from './vendor/three.module.min.js';

const TAU = Math.PI * 2;

// ---------------------------------------------------------------- rim light
// A thin bright edge on the side facing the rim light, like a cel-shaded
// cartoon. One set of uniforms shared by every material, set once per frame.
export const RIM = {
  color: { value: new THREE.Color('#ffffff') },
  dir: { value: new THREE.Vector3(-0.6, 0.5, -0.6) }, // view space
  strength: { value: 0.55 },
};
// Gentle wind for grass and leaves.
export const WIND = { time: { value: 0 } };

function rimCompile(shader) {
  shader.uniforms.uRimColor = RIM.color;
  shader.uniforms.uRimDir = RIM.dir;
  shader.uniforms.uRimStr = RIM.strength;
  shader.fragmentShader = shader.fragmentShader
    .replace('#include <common>', '#include <common>\nuniform vec3 uRimColor;\nuniform vec3 uRimDir;\nuniform float uRimStr;')
    .replace('#include <opaque_fragment>', `{
      vec3 rimView = normalize(vViewPosition);
      float rimFres = 1.0 - clamp(dot(normal, rimView), 0.0, 1.0);
      float rimSide = clamp(dot(normal, uRimDir) * 1.4 + 0.35, 0.0, 1.0);
      float rimAmt = smoothstep(0.55, 0.66, rimFres) * rimSide * uRimStr;
      outgoingLight += uRimColor * rimAmt * (0.3 + 0.7 * diffuseColor.rgb);
    }
    #include <opaque_fragment>`);
}

/** Give a toon material the rim light (safe to call twice). */
export function addRim(mat) {
  if (!mat || !mat.isMeshToonMaterial || mat.userData.rim) return mat;
  mat.userData.rim = true;
  mat.onBeforeCompile = rimCompile;
  mat.customProgramCacheKey = () => 'msmd-rim-1';
  mat.needsUpdate = true;
  return mat;
}

/** Rim on every toon material under `root` that doesn't have it yet. */
export function rimAll(root) {
  root.traverse((o) => {
    if (!o.material) return;
    for (const m of Array.isArray(o.material) ? o.material : [o.material]) addRim(m);
  });
}

/** Toon material whose vertices sway in the wind (grass, fronds). y = height. */
export function windy(mat, amount = 0.08, freq = 1.7) {
  mat.userData.rim = true;
  mat.onBeforeCompile = (shader) => {
    rimCompile(shader);
    shader.uniforms.uWindT = WIND.time;
    shader.vertexShader = shader.vertexShader
      .replace('#include <common>', '#include <common>\nuniform float uWindT;')
      .replace('#include <begin_vertex>', `#include <begin_vertex>
      {
        vec3 wp = vec3(0.0);
        #ifdef USE_INSTANCING
          wp = instanceMatrix[3].xyz;
        #endif
        float h = max(0.0, position.y);
        transformed.x += sin(uWindT * ${freq.toFixed(2)} + wp.x * 0.6 + wp.z * 0.4) * ${amount.toFixed(3)} * h;
        transformed.z += cos(uWindT * ${(freq * 0.8).toFixed(2)} + wp.x * 0.3) * ${(amount * 0.5).toFixed(3)} * h;
      }`);
  };
  mat.customProgramCacheKey = () => `msmd-wind-${amount}-${freq}`;
  return mat;
}

// ---------------------------------------------------------------- merging

function toIndexed(g) {
  if (g.index) return g;
  const n = g.attributes.position.count;
  const idx = new (n > 65535 ? Uint32Array : Uint16Array)(n);
  for (let i = 0; i < n; i++) idx[i] = i;
  g.setIndex(new THREE.BufferAttribute(idx, 1));
  return g;
}

/** Merge geometries (already in a shared space) into one. */
export function mergeGeometries(list) {
  const geos = list.map((g) => toIndexed(g));
  const hasColor = geos.some((g) => g.attributes.color);
  let nv = 0;
  let ni = 0;
  for (const g of geos) {
    if (!g.attributes.normal) g.computeVertexNormals();
    nv += g.attributes.position.count;
    ni += g.index.count;
  }
  const pos = new Float32Array(nv * 3);
  const nor = new Float32Array(nv * 3);
  const uv = new Float32Array(nv * 2);
  const col = hasColor ? new Float32Array(nv * 3) : null;
  const idx = new (nv > 65535 ? Uint32Array : Uint16Array)(ni);
  let vo = 0;
  let io = 0;
  for (const g of geos) {
    const n = g.attributes.position.count;
    const P = g.attributes.position;
    const N = g.attributes.normal;
    const U = g.attributes.uv;
    const C = g.attributes.color;
    for (let i = 0; i < n; i++) {
      pos[(vo + i) * 3] = P.getX(i); pos[(vo + i) * 3 + 1] = P.getY(i); pos[(vo + i) * 3 + 2] = P.getZ(i);
      nor[(vo + i) * 3] = N.getX(i); nor[(vo + i) * 3 + 1] = N.getY(i); nor[(vo + i) * 3 + 2] = N.getZ(i);
      if (U) { uv[(vo + i) * 2] = U.getX(i); uv[(vo + i) * 2 + 1] = U.getY(i); }
      if (col) {
        if (C) { col[(vo + i) * 3] = C.getX(i); col[(vo + i) * 3 + 1] = C.getY(i); col[(vo + i) * 3 + 2] = C.getZ(i); }
        else { col[(vo + i) * 3] = 1; col[(vo + i) * 3 + 1] = 1; col[(vo + i) * 3 + 2] = 1; }
      }
    }
    const I = g.index;
    for (let k = 0; k < I.count; k++) idx[io + k] = I.getX(k) + vo;
    vo += n;
    io += I.count;
  }
  const out = new THREE.BufferGeometry();
  out.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  out.setAttribute('normal', new THREE.BufferAttribute(nor, 3));
  out.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  if (col) out.setAttribute('color', new THREE.BufferAttribute(col, 3));
  out.setIndex(new THREE.BufferAttribute(idx, 1));
  out.computeBoundingSphere();
  return out;
}

const _inv = new THREE.Matrix4();
const _rel = new THREE.Matrix4();

/**
 * Merge the static meshes under `group` into one mesh per material.
 * shallow: only direct children with userData.static (the monkey's joints).
 * Otherwise every mesh in the subtree except those marked userData.dynamic
 * (or inside a dynamic group), Points and instanced meshes.
 */
export function bakeStatic(group, { shallow = false } = {}) {
  group.updateMatrixWorld(true);
  _inv.copy(group.matrixWorld).invert();
  const buckets = new Map();
  const victims = [];
  const visit = (o, dyn) => {
    for (const c of [...o.children]) {
      // dynamic objects and optional detail groups (baked on their own) are left alone
      const d = dyn || !!c.userData.dynamic || !!c.userData.detailLevel;
      if (c.isMesh && !c.isInstancedMesh && !d && (!shallow || c.userData.static) && !c.isSkinnedMesh) {
        const m = c.material;
        if (Array.isArray(m)) continue;
        const key = m.uuid + (c.castShadow ? 'c' : '') + (c.receiveShadow ? 'r' : '') + (c.visible ? '' : 'h') + (c.renderOrder || 0);
        if (!buckets.has(key)) buckets.set(key, { mat: m, items: [], cast: c.castShadow, recv: c.receiveShadow, visible: c.visible, order: c.renderOrder, outline: !!c.userData.outline });
        _rel.multiplyMatrices(_inv, c.matrixWorld);
        const g = c.geometry.clone();
        g.applyMatrix4(_rel);
        for (const k of Object.keys(g.attributes)) if (!['position', 'normal', 'uv', 'color'].includes(k)) g.deleteAttribute(k);
        buckets.get(key).items.push(g);
        victims.push(c);
      }
      if (!shallow && !c.isMesh) visit(c, d);
    }
  };
  visit(group, false);
  const used = new Set();
  for (const v of victims) {
    if (v.parent) v.parent.remove(v);
    used.add(v.geometry);
  }
  const made = [];
  for (const b of buckets.values()) {
    // keep each mesh under 65k vertices so 16-bit indices work everywhere
    let chunk = [];
    let count = 0;
    const flush = () => {
      if (!chunk.length) return;
      const mesh = new THREE.Mesh(mergeGeometries(chunk), b.mat);
      mesh.castShadow = b.cast;
      mesh.receiveShadow = b.recv;
      mesh.visible = b.visible;
      mesh.renderOrder = b.order || 0;
      mesh.userData.baked = true;
      if (b.outline) mesh.userData.outline = true;
      group.add(mesh);
      made.push(mesh);
      for (const g of chunk) g.dispose();
      chunk = [];
      count = 0;
    };
    for (const g of b.items) {
      const n = g.attributes.position.count;
      if (count + n > 65000) flush();
      chunk.push(g);
      count += n;
    }
    flush();
  }
  // free source geometries nothing else uses
  const still = new Set();
  group.traverse((o) => { if (o.geometry) still.add(o.geometry); });
  for (const g of used) if (!still.has(g)) g.dispose();
  return made;
}

// ---------------------------------------------------------------- textures

export function canvas(w, h) {
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  return c;
}

export function tex(cv, { repeat = 1, srgb = true, wrap = true } = {}) {
  const t = new THREE.CanvasTexture(cv);
  if (srgb) t.colorSpace = THREE.SRGBColorSpace;
  if (wrap) {
    t.wrapS = t.wrapT = THREE.RepeatWrapping;
    t.repeat.set(repeat, repeat);
  }
  return t;
}

export function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const shade = (hex, k) => {
  const c = new THREE.Color(hex);
  if (k >= 0) c.lerp(new THREE.Color(1, 1, 1), k);
  else c.multiplyScalar(1 + k);
  return '#' + c.getHexString();
};

/** Wrap-around blob drawing so tiles repeat without seams. */
function wrapDraw(S, x, y, r, fn) {
  for (const dx of [-S, 0, S]) for (const dy of [-S, 0, S]) {
    if (x + dx + r < 0 || x + dx - r > S || y + dy + r < 0 || y + dy - r > S) continue;
    fn(x + dx, y + dy);
  }
}

/** A painted ground tile. kind: grass, sand, moon, stone, bark, leaves. */
export function groundTexture(kind, base, S = 512, repeat = 10, seed = 5) {
  const cv = canvas(S, S);
  const g = cv.getContext('2d');
  const r = rng(seed);
  g.fillStyle = base;
  g.fillRect(0, 0, S, S);
  if (kind === 'leaves') {
    // overlapping leaf shapes in nearby greens, darker underneath
    for (let i = 0; i < 1400; i++) {
      const x = r() * S, y = r() * S;
      const len = (6 + r() * 9) * (S / 256);
      const a = r() * TAU;
      g.fillStyle = shade(base, (r() - 0.55) * 0.32);
      wrapDraw(S, x, y, len, (px, py) => {
        g.save();
        g.translate(px, py);
        g.rotate(a);
        g.beginPath();
        g.ellipse(0, 0, len, len * 0.42, 0, 0, TAU);
        g.fill();
        g.restore();
      });
    }
    return tex(cv, { repeat });
  }
  if (kind === 'grass') {
    // big soft patches, then thousands of short strokes
    for (let i = 0; i < 26; i++) {
      const x = r() * S, y = r() * S, rad = S * (0.06 + r() * 0.12);
      const col = shade(base, (r() - 0.5) * 0.25);
      wrapDraw(S, x, y, rad, (px, py) => {
        const grd = g.createRadialGradient(px, py, 0, px, py, rad);
        grd.addColorStop(0, col);
        grd.addColorStop(1, col + '00');
        g.fillStyle = grd;
        g.fillRect(px - rad, py - rad, rad * 2, rad * 2);
      });
    }
    const n = kind === 'grass' ? 5200 : 1800;
    g.lineCap = 'round';
    for (let i = 0; i < n; i++) {
      const x = r() * S, y = r() * S;
      const len = (kind === 'grass' ? 4 + r() * 7 : 8 + r() * 14) * (S / 512);
      const a = kind === 'grass' ? -Math.PI / 2 + (r() - 0.5) * 0.9 : r() * TAU;
      g.strokeStyle = shade(base, (r() - 0.45) * 0.5);
      g.lineWidth = (kind === 'grass' ? 1.4 : 3 + r() * 3) * (S / 512);
      g.beginPath();
      g.moveTo(x, y);
      g.lineTo(x + Math.cos(a) * len, y + Math.sin(a) * len);
      g.stroke();
    }
  } else if (kind === 'sand') {
    for (let i = 0; i < 20; i++) {
      const x = r() * S, y = r() * S, rad = S * (0.08 + r() * 0.15);
      const col = shade(base, (r() - 0.5) * 0.14);
      wrapDraw(S, x, y, rad, (px, py) => {
        const grd = g.createRadialGradient(px, py, 0, px, py, rad);
        grd.addColorStop(0, col);
        grd.addColorStop(1, col + '00');
        g.fillStyle = grd;
        g.fillRect(px - rad, py - rad, rad * 2, rad * 2);
      });
    }
    // wind ripples
    g.strokeStyle = shade(base, -0.08);
    g.lineWidth = 2 * (S / 512);
    for (let k = 0; k < 18; k++) {
      const y0 = r() * S;
      g.beginPath();
      for (let x = 0; x <= S; x += 8) g.lineTo(x, y0 + Math.sin(x * 0.04 + k) * 5);
      g.stroke();
    }
    for (let i = 0; i < 7000; i++) {
      g.fillStyle = shade(base, (r() - 0.5) * 0.45);
      const s = (0.8 + r() * 1.6) * (S / 512);
      g.fillRect(r() * S, r() * S, s, s);
    }
  } else if (kind === 'moon') {
    for (let i = 0; i < 30; i++) {
      const x = r() * S, y = r() * S, rad = S * (0.05 + r() * 0.16);
      const col = shade(base, (r() - 0.55) * 0.3);
      wrapDraw(S, x, y, rad, (px, py) => {
        const grd = g.createRadialGradient(px, py, 0, px, py, rad);
        grd.addColorStop(0, col);
        grd.addColorStop(1, col + '00');
        g.fillStyle = grd;
        g.fillRect(px - rad, py - rad, rad * 2, rad * 2);
      });
    }
    // tiny craters: dark bowl, light rim
    for (let i = 0; i < 70; i++) {
      const x = r() * S, y = r() * S, rad = (2 + r() * r() * 16) * (S / 512);
      wrapDraw(S, x, y, rad + 2, (px, py) => {
        g.fillStyle = shade(base, -0.22);
        g.beginPath(); g.arc(px, py, rad, 0, TAU); g.fill();
        g.strokeStyle = shade(base, 0.25);
        g.lineWidth = Math.max(1, rad * 0.25);
        g.beginPath(); g.arc(px + rad * 0.12, py + rad * 0.12, rad, Math.PI * 0.1, Math.PI * 1.0); g.stroke();
      });
    }
    for (let i = 0; i < 5000; i++) {
      g.fillStyle = shade(base, (r() - 0.5) * 0.35);
      g.fillRect(r() * S, r() * S, S / 512 * 1.5, S / 512 * 1.5);
    }
  } else if (kind === 'stone') {
    // blocks with mortar lines
    const rows = 8;
    const h = S / rows;
    for (let row = 0; row < rows; row++) {
      const off = (row % 2) * h;
      for (let x = -h; x < S + h; x += h * 2) {
        g.fillStyle = shade(base, (r() - 0.5) * 0.2);
        g.fillRect(x + off + 2, row * h + 2, h * 2 - 4, h - 4);
      }
    }
    for (let i = 0; i < 3000; i++) {
      g.fillStyle = shade(base, (r() - 0.5) * 0.3);
      g.fillRect(r() * S, r() * S, 2, 2);
    }
  } else if (kind === 'bark') {
    for (let i = 0; i < 160; i++) {
      const x = r() * S;
      g.strokeStyle = shade(base, (r() - 0.6) * 0.5);
      g.lineWidth = 2 + r() * 5;
      g.beginPath();
      g.moveTo(x, 0);
      for (let y = 0; y <= S; y += 32) g.lineTo(x + Math.sin(y * 0.02 + i) * 6, y);
      g.stroke();
    }
  }
  return tex(cv, { repeat });
}

/** A vertical sky gradient with painted clouds, haze, a nebula or stars. */
export function skyTexture(stops, extra = {}) {
  const W = 512, H = 1024;
  const cv = canvas(W, H);
  const g = cv.getContext('2d');
  const grd = g.createLinearGradient(0, 0, 0, H);
  for (const [o, c] of stops) grd.addColorStop(o, c);
  g.fillStyle = grd;
  g.fillRect(0, 0, W, H);
  const r = rng(extra.seed || 9);
  if (extra.nebula) {
    for (const [cx, cy, rad, col] of extra.nebula) {
      for (let k = 0; k < 9; k++) {
        const x = cx * W + (r() - 0.5) * rad * W * 0.9, y = cy * H + (r() - 0.5) * rad * H * 0.5, rr = rad * W * (0.4 + r() * 0.6);
        const ng = g.createRadialGradient(x, y, 0, x, y, rr);
        ng.addColorStop(0, col);
        ng.addColorStop(1, col.slice(0, 7) + '00');
        g.fillStyle = ng;
        g.fillRect(x - rr, y - rr, rr * 2, rr * 2);
      }
    }
  }
  if (extra.band) {
    // a soft diagonal band of tiny stars (the Milky Way)
    g.save();
    g.translate(W / 2, H * 0.3);
    g.rotate(-0.5);
    const bg = g.createLinearGradient(0, -90, 0, 90);
    bg.addColorStop(0, 'rgba(180,190,255,0)');
    bg.addColorStop(0.5, 'rgba(180,190,255,0.16)');
    bg.addColorStop(1, 'rgba(180,190,255,0)');
    g.fillStyle = bg;
    g.fillRect(-W, -90, W * 2, 180);
    for (let i = 0; i < 900; i++) {
      g.fillStyle = `rgba(255,255,255,${0.2 + r() * 0.5})`;
      g.fillRect((r() - 0.5) * W * 2, (r() + r() + r() - 1.5) * 70, 1.2, 1.2);
    }
    g.restore();
  }
  if (extra.stars) {
    for (let i = 0; i < extra.stars; i++) {
      const y = Math.pow(r(), 1.4) * H * 0.75;
      g.fillStyle = `rgba(255,255,255,${0.3 + r() * 0.7})`;
      const s = r() < 0.08 ? 2.2 : 1.2;
      g.fillRect(r() * W, y, s, s);
    }
  }
  if (extra.clouds) {
    const { color = '#ffffff', y0 = 0.35, y1 = 0.65, n = 9, alpha = 0.75 } = extra.clouds;
    for (let i = 0; i < n; i++) {
      const cx = r() * W, cy = (y0 + r() * (y1 - y0)) * H, w = 60 + r() * 110;
      for (let k = 0; k < 7; k++) {
        const x = cx + (k - 3) * w * 0.28 + (r() - 0.5) * 10, y = cy - Math.sin((k / 6) * Math.PI) * w * 0.22 + (r() - 0.5) * 8, rr = w * (0.22 + r() * 0.16);
        const cg = g.createRadialGradient(x, y, 0, x, y, rr);
        cg.addColorStop(0, hexA(color, alpha));
        cg.addColorStop(0.65, hexA(color, alpha * 0.6));
        cg.addColorStop(1, hexA(color, 0));
        g.fillStyle = cg;
        g.fillRect(x - rr, y - rr, rr * 2, rr * 2);
      }
    }
  }
  if (extra.haze) {
    const hg = g.createLinearGradient(0, H * 0.55, 0, H);
    hg.addColorStop(0, hexA(extra.haze, 0));
    hg.addColorStop(1, hexA(extra.haze, 0.55));
    g.fillStyle = hg;
    g.fillRect(0, H * 0.55, W, H * 0.45);
  }
  const t = tex(cv, { wrap: false });
  return t;
}

function hexA(hex, a) {
  const c = new THREE.Color(hex);
  return `rgba(${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)},${a})`;
}

let glowTex = null;
/** Soft round glow for additive sprites and points. */
export function glowTexture() {
  if (glowTex) return glowTex;
  const S = 128;
  const cv = canvas(S, S);
  const g = cv.getContext('2d');
  const grd = g.createRadialGradient(S / 2, S / 2, 0, S / 2, S / 2, S / 2);
  grd.addColorStop(0, 'rgba(255,255,255,1)');
  grd.addColorStop(0.2, 'rgba(255,255,255,0.7)');
  grd.addColorStop(0.5, 'rgba(255,255,255,0.18)');
  grd.addColorStop(1, 'rgba(255,255,255,0)');
  g.fillStyle = grd;
  g.fillRect(0, 0, S, S);
  glowTex = tex(cv, { wrap: false });
  return glowTex;
}

let sparkTex = null;
/** A four-point sparkle for hit effects. */
export function sparkTexture() {
  if (sparkTex) return sparkTex;
  const S = 128;
  const cv = canvas(S, S);
  const g = cv.getContext('2d');
  g.translate(S / 2, S / 2);
  const grd = g.createRadialGradient(0, 0, 0, 0, 0, S * 0.22);
  grd.addColorStop(0, 'rgba(255,255,255,1)');
  grd.addColorStop(1, 'rgba(255,255,255,0)');
  g.fillStyle = grd;
  g.fillRect(-S / 2, -S / 2, S, S);
  g.fillStyle = '#fff';
  for (let k = 0; k < 4; k++) {
    g.rotate(Math.PI / 2);
    g.beginPath();
    g.moveTo(0, -S * 0.48);
    g.quadraticCurveTo(S * 0.03, -S * 0.06, S * 0.48 * 0.08, 0);
    g.lineTo(-S * 0.48 * 0.08, 0);
    g.quadraticCurveTo(-S * 0.03, -S * 0.06, 0, -S * 0.48);
    g.fill();
  }
  sparkTex = tex(cv, { wrap: false });
  return sparkTex;
}

/** Vertical fade (bright at v=1) for light beams and god rays. */
export function beamTexture(soft = true) {
  const cv = canvas(64, 256);
  const g = cv.getContext('2d');
  const grd = g.createLinearGradient(0, 256, 0, 0);
  grd.addColorStop(0, 'rgba(255,255,255,0)');
  grd.addColorStop(0.6, 'rgba(255,255,255,0.45)');
  grd.addColorStop(1, 'rgba(255,255,255,0.9)');
  g.fillStyle = grd;
  g.fillRect(0, 0, 64, 256);
  if (soft) {
    const sg = g.createLinearGradient(0, 0, 64, 0);
    sg.addColorStop(0, 'rgba(0,0,0,1)');
    sg.addColorStop(0.3, 'rgba(0,0,0,0)');
    sg.addColorStop(0.7, 'rgba(0,0,0,0)');
    sg.addColorStop(1, 'rgba(0,0,0,1)');
    g.globalCompositeOperation = 'destination-out';
    g.fillStyle = sg;
    g.fillRect(0, 0, 64, 256);
  }
  return tex(cv, { wrap: false });
}

/** A rounded teardrop (fur tuft, flame, leaf bud): base at y=0, tip at y=h. */
export function tuftGeometry(r = 0.1, h = 0.3, seg = 14) {
  const pts = [];
  const n = 10;
  for (let i = 0; i <= n; i++) {
    const t = i / n;
    // round bottom, then a smooth taper to a soft point
    const y = -r * 0.9 + t * (h + r * 0.9);
    const k = t < 0.25 ? Math.sin((t / 0.25) * Math.PI / 2) : Math.pow(1 - (t - 0.25) / 0.75, 1.15);
    pts.push(new THREE.Vector2(Math.max(0.0005, r * k), y));
  }
  pts[0].x = 0.0005;
  return new THREE.LatheGeometry(pts, seg);
}
