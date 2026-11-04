// The 3D world around the monkey: renderer, camera framing, four stages
// (jungle, beach, temple disco, moon), the light-up dance pad, and effects
// (rings, confetti, dust, dizzy stars, camera shake).
import * as THREE from './vendor/three.module.min.js';
import { MOVES } from './moves.js';
import { makeGradient } from './monkey.js';

const TAU = Math.PI * 2;
const PAD_ANGLES = { RA: 30, HD: 90, LA: 150, LL: 210, FL: 270, RL: 330 }; // degrees, see pad layout

function gradientTexture(stops) {
  const c = document.createElement('canvas');
  c.width = 4;
  c.height = 256;
  const g = c.getContext('2d');
  const grd = g.createLinearGradient(0, 0, 0, 256);
  for (const [o, col] of stops) grd.addColorStop(o, col);
  g.fillStyle = grd;
  g.fillRect(0, 0, 4, 256);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

const ENVS = {
  jungle: { sky: [[0, '#145a4f'], [0.55, '#3f9a6a'], [1, '#f3e8a6']], fog: '#7fb98a', hemi: ['#fff6d8', '#2d5a2a', 1.6], key: ['#fff1cf', 2.4], rim: ['#9fffe0', 1.2], ground: '#4f9a3d', music: 'jungle' },
  beach: { sky: [[0, '#5a6fd6'], [0.45, '#ff8f7a'], [0.75, '#ffc27a'], [1, '#ffe6b0']], fog: '#ffc79a', hemi: ['#fff0e0', '#b8875a', 1.6], key: ['#ffe2c4', 2.4], rim: ['#ff9ad0', 1.3], ground: '#f1d39a', music: 'beach' },
  disco: { sky: [[0, '#0d0420'], [0.6, '#2c0f55'], [1, '#5b1f7a']], fog: '#2a0f4a', hemi: ['#d9c8ff', '#2a1440', 1.3], key: ['#ffffff', 2.2], rim: ['#ff4fd8', 2.0], ground: '#2b2140', music: 'disco' },
  moon: { sky: [[0, '#02030a'], [0.7, '#0b1236'], [1, '#26305e']], fog: '#10173a', hemi: ['#dfe8ff', '#30303a', 1.4], key: ['#f4f6ff', 2.4], rim: ['#7fb2ff', 1.6], ground: '#9c9ca6', music: 'moon' },
};

export class Stage {
  constructor(canvas, opts = {}) {
    this.canvas = canvas;
    this.quality = opts.quality || 'auto';
    this.reduceMotion = false;
    const params = { canvas, antialias: true, powerPreference: 'high-performance' };
    // ?gl=1 forces WebGL 1 to test older phones; three.js falls back to it by itself when WebGL 2 is missing
    if (opts.forceWebGL1) params.context = canvas.getContext('webgl', { antialias: true, alpha: false }) || undefined;
    this.renderer = new THREE.WebGLRenderer(params);
    this.toonSteps = makeGradient([178, 178, 178, 178, 178, 178, 178, 255, 255, 255]);
    this.webgl = this.renderer.capabilities.isWebGL2 ? 2 : 1;
    this.maxDpr = this.quality === 'low' ? 1 : 2;
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, this.maxDpr));
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(30, 1, 0.1, 200);
    this.camPos = new THREE.Vector3(0, 1.9, 9);
    this.camTarget = new THREE.Vector3(0, 1.7, 0);
    this.camGoal = { pos: this.camPos.clone(), target: this.camTarget.clone() };
    this.frame = { top: 0, bottom: 0 };
    this.shakeAmt = 0;
    this.time = 0;

    this.hemi = new THREE.HemisphereLight(0xffffff, 0x444444, 1.5);
    this.scene.add(this.hemi);
    this.key = new THREE.DirectionalLight(0xffffff, 2.4);
    this.key.position.set(3, 6, 6);
    this.scene.add(this.key);
    this.rim = new THREE.DirectionalLight(0xffffff, 1.2);
    this.rim.position.set(-4, 4, -5);
    this.scene.add(this.rim);

    this.buildPad();
    this.envs = {};
    this.envId = null;
    this.buildEffects();
    this.resize();
  }

  // ------------------------------------------------------------ dance pad

  buildPad() {
    const g = new THREE.Group();
    const base = new THREE.Mesh(new THREE.CylinderGeometry(2.25, 2.4, 0.26, 48), this.toon(0x3a2a24));
    base.position.y = -0.13;
    g.add(base);
    this.padBase = base;
    this.wedges = {};
    for (const [id, deg] of Object.entries(PAD_ANGLES)) {
      const color = new THREE.Color(MOVES[id].color);
      const mat = new THREE.MeshBasicMaterial({ color: color.clone().multiplyScalar(0.45) });
      const w = new THREE.Mesh(new THREE.CircleGeometry(2.05, 12, THREE.MathUtils.degToRad(deg - 28), THREE.MathUtils.degToRad(56)), mat);
      w.rotation.x = -Math.PI / 2;
      w.position.y = 0.006;
      g.add(w);
      this.wedges[id] = { mesh: w, base: color.clone().multiplyScalar(0.45), lit: color.clone().lerp(new THREE.Color(0xffffff), 0.25), flash: -10 };
    }
    const hub = new THREE.Mesh(new THREE.CircleGeometry(0.7, 32), new THREE.MeshBasicMaterial({ color: 0x2a1d18 }));
    hub.rotation.x = -Math.PI / 2;
    hub.position.y = 0.01;
    g.add(hub);
    this.hub = hub;
    // blob shadow
    const sc = document.createElement('canvas');
    sc.width = sc.height = 64;
    const sg = sc.getContext('2d');
    const grd = sg.createRadialGradient(32, 32, 0, 32, 32, 32);
    grd.addColorStop(0, 'rgba(0,0,0,0.55)');
    grd.addColorStop(1, 'rgba(0,0,0,0)');
    sg.fillStyle = grd;
    sg.fillRect(0, 0, 64, 64);
    const shadow = new THREE.Mesh(new THREE.PlaneGeometry(1.9, 1.5), new THREE.MeshBasicMaterial({ map: new THREE.CanvasTexture(sc), transparent: true, depthWrite: false }));
    shadow.rotation.x = -Math.PI / 2;
    shadow.position.y = 0.02;
    g.add(shadow);
    this.shadow = shadow;
    // bulbs around the rim
    this.bulbs = [];
    const bulbGeo = new THREE.SphereGeometry(0.06, 10, 8);
    for (let i = 0; i < 24; i++) {
      const a = (i / 24) * TAU;
      const m = new THREE.Mesh(bulbGeo, new THREE.MeshBasicMaterial({ color: 0xfff1b0 }));
      m.position.set(Math.cos(a) * 2.32, 0.02, Math.sin(a) * 2.32);
      g.add(m);
      this.bulbs.push(m);
    }
    this.scene.add(g);
    this.pad = g;
  }

  lightPad(id, at) {
    const w = this.wedges[id];
    if (w) w.flash = at ?? this.time;
  }

  // ------------------------------------------------------------ environments

  setEnvironment(id) {
    if (!ENVS[id]) id = 'jungle';
    if (this.envId === id) return;
    for (const [k, g] of Object.entries(this.envs)) g.visible = k === id;
    if (!this.envs[id]) {
      const g = this['build_' + id]();
      this.envs[id] = g;
      this.scene.add(g);
    }
    const e = ENVS[id];
    if (this.skyTex) this.skyTex.dispose();
    this.skyTex = gradientTexture(e.sky);
    this.scene.background = this.skyTex;
    this.scene.fog = new THREE.Fog(e.fog, 16, 60);
    this.hemi.color.set(e.hemi[0]);
    this.hemi.groundColor.set(e.hemi[1]);
    this.hemi.intensity = e.hemi[2];
    this.key.color.set(e.key[0]);
    this.key.intensity = e.key[1];
    this.rim.color.set(e.rim[0]);
    this.rim.intensity = e.rim[1];
    this.envId = id;
  }

  musicFor(id) {
    return (ENVS[id] || ENVS.jungle).music;
  }

  toon(c) {
    return new THREE.MeshToonMaterial({ color: c, gradientMap: this.toonSteps });
  }

  ground(color, r = 40) {
    const m = new THREE.Mesh(new THREE.CircleGeometry(r, 48), this.toon(color));
    m.rotation.x = -Math.PI / 2;
    m.position.y = -0.27;
    return m;
  }

  build_jungle() {
    const g = new THREE.Group();
    g.add(this.ground(ENVS.jungle.ground));
    const trunk = this.toon(0x6b4423);
    const leaf = [this.toon(0x2d7a3a), this.toon(0x3f9446), this.toon(0x24663a)];
    const rnd = mulberry(7);
    const trees = [[-6.5, -6], [-9, -2], [6, -7], [9.5, -3], [-3, -11], [3.5, -12], [0, -16], [-12, -9], [12, -10]];
    for (const [x, z] of trees) {
      const h = 4 + rnd() * 3;
      const t = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.38, h, 10), trunk);
      t.position.set(x, h / 2 - 0.27, z);
      g.add(t);
      for (let k = 0; k < 4; k++) {
        const s = new THREE.Mesh(new THREE.SphereGeometry(1.2 + rnd() * 0.9, 16, 12), leaf[k % 3]);
        s.position.set(x + (rnd() - 0.5) * 2.2, h + (rnd() - 0.2) * 1.2, z + (rnd() - 0.5) * 1.6);
        g.add(s);
      }
    }
    // bushes
    for (let k = 0; k < 14; k++) {
      const side = k % 2 ? 1 : -1;
      const b = new THREE.Mesh(new THREE.SphereGeometry(0.6 + rnd() * 0.6, 14, 10), leaf[k % 3]);
      b.position.set(side * (3.4 + rnd() * 4), 0, -1 - rnd() * 7);
      b.scale.y = 0.75;
      g.add(b);
    }
    // flowers on the bushes
    const petal = [this.toon(0xff6fae), this.toon(0xffd23f), this.toon(0xffffff)];
    for (let k = 0; k < 18; k++) {
      const side = k % 2 ? 1 : -1;
      const f = new THREE.Mesh(new THREE.SphereGeometry(0.09, 8, 6), petal[k % 3]);
      f.position.set(side * (3.2 + rnd() * 4), 0.3 + rnd() * 0.5, -0.5 - rnd() * 7);
      g.add(f);
    }
    // hanging vines
    const vine = this.toon(0x3c7d2f);
    for (const [x, z, len] of [[-3.6, -2.5, 4], [-2.4, -4, 3], [3.2, -3, 4.5], [4.4, -1.5, 3.5], [-4.8, -0.5, 3]]) {
      const v = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.035, len, 6), vine);
      v.position.set(x, 8 - len / 2, z);
      g.add(v);
      for (let k = 0; k < 4; k++) {
        const l = new THREE.Mesh(new THREE.SphereGeometry(0.16, 8, 6), leaf[1]);
        l.scale.set(1, 0.4, 0.6);
        l.position.set(x + (k % 2 ? 0.12 : -0.12), 8 - (k + 0.7) * (len / 4.4), z);
        g.add(l);
      }
    }
    // a banana bunch on a tree
    const banana = this.toon(0xffd23f);
    for (let k = 0; k < 5; k++) {
      const b = new THREE.Mesh(new THREE.TorusGeometry(0.22, 0.07, 8, 12, Math.PI * 0.8), banana);
      b.position.set(-6 + k * 0.12, 3.6 - (k % 2) * 0.15, -5.4);
      b.rotation.set(0, 0, -1.2 + k * 0.2);
      g.add(b);
    }
    g.add(this.fireflies(0xfff4a0, 50, 10, 6));
    return g;
  }

  build_beach() {
    const g = new THREE.Group();
    g.add(this.ground(ENVS.beach.ground));
    const sea = new THREE.Mesh(new THREE.PlaneGeometry(200, 60), new THREE.MeshBasicMaterial({ color: 0x2fa6c9 }));
    sea.rotation.x = -Math.PI / 2;
    sea.position.set(0, -0.2, -40);
    g.add(sea);
    const foam = new THREE.Mesh(new THREE.PlaneGeometry(200, 0.6), new THREE.MeshBasicMaterial({ color: 0xffffff }));
    foam.rotation.x = -Math.PI / 2;
    foam.position.set(0, -0.19, -10.2);
    g.add(foam);
    this.foam = foam;
    const sun = new THREE.Mesh(new THREE.CircleGeometry(5, 40), new THREE.MeshBasicMaterial({ color: 0xffe08a, fog: false }));
    sun.position.set(-4, 3, -70);
    g.add(sun);
    const trunk = this.toon(0x9a6a3a);
    const frond = this.toon(0x3d9a4a);
    for (const [x, z, lean] of [[-5.5, -4, -0.25], [6, -5, 0.3], [-8, -8, -0.15], [9, -9, 0.2]]) {
      const palm = new THREE.Group();
      palm.position.set(x, -0.27, z);
      let y = 0;
      let px = 0;
      for (let k = 0; k < 8; k++) {
        const seg = new THREE.Mesh(new THREE.CylinderGeometry(0.2 - k * 0.012, 0.24 - k * 0.012, 0.75, 9), trunk);
        px += lean * 0.18 * k * 0.3;
        seg.position.set(px, y + 0.37, 0);
        seg.rotation.z = -lean * 0.3;
        palm.add(seg);
        y += 0.7;
      }
      for (let k = 0; k < 7; k++) {
        const a = (k / 7) * TAU;
        const f = new THREE.Mesh(new THREE.SphereGeometry(1, 12, 8), frond);
        f.scale.set(1.5, 0.12, 0.38);
        f.position.set(px + Math.cos(a) * 1.2, y - 0.25, Math.sin(a) * 1.2);
        f.rotation.set(0, -a, -0.45);
        palm.add(f);
      }
      g.add(palm);
    }
    // beach ball + surfboard
    const ball = new THREE.Group();
    const cols = [0xff4f4f, 0xffffff, 0x2e8bff, 0xffd23f];
    for (let k = 0; k < 4; k++) {
      const s = new THREE.Mesh(new THREE.SphereGeometry(0.45, 16, 12, (k / 4) * TAU, TAU / 4), this.toon(cols[k]));
      ball.add(s);
    }
    ball.position.set(3.4, 0.18, -1.8);
    g.add(ball);
    this.ball = ball;
    const board = new THREE.Mesh(new THREE.CapsuleGeometry(0.4, 2.2, 6, 16), this.toon(0x2ec4b6));
    board.scale.z = 0.15;
    board.position.set(-3.8, 1.2, -3);
    board.rotation.z = 0.15;
    g.add(board);
    const stripe = new THREE.Mesh(new THREE.BoxGeometry(0.14, 2.6, 0.13), this.toon(0xff8a1f));
    stripe.position.copy(board.position);
    stripe.rotation.copy(board.rotation);
    g.add(stripe);
    return g;
  }

  build_disco() {
    const g = new THREE.Group();
    g.add(this.ground(ENVS.disco.ground));
    // light-up floor tiles
    this.tiles = [];
    const tileGeo = new THREE.BoxGeometry(1.15, 0.08, 1.15);
    const palette = [0xff4fd8, 0x4fd8ff, 0xffd23f, 0x7a5cff, 0x4fff9a];
    for (let i = -6; i <= 6; i++) {
      for (let k = -9; k <= 3; k++) {
        if (Math.hypot(i, k) < 2.2) continue;
        const m = new THREE.Mesh(tileGeo, new THREE.MeshBasicMaterial({ color: 0x1a1030 }));
        m.position.set(i * 1.2, -0.23, k * 1.2);
        m.userData.col = new THREE.Color(palette[(i * 7 + k * 3 + 100) % palette.length]);
        m.userData.phase = (i + k + 100) % 3;
        g.add(m);
        this.tiles.push(m);
      }
    }
    // temple pillars
    const stone = this.toon(0x8a7a9a);
    for (const x of [-7, -4.2, 4.2, 7]) {
      const p = new THREE.Mesh(new THREE.CylinderGeometry(0.45, 0.5, 7, 14), stone);
      p.position.set(x, 3.2, -8);
      g.add(p);
      const cap = new THREE.Mesh(new THREE.BoxGeometry(1.4, 0.4, 1.4), stone);
      cap.position.set(x, 6.8, -8);
      g.add(cap);
      // torch
      const flame = new THREE.Mesh(new THREE.ConeGeometry(0.22, 0.6, 10), new THREE.MeshBasicMaterial({ color: 0xffa23f }));
      flame.position.set(x, 7.35, -8);
      g.add(flame);
      (this.flames = this.flames || []).push(flame);
    }
    const lintel = new THREE.Mesh(new THREE.BoxGeometry(16, 0.7, 1.5), stone);
    lintel.position.set(0, 7.3, -8.2);
    g.add(lintel);
    // disco ball
    const ball = new THREE.Mesh(new THREE.IcosahedronGeometry(0.75, 2), new THREE.MeshPhongMaterial({ color: 0xd8d8f0, flatShading: true, shininess: 120, specular: 0xffffff }));
    ball.position.set(0, 6.2, -3);
    g.add(ball);
    const rope = new THREE.Mesh(new THREE.CylinderGeometry(0.02, 0.02, 3, 6), new THREE.MeshBasicMaterial({ color: 0x999999 }));
    rope.position.set(0, 8.1, -3);
    g.add(rope);
    this.discoBall = ball;
    // light beams
    this.beams = [];
    const beamCols = [0xff4fd8, 0x4fd8ff, 0xffd23f, 0x7a5cff];
    for (let k = 0; k < 4; k++) {
      const pivot = new THREE.Group();
      pivot.position.set(-4.5 + k * 3, 7, -6);
      const cone = new THREE.Mesh(new THREE.ConeGeometry(1.2, 9, 20, 1, true), new THREE.MeshBasicMaterial({ color: beamCols[k], transparent: true, opacity: 0.16, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide }));
      cone.position.y = -4.5;
      pivot.add(cone);
      pivot.userData.phase = k * 1.3;
      g.add(pivot);
      this.beams.push(pivot);
    }
    return g;
  }

  build_moon() {
    const g = new THREE.Group();
    g.add(this.ground(ENVS.moon.ground));
    const crater = this.toon(0x7c7c88);
    const rnd = mulberry(3);
    for (let k = 0; k < 14; k++) {
      const c = new THREE.Mesh(new THREE.CircleGeometry(0.5 + rnd() * 1.2, 24), crater);
      c.rotation.x = -Math.PI / 2;
      const a = rnd() * TAU, r = 3.5 + rnd() * 12;
      c.position.set(Math.cos(a) * r, -0.26, -Math.abs(Math.sin(a) * r) - 1);
      g.add(c);
    }
    const earth = new THREE.Group();
    earth.add(new THREE.Mesh(new THREE.SphereGeometry(2.4, 32, 24), this.toon(0x2e7bff)));
    const land = this.toon(0x3fbf5a);
    for (const [x, y, z, s] of [[0.9, 0.8, 1.9, 0.9], [-1.1, -0.3, 1.9, 1.0], [0.2, -1.4, 1.7, 0.7], [1.6, -0.6, 1.4, 0.6]]) {
      const l = new THREE.Mesh(new THREE.SphereGeometry(s, 14, 10), land);
      l.position.set(x, y, z);
      l.scale.z = 0.6;
      earth.add(l);
    }
    earth.position.set(7, 9, -30);
    g.add(earth);
    this.earth = earth;
    // little rocket
    const rocket = new THREE.Group();
    const body = new THREE.Mesh(new THREE.CylinderGeometry(0.4, 0.45, 2, 16), this.toon(0xf0f0f0));
    body.position.y = 1;
    rocket.add(body);
    const nose = new THREE.Mesh(new THREE.ConeGeometry(0.4, 0.8, 16), this.toon(0xff4f4f));
    nose.position.y = 2.4;
    rocket.add(nose);
    const win = new THREE.Mesh(new THREE.CircleGeometry(0.16, 16), new THREE.MeshBasicMaterial({ color: 0x4fd8ff }));
    win.position.set(0, 1.4, 0.46);
    rocket.add(win);
    for (let k = 0; k < 3; k++) {
      const fin = new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.6, 0.5), this.toon(0xff4f4f));
      const a = (k / 3) * TAU;
      fin.position.set(Math.sin(a) * 0.45, 0.25, Math.cos(a) * 0.45);
      fin.rotation.y = a;
      rocket.add(fin);
    }
    rocket.position.set(-5, -0.27, -6);
    rocket.rotation.z = 0.08;
    g.add(rocket);
    // stars
    const n = 400;
    const pos = new Float32Array(n * 3);
    for (let k = 0; k < n; k++) {
      const a = rnd() * TAU, b = rnd() * 0.5 + 0.05, r = 80;
      pos[k * 3] = Math.cos(a) * Math.cos(b) * r;
      pos[k * 3 + 1] = Math.sin(b) * r;
      pos[k * 3 + 2] = -Math.abs(Math.sin(a) * Math.cos(b) * r) - 5;
    }
    const sg = new THREE.BufferGeometry();
    sg.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    g.add(new THREE.Points(sg, new THREE.PointsMaterial({ color: 0xffffff, size: 0.35, fog: false })));
    return g;
  }

  fireflies(color, n, spread, height) {
    const pos = new Float32Array(n * 3);
    const rnd = mulberry(11);
    for (let k = 0; k < n; k++) {
      pos[k * 3] = (rnd() - 0.5) * spread * 2;
      pos[k * 3 + 1] = 0.5 + rnd() * height;
      pos[k * 3 + 2] = -1 - rnd() * spread;
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    const pts = new THREE.Points(geo, new THREE.PointsMaterial({ color, size: 0.12, transparent: true, opacity: 0.85, blending: THREE.AdditiveBlending, depthWrite: false }));
    pts.userData.base = pos.slice();
    this.flies = pts;
    return pts;
  }

  // ------------------------------------------------------------ effects

  buildEffects() {
    this.rings = [];
    const ringGeo = new THREE.RingGeometry(0.3, 0.42, 36);
    for (let i = 0; i < 10; i++) {
      const m = new THREE.Mesh(ringGeo, new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0, depthWrite: false, depthTest: false }));
      m.visible = false;
      m.renderOrder = 10;
      m.userData.t0 = -10;
      this.scene.add(m);
      this.rings.push(m);
    }
    // confetti
    this.confN = 180;
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
    const dg = new THREE.SphereGeometry(0.16, 10, 8);
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
    const fov = THREE.MathUtils.degToRad(this.camera.fov);
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

  setQuality(q) {
    this.quality = q;
    this.maxDpr = q === 'low' ? 1 : q === 'high' ? 2.5 : 2;
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, this.maxDpr));
    this.resize();
  }

  // ------------------------------------------------------------ per frame

  onBeat(n) {
    this.beatFlash = this.time;
    this.beatN = n;
  }

  update(time, dt, beat, monkey) {
    this.time = time;
    // camera ease + shake
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
    const shift = this.viewShift || 0;
    this.camera.setViewOffset(this.width, this.height, 0, shift, this.width, this.height);
    this.camera.updateProjectionMatrix();

    // pad wedges + bulbs + beat
    const bf = beat - Math.floor(beat);
    const pulse = Math.pow(1 - bf, 3);
    for (const w of Object.values(this.wedges)) {
      const e = time - w.flash;
      const f = e >= 0 && e < 0.6 ? 1 - e / 0.6 : 0;
      w.mesh.material.color.copy(w.base).lerp(w.lit, Math.max(f, pulse * 0.12));
    }
    const chase = Math.floor(beat * 2) % 4;
    this.bulbs.forEach((b, i) => {
      b.material.color.setHex(i % 4 === chase ? 0xffffff : 0xb08a3a);
    });
    this.hub.material.color.setRGB(0.16 + pulse * 0.12, 0.11 + pulse * 0.08, 0.09 + pulse * 0.05);

    // environment animation
    if (this.envId === 'disco' && this.tiles) {
      const bi = Math.floor(beat);
      for (const t of this.tiles) {
        const on = (bi + t.userData.phase) % 3 === 0;
        t.material.color.copy(t.userData.col).multiplyScalar(on ? 0.35 + pulse * 0.65 : 0.12);
      }
      this.discoBall.rotation.y += dt * 0.8;
      this.beams.forEach((b) => {
        b.rotation.z = Math.sin(time * 0.9 + b.userData.phase) * 0.5;
        b.rotation.x = Math.cos(time * 0.7 + b.userData.phase) * 0.25;
      });
      for (const f of this.flames || []) f.scale.set(1 + Math.sin(time * 17 + f.position.x) * 0.1, 1 + Math.sin(time * 13 + f.position.x * 3) * 0.18, 1);
    }
    if (this.envId === 'jungle' && this.flies) {
      const pos = this.flies.geometry.attributes.position;
      const base = this.flies.userData.base;
      for (let i = 0; i < pos.count; i++) {
        pos.array[i * 3] = base[i * 3] + Math.sin(time * 0.6 + i) * 0.4;
        pos.array[i * 3 + 1] = base[i * 3 + 1] + Math.sin(time * 0.9 + i * 1.7) * 0.3;
      }
      pos.needsUpdate = true;
      this.flies.material.opacity = 0.55 + 0.35 * Math.sin(time * 2);
    }
    if (this.envId === 'beach') {
      if (this.ball) this.ball.position.y = 0.18 + Math.abs(Math.sin(time * 1.6)) * 0.25;
      if (this.foam) this.foam.position.z = -10.2 + Math.sin(time * 0.8) * 0.4;
    }
    if (this.envId === 'moon' && this.earth) this.earth.rotation.y += dt * 0.1;

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
    // dizzy stars around the head
    if (this.dizzyGroup.visible && monkey) {
      if (time > this.dizzyUntil) this.dizzyGroup.visible = false;
      const head = monkey.j.head.getWorldPosition(new THREE.Vector3());
      this.dizzyGroup.children.forEach((s, i) => {
        const a = time * 5 + (i / 3) * TAU;
        s.position.set(head.x + Math.cos(a) * 0.75, head.y + 1.15 + Math.sin(a * 2) * 0.05, head.z + Math.sin(a) * 0.4);
        s.rotation.z = time * 4;
        s.quaternion.premultiply(new THREE.Quaternion());
      });
    }

    this.renderer.render(this.scene, this.camera);
  }
}

function mulberry(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
