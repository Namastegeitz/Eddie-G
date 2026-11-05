// The 3D world around the monkey: renderer and quality levels, camera
// framing, real-time soft shadows, four detailed stages (jungle, beach,
// temple disco, moon), the light-up dance pad, and effects (rings, sparks,
// confetti, dust, dizzy stars, camera shake and punch).
// Static scenery is merged into a few meshes per stage (js/gfx.js), so phones
// draw a lot of detail in few draw calls.
import * as THREE from './vendor/three.module.min.js';
import { MOVES } from './moves.js';
import { makeGradient } from './monkey.js';
import {
  RIM, WIND, addRim, windy, bakeStatic, groundTexture, skyTexture, glowTexture, sparkTexture,
  beamTexture, tuftGeometry, canvas as makeCanvas, tex, rng,
} from './gfx.js';

const TAU = Math.PI * 2;
const PAD_ANGLES = { RA: 30, HD: 90, LA: 150, LL: 210, FL: 270, RL: 330 }; // degrees, see pad layout

/**
 * Quality levels. dpr = sharpest pixel ratio used; shadow = shadow map size
 * (0 = soft blob only); detail = grass, flowers, light rays, butterflies...
 */
export const QUALITY = {
  low: { dpr: 1, shadow: 0, rim: 0.3, detail: 0, outlines: false },
  medium: { dpr: 1.5, shadow: 0, rim: 0.55, detail: 1, outlines: true },
  high: { dpr: 2, shadow: 1024, rim: 0.6, detail: 2, outlines: true },
  ultra: { dpr: 3, shadow: 2048, rim: 0.6, detail: 2, outlines: true },
};

const ENVS = {
  jungle: {
    sky: [[0, '#0f5a52'], [0.45, '#3f9a72'], [0.78, '#bfe0a0'], [1, '#f3e8a6']],
    skyExtra: { clouds: { color: '#fffbe6', y0: 0.38, y1: 0.6, n: 8, alpha: 0.42 }, haze: '#f6f0c0', seed: 3 },
    fog: '#86bf8e', fogNear: 26, fogFar: 85,
    hemi: ['#fff6d8', '#2d5a2a', 1.5], key: ['#fff1cf', 2.5], rim: ['#c8ffe8', 1.3], rimShader: '#e6ffd0', ground: '#4f9a3d', music: 'jungle',
  },
  beach: {
    sky: [[0, '#4a5fcf'], [0.35, '#a36fc8'], [0.58, '#ff8f7a'], [0.8, '#ffc27a'], [1, '#ffe6b0']],
    skyExtra: { clouds: { color: '#ffd8c8', y0: 0.3, y1: 0.55, n: 10, alpha: 0.55 }, haze: '#ffe2b8', seed: 7 },
    fog: '#ffc79a', fogNear: 28, fogFar: 95,
    hemi: ['#fff0e0', '#b8875a', 1.55], key: ['#ffe2c4', 2.5], rim: ['#ff9ad0', 1.4], rimShader: '#ffd0e8', ground: '#e2bb7c', music: 'beach',
  },
  disco: {
    sky: [[0, '#0b031c'], [0.55, '#2c0f55'], [1, '#5b1f7a']],
    skyExtra: { nebula: [[0.25, 0.35, 0.3, '#ff4fd833'], [0.75, 0.45, 0.3, '#4fd8ff26'], [0.5, 0.7, 0.4, '#7a5cff33']], stars: 120, seed: 4 },
    fog: '#2a0f4a', fogNear: 22, fogFar: 70,
    hemi: ['#d9c8ff', '#2a1440', 1.25], key: ['#ffffff', 2.3], rim: ['#ff4fd8', 2.2], rimShader: '#ff8ae6', ground: '#20182f', music: 'disco',
  },
  moon: {
    sky: [[0, '#010208'], [0.62, '#0b1236'], [1, '#2a3466']],
    skyExtra: { stars: 900, band: true, nebula: [[0.2, 0.25, 0.25, '#5a3aa033'], [0.8, 0.18, 0.2, '#2a6ab033']], seed: 11 },
    fog: '#10173a', fogNear: 32, fogFar: 110,
    hemi: ['#dfe8ff', '#30303a', 1.4], key: ['#f4f6ff', 2.6], rim: ['#7fb2ff', 1.7], rimShader: '#a8ccff', ground: '#83838f', music: 'moon',
  },
};

export class Stage {
  constructor(canvas, opts = {}) {
    this.canvas = canvas;
    this.reduceMotion = false;
    const params = { canvas, antialias: true, powerPreference: 'high-performance' };
    // ?gl=1 forces WebGL 1 to test older phones; three.js falls back to it by itself when WebGL 2 is missing
    if (opts.forceWebGL1) params.context = canvas.getContext('webgl', { antialias: true, alpha: false }) || undefined;
    this.renderer = new THREE.WebGLRenderer(params);
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.toonSteps = makeGradient([178, 178, 178, 178, 178, 178, 178, 255, 255, 255]);
    this.webgl = this.renderer.capabilities.isWebGL2 ? 2 : 1;
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(30, 1, 0.1, 200);
    this.baseFov = 30;
    this.camPos = new THREE.Vector3(0, 1.9, 9);
    this.camTarget = new THREE.Vector3(0, 1.7, 0);
    this.camGoal = { pos: this.camPos.clone(), target: this.camTarget.clone() };
    this.frame = { top: 0, bottom: 0 };
    this.shakeAmt = 0;
    this.punchAmt = 0;
    this.time = 0;
    this.streak = 0;
    this.mats = new Map();

    this.hemi = new THREE.HemisphereLight(0xffffff, 0x444444, 1.5);
    this.scene.add(this.hemi);
    this.key = new THREE.DirectionalLight(0xffffff, 2.4);
    this.key.position.set(3, 7.2, 6);
    this.key.target.position.set(0, 1.2, 0);
    this.scene.add(this.key, this.key.target);
    const sc = this.key.shadow.camera;
    sc.left = -2.8; sc.right = 2.8; sc.top = 3.2; sc.bottom = -2.6; sc.near = 1; sc.far = 22;
    this.key.shadow.bias = -0.0006;
    this.key.shadow.normalBias = 0.025;
    this.key.shadow.radius = 3;
    this.rim = new THREE.DirectionalLight(0xffffff, 1.2);
    this.rim.position.set(-4, 4, -5);
    this.scene.add(this.rim);

    this.buildPad();
    this.envs = {};
    this.envId = null;
    this.buildEffects();
    this.setQuality(opts.quality || 'auto');
  }

  // ------------------------------------------------------------ materials

  /** A cached toon material (with rim light) per colour/map. */
  toon(c, opts = {}) {
    const key = `${typeof c === 'number' ? c.toString(16) : c}|${opts.map ? opts.map.uuid : ''}|${opts.side || 0}|${opts.vertexColors ? 1 : 0}|${opts.emissive || ''}`;
    let m = this.mats.get(key);
    if (!m) {
      m = addRim(new THREE.MeshToonMaterial({ color: c, gradientMap: this.toonSteps, ...opts }));
      this.mats.set(key, m);
    }
    return m;
  }

  basic(c, opts = {}) {
    return new THREE.MeshBasicMaterial({ color: c, ...opts });
  }

  glowSprite(color, size, opacity = 1) {
    const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture(), color, transparent: true, opacity, blending: THREE.AdditiveBlending, depthWrite: false, fog: false }));
    s.scale.set(size, size, 1);
    s.userData.dynamic = true;
    return s;
  }

  // ------------------------------------------------------------ dance pad

  buildPad() {
    const g = new THREE.Group();
    // layered base: dark plinth, gold trim, wooden deck
    const plinth = new THREE.Mesh(new THREE.CylinderGeometry(2.36, 2.5, 0.22, 72), this.toon(0x2a1c18));
    plinth.position.y = -0.17;
    g.add(plinth);
    const trim = new THREE.Mesh(new THREE.TorusGeometry(2.3, 0.07, 10, 96), this.toon(0xe0a83a));
    trim.rotation.x = Math.PI / 2;
    trim.position.y = -0.03;
    g.add(trim);
    this.padTrim = trim.material = addRim(new THREE.MeshToonMaterial({ color: 0xe0a83a, gradientMap: this.toonSteps, emissive: 0x000000 }));
    const deck = new THREE.Mesh(new THREE.CylinderGeometry(2.22, 2.24, 0.1, 72), this.toon(0x3a2a24));
    deck.position.y = -0.06;
    g.add(deck);
    this.padBase = deck;
    this.wedges = {};
    for (const [id, deg] of Object.entries(PAD_ANGLES)) {
      const color = new THREE.Color(MOVES[id].color);
      const a0 = THREE.MathUtils.degToRad(deg - 27.5);
      const geo = new THREE.RingGeometry(0.74, 2.08, 18, 2, a0, THREE.MathUtils.degToRad(55));
      const mat = new THREE.MeshBasicMaterial({ color: color.clone().multiplyScalar(0.45) });
      const w = new THREE.Mesh(geo, mat);
      w.rotation.x = -Math.PI / 2;
      w.position.y = 0.006;
      g.add(w);
      // bright edge and an additive glow sheet that light up on a hit
      const edge = new THREE.Mesh(new THREE.RingGeometry(1.98, 2.08, 18, 1, a0, THREE.MathUtils.degToRad(55)), new THREE.MeshBasicMaterial({ color: color.clone().lerp(new THREE.Color(0xffffff), 0.3) }));
      edge.rotation.x = -Math.PI / 2;
      edge.position.y = 0.008;
      g.add(edge);
      const glow = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({ color: color.clone().lerp(new THREE.Color(0xffffff), 0.35), transparent: true, opacity: 0, blending: THREE.AdditiveBlending, depthWrite: false }));
      glow.rotation.x = -Math.PI / 2;
      glow.position.y = 0.03;
      glow.scale.setScalar(1.0);
      g.add(glow);
      this.wedges[id] = { mesh: w, glow, base: color.clone().multiplyScalar(0.45), lit: color.clone().lerp(new THREE.Color(0xffffff), 0.25), flash: -10 };
    }
    // raised gold dividers between wedges
    const divMat = this.toon(0xc8902e);
    for (const deg of [0, 60, 120, 180, 240, 300]) {
      const a = THREE.MathUtils.degToRad(deg);
      const d = new THREE.Mesh(new THREE.BoxGeometry(1.36, 0.035, 0.05), divMat);
      d.position.set(Math.cos(a) * 1.41, 0.018, -Math.sin(a) * 1.41);
      d.rotation.y = a;
      g.add(d);
    }
    const hub = new THREE.Mesh(new THREE.CircleGeometry(0.74, 48), new THREE.MeshBasicMaterial({ color: 0x2a1d18 }));
    hub.rotation.x = -Math.PI / 2;
    hub.position.y = 0.01;
    g.add(hub);
    this.hub = hub;
    const hubRing = new THREE.Mesh(new THREE.RingGeometry(0.66, 0.74, 48), new THREE.MeshBasicMaterial({ color: 0xe0a83a }));
    hubRing.rotation.x = -Math.PI / 2;
    hubRing.position.y = 0.012;
    g.add(hubRing);
    // a banana-star emblem in the middle
    const star = new THREE.Shape();
    for (let k = 0; k < 10; k++) {
      const r = k % 2 ? 0.2 : 0.46;
      const a = (k / 10) * TAU + Math.PI / 2;
      if (k === 0) star.moveTo(Math.cos(a) * r, Math.sin(a) * r);
      else star.lineTo(Math.cos(a) * r, Math.sin(a) * r);
    }
    const emblem = new THREE.Mesh(new THREE.ShapeGeometry(star), new THREE.MeshBasicMaterial({ color: 0x5a3a20 }));
    emblem.rotation.x = -Math.PI / 2;
    emblem.position.y = 0.014;
    g.add(emblem);
    this.emblem = emblem;
    // soft contact shadow (always) + real shadows on top (High and Ultra)
    const scv = makeCanvas(128, 128);
    const sg = scv.getContext('2d');
    const grd = sg.createRadialGradient(64, 64, 0, 64, 64, 64);
    grd.addColorStop(0, 'rgba(0,0,0,0.5)');
    grd.addColorStop(0.55, 'rgba(0,0,0,0.25)');
    grd.addColorStop(1, 'rgba(0,0,0,0)');
    sg.fillStyle = grd;
    sg.fillRect(0, 0, 128, 128);
    const shadow = new THREE.Mesh(new THREE.PlaneGeometry(1.9, 1.5), new THREE.MeshBasicMaterial({ map: new THREE.CanvasTexture(scv), transparent: true, depthWrite: false }));
    shadow.rotation.x = -Math.PI / 2;
    shadow.position.y = 0.02;
    g.add(shadow);
    this.shadow = shadow;
    const catcher = new THREE.Mesh(new THREE.CircleGeometry(2.3, 64), new THREE.ShadowMaterial({ opacity: 0.32, depthWrite: false }));
    catcher.rotation.x = -Math.PI / 2;
    catcher.position.y = 0.022;
    catcher.receiveShadow = true;
    g.add(catcher);
    this.shadowCatcher = catcher;
    // and on the ground just around the pad, where a long shadow can reach
    const catcher2 = new THREE.Mesh(new THREE.RingGeometry(2.45, 5.5, 64, 1), new THREE.ShadowMaterial({ opacity: 0.28, depthWrite: false }));
    catcher2.rotation.x = -Math.PI / 2;
    catcher2.position.y = -0.18;
    catcher2.receiveShadow = true;
    g.add(catcher2);
    this.shadowCatcher2 = catcher2;
    // bulbs around the rim: one instanced mesh + one glow layer
    const N = 32;
    this.bulbN = N;
    this.bulbs = new THREE.InstancedMesh(new THREE.SphereGeometry(0.055, 12, 8), new THREE.MeshBasicMaterial({ color: 0xffffff }), N);
    const m4 = new THREE.Matrix4();
    const gp = new Float32Array(N * 3);
    for (let i = 0; i < N; i++) {
      const a = (i / N) * TAU;
      m4.makeTranslation(Math.cos(a) * 2.38, -0.04, Math.sin(a) * 2.38);
      this.bulbs.setMatrixAt(i, m4);
      this.bulbs.setColorAt(i, new THREE.Color(0xfff1b0));
      gp.set([Math.cos(a) * 2.38, -0.04, Math.sin(a) * 2.38], i * 3);
    }
    g.add(this.bulbs);
    const gg = new THREE.BufferGeometry();
    gg.setAttribute('position', new THREE.BufferAttribute(gp, 3));
    gg.setAttribute('color', new THREE.BufferAttribute(new Float32Array(N * 3).fill(1), 3));
    this.bulbGlow = new THREE.Points(gg, new THREE.PointsMaterial({ size: 0.42, map: glowTexture(), vertexColors: true, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, opacity: 0.8 }));
    this.bulbGlow.frustumCulled = false;
    g.add(this.bulbGlow);
    this.scene.add(g);
    this.pad = g;
  }

  lightPad(id, at) {
    const w = this.wedges[id];
    if (w) w.flash = at ?? this.time;
  }

  /** The pad trim glows warmer the longer your streak. */
  setStreak(n) {
    this.streak = n || 0;
  }

  // ------------------------------------------------------------ environments

  setEnvironment(id) {
    if (!ENVS[id]) id = 'jungle';
    if (this.envId === id) return;
    for (const [k, g] of Object.entries(this.envs)) g.visible = k === id;
    if (!this.envs[id]) {
      const g = this['build_' + id]();
      const parts = [];
      g.traverse((o) => { if (o !== g && o.userData.detailLevel && !o.isMesh && !o.isPoints && !o.userData.dynamic) parts.push(o); });
      for (const o of parts) bakeStatic(o);
      bakeStatic(g);
      this.envs[id] = g;
      this.scene.add(g);
    }
    const e = ENVS[id];
    this.skies = this.skies || {};
    if (!this.skies[id]) this.skies[id] = skyTexture(e.sky, e.skyExtra); // painted once per stage
    this.skyTex = this.skies[id];
    this.scene.background = this.skyTex;
    this.scene.fog = new THREE.Fog(e.fog, e.fogNear, e.fogFar);
    this.hemi.color.set(e.hemi[0]);
    this.hemi.groundColor.set(e.hemi[1]);
    this.hemi.intensity = e.hemi[2];
    this.key.color.set(e.key[0]);
    this.key.intensity = e.key[1];
    this.rim.color.set(e.rim[0]);
    this.rim.intensity = e.rim[1];
    RIM.color.value.set(e.rimShader);
    this.envId = id;
    this.applyDetail();
  }

  musicFor(id) {
    return (ENVS[id] || ENVS.jungle).music;
  }

  /** Detail groups (grass, flowers, rays...) show only when quality allows. */
  applyDetail() {
    const lvl = (QUALITY[this.level] || QUALITY.high).detail;
    for (const g of Object.values(this.envs)) {
      g.traverse((o) => { if (o.userData.detailLevel) o.visible = lvl >= o.userData.detailLevel; });
    }
  }

  detail(g, level = 1) {
    g.userData.detailLevel = level;
    return g;
  }

  ground(color, kind, r = 44) {
    const map = groundTexture(kind, color, 512, kind === 'moon' ? 9 : 12);
    map.anisotropy = this.level === 'low' ? 1 : 4;
    (this.groundTexs = this.groundTexs || []).push(map);
    const m = new THREE.Mesh(new THREE.CircleGeometry(r, 72), this.toon(0xffffff, { map }));
    m.rotation.x = -Math.PI / 2;
    m.position.y = -0.27;
    return m;
  }

  /** Grass tufts as one instanced mesh that sways in the wind. */
  grass(n, colors, area, seed = 1) {
    const blades = [];
    for (let k = 0; k < 5; k++) {
      const a = (k / 5) * Math.PI + 0.3;
      const h = 0.22 + (k % 3) * 0.06;
      const lean = (k - 2) * 0.05;
      const x = Math.cos(a) * 0.045, z = Math.sin(a) * 0.045;
      blades.push(
        -x, 0, -z, x, 0, z, lean * 2 + Math.cos(a + 1.2) * 0.01, h, Math.sin(a + 1.2) * 0.01 + lean,
      );
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(blades, 3));
    const col = [];
    const dark = new THREE.Color(colors[0]);
    const light = new THREE.Color(colors[1]);
    for (let i = 0; i < blades.length / 3; i++) {
      const c = i % 3 === 2 ? light : dark;
      col.push(c.r, c.g, c.b);
    }
    geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
    geo.computeVertexNormals();
    const mat = windy(new THREE.MeshToonMaterial({ color: 0xffffff, vertexColors: true, gradientMap: this.toonSteps, side: THREE.DoubleSide }), 0.35, 1.6);
    const mesh = new THREE.InstancedMesh(geo, mat, n);
    const r = rng(seed);
    const m4 = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const s = new THREE.Vector3();
    const p = new THREE.Vector3();
    for (let i = 0; i < n; i++) {
      let x, z;
      do {
        x = (r() - 0.5) * area.w;
        z = area.z0 + r() * (area.z1 - area.z0);
      } while (Math.hypot(x, z) < 3.1 || (z > 1.2 && Math.abs(x) < 3.6));
      p.set(x, -0.27, z);
      q.setFromAxisAngle(new THREE.Vector3(0, 1, 0), r() * TAU);
      const k = 0.7 + r() * 1.1;
      s.set(k, k * (0.8 + r() * 0.6), k);
      m4.compose(p, q, s);
      mesh.setMatrixAt(i, m4);
    }
    mesh.frustumCulled = false;
    return mesh;
  }

  /** A leaf blob canopy: several smooth lumps with a painted leaf texture. */
  canopy(g, x, y, z, size, mats, r) {
    const n = 5 + Math.floor(r() * 3);
    for (let k = 0; k < n; k++) {
      const rad = size * (0.55 + r() * 0.45);
      const s = new THREE.Mesh(new THREE.IcosahedronGeometry(rad, 2), mats[k % mats.length]);
      const a = (k / n) * TAU + r();
      s.position.set(x + Math.cos(a) * size * 0.7 * r(), y + (r() - 0.3) * size * 0.6, z + Math.sin(a) * size * 0.5 * r());
      s.scale.y = 0.78 + r() * 0.2;
      g.add(s);
    }
  }

  leafGeometry(len = 0.9, width = 0.22, droop = 0.35) {
    // a long leaf with a centre fold, bending down towards the tip
    const segs = 10;
    const pos = [];
    const idx = [];
    for (let i = 0; i <= segs; i++) {
      const t = i / segs;
      const w = Math.sin(Math.PI * Math.pow(t, 0.75)) * width;
      const y = -droop * t * t;
      const x = t * len;
      pos.push(x, y + 0.02, 0, x, y - 0.01, w, x, y - 0.01, -w);
    }
    for (let i = 0; i < segs; i++) {
      const a = i * 3, b = (i + 1) * 3;
      idx.push(a, b, a + 1, a + 1, b, b + 1, a, a + 2, b, a + 2, b + 2, b);
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    geo.setIndex(idx);
    geo.computeVertexNormals();
    return geo;
  }

  frondGeometry(len = 1.9) {
    // palm frond: a bent rib with many thin leaflets on both sides
    const pos = [];
    const segs = 16;
    const pt = (t) => [t * len, -0.75 * t * t, 0];
    for (let i = 1; i < segs; i++) {
      const t = i / segs;
      const [x, y] = pt(t);
      const l = 0.42 * Math.sin(Math.PI * Math.pow(t, 0.6));
      for (const side of [-1, 1]) {
        const [x2, y2] = pt(Math.min(1, t + 0.08));
        pos.push(x - 0.03, y, 0, x + 0.05, y, 0, x2 + 0.1, y2 - 0.22, side * l);
      }
    }
    // the rib itself
    for (let i = 0; i < segs; i++) {
      const [x1, y1] = pt(i / segs);
      const [x2, y2] = pt((i + 1) / segs);
      pos.push(x1, y1 + 0.02, -0.02, x2, y2 + 0.02, -0.02, x2, y2 + 0.02, 0.02, x1, y1 + 0.02, -0.02, x2, y2 + 0.02, 0.02, x1, y1 + 0.02, 0.02);
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    geo.computeVertexNormals();
    return geo;
  }

  build_jungle() {
    const g = new THREE.Group();
    const e = ENVS.jungle;
    g.add(this.ground(e.ground, 'grass'));
    const more = this.detail(new THREE.Group(), 1); // extra scenery, hidden on Low
    g.add(more);
    const r = rng(7);
    const bark = this.toon(0xffffff, { map: groundTexture('bark', '#6b4423', 256, 1, 2) });
    const leafTex = [groundTexture('leaves', '#2d7a3a', 256, 2, 3), groundTexture('leaves', '#3f9446', 256, 2, 4), groundTexture('leaves', '#246638', 256, 2, 5)];
    const leaf = leafTex.map((t) => this.toon(0xffffff, { map: t }));
    // far canopy layers (fog paints them blue-green)
    for (const [z, y, c, n] of [[-34, 7, 0x2a6a48, 18], [-25, 5.5, 0x2f7a46, 14]]) {
      const m = this.toon(c);
      for (let k = 0; k < n; k++) {
        const x = -44 + (k / (n - 1)) * 88 + (r() - 0.5) * 3;
        const s = new THREE.Mesh(new THREE.IcosahedronGeometry(3.4 + r() * 2.4, 2), m);
        s.position.set(x, y + r() * 3, z + (r() - 0.5) * 4);
        s.scale.y = 0.8;
        more.add(s);
        const t = new THREE.Mesh(new THREE.CylinderGeometry(0.35, 0.55, y, 8), this.toon(0x3a2a1a));
        t.position.set(x, y / 2 - 0.27, z);
        more.add(t);
      }
    }
    // trees around the clearing
    const trees = [[-6.5, -6], [-9, -2], [6, -7], [9.5, -3], [-3, -11], [3.5, -12], [0, -16], [-12, -9], [12, -10], [-15, -4], [15, -5]];
    for (const [x, z] of trees) {
      const h = 4.4 + r() * 3;
      const t = new THREE.Mesh(new THREE.CylinderGeometry(0.24, 0.42, h, 14, 4), bark);
      t.position.set(x, h / 2 - 0.27, z);
      t.rotation.z = (r() - 0.5) * 0.08;
      t.castShadow = false;
      g.add(t);
      // root flares
      for (let k = 0; k < 4; k++) {
        const a = (k / 4) * TAU + r();
        const root = new THREE.Mesh(new THREE.ConeGeometry(0.2, 1.1, 8), bark);
        root.position.set(x + Math.cos(a) * 0.38, 0.05, z + Math.sin(a) * 0.38);
        root.rotation.set(Math.sin(a) * 1.0, 0, -Math.cos(a) * 1.0);
        more.add(root);
      }
      // a branch
      const br = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.12, 1.6, 8), bark);
      const side = x < 0 ? 1 : -1;
      br.position.set(x + side * 0.6, h * 0.7, z + 0.2);
      br.rotation.z = side * -0.9;
      more.add(br);
      this.canopy(g, x, h + 0.2, z, 1.5 + r() * 0.6, leaf, r);
      this.canopy(more, x + side * 1.2, h * 0.78, z + 0.3, 0.9, leaf, r);
    }
    // bushes with leaf texture, close to the clearing
    for (let k = 0; k < 16; k++) {
      const side = k % 2 ? 1 : -1;
      const bx = side * (3.4 + r() * 4.5), bz = -0.8 - r() * 7.5;
      for (let j = 0; j < 3; j++) {
        const b = new THREE.Mesh(new THREE.IcosahedronGeometry(0.5 + r() * 0.45, 2), leaf[(k + j) % 3]);
        b.position.set(bx + (j - 1) * 0.5, 0.05 + r() * 0.15, bz + (r() - 0.5) * 0.4);
        b.scale.y = 0.72;
        (j === 1 ? g : more).add(b);
      }
    }
    // big fan leaves at the clearing's edges
    const leafGeo = this.leafGeometry(1.0, 0.24, 0.4);
    const bigLeaf = this.toon(0x3aa24a, { side: THREE.DoubleSide });
    const bigLeaf2 = this.toon(0x2a8a3e, { side: THREE.DoubleSide });
    for (const [cx, cz, n] of [[-3.4, -1.6, 7], [3.6, -1.2, 7], [-4.6, -3.8, 6], [4.8, -3.4, 6], [-2.6, -5.5, 5], [2.8, -6, 5]]) {
      for (let k = 0; k < n; k++) {
        const l = new THREE.Mesh(leafGeo, k % 2 ? bigLeaf : bigLeaf2);
        const a = (k / n) * TAU + r() * 0.4;
        l.position.set(cx, -0.2, cz);
        l.rotation.set(0, a, 0.5 + r() * 0.5);
        l.scale.setScalar(0.8 + r() * 0.5);
        more.add(l);
      }
    }
    // mushrooms and mossy rocks
    const capRed = this.toon(0xe0483a);
    const dot = this.toon(0xfff4e0);
    const stem = this.toon(0xf4e6cc);
    for (let k = 0; k < 7; k++) {
      const side = k % 2 ? 1 : -1;
      const mx = side * (2.8 + r() * 3), mz = -0.5 - r() * 5;
      const sc = 0.6 + r() * 0.6;
      const st = new THREE.Mesh(new THREE.CylinderGeometry(0.05 * sc, 0.07 * sc, 0.22 * sc, 10), stem);
      st.position.set(mx, -0.27 + 0.11 * sc, mz);
      more.add(st);
      const cap = new THREE.Mesh(new THREE.SphereGeometry(0.15 * sc, 18, 10, 0, TAU, 0, Math.PI / 2), capRed);
      cap.position.set(mx, -0.27 + 0.2 * sc, mz);
      cap.scale.y = 0.7;
      more.add(cap);
      for (let d = 0; d < 4; d++) {
        const a = (d / 4) * TAU + r();
        const sp = new THREE.Mesh(new THREE.SphereGeometry(0.025 * sc, 8, 6), dot);
        sp.position.set(mx + Math.cos(a) * 0.08 * sc, -0.27 + 0.27 * sc, mz + Math.sin(a) * 0.08 * sc);
        more.add(sp);
      }
    }
    const rock = this.toon(0x7d8a86);
    const moss = this.toon(0x4f9a3d);
    for (let k = 0; k < 8; k++) {
      const side = k % 2 ? 1 : -1;
      const rx = side * (3 + r() * 6), rz = 0.5 - r() * 9;
      const s = 0.25 + r() * 0.35;
      const rk = new THREE.Mesh(new THREE.DodecahedronGeometry(s, 1), rock);
      rk.position.set(rx, -0.27 + s * 0.4, rz);
      rk.scale.y = 0.65;
      more.add(rk);
      const mo = new THREE.Mesh(new THREE.SphereGeometry(s * 0.85, 14, 6, 0, TAU, 0, Math.PI / 3), moss);
      mo.position.set(rx, -0.27 + s * 0.48, rz);
      mo.scale.y = 0.5;
      more.add(mo);
    }
    // hanging vines with leaves
    const vine = this.toon(0x3c7d2f);
    const vineLeaf = this.toon(0x4aa83c, { side: THREE.DoubleSide });
    const vLeafGeo = this.leafGeometry(0.28, 0.09, 0.06);
    for (const [x, z, len] of [[-3.6, -2.5, 4], [-2.4, -4, 3], [3.2, -3, 4.5], [4.4, -1.5, 3.5], [-4.8, -0.5, 3], [1.2, -6, 3.2], [-1.4, -7, 2.6]]) {
      const pts = [];
      for (let k = 0; k <= 8; k++) pts.push(new THREE.Vector3(x + Math.sin(k * 0.9) * 0.12, 9 - (k / 8) * len, z + Math.cos(k * 0.7) * 0.08));
      const v = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 24, 0.035, 6), vine);
      more.add(v);
      for (let k = 0; k < 7; k++) {
        const p = pts[1 + Math.floor((k / 7) * 7)];
        const l = new THREE.Mesh(vLeafGeo, vineLeaf);
        l.position.copy(p);
        l.rotation.set(0.3, (k % 2 ? 0 : Math.PI) + r() * 0.6, -0.6);
        more.add(l);
      }
    }
    // a banana bunch on a tree
    const banana = this.toon(0xffd23f);
    const tip = this.toon(0x5a3a1a);
    for (let k = 0; k < 6; k++) {
      const b = new THREE.Mesh(new THREE.TorusGeometry(0.22, 0.065, 10, 16, Math.PI * 0.75), banana);
      b.position.set(-6.05 + k * 0.1, 3.55 - (k % 2) * 0.14, -5.35 + (k % 3) * 0.05);
      b.rotation.set(0, (k - 2.5) * 0.25, -1.2 + k * 0.18);
      g.add(b);
    }
    const stalk = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.04, 0.5, 8), tip);
    stalk.position.set(-5.85, 3.95, -5.4);
    g.add(stalk);
    // detail: grass, flowers, light rays, butterflies, fireflies
    g.add(this.detail(this.grass(520, ['#2f6e2a', '#8fd65a'], { w: 30, z0: -14, z1: 6 }, 3), 1));
    g.add(this.detail(this.flowers(56, ['#ff6fae', '#ffd23f', '#ffffff', '#ff8a3a', '#b98aff'], { w: 18, z0: -9, z1: 3 }, 8), 1));
    const rays = this.detail(new THREE.Group(), 2);
    rays.userData.dynamic = true;
    const rayMat = new THREE.MeshBasicMaterial({ map: beamTexture(), color: 0xfff6c8, transparent: true, opacity: 0.22, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide, fog: false });
    this.rays = [];
    for (const [x, z, w] of [[-4, -8, 1.6], [-1.2, -10, 2.2], [2.5, -7, 1.4], [5.5, -11, 2]]) {
      const m = new THREE.Mesh(new THREE.PlaneGeometry(w, 14), rayMat.clone());
      m.position.set(x + 1.6, 6, z);
      m.rotation.z = 0.35;
      m.userData.phase = r() * TAU;
      rays.add(m);
      this.rays.push(m);
    }
    g.add(rays);
    g.add(this.detail(this.butterflies(6), 2));
    g.add(this.fireflies(0xfff4a0, 60, 10, 6));
    return g;
  }

  /** Instanced flower heads (petals coloured per flower) with yellow middles. */
  flowers(n, colors, area, seed) {
    const g = new THREE.Group();
    const petals = [];
    for (let k = 0; k < 5; k++) {
      const p = new THREE.SphereGeometry(0.06, 8, 6);
      const a = (k / 5) * TAU;
      p.scale(1, 0.35, 0.6);
      p.rotateY(-a);
      p.translate(Math.cos(a) * 0.06, 0, Math.sin(a) * 0.06);
      petals.push(p);
    }
    const head = mergeList(petals);
    const petalMesh = new THREE.InstancedMesh(head, this.toon(0xffffff), n);
    const mid = new THREE.InstancedMesh(new THREE.SphereGeometry(0.035, 8, 6), this.toon(0xffc020), n);
    const stems = new THREE.InstancedMesh(new THREE.CylinderGeometry(0.008, 0.01, 1, 5), this.toon(0x3c8a2f), n);
    const r = rng(seed);
    const m4 = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    for (let i = 0; i < n; i++) {
      let x, z;
      do { x = (r() - 0.5) * area.w; z = area.z0 + r() * (area.z1 - area.z0); } while (Math.hypot(x, z) < 3.1 || (z > 1.2 && Math.abs(x) < 3.6));
      const h = 0.12 + r() * 0.22;
      const s = 0.8 + r() * 0.7;
      q.setFromEuler(new THREE.Euler((r() - 0.5) * 0.5, r() * TAU, (r() - 0.5) * 0.5));
      m4.compose(new THREE.Vector3(x, -0.27 + h, z), q, new THREE.Vector3(s, s, s));
      petalMesh.setMatrixAt(i, m4);
      mid.setMatrixAt(i, m4);
      petalMesh.setColorAt(i, new THREE.Color(colors[i % colors.length]));
      m4.compose(new THREE.Vector3(x, -0.27 + h / 2, z), new THREE.Quaternion(), new THREE.Vector3(1, h, 1));
      stems.setMatrixAt(i, m4);
    }
    for (const m of [petalMesh, mid, stems]) { m.frustumCulled = false; g.add(m); }
    return g;
  }

  butterflies(n) {
    const g = new THREE.Group();
    g.userData.dynamic = true;
    const wing = new THREE.Shape();
    wing.moveTo(0, 0);
    wing.bezierCurveTo(0.05, 0.16, 0.2, 0.2, 0.2, 0.08);
    wing.bezierCurveTo(0.2, 0.0, 0.12, -0.02, 0.16, -0.1);
    wing.bezierCurveTo(0.12, -0.18, 0.02, -0.12, 0, 0);
    const geo = new THREE.ShapeGeometry(wing, 6);
    geo.rotateX(-Math.PI / 2);
    const mesh = new THREE.InstancedMesh(geo, new THREE.MeshBasicMaterial({ side: THREE.DoubleSide }), n * 2);
    const cols = ['#ff8a1f', '#4fd8ff', '#ffd23f', '#ff4f9a', '#b98aff', '#ffffff'];
    for (let i = 0; i < n * 2; i++) mesh.setColorAt(i, new THREE.Color(cols[Math.floor(i / 2) % cols.length]));
    mesh.frustumCulled = false;
    g.add(mesh);
    this.flutter = { mesh, n, seeds: Array.from({ length: n }, (_, i) => i * 1.7 + 0.4) };
    return g;
  }

  build_beach() {
    const g = new THREE.Group();
    const e = ENVS.beach;
    g.add(this.ground(e.ground, 'sand'));
    const r = rng(5);
    // wet sand band along the water
    const wcv = makeCanvas(4, 64);
    const wg = wcv.getContext('2d');
    const wgr = wg.createLinearGradient(0, 0, 0, 64);
    wgr.addColorStop(0, 'rgba(160,120,80,0.55)');
    wgr.addColorStop(1, 'rgba(160,120,80,0)');
    wg.fillStyle = wgr;
    wg.fillRect(0, 0, 4, 64);
    const wet = new THREE.Mesh(new THREE.PlaneGeometry(200, 3), new THREE.MeshBasicMaterial({ map: tex(wcv, { wrap: false }), transparent: true, depthWrite: false }));
    wet.rotation.x = -Math.PI / 2;
    wet.position.set(0, -0.265, -9.2);
    g.add(wet);
    // the sea: waves move in the vertex shader, colour fades shallow to deep
    const seaMat = new THREE.MeshBasicMaterial({ color: 0xffffff });
    const seaT = { value: 0 };
    this.seaT = seaT;
    seaMat.onBeforeCompile = (sh) => {
      sh.uniforms.uT = seaT;
      sh.vertexShader = sh.vertexShader
        .replace('#include <common>', '#include <common>\nuniform float uT;\nvarying float vW;\nvarying float vD;')
        .replace('#include <begin_vertex>', `#include <begin_vertex>
          float w = sin(position.x * 0.32 + uT * 1.1) * 0.13 + sin(position.y * 0.55 - uT * 1.7) * 0.11 + sin((position.x + position.y) * 0.95 + uT * 2.4) * 0.045;
          transformed.z += w;
          vW = w;
          vD = (position.y + 30.0) / 60.0;`);
      sh.fragmentShader = sh.fragmentShader
        .replace('#include <common>', '#include <common>\nvarying float vW;\nvarying float vD;')
        .replace('vec4 diffuseColor = vec4( diffuse, opacity );', `
          vec3 shallow = vec3(0.25, 0.82, 0.84);
          vec3 deep = vec3(0.10, 0.36, 0.70);
          vec3 sc = mix(shallow, deep, smoothstep(0.0, 0.45, vD));
          sc += vec3(0.9, 0.95, 1.0) * smoothstep(0.13, 0.22, vW) * (1.0 - vD) * 0.55;
          sc += vec3(1.0, 0.85, 0.6) * smoothstep(0.05, 0.25, vW) * 0.12;
          vec4 diffuseColor = vec4( sc, opacity );`);
    };
    seaMat.customProgramCacheKey = () => 'msmd-sea';
    const sea = new THREE.Mesh(new THREE.PlaneGeometry(200, 60, 120, 36), seaMat);
    sea.rotation.x = -Math.PI / 2;
    sea.position.set(0, -0.24, -40);
    sea.userData.dynamic = true;
    g.add(sea);
    // foam that washes in and out
    const fcv = makeCanvas(256, 32);
    const fg = fcv.getContext('2d');
    fg.fillStyle = 'rgba(255,255,255,0.95)';
    fg.beginPath();
    fg.moveTo(0, 32);
    for (let x = 0; x <= 256; x += 4) fg.lineTo(x, 12 + Math.sin(x * 0.09) * 5 + Math.sin(x * 0.23) * 3);
    fg.lineTo(256, 32);
    fg.fill();
    for (let i = 0; i < 60; i++) { fg.fillStyle = 'rgba(255,255,255,0.7)'; fg.beginPath(); fg.arc(Math.random() * 256, 4 + Math.random() * 10, 1 + Math.random() * 2, 0, TAU); fg.fill(); }
    const foamTex = tex(fcv, { wrap: true });
    foamTex.repeat.set(16, 1);
    const foam = new THREE.Mesh(new THREE.PlaneGeometry(200, 1.0), new THREE.MeshBasicMaterial({ map: foamTex, transparent: true, depthWrite: false }));
    foam.rotation.x = -Math.PI / 2;
    foam.position.set(0, -0.2, -10.2);
    foam.userData.dynamic = true;
    g.add(foam);
    this.foam = foam;
    // the sun, its glow and its path on the water
    const sun = new THREE.Mesh(new THREE.CircleGeometry(4.2, 48), this.basic(0xfff0b0, { fog: false }));
    sun.position.set(-4, 4.5, -70);
    g.add(sun);
    const sunGlow = this.glowSprite(0xffc070, 26, 0.7);
    sunGlow.position.set(-4, 4.5, -69);
    g.add(sunGlow);
    const path = new THREE.Mesh(new THREE.PlaneGeometry(6, 50), new THREE.MeshBasicMaterial({ map: beamTexture(), color: 0xffd090, transparent: true, opacity: 0.45, blending: THREE.AdditiveBlending, depthWrite: false, fog: false }));
    path.rotation.x = -Math.PI / 2;
    path.position.set(-3, -0.05, -40);
    path.userData.dynamic = true;
    g.add(path);
    this.sunPath = path;
    // an island far away
    const more = this.detail(new THREE.Group(), 1);
    g.add(more);
    const isl = this.toon(0x3d8a5a);
    const islSand = this.toon(0xe8c890);
    const ib = new THREE.Mesh(new THREE.SphereGeometry(5, 24, 12, 0, TAU, 0, Math.PI / 2), islSand);
    ib.scale.y = 0.18;
    ib.position.set(22, -0.3, -58);
    more.add(ib);
    for (let k = 0; k < 4; k++) {
      const h = new THREE.Mesh(new THREE.IcosahedronGeometry(2 + r() * 1.2, 2), isl);
      h.position.set(19 + k * 2, 0.6 + r(), -58 - r());
      h.scale.y = 0.6;
      more.add(h);
    }
    // drifting clouds
    const clouds = new THREE.Group();
    clouds.userData.dynamic = true;
    const cloudMat = this.basic(0xfff2ea, { fog: false, transparent: true, opacity: 0.92 });
    for (let c = 0; c < 6; c++) {
      const cx = -40 + c * 16 + r() * 6, cy = 11 + r() * 5, cz = -55 - r() * 10;
      for (let k = 0; k < 6; k++) {
        const s = new THREE.Mesh(new THREE.SphereGeometry(1.6 + r() * 1.4, 16, 10), cloudMat);
        s.position.set(cx + (k - 2.5) * 1.7, cy + Math.sin((k / 5) * Math.PI) * 1.2, cz);
        s.scale.y = 0.6;
        clouds.add(s);
      }
    }
    bakeStatic(clouds);
    this.detail(clouds, 1);
    g.add(clouds);
    this.clouds = clouds;
    // palms: curved, ringed trunks with drooping fronds that sway
    const trunk = this.toon(0xffffff, { map: palmBark() });
    const frond = [this.toon(0x3d9a4a, { side: THREE.DoubleSide }), this.toon(0x2e8a40, { side: THREE.DoubleSide })];
    const coconut = this.toon(0x6a4a2a);
    const fGeo = this.frondGeometry(2.0);
    this.palms = [];
    for (const [x, z, lean, h] of [[-5.5, -4, -0.25, 8], [6, -5, 0.3, 9], [-8.5, -8, -0.15, 10], [9.5, -9, 0.2, 9], [-13, -6, -0.2, 8], [14, -7, 0.25, 9]]) {
      const palm = new THREE.Group();
      palm.position.set(x, -0.27, z);
      let y = 0;
      let px = 0;
      for (let k = 0; k < h; k++) {
        const seg = new THREE.Mesh(new THREE.CylinderGeometry(0.19 - k * 0.008, 0.25 - k * 0.008, 0.72, 12), trunk);
        px += lean * 0.06 * k;
        seg.position.set(px, y + 0.36, 0);
        seg.rotation.z = -lean * 0.3 - lean * k * 0.02;
        palm.add(seg);
        y += 0.66;
      }
      const crown = new THREE.Group();
      crown.position.set(px, y - 0.1, 0);
      for (let k = 0; k < 10; k++) {
        const a = (k / 10) * TAU;
        const f = new THREE.Mesh(fGeo, frond[k % 2]);
        f.rotation.set(0, -a, 0.25 + (k % 3) * 0.12);
        f.scale.setScalar(0.9 + (k % 4) * 0.08);
        crown.add(f);
      }
      for (let k = 0; k < 4; k++) {
        const c = new THREE.Mesh(new THREE.SphereGeometry(0.16, 12, 10), coconut);
        c.position.set(Math.cos(k * 1.6) * 0.2, -0.18, Math.sin(k * 1.6) * 0.2);
        crown.add(c);
      }
      bakeStatic(crown);
      crown.userData.dynamic = true;
      crown.userData.phase = r() * TAU;
      palm.add(crown);
      this.palms.push(crown);
      g.add(palm);
    }
    // beach ball (bounces), surfboard, umbrella, towel, sandcastle, starfish, shells
    const ball = new THREE.Group();
    const cols = [0xff4f4f, 0xffffff, 0x2e8bff, 0xffd23f, 0xffffff, 0x1fb57a];
    for (let k = 0; k < 6; k++) {
      ball.add(new THREE.Mesh(new THREE.SphereGeometry(0.45, 12, 16, (k / 6) * TAU, TAU / 6), this.toon(cols[k])));
    }
    ball.position.set(3.4, 0.18, -1.8);
    ball.userData.dynamic = true;
    g.add(ball);
    this.ball = ball;
    const board = new THREE.Mesh(new THREE.CapsuleGeometry(0.4, 2.2, 10, 24), this.toon(0x2ec4b6));
    board.scale.z = 0.14;
    board.position.set(-3.8, 1.2, -3);
    board.rotation.z = 0.15;
    g.add(board);
    for (const [w, c, dx] of [[0.16, 0xff8a1f, 0], [0.05, 0xffffff, 0.14], [0.05, 0xffffff, -0.14]]) {
      const stripe = new THREE.Mesh(new THREE.BoxGeometry(w, 2.6, 0.13), this.toon(c));
      stripe.position.copy(board.position).add(new THREE.Vector3(dx, 0, 0));
      stripe.rotation.copy(board.rotation);
      g.add(stripe);
    }
    // umbrella with stripes
    const ucv = makeCanvas(256, 8);
    const ug = ucv.getContext('2d');
    for (let k = 0; k < 8; k++) { ug.fillStyle = k % 2 ? '#ffffff' : '#ff5a6a'; ug.fillRect(k * 32, 0, 32, 8); }
    const umb = new THREE.Mesh(new THREE.ConeGeometry(1.7, 0.6, 32, 1, true), this.toon(0xffffff, { map: tex(ucv, { wrap: false }), side: THREE.DoubleSide }));
    umb.position.set(5.2, 2.5, -3.2);
    umb.rotation.z = -0.15;
    g.add(umb);
    const pole = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.035, 2.8, 8), this.toon(0xf4f4f4));
    pole.position.set(5.1, 1.1, -3.2);
    pole.rotation.z = -0.15;
    g.add(pole);
    const tcv = makeCanvas(8, 64);
    const tg = tcv.getContext('2d');
    for (let k = 0; k < 8; k++) { tg.fillStyle = ['#2e8bff', '#ffffff', '#ffd23f', '#ffffff'][k % 4]; tg.fillRect(0, k * 8, 8, 8); }
    const towel = new THREE.Mesh(new THREE.PlaneGeometry(1.2, 2.2), this.toon(0xffffff, { map: tex(tcv, { wrap: false }) }));
    towel.rotation.set(-Math.PI / 2, 0, 0.3);
    towel.position.set(4.6, -0.255, -2.2);
    towel.receiveShadow = true;
    g.add(towel);
    const castle = this.toon(0xe8c48a);
    for (const [cx, cz, h, rr] of [[-3.2, 0.6, 0.5, 0.26], [-2.7, 0.5, 0.36, 0.18], [-3.55, 0.3, 0.34, 0.16]]) {
      const tw = new THREE.Mesh(new THREE.CylinderGeometry(rr, rr * 1.1, h, 14), castle);
      tw.position.set(cx, -0.27 + h / 2, cz);
      g.add(tw);
      const roof = new THREE.Mesh(new THREE.ConeGeometry(rr * 1.05, h * 0.6, 14), castle);
      roof.position.set(cx, -0.27 + h + h * 0.3, cz);
      g.add(roof);
    }
    const flagPole = new THREE.Mesh(new THREE.CylinderGeometry(0.01, 0.01, 0.4, 5), this.toon(0x6a4a2a));
    flagPole.position.set(-3.2, 0.73, 0.6);
    g.add(flagPole);
    const flag = new THREE.Mesh(new THREE.PlaneGeometry(0.18, 0.1), this.toon(0xff4f4f, { side: THREE.DoubleSide }));
    flag.position.set(-3.11, 0.86, 0.6);
    g.add(flag);
    const starShape = new THREE.Shape();
    for (let k = 0; k < 10; k++) {
      const rr = k % 2 ? 0.07 : 0.2;
      const a = (k / 10) * TAU;
      if (k === 0) starShape.moveTo(Math.cos(a) * rr, Math.sin(a) * rr);
      else starShape.lineTo(Math.cos(a) * rr, Math.sin(a) * rr);
    }
    const starGeo = new THREE.ExtrudeGeometry(starShape, { depth: 0.04, bevelEnabled: true, bevelSize: 0.02, bevelThickness: 0.02, bevelSegments: 2 });
    for (const [sx, sz, c] of [[2.6, 1.2, 0xff7a4a], [-1.9, 2.0, 0xffa24a], [6.4, -0.5, 0xff5a7a]]) {
      const s = new THREE.Mesh(starGeo, this.toon(c));
      s.rotation.set(-Math.PI / 2, 0, r() * TAU);
      s.position.set(sx, -0.25, sz);
      more.add(s);
    }
    const shellMat = [this.toon(0xfff0e0), this.toon(0xffc8b0)];
    for (let k = 0; k < 8; k++) {
      const sh = new THREE.Mesh(new THREE.SphereGeometry(0.08, 12, 8, 0, TAU, 0, Math.PI / 2), shellMat[k % 2]);
      sh.position.set((r() - 0.5) * 12, -0.26, 2.5 - r() * 8);
      if (Math.hypot(sh.position.x, sh.position.z) < 2.7) sh.position.x += 3;
      sh.scale.set(1, 0.5, 1.2);
      more.add(sh);
    }
    // seagulls far away
    const gulls = new THREE.Group();
    gulls.userData.dynamic = true;
    this.gulls = [];
    const gullMat = this.basic(0xffffff, { fog: false });
    for (let k = 0; k < 4; k++) {
      const b = new THREE.Group();
      for (const s of [-1, 1]) {
        const w = new THREE.Mesh(new THREE.CapsuleGeometry(0.06, 0.6, 2, 6), gullMat);
        w.rotation.z = Math.PI / 2;
        w.position.x = s * 0.3;
        const piv = new THREE.Group();
        piv.add(w);
        piv.userData.s = s;
        b.add(piv);
      }
      b.userData.phase = k * 1.9;
      b.userData.r = 9 + k * 3;
      gulls.add(b);
      this.gulls.push(b);
    }
    g.add(gulls);
    g.add(this.detail(this.grass(90, ['#7a8a3a', '#c8c870'], { w: 26, z0: -8, z1: 4 }, 9), 1));
    return g;
  }

  build_disco() {
    const g = new THREE.Group();
    const e = ENVS.disco;
    const floorBase = new THREE.Mesh(new THREE.CircleGeometry(44, 64), this.toon(0x1a1028));
    floorBase.rotation.x = -Math.PI / 2;
    floorBase.position.y = -0.27;
    floorBase.receiveShadow = true;
    g.add(floorBase);
    // light-up floor: one instanced mesh, a colour per tile
    const spots = [];
    for (let i = -7; i <= 7; i++) for (let k = -10; k <= 4; k++) if (Math.hypot(i, k) >= 2.2) spots.push([i, k]);
    const tiles = new THREE.InstancedMesh(new THREE.BoxGeometry(1.12, 0.08, 1.12), new THREE.MeshBasicMaterial({ color: 0xffffff }), spots.length);
    const palette = [0xff4fd8, 0x4fd8ff, 0xffd23f, 0x7a5cff, 0x4fff9a].map((c) => new THREE.Color(c));
    const m4 = new THREE.Matrix4();
    this.tileData = spots.map(([i, k], n) => {
      m4.makeTranslation(i * 1.2, -0.23, k * 1.2);
      tiles.setMatrixAt(n, m4);
      tiles.setColorAt(n, new THREE.Color(0x1a1030));
      return { col: palette[(i * 7 + k * 3 + 100) % palette.length], phase: (i + k + 100) % 3, ring: Math.hypot(i, k) };
    });
    tiles.frustumCulled = false;
    g.add(tiles);
    this.tiles = tiles;
    // temple: back wall, steps, fluted pillars with braziers, frieze
    const stoneTex = groundTexture('stone', '#7a6a8a', 256, 1, 6);
    stoneTex.repeat.set(6, 2);
    const wall = new THREE.Mesh(new THREE.BoxGeometry(32, 12, 1), this.toon(0xb8a8c8, { map: stoneTex }));
    wall.position.set(0, 5.6, -13);
    g.add(wall);
    const stone = this.toon(0x8a7a9a);
    const stoneDark = this.toon(0x6a5a7a);
    const gold = this.toon(0xe0a83a);
    for (let s = 0; s < 3; s++) {
      const step = new THREE.Mesh(new THREE.BoxGeometry(18 - s * 2, 0.35, 1.4), s % 2 ? stone : stoneDark);
      step.position.set(0, -0.1 + s * 0.35, -10.6 - s * 0.8);
      g.add(step);
    }
    const fluted = new THREE.CylinderGeometry(0.45, 0.5, 7, 32, 1);
    const fp = fluted.attributes.position;
    for (let i = 0; i < fp.count; i++) {
      const x = fp.getX(i), z = fp.getZ(i);
      const a = Math.atan2(z, x);
      const k = 1 - 0.06 * Math.max(0, Math.cos(a * 16));
      fp.setX(i, x * k);
      fp.setZ(i, z * k);
    }
    fluted.computeVertexNormals();
    this.flames = [];
    for (const x of [-7, -4.2, 4.2, 7]) {
      const p = new THREE.Mesh(fluted, stone);
      p.position.set(x, 3.2, -8);
      g.add(p);
      const base = new THREE.Mesh(new THREE.BoxGeometry(1.3, 0.35, 1.3), stoneDark);
      base.position.set(x, -0.1, -8);
      g.add(base);
      const cap = new THREE.Mesh(new THREE.BoxGeometry(1.4, 0.4, 1.4), stoneDark);
      cap.position.set(x, 6.8, -8);
      g.add(cap);
      for (const y of [0.4, 6.4]) {
        const ring = new THREE.Mesh(new THREE.TorusGeometry(0.5, 0.05, 8, 32), gold);
        ring.rotation.x = Math.PI / 2;
        ring.position.set(x, y, -8);
        g.add(ring);
      }
      // brazier
      const bowl = new THREE.Mesh(new THREE.CylinderGeometry(0.4, 0.22, 0.3, 16), gold);
      bowl.position.set(x, 7.15, -8);
      g.add(bowl);
      const fl = new THREE.Group();
      fl.position.set(x, 7.3, -8);
      fl.userData.dynamic = true;
      const outer = new THREE.Mesh(tuftGeometry(0.22, 0.6, 12), this.basic(0xff8a2a));
      const inner = new THREE.Mesh(tuftGeometry(0.12, 0.38, 10), this.basic(0xffe080));
      inner.position.z = 0.05;
      fl.add(outer, inner);
      const glow = this.glowSprite(0xff9a40, 2.6, 0.7);
      glow.position.y = 0.35;
      fl.add(glow);
      fl.userData.glow = glow;
      g.add(fl);
      this.flames.push(fl);
    }
    const lintel = new THREE.Mesh(new THREE.BoxGeometry(16, 0.7, 1.5), stone);
    lintel.position.set(0, 7.3, -8.2);
    g.add(lintel);
    const frieze = new THREE.Mesh(new THREE.BoxGeometry(16.2, 0.12, 1.55), gold);
    frieze.position.set(0, 7.0, -8.2);
    g.add(frieze);
    for (let k = -7; k <= 7; k++) {
      const gem = new THREE.Mesh(new THREE.OctahedronGeometry(0.13, 0), this.toon([0xff4fd8, 0x4fd8ff, 0xffd23f][(k + 9) % 3], { emissive: '#331133' }));
      gem.position.set(k * 1.05, 7.35, -7.42);
      g.add(gem);
    }
    // speakers that thump on the beat
    this.speakers = [];
    const cab = this.toon(0x18121f);
    const cone = this.toon(0x3a3348);
    for (const sx of [-5.6, 5.6]) {
      const sp = new THREE.Group();
      sp.position.set(sx, -0.27, -4.2);
      const box = new THREE.Mesh(new THREE.BoxGeometry(1.3, 2.4, 1.0), cab);
      box.position.y = 1.2;
      sp.add(box);
      const woofs = new THREE.Group();
      woofs.userData.dynamic = true;
      for (const [y, rr] of [[0.75, 0.42], [1.75, 0.3]]) {
        const w = new THREE.Group();
        w.position.set(0, y, 0.51);
        const ring = new THREE.Mesh(new THREE.TorusGeometry(rr, 0.05, 8, 28), gold);
        const c = new THREE.Mesh(new THREE.CircleGeometry(rr, 28), cone);
        const dome = new THREE.Mesh(new THREE.SphereGeometry(rr * 0.3, 14, 8, 0, TAU, 0, Math.PI / 2), cab);
        dome.rotation.x = Math.PI / 2;
        w.add(ring, c, dome);
        woofs.add(w);
      }
      sp.add(woofs);
      sp.rotation.y = sx < 0 ? 0.35 : -0.35;
      g.add(sp);
      this.speakers.push(woofs);
    }
    // disco ball with mirror tiles
    const ball = new THREE.Mesh(new THREE.IcosahedronGeometry(0.75, 3), new THREE.MeshMatcapMaterial({ matcap: mirrorMatcap(), flatShading: true }));
    ball.position.set(0, 6.2, -3);
    ball.userData.dynamic = true;
    g.add(ball);
    const rope = new THREE.Mesh(new THREE.CylinderGeometry(0.02, 0.02, 3, 6), this.basic(0x999999));
    rope.position.set(0, 8.1, -3);
    g.add(rope);
    this.discoBall = ball;
    const ballGlow = this.glowSprite(0xffffff, 3.2, 0.35);
    ballGlow.position.copy(ball.position);
    g.add(ballGlow);
    // light specks thrown by the ball
    const N = 260;
    const sp = new Float32Array(N * 3);
    const scol = new Float32Array(N * 3);
    const rr = rng(21);
    for (let k = 0; k < N; k++) {
      const u = rr() * 2 - 1, a = rr() * TAU, rad = 7 + rr() * 5;
      const s = Math.sqrt(1 - u * u);
      sp.set([Math.cos(a) * s * rad, u * rad * 0.6, Math.sin(a) * s * rad], k * 3);
      const c = palette[k % palette.length].clone().lerp(new THREE.Color(1, 1, 1), 0.5);
      scol.set([c.r, c.g, c.b], k * 3);
    }
    const sg = new THREE.BufferGeometry();
    sg.setAttribute('position', new THREE.BufferAttribute(sp, 3));
    sg.setAttribute('color', new THREE.BufferAttribute(scol, 3));
    const specks = new THREE.Points(sg, new THREE.PointsMaterial({ size: 0.28, map: glowTexture(), vertexColors: true, transparent: true, opacity: 0.85, blending: THREE.AdditiveBlending, depthWrite: false }));
    specks.position.copy(ball.position);
    specks.userData.dynamic = true;
    specks.frustumCulled = false;
    g.add(this.detail(specks, 1));
    this.specks = specks;
    // light beams fading down from the ceiling
    this.beams = [];
    const beamCols = [0xff4fd8, 0x4fd8ff, 0xffd23f, 0x7a5cff, 0x4fff9a, 0xff4fd8];
    const beamTex = beamTexture(false);
    for (let k = 0; k < 6; k++) {
      const pivot = new THREE.Group();
      pivot.position.set(-6.25 + k * 2.5, 7.4, -6);
      pivot.userData.dynamic = true;
      const c = new THREE.Mesh(new THREE.ConeGeometry(1.3, 10, 24, 1, true), new THREE.MeshBasicMaterial({ color: beamCols[k], map: beamTex, transparent: true, opacity: 0.32, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide, fog: false }));
      c.position.y = -5;
      pivot.add(c);
      const lamp = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.24, 0.3, 12), cab);
      pivot.add(lamp);
      const lg = this.glowSprite(beamCols[k], 1.1, 0.9);
      lg.position.y = -0.2;
      pivot.add(lg);
      pivot.userData.phase = k * 1.3;
      g.add(pivot);
      this.beams.push(pivot);
    }
    // low haze
    const haze = new THREE.Mesh(new THREE.PlaneGeometry(30, 3), new THREE.MeshBasicMaterial({ map: beamTexture(false), color: 0xb070ff, transparent: true, opacity: 0.18, blending: THREE.AdditiveBlending, depthWrite: false, fog: false }));
    haze.rotation.z = Math.PI;
    haze.position.set(0, 0.9, -7);
    haze.userData.dynamic = true;
    g.add(this.detail(haze, 2));
    this.haze = haze;
    void e;
    return g;
  }

  build_moon() {
    const g = new THREE.Group();
    const e = ENVS.moon;
    g.add(this.ground(e.ground, 'moon'));
    const r = rng(3);
    // craters with raised rims
    const rim = this.toon(0xb4b4be);
    const bowl = this.toon(0x7c7c88);
    for (let k = 0; k < 16; k++) {
      const a = r() * TAU, d = 3.6 + r() * 13;
      const x = Math.cos(a) * d, z = -Math.abs(Math.sin(a) * d) - 1;
      const rad = 0.5 + r() * 1.3;
      const ring = new THREE.Mesh(new THREE.TorusGeometry(rad, rad * 0.16, 8, 36), rim);
      ring.rotation.x = Math.PI / 2;
      ring.scale.z = 0.45;
      ring.position.set(x, -0.25, z);
      ring.receiveShadow = true;
      g.add(ring);
      const b = new THREE.Mesh(new THREE.CircleGeometry(rad, 36), bowl);
      b.rotation.x = -Math.PI / 2;
      b.position.set(x, -0.262, z);
      g.add(b);
    }
    // rocks
    const more = this.detail(new THREE.Group(), 1);
    g.add(more);
    const rockMats = [this.toon(0x8c8c96), this.toon(0xa4a4ae), this.toon(0x74747e)];
    for (let k = 0; k < 26; k++) {
      const a = r() * TAU, d = 2.9 + r() * 14;
      const s = 0.08 + r() * r() * 0.5;
      const rk = new THREE.Mesh(new THREE.DodecahedronGeometry(s, 0), rockMats[k % 3]);
      rk.position.set(Math.cos(a) * d, -0.27 + s * 0.35, -Math.abs(Math.sin(a) * d) + 2);
      rk.rotation.set(r() * 3, r() * 3, r() * 3);
      rk.scale.y = 0.7;
      more.add(rk);
    }
    // Earth with clouds and a blue glow
    const earth = new THREE.Group();
    earth.userData.dynamic = true;
    earth.add(new THREE.Mesh(new THREE.SphereGeometry(2.4, 48, 32), this.basic(0xffffff, { map: earthTexture(), fog: false })));
    const cloudsM = new THREE.Mesh(new THREE.SphereGeometry(2.46, 48, 32), new THREE.MeshBasicMaterial({ map: earthClouds(), transparent: true, depthWrite: false, fog: false }));
    earth.add(cloudsM);
    earth.userData.clouds = cloudsM;
    const halo = this.glowSprite(0x6ab0ff, 8.5, 0.55);
    earth.position.set(7, 9, -30);
    halo.position.set(7, 9, -30.5);
    g.add(earth, halo);
    this.earth = earth;
    // a ringed planet far away
    const planet = new THREE.Group();
    planet.add(new THREE.Mesh(new THREE.SphereGeometry(2.2, 40, 24), this.basic(0xffffff, { map: bandTexture(['#e8b070', '#c88850', '#f0d0a0', '#b87040', '#e8c090']), fog: false })));
    const ringGeo = new THREE.RingGeometry(3.0, 4.6, 64, 1);
    const ruv = ringGeo.attributes.uv;
    const rpos = ringGeo.attributes.position;
    for (let i = 0; i < ruv.count; i++) {
      const d = Math.hypot(rpos.getX(i), rpos.getY(i));
      ruv.setXY(i, (d - 3.0) / 1.6, 0.5);
    }
    const ring = new THREE.Mesh(ringGeo, new THREE.MeshBasicMaterial({ map: bandTexture(['#f0d8b088', '#c8a07066', '#f8e8c8aa', '#a0805044', '#e8d0a088'], true), transparent: true, side: THREE.DoubleSide, depthWrite: false, fog: false }));
    ring.rotation.x = Math.PI / 2 - 0.35;
    planet.add(ring);
    planet.position.set(-16, 13, -48);
    planet.rotation.z = 0.3;
    more.add(planet);
    // star layers that twinkle
    this.starLayers = [];
    for (const [n, size, seed] of [[500, 0.22, 4], [160, 0.42, 5], [40, 0.7, 6]]) {
      const pos = new Float32Array(n * 3);
      const rr = rng(seed);
      for (let k = 0; k < n; k++) {
        const a = rr() * TAU, b = rr() * 0.55 + 0.04, R = 85;
        pos.set([Math.cos(a) * Math.cos(b) * R, Math.sin(b) * R, -Math.abs(Math.sin(a) * Math.cos(b) * R) - 5], k * 3);
      }
      const sg = new THREE.BufferGeometry();
      sg.setAttribute('position', new THREE.BufferAttribute(pos, 3));
      const pts = new THREE.Points(sg, new THREE.PointsMaterial({ color: 0xffffff, size, map: glowTexture(), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, fog: false }));
      pts.userData.dynamic = true;
      pts.userData.seed = seed;
      g.add(pts);
      this.starLayers.push(pts);
    }
    // the rocket
    const rocket = new THREE.Group();
    const white = this.toon(0xf0f0f4);
    const red = this.toon(0xff4f4f);
    const body = new THREE.Mesh(new THREE.CylinderGeometry(0.42, 0.46, 2.1, 28), white);
    body.position.y = 1.05;
    rocket.add(body);
    const nose = new THREE.Mesh(new THREE.ConeGeometry(0.42, 0.9, 28), red);
    nose.position.y = 2.55;
    rocket.add(nose);
    for (const y of [0.25, 2.0]) {
      const band = new THREE.Mesh(new THREE.CylinderGeometry(0.47, 0.47, 0.08, 28), red);
      band.position.y = y;
      rocket.add(band);
    }
    for (const [y, rr] of [[1.45, 0.17], [0.9, 0.12]]) {
      const w = new THREE.Mesh(new THREE.CircleGeometry(rr, 24), this.basic(0x4fd8ff));
      w.position.set(0, y, 0.465);
      rocket.add(w);
      const fr = new THREE.Mesh(new THREE.TorusGeometry(rr, 0.03, 8, 24), this.toon(0x8a8a9a));
      fr.position.set(0, y, 0.46);
      rocket.add(fr);
    }
    for (let k = 0; k < 4; k++) {
      const fin = new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.7, 0.55), red);
      const a = (k / 4) * TAU + Math.PI / 4;
      fin.position.set(Math.sin(a) * 0.5, 0.3, Math.cos(a) * 0.5);
      fin.rotation.y = a;
      rocket.add(fin);
    }
    const nozzle = new THREE.Mesh(new THREE.CylinderGeometry(0.25, 0.34, 0.25, 20), this.toon(0x55555f));
    nozzle.position.y = -0.05;
    rocket.add(nozzle);
    rocket.position.set(-5, -0.27, -6);
    rocket.rotation.z = 0.08;
    g.add(rocket);
    // a flag planted in the dust
    const pole = new THREE.Mesh(new THREE.CylinderGeometry(0.025, 0.025, 2.2, 8), this.toon(0xd8d8e0));
    pole.position.set(4.2, 0.83, -4.5);
    g.add(pole);
    const fcv = makeCanvas(64, 32);
    const fg = fcv.getContext('2d');
    fg.fillStyle = '#ffd23f'; fg.fillRect(0, 0, 64, 32);
    fg.beginPath(); fg.arc(32, 14, 10, 0.3, Math.PI - 0.3); fg.lineWidth = 5; fg.strokeStyle = '#8a4a1a'; fg.stroke();
    const flagGeo = new THREE.PlaneGeometry(0.9, 0.56, 8, 1);
    const fpos = flagGeo.attributes.position;
    for (let i = 0; i < fpos.count; i++) fpos.setZ(i, Math.sin((fpos.getX(i) + 0.45) * 6) * 0.04);
    flagGeo.computeVertexNormals();
    const flag = new THREE.Mesh(flagGeo, this.toon(0xffffff, { map: tex(fcv, { wrap: false }), side: THREE.DoubleSide }));
    flag.position.set(4.65, 1.65, -4.5);
    g.add(flag);
    // a shooting star now and then
    const streak = new THREE.Mesh(new THREE.PlaneGeometry(4, 0.06), new THREE.MeshBasicMaterial({ map: beamTexture(false), transparent: true, opacity: 0, blending: THREE.AdditiveBlending, depthWrite: false, fog: false }));
    streak.rotation.z = Math.PI / 2;
    streak.userData.dynamic = true;
    streak.userData.next = 4;
    g.add(this.detail(streak, 1));
    this.shootingStar = streak;
    // floating dust
    const dust = this.fireflies(0xc8d8ff, 40, 9, 4);
    dust.material.size = 0.07;
    g.add(this.detail(dust, 1));
    void e;
    return g;
  }

  fireflies(color, n, spread, height) {
    const pos = new Float32Array(n * 3);
    const rnd = rng(11);
    for (let k = 0; k < n; k++) {
      pos[k * 3] = (rnd() - 0.5) * spread * 2;
      pos[k * 3 + 1] = 0.5 + rnd() * height;
      pos[k * 3 + 2] = -1 - rnd() * spread;
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    const pts = new THREE.Points(geo, new THREE.PointsMaterial({ color, size: 0.16, map: glowTexture(), transparent: true, opacity: 0.85, blending: THREE.AdditiveBlending, depthWrite: false }));
    pts.userData.base = pos.slice();
    pts.userData.dynamic = true;
    pts.frustumCulled = false;
    (this.flyLayers = this.flyLayers || []).push(pts);
    return pts;
  }

  // ------------------------------------------------------------ effects

  buildEffects() {
    this.rings = [];
    const ringGeo = new THREE.RingGeometry(0.3, 0.42, 48);
    for (let i = 0; i < 10; i++) {
      const m = new THREE.Mesh(ringGeo, new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0, depthWrite: false, depthTest: false }));
      m.visible = false;
      m.renderOrder = 10;
      m.userData.t0 = -10;
      this.scene.add(m);
      this.rings.push(m);
    }
    // sparkles for correct moves (one Points object, recycled)
    this.sparkN = 160;
    const sp = new Float32Array(this.sparkN * 3);
    const sc = new Float32Array(this.sparkN * 4);
    const sg = new THREE.BufferGeometry();
    sg.setAttribute('position', new THREE.BufferAttribute(sp, 3));
    sg.setAttribute('color', new THREE.BufferAttribute(sc, 4));
    this.sparkPts = new THREE.Points(sg, new THREE.PointsMaterial({ size: 0.34, map: sparkTexture(), vertexColors: true, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, depthTest: false }));
    this.sparkPts.renderOrder = 12;
    this.sparkPts.frustumCulled = false;
    this.sparkData = Array.from({ length: this.sparkN }, () => ({ p: new THREE.Vector3(), v: new THREE.Vector3(), life: 0, max: 1, c: new THREE.Color() }));
    this.sparkNext = 0;
    this.scene.add(this.sparkPts);
    // coloured trails behind the limb that is moving (makes each move easier to read)
    this.trailIds = ['LA', 'RA', 'LL', 'RL', 'HD', 'FL'];
    this.trailLen = 16;
    const tn = this.trailIds.length * this.trailLen;
    const tg = new THREE.BufferGeometry();
    tg.setAttribute('position', new THREE.BufferAttribute(new Float32Array(tn * 3), 3));
    tg.setAttribute('color', new THREE.BufferAttribute(new Float32Array(tn * 4), 4));
    this.trailPts = new THREE.Points(tg, new THREE.PointsMaterial({ size: 0.3, map: glowTexture(), vertexColors: true, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false }));
    this.trailPts.frustumCulled = false;
    this.trailPts.renderOrder = 6;
    this.trailHist = Object.fromEntries(this.trailIds.map((id) => [id, []]));
    this.scene.add(this.trailPts);
    // a soft flash behind a Perfect
    this.flashes = [];
    for (let i = 0; i < 4; i++) {
      const s = this.glowSprite(0xffffff, 1, 0);
      s.material.depthTest = false;
      s.renderOrder = 11;
      s.visible = false;
      s.userData.t0 = -10;
      this.scene.add(s);
      this.flashes.push(s);
    }
    // confetti
    this.confN = 220;
    const cg = new THREE.PlaneGeometry(0.13, 0.08);
    this.conf = new THREE.InstancedMesh(cg, new THREE.MeshBasicMaterial({ side: THREE.DoubleSide }), this.confN);
    this.conf.frustumCulled = false;
    this.conf.visible = false;
    const cols = ['#FF8A1F', '#FFC926', '#2E8BFF', '#1FB57A', '#FF4F9A', '#9B5CFF', '#ffffff'].map((c) => new THREE.Color(c));
    this.confData = [];
    for (let i = 0; i < this.confN; i++) {
      this.conf.setColorAt(i, cols[i % cols.length]);
      this.confData.push({ p: new THREE.Vector3(), v: new THREE.Vector3(), r: new THREE.Euler(), w: new THREE.Vector3(), life: 0 });
    }
    this.scene.add(this.conf);
    this.confUntil = 0;
    // dust puffs
    this.dusts = [];
    const dg = new THREE.SphereGeometry(0.16, 12, 8);
    for (let i = 0; i < 12; i++) {
      const m = new THREE.Mesh(dg, new THREE.MeshBasicMaterial({ color: 0xfff4dc, transparent: true, opacity: 0, depthWrite: false }));
      m.visible = false;
      m.userData = { t0: -10, v: new THREE.Vector3() };
      this.scene.add(m);
      this.dusts.push(m);
    }
    // dizzy stars
    const shape = new THREE.Shape();
    for (let k = 0; k < 10; k++) {
      const r = k % 2 ? 0.06 : 0.14;
      const a = (k / 10) * TAU + Math.PI / 2;
      if (k === 0) shape.moveTo(Math.cos(a) * r, Math.sin(a) * r);
      else shape.lineTo(Math.cos(a) * r, Math.sin(a) * r);
    }
    const sgeo = new THREE.ShapeGeometry(shape);
    this.dizzyGroup = new THREE.Group();
    for (let k = 0; k < 3; k++) {
      const s = new THREE.Mesh(sgeo, new THREE.MeshBasicMaterial({ color: 0xffd23f, side: THREE.DoubleSide, depthTest: false }));
      s.renderOrder = 11;
      this.dizzyGroup.add(s);
    }
    this.dizzyGroup.visible = false;
    this.dizzyUntil = 0;
    this.scene.add(this.dizzyGroup);
  }

  ring(pos, color, at) {
    const m = this.rings.find((r) => this.time - r.userData.t0 > 0.6) || this.rings[0];
    m.position.copy(pos);
    m.material.color.set(color);
    m.userData.t0 = at ?? this.time;
    m.visible = true;
  }

  /** Sparkles burst from a limb. power: 0.4 good, 0.7 great, 1 perfect. */
  sparks(pos, color, power = 0.7) {
    if (this.reduceMotion) power *= 0.5;
    const n = Math.round(8 + 22 * power);
    const c = new THREE.Color(color);
    for (let i = 0; i < n; i++) {
      const d = this.sparkData[this.sparkNext];
      this.sparkNext = (this.sparkNext + 1) % this.sparkN;
      d.p.copy(pos);
      const a = Math.random() * TAU, u = Math.random() * 2 - 1, s = Math.sqrt(1 - u * u);
      const sp = (1.4 + Math.random() * 2.2) * (0.6 + power * 0.6);
      d.v.set(Math.cos(a) * s * sp, u * sp + 1.2, Math.sin(a) * s * sp * 0.6);
      d.max = 0.35 + Math.random() * 0.35 + power * 0.2;
      d.life = d.max;
      d.c.copy(c).lerp(new THREE.Color(1, 1, 1), Math.random() * 0.6);
    }
    if (power >= 0.95) this.flash(pos, color);
  }

  flash(pos, color) {
    const s = this.flashes.find((f) => this.time - f.userData.t0 > 0.4) || this.flashes[0];
    s.position.copy(pos);
    s.material.color.set(color).lerp(new THREE.Color(1, 1, 1), 0.5);
    s.userData.t0 = this.time;
    s.visible = true;
  }

  /** A tiny zoom kick (perfect hits, round clears). */
  punch(amount = 1) {
    if (this.reduceMotion) return;
    this.punchAmt = Math.max(this.punchAmt, amount);
  }

  confetti(amount = 1) {
    if (this.reduceMotion) amount *= 0.3;
    const n = Math.floor(this.confN * Math.min(1, amount));
    for (let i = 0; i < this.confN; i++) {
      const d = this.confData[i];
      if (i >= n) { d.life = 0; continue; }
      d.p.set((Math.random() - 0.5) * 6, 4 + Math.random() * 3, (Math.random() - 0.3) * 3);
      d.v.set((Math.random() - 0.5) * 3, Math.random() * 2, (Math.random() - 0.5) * 2);
      d.r.set(Math.random() * TAU, Math.random() * TAU, 0);
      d.w.set((Math.random() - 0.5) * 12, (Math.random() - 0.5) * 12, 0);
      d.life = 2.6 + Math.random();
    }
    this.conf.visible = true;
    this.confUntil = this.time + 3.8;
  }

  dust(pos) {
    for (let k = 0; k < 3; k++) {
      const m = this.dusts.find((d) => this.time - d.userData.t0 > 0.5);
      if (!m) return;
      m.position.set(pos.x + (k - 1) * 0.15, 0.1, pos.z + 0.15);
      m.userData.v.set((k - 1) * 0.9, 0.5, 0.4);
      m.userData.t0 = this.time;
      m.visible = true;
    }
  }

  dizzy(seconds = 1.4) {
    this.dizzyUntil = this.time + seconds;
    this.dizzyGroup.visible = true;
  }

  shake(amount) {
    if (this.reduceMotion) return;
    this.shakeAmt = Math.max(this.shakeAmt, amount);
  }

  // ------------------------------------------------------------ camera

  /** Fit the monkey into the band of the screen between `top` and `bottom` px insets. */
  setFrame(top, bottom, instant = false) {
    this.frame = { top, bottom };
    this.computeCamera();
    if (instant) {
      this.camPos.copy(this.camGoal.pos);
      this.camTarget.copy(this.camGoal.target);
    }
  }

  computeCamera() {
    const W = this.width || 1, H = this.height || 1;
    const top = this.frame.top, bottom = this.frame.bottom;
    const band = Math.max(120, H - top - bottom);
    const fov = THREE.MathUtils.degToRad(this.baseFov);
    const tan = Math.tan(fov / 2);
    const monkeyH = 4.5; // floor to raised hands, plus a hat
    const monkeyW = 4.4; // arms out, plus the pad
    const dV = (monkeyH * H) / (0.94 * band * 2 * tan);
    const dH = (monkeyW * H) / (0.96 * W * 2 * tan);
    const d = Math.max(dV, dH, 6);
    const centerY = 1.95;
    this.camGoal.target.set(0, centerY, 0);
    this.camGoal.pos.set(0, centerY + d * 0.07, d);
    // shift the picture so the monkey sits in the band's centre
    const bandCenter = top + band / 2;
    this.viewShift = H / 2 - bandCenter;
  }

  resize() {
    const W = this.canvas.clientWidth || window.innerWidth;
    const H = this.canvas.clientHeight || window.innerHeight;
    this.width = W;
    this.height = H;
    this.renderer.setSize(W, H, false);
    this.camera.aspect = W / H;
    this.computeCamera();
  }

  /** quality: auto | low | medium | high | ultra ('auto' starts at high; main.js steps it down if frames are slow). */
  setQuality(q) {
    this.quality = q;
    const level = q === 'auto' ? 'high' : QUALITY[q] ? q : 'high';
    this.level = level;
    const Q = QUALITY[level];
    this.maxDpr = Q.dpr;
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, Q.dpr));
    const wantShadows = Q.shadow > 0;
    if (this.renderer.shadowMap.enabled !== wantShadows) {
      this.renderer.shadowMap.enabled = wantShadows;
      this.scene.traverse((o) => {
        if (o.material) for (const m of Array.isArray(o.material) ? o.material : [o.material]) m.needsUpdate = true;
      });
    }
    this.key.castShadow = wantShadows;
    if (wantShadows && this.key.shadow.mapSize.x !== Q.shadow) {
      this.key.shadow.mapSize.set(Q.shadow, Q.shadow);
      if (this.key.shadow.map) { this.key.shadow.map.dispose(); this.key.shadow.map = null; }
    }
    this.shadowCatcher.visible = wantShadows;
    this.shadowCatcher2.visible = wantShadows;
    this.shadow.material.opacity = wantShadows ? 0.55 : 1;
    RIM.strength.value = Q.rim;
    for (const t of this.groundTexs || []) {
      const a = level === 'low' ? 1 : 4;
      if (t.anisotropy !== a) { t.anisotropy = a; t.needsUpdate = true; }
    }
    this.applyDetail();
    this.resize();
  }

  // ------------------------------------------------------------ per frame

  onBeat(n) {
    this.beatFlash = this.time;
    this.beatN = n;
  }

  update(time, dt, beat, monkey) {
    this.time = time;
    WIND.time.value = time;
    // camera ease + shake + punch
    const k = Math.min(1, dt * 4);
    this.camPos.lerp(this.camGoal.pos, k);
    this.camTarget.lerp(this.camGoal.target, k);
    this.camera.position.copy(this.camPos);
    if (this.shakeAmt > 0.001) {
      this.camera.position.x += (Math.random() - 0.5) * this.shakeAmt;
      this.camera.position.y += (Math.random() - 0.5) * this.shakeAmt;
      this.shakeAmt *= Math.pow(0.002, dt);
    }
    this.camera.lookAt(this.camTarget);
    const fov = this.baseFov * (1 - 0.035 * this.punchAmt);
    if (this.punchAmt > 0.001) this.punchAmt *= Math.pow(0.0005, dt);
    else this.punchAmt = 0;
    this.camera.fov = fov;
    const shift = this.viewShift || 0;
    this.camera.setViewOffset(this.width, this.height, 0, shift, this.width, this.height);
    this.camera.updateProjectionMatrix();
    // rim light direction in view space
    RIM.dir.value.copy(this.rim.position).normalize().transformDirection(this.camera.matrixWorldInverse);

    // pad wedges + bulbs + beat
    const bf = beat - Math.floor(beat);
    const pulse = Math.pow(1 - bf, 3);
    for (const w of Object.values(this.wedges)) {
      const e = time - w.flash;
      const f = e >= 0 && e < 0.6 ? 1 - e / 0.6 : 0;
      w.mesh.material.color.copy(w.base).lerp(w.lit, Math.max(f, pulse * 0.12));
      w.glow.material.opacity = f * 0.75;
      w.glow.visible = f > 0.01;
    }
    const chase = Math.floor(beat * 2) % 4;
    const hot = Math.min(1, this.streak / 20);
    const on = new THREE.Color(0xffffff);
    const off = new THREE.Color(0xb08a3a).lerp(new THREE.Color(0xff8a3a), hot);
    const gcol = this.bulbGlow.geometry.attributes.color;
    for (let i = 0; i < this.bulbN; i++) {
      const lit = i % 4 === chase;
      const c = lit ? on : off;
      this.bulbs.setColorAt(i, c);
      const gl = lit ? 1 : 0.25 + hot * 0.3;
      gcol.setXYZ(i, c.r * gl, c.g * gl, c.b * gl);
    }
    this.bulbs.instanceColor.needsUpdate = true;
    gcol.needsUpdate = true;
    this.hub.material.color.setRGB(0.16 + pulse * 0.12, 0.11 + pulse * 0.08, 0.09 + pulse * 0.05);
    this.padTrim.emissive.setRGB(hot * 0.5 + pulse * 0.08, hot * 0.25 + pulse * 0.05, 0);

    // environment animation
    this.animateEnv(time, dt, beat, pulse);

    // shadow follows the monkey's hips
    if (monkey) {
      const hy = monkey.j.hips.position.y - monkey.hipsRestY;
      const s = 1 - Math.min(0.5, Math.max(0, hy) * 0.8);
      this.shadow.scale.set(s, s, 1);
    }

    // rings
    for (const r of this.rings) {
      const e = time - r.userData.t0;
      if (e < 0 || e > 0.55) { r.visible = false; continue; }
      r.visible = true;
      const s = 1 + e * 4;
      r.scale.set(s, s, s);
      r.material.opacity = 0.9 * (1 - e / 0.55);
      r.quaternion.copy(this.camera.quaternion);
    }
    // sparks
    const spos = this.sparkPts.geometry.attributes.position;
    const scol = this.sparkPts.geometry.attributes.color;
    for (let i = 0; i < this.sparkN; i++) {
      const d = this.sparkData[i];
      if (d.life <= 0) { scol.setXYZW(i, 0, 0, 0, 0); continue; }
      d.life -= dt;
      d.v.y -= 4.5 * dt;
      d.v.multiplyScalar(Math.pow(0.15, dt));
      d.p.addScaledVector(d.v, dt);
      spos.setXYZ(i, d.p.x, d.p.y, d.p.z);
      const a = Math.max(0, d.life / d.max);
      scol.setXYZW(i, d.c.r, d.c.g, d.c.b, Math.min(1, a * 1.6));
    }
    spos.needsUpdate = true;
    scol.needsUpdate = true;
    for (const f of this.flashes) {
      const e = time - f.userData.t0;
      if (e < 0 || e > 0.35) { f.visible = false; continue; }
      const s = 0.8 + e * 6;
      f.scale.set(s, s, 1);
      f.material.opacity = 0.8 * (1 - e / 0.35);
    }
    // confetti
    if (this.conf.visible) {
      const m = new THREE.Matrix4();
      const q = new THREE.Quaternion();
      const one = new THREE.Vector3(1, 1, 1);
      for (let i = 0; i < this.confN; i++) {
        const d = this.confData[i];
        if (d.life <= 0) {
          m.makeScale(0, 0, 0);
        } else {
          d.life -= dt;
          d.v.y -= 3.2 * dt;
          d.v.multiplyScalar(Math.pow(0.4, dt));
          d.p.addScaledVector(d.v, dt);
          d.r.x += d.w.x * dt;
          d.r.y += d.w.y * dt;
          q.setFromEuler(d.r);
          m.compose(d.p, q, one);
        }
        this.conf.setMatrixAt(i, m);
      }
      this.conf.instanceMatrix.needsUpdate = true;
      if (time > this.confUntil) this.conf.visible = false;
    }
    // dust
    for (const d of this.dusts) {
      const e = time - d.userData.t0;
      if (e > 0.5) { d.visible = false; continue; }
      d.position.addScaledVector(d.userData.v, dt);
      d.scale.setScalar(1 + e * 3);
      d.material.opacity = 0.7 * (1 - e / 0.5);
    }
    if (monkey) this.updateTrails(monkey, time);
    // dizzy stars around the head
    if (this.dizzyGroup.visible && monkey) {
      if (time > this.dizzyUntil) this.dizzyGroup.visible = false;
      const head = monkey.j.head.getWorldPosition(new THREE.Vector3());
      this.dizzyGroup.children.forEach((s, i) => {
        const a = time * 5 + (i / 3) * TAU;
        s.position.set(head.x + Math.cos(a) * 0.75, head.y + 1.15 + Math.sin(a * 2) * 0.05, head.z + Math.sin(a) * 0.4);
        s.rotation.z = time * 4;
      });
    }

    this.renderer.render(this.scene, this.camera);
  }

  updateTrails(monkey, time) {
    const on = (QUALITY[this.level] || QUALITY.high).detail >= 1;
    this.trailPts.visible = on;
    if (!on) return;
    const pos = this.trailPts.geometry.attributes.position;
    const col = this.trailPts.geometry.attributes.color;
    const v = new THREE.Vector3();
    const c = new THREE.Color();
    this.trailIds.forEach((id, n) => {
      const hist = this.trailHist[id];
      const h = monkey.highlight[id];
      const e = h ? time - h.at : 99;
      if (e >= 0 && e < 0.5) {
        monkey.anchorWorld(id, v);
        if (id === 'HD') v.y += 0.55;
        if (id === 'FL') v.y += 0.3;
        hist.unshift(v.clone());
        if (hist.length > this.trailLen) hist.length = this.trailLen;
        c.set(MOVES[id].color).lerp(new THREE.Color(1, 1, 1), 0.25);
        this.trailCol = this.trailCol || {};
        this.trailCol[id] = c.clone();
      } else if (hist.length) hist.pop();
      const k = e >= 0 && e < 0.7 ? 1 - e / 0.7 : 0;
      const tc = (this.trailCol && this.trailCol[id]) || c.set(0xffffff);
      for (let j = 0; j < this.trailLen; j++) {
        const i = n * this.trailLen + j;
        const p = hist[j];
        if (!p) { col.setXYZW(i, 0, 0, 0, 0); continue; }
        pos.setXYZ(i, p.x, p.y, p.z);
        const a = (1 - j / this.trailLen) * 0.7 * Math.max(k, 0.25);
        col.setXYZW(i, tc.r, tc.g, tc.b, a);
      }
    });
    pos.needsUpdate = true;
    col.needsUpdate = true;
  }

  animateEnv(time, dt, beat, pulse) {
    const id = this.envId;
    if (id === 'disco' && this.tiles) {
      const bi = Math.floor(beat);
      const c = new THREE.Color();
      this.tileData.forEach((t, n) => {
        const lit = (bi + t.phase) % 3 === 0;
        const wave = Math.max(0, 1 - Math.abs(((beat * 2.5) % 14) - t.ring) * 0.6);
        c.copy(t.col).multiplyScalar(lit ? 0.35 + pulse * 0.65 : 0.1 + wave * 0.45);
        this.tiles.setColorAt(n, c);
      });
      this.tiles.instanceColor.needsUpdate = true;
      this.discoBall.rotation.y += dt * 0.8;
      if (this.specks) {
        this.specks.rotation.y += dt * 0.8;
        this.specks.material.opacity = 0.55 + pulse * 0.4;
      }
      this.beams.forEach((b) => {
        b.rotation.z = Math.sin(time * 0.9 + b.userData.phase) * 0.55;
        b.rotation.x = Math.cos(time * 0.7 + b.userData.phase) * 0.28;
      });
      for (const f of this.flames || []) {
        f.scale.set(1 + Math.sin(time * 17 + f.position.x) * 0.1, 1 + Math.sin(time * 13 + f.position.x * 3) * 0.18, 1);
        f.userData.glow.material.opacity = 0.55 + Math.sin(time * 11 + f.position.x) * 0.15;
      }
      for (const s of this.speakers || []) s.scale.setScalar(1 + pulse * 0.08);
      if (this.haze) this.haze.material.opacity = 0.12 + pulse * 0.1;
    }
    if (id === 'jungle') {
      for (const fl of this.flyLayers || []) {
        if (!fl.visible || !fl.parent || !fl.parent.visible) continue;
        const pos = fl.geometry.attributes.position;
        const base = fl.userData.base;
        for (let i = 0; i < pos.count; i++) {
          pos.array[i * 3] = base[i * 3] + Math.sin(time * 0.6 + i) * 0.4;
          pos.array[i * 3 + 1] = base[i * 3 + 1] + Math.sin(time * 0.9 + i * 1.7) * 0.3;
        }
        pos.needsUpdate = true;
        fl.material.opacity = 0.55 + 0.35 * Math.sin(time * 2);
      }
      for (const r of this.rays || []) r.material.opacity = 0.12 + 0.1 * (0.5 + 0.5 * Math.sin(time * 0.4 + r.userData.phase));
      if (this.flutter && this.flutter.mesh.parent.visible) {
        const { mesh, n, seeds } = this.flutter;
        const m4 = new THREE.Matrix4();
        const q = new THREE.Quaternion();
        const p = new THREE.Vector3();
        const one = new THREE.Vector3(1, 1, 1);
        for (let i = 0; i < n; i++) {
          const s = seeds[i];
          const t = time * 0.35 + s;
          p.set(Math.sin(t * 1.3) * 4.5 + Math.sin(t * 2.9) * 0.6, 1.2 + Math.sin(t * 1.7) * 0.7 + (i % 3) * 0.6, -2.5 - (i % 3) * 1.5 + Math.cos(t) * 1.6);
          const heading = Math.atan2(Math.cos(t * 1.3) * 1.3, -Math.sin(t) * 1.6);
          const flap = Math.sin(time * 16 + s * 5) * 0.9;
          for (const side of [0, 1]) {
            q.setFromEuler(new THREE.Euler(0, heading, side ? flap + 0.2 : Math.PI - flap - 0.2, 'YXZ'));
            m4.compose(p, q, one);
            mesh.setMatrixAt(i * 2 + side, m4);
          }
        }
        mesh.instanceMatrix.needsUpdate = true;
      }
    }
    if (id === 'beach') {
      if (this.seaT) this.seaT.value = time;
      if (this.ball) {
        this.ball.position.y = 0.18 + Math.abs(Math.sin(time * 1.6)) * 0.25;
        this.ball.rotation.z = Math.sin(time * 0.8) * 0.4;
      }
      if (this.foam) {
        this.foam.position.z = -10.2 + Math.sin(time * 0.8) * 0.5;
        this.foam.material.opacity = 0.75 + Math.sin(time * 0.8) * 0.25;
        this.foam.material.map.offset.x = time * 0.01;
      }
      if (this.clouds) this.clouds.position.x = ((time * 0.4) % 40) - 20;
      for (const c of this.palms || []) c.rotation.z = Math.sin(time * 0.9 + c.userData.phase) * 0.04;
      for (const b of this.gulls || []) {
        const t = time * 0.25 + b.userData.phase;
        b.position.set(Math.cos(t) * b.userData.r - 6, 8 + Math.sin(t * 2) * 0.8, -26 + Math.sin(t) * 6);
        b.rotation.y = -t;
        const flap = Math.sin(time * 7 + b.userData.phase) * 0.45;
        for (const piv of b.children) piv.rotation.z = piv.userData.s * flap;
      }
    }
    if (id === 'moon') {
      if (this.earth) {
        this.earth.rotation.y += dt * 0.08;
        this.earth.userData.clouds.rotation.y += dt * 0.03;
      }
      this.starLayers.forEach((s, i) => { s.material.opacity = 0.65 + 0.35 * Math.sin(time * (1.3 + i * 0.7) + i * 2); });
      const st = this.shootingStar;
      if (st) {
        if (time > st.userData.next) {
          st.userData.t0 = time;
          st.userData.next = time + 5 + Math.random() * 6;
          st.userData.from = new THREE.Vector3(-20 + Math.random() * 40, 18 + Math.random() * 6, -40);
        }
        const e = time - (st.userData.t0 ?? -10);
        if (e >= 0 && e < 0.9) {
          st.position.copy(st.userData.from).add(new THREE.Vector3(e * 26, -e * 9, 0));
          st.rotation.z = Math.atan2(-9, 26) + Math.PI;
          st.material.opacity = Math.sin((e / 0.9) * Math.PI) * 0.9;
        } else st.material.opacity = 0;
      }
      for (const fl of this.flyLayers || []) {
        if (!fl.parent || fl.parent !== this.envs.moon) continue;
        const pos = fl.geometry.attributes.position;
        const base = fl.userData.base;
        for (let i = 0; i < pos.count; i++) pos.array[i * 3 + 1] = base[i * 3 + 1] * 0.5 + ((time * 0.08 + i * 0.37) % 1) * 3;
        pos.needsUpdate = true;
      }
    }
  }
}

// ---------------------------------------------------------------- painted textures

function mergeList(geos) {
  // small local merge for instanced shapes (all non-indexed or indexed spheres)
  const pos = [];
  const nor = [];
  for (const g0 of geos) {
    const g = g0.index ? g0.toNonIndexed() : g0;
    pos.push(...g.attributes.position.array);
    nor.push(...g.attributes.normal.array);
  }
  const out = new THREE.BufferGeometry();
  out.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  out.setAttribute('normal', new THREE.Float32BufferAttribute(nor, 3));
  return out;
}

function palmBark() {
  const cv = makeCanvas(64, 64);
  const g = cv.getContext('2d');
  g.fillStyle = '#a0703c';
  g.fillRect(0, 0, 64, 64);
  for (let y = 0; y < 64; y += 16) {
    const grd = g.createLinearGradient(0, y, 0, y + 16);
    grd.addColorStop(0, '#7a5028');
    grd.addColorStop(0.3, '#b08048');
    grd.addColorStop(1, '#8a5a30');
    g.fillStyle = grd;
    g.fillRect(0, y, 64, 16);
  }
  return tex(cv, { repeat: 1 });
}

function mirrorMatcap() {
  const S = 128;
  const cv = makeCanvas(S, S);
  const g = cv.getContext('2d');
  const grd = g.createRadialGradient(S * 0.4, S * 0.35, 0, S / 2, S / 2, S / 2);
  grd.addColorStop(0, '#ffffff');
  grd.addColorStop(0.3, '#c8c8e8');
  grd.addColorStop(0.7, '#6a5a9a');
  grd.addColorStop(1, '#2a1a4a');
  g.fillStyle = grd;
  g.fillRect(0, 0, S, S);
  const r = rng(13);
  for (let i = 0; i < 40; i++) {
    g.fillStyle = ['#ff8ae6', '#8ae6ff', '#fff08a', '#ffffff'][i % 4];
    g.globalAlpha = 0.5 + r() * 0.5;
    g.fillRect(r() * S, r() * S, 4 + r() * 6, 4 + r() * 6);
  }
  g.globalAlpha = 1;
  const t = tex(cv, { wrap: false });
  return t;
}

function earthTexture() {
  const W = 512, H = 256;
  const cv = makeCanvas(W, H);
  const g = cv.getContext('2d');
  const sea = g.createLinearGradient(0, 0, 0, H);
  sea.addColorStop(0, '#2a6ad8');
  sea.addColorStop(0.5, '#2e7bff');
  sea.addColorStop(1, '#2a6ad8');
  g.fillStyle = sea;
  g.fillRect(0, 0, W, H);
  const r = rng(17);
  const land = ['#3fbf5a', '#4fae4a', '#c8b060', '#3a9a4a'];
  for (let c = 0; c < 7; c++) {
    const cx = r() * W, cy = H * (0.25 + r() * 0.5);
    for (let k = 0; k < 14; k++) {
      g.fillStyle = land[(c + k) % land.length];
      g.beginPath();
      g.ellipse(cx + (r() - 0.5) * 70, cy + (r() - 0.5) * 50, 10 + r() * 26, 8 + r() * 18, r() * 3, 0, TAU);
      g.fill();
    }
  }
  g.fillStyle = '#f4f8ff';
  g.fillRect(0, 0, W, 14);
  g.fillRect(0, H - 12, W, 12);
  return tex(cv, { wrap: false });
}

function earthClouds() {
  const W = 512, H = 256;
  const cv = makeCanvas(W, H);
  const g = cv.getContext('2d');
  const r = rng(19);
  for (let i = 0; i < 90; i++) {
    const x = r() * W, y = H * (0.1 + r() * 0.8), w = 20 + r() * 60;
    const cg = g.createRadialGradient(x, y, 0, x, y, w);
    cg.addColorStop(0, 'rgba(255,255,255,0.75)');
    cg.addColorStop(1, 'rgba(255,255,255,0)');
    g.fillStyle = cg;
    g.fillRect(x - w, y - w * 0.4, w * 2, w * 0.8);
  }
  return tex(cv, { wrap: false });
}

function bandTexture(colors, alpha = false) {
  const cv = makeCanvas(alpha ? 128 : 8, alpha ? 4 : 128);
  const g = cv.getContext('2d');
  const n = alpha ? 128 : 128;
  for (let i = 0; i < n; i++) {
    g.fillStyle = colors[Math.floor((i / n) * colors.length * 3) % colors.length];
    if (alpha) g.fillRect(i, 0, 1, 4);
    else g.fillRect(0, i, 8, 1);
  }
  return tex(cv, { wrap: false });
}
