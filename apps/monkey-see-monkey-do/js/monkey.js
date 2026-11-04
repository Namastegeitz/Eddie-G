// The monkey: a cel-shaded cartoon built from simple shapes, with jointed
// arms and legs, a curly tail, a face that changes expression, and slots
// for hats, glasses and neckwear. Animation is layered: an idle groove that
// follows the beat, plus any number of moves/reactions added on top.
import * as THREE from './vendor/three.module.min.js';
import { MOVES } from './moves.js';
import { getSkin } from './skins.js';
import { applySkin, flashMaterial, updateSkinFx, setAura, refreshSkinExtras } from './skinlook.js';
import { buildGear, updateGearFx } from './gear.js';
import { getItem, GEAR_SLOTS } from './shop.js';

const TAU = Math.PI * 2;
const clamp01 = (x) => (x < 0 ? 0 : x > 1 ? 1 : x);
const smooth = (x) => { x = clamp01(x); return x * x * (3 - 2 * x); };
const outBack = (x) => { x = clamp01(x); const c = 1.7; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); };
// 0 -> 1 -> 0 over the move, with a quick rise and a held peak
const hump = (t, rise = 0.3, hold = 0.65) => (t < rise ? outBack(t / rise) : t < hold ? 1 : 1 - smooth((t - hold) / (1 - hold)));
const OUTLINE = 0.028;

const JOINTS = ['hips', 'torso', 'head', 'shL', 'shR', 'elL', 'elR', 'haL', 'haR', 'hipL', 'hipR', 'knL', 'knR', 'ftL', 'ftR', 'earL', 'earR'];
const SIDE = { L: -1, R: 1 }; // L = left of the screen (x < 0)

/**
 * Cel-shading steps as a tiny texture. Every toon material gets one: without it
 * three.js uses fwidth(), which older phones on WebGL 1 can't compile.
 */
export function makeGradient(levels = [90, 170, 235, 255]) {
  const data = new Uint8Array(levels.length * 4);
  levels.forEach((v, i) => data.set([v, v, v, 255], i * 4));
  const tex = new THREE.DataTexture(data, levels.length, 1, THREE.RGBAFormat);
  tex.minFilter = THREE.NearestFilter;
  tex.magFilter = THREE.NearestFilter;
  tex.needsUpdate = true;
  return tex;
}

function newPose() {
  const j = {};
  for (const n of JOINTS) j[n] = [0, 0, 0];
  return {
    j, y: 0, ry: 0, hipsY: 0, squash: 0, tail: 0,
    face: { mouth: null, eyes: null, brow: 0, tilt: 0, pri: -1 },
  };
}

function resetPose(p) {
  for (const n of JOINTS) { const v = p.j[n]; v[0] = 0; v[1] = 0; v[2] = 0; }
  p.y = 0; p.ry = 0; p.hipsY = 0; p.squash = 0; p.tail = 0;
  p.face.mouth = null; p.face.eyes = null; p.face.brow = 0; p.face.tilt = 0; p.face.pri = -1;
}

function setFace(p, pri, mouth, eyes, brow = 0, tilt = 0) {
  if (pri < p.face.pri) return;
  p.face.pri = pri;
  if (mouth) p.face.mouth = mouth;
  if (eyes) p.face.eyes = eyes;
  p.face.brow = brow;
  p.face.tilt = tilt;
}

// ---------------------------------------------------------------- move animations
// Each gets (pose, t 0..1, seconds elapsed, extra). s = -1 for screen-left limbs.

function armUp(p, side, t) {
  const s = SIDE[side];
  const k = hump(t, 0.28, 0.7);
  const sh = side === 'L' ? 'shL' : 'shR';
  const el = side === 'L' ? 'elL' : 'elR';
  const ha = side === 'L' ? 'haL' : 'haR';
  p.j[sh][2] += s * 2.25 * k;
  p.j[sh][0] += -0.25 * k;
  p.j[el][2] += s * (0.25 + 0.3 * Math.sin(t * TAU * 2.2)) * k; // wave
  p.j[el][0] += 0.2 * k;
  p.j[ha][2] += s * 0.4 * Math.sin(t * TAU * 2.2 + 1) * k;
  p.j.torso[2] += -s * 0.1 * k;
  p.j.head[2] += s * 0.12 * k;
  p.j.head[1] += s * 0.18 * k;
  p.hipsY += 0.03 * k;
  setFace(p, 1, 'grin', null, 0.5);
}

function legStomp(p, side, t, el, ctx) {
  const s = SIDE[side];
  const lift = t < 0.42 ? outBack(t / 0.42) : t < 0.52 ? 1 : 1 - smooth((t - 0.52) / 0.12);
  const hip = side === 'L' ? 'hipL' : 'hipR';
  const kn = side === 'L' ? 'knL' : 'knR';
  const ft = side === 'L' ? 'ftL' : 'ftR';
  p.j[hip][0] += -1.35 * lift;
  p.j[hip][2] += s * 0.18 * lift;
  p.j[kn][0] += 1.85 * lift;
  p.j[ft][0] += -0.35 * lift;
  p.j.torso[2] += -s * 0.14 * lift;
  p.j.torso[0] += -0.06 * lift;
  // arms balance: opposite arm swings up, same arm out a little
  const op = side === 'L' ? 'shR' : 'shL';
  const me = side === 'L' ? 'shL' : 'shR';
  p.j[op][2] += -s * 0.85 * lift;
  p.j[me][2] += s * 0.35 * lift;
  // stomp: body dips after the foot lands
  if (t > 0.62) {
    const d = (t - 0.62) / 0.38;
    p.hipsY += -0.09 * Math.sin(Math.min(1, d * 2.2) * Math.PI) * (1 - d);
    p.squash += 0.08 * Math.max(0, 1 - d * 2.5);
  }
  if (ctx && !ctx.stomped && t >= 0.64) {
    ctx.stomped = true;
    ctx.monkey.emit('stomp', side);
  }
  setFace(p, 1, 'grin', null, 0.2);
}

function headBob(p, t) {
  const n = Math.abs(Math.sin(t * TAU));
  const env = 1 - smooth((t - 0.85) / 0.15);
  p.j.head[0] += 0.38 * n * env;
  p.j.torso[0] += 0.06 * n * env;
  p.hipsY += -0.06 * n * env;
  p.j.earL[2] += 0.45 * n * env;
  p.j.earR[2] += -0.45 * n * env;
  p.j.shL[2] += -0.25 * n * env;
  p.j.shR[2] += 0.25 * n * env;
  setFace(p, 1, 'grin', 'happy', 0.6);
}

const FLAIRS = {
  wiggle(p, t) {
    const env = hump(t, 0.15, 0.85);
    const w = Math.sin(t * TAU * 2);
    p.j.hips[2] += 0.3 * w * env;
    p.j.hips[1] += 0.25 * w * env;
    p.j.torso[2] += -0.28 * w * env;
    // hands on hips
    p.j.shL[2] += -0.55 * env; p.j.shR[2] += 0.55 * env;
    p.j.elL[2] += 1.5 * env; p.j.elR[2] += -1.5 * env;
    p.j.elL[0] += -0.4 * env; p.j.elR[0] += -0.4 * env;
    p.j.head[2] += 0.12 * w * env;
    p.tail += 1.2 * env;
    setFace(p, 1, 'tongue', 'happy', 0.4);
  },
  spin(p, t) {
    const env = hump(t, 0.15, 0.8);
    p.ry += TAU * smooth(t / 0.9);
    p.j.shL[2] += -1.3 * env; p.j.shR[2] += 1.3 * env;
    p.j.hipL[0] += -0.5 * env; p.j.knL[0] += 0.9 * env;
    p.hipsY += 0.08 * env;
    setFace(p, 1, 'grin', 'happy', 0.5);
  },
  shimmy(p, t) {
    const env = hump(t, 0.15, 0.85);
    const w = Math.sin(t * TAU * 3);
    p.j.torso[1] += 0.32 * w * env;
    p.j.shL[0] += 0.5 * w * env; p.j.shR[0] += -0.5 * w * env;
    p.j.shL[2] += -0.7 * env; p.j.shR[2] += 0.7 * env;
    p.j.elL[0] += -0.9 * env; p.j.elR[0] += -0.9 * env;
    p.hipsY += -0.05 * Math.abs(w) * env;
    p.j.knL[0] += 0.25 * env; p.j.knR[0] += 0.25 * env; p.j.hipL[0] += -0.15 * env; p.j.hipR[0] += -0.15 * env;
    setFace(p, 1, 'grin', 'happy', 0.7);
  },
  robot(p, t) {
    const seg = Math.min(3, Math.floor(t * 4));
    const f = smooth(((t * 4) % 1) / 0.18);
    const poses = [
      [1, 0, -0.5], // [left up?, right up?, head yaw]
      [0, 1, 0.5],
      [1, 1, 0],
      [0, 0, 0],
    ];
    const prev = poses[Math.max(0, seg - 1)];
    const cur = poses[seg];
    const mix = (a, b) => a + (b - a) * (seg === 0 ? smooth(t * 4 / 0.18) : f);
    const env = 1 - smooth((t - 0.85) / 0.15);
    const lu = mix(seg === 0 ? 0 : prev[0], cur[0]) * env;
    const ru = mix(seg === 0 ? 0 : prev[1], cur[1]) * env;
    const hy = mix(seg === 0 ? 0 : prev[2], cur[2]) * env;
    p.j.shL[2] += -1.25 * lu; p.j.elL[2] += -1.57 * lu;
    p.j.shR[2] += 1.25 * ru; p.j.elR[2] += 1.57 * ru;
    p.j.shL[0] += -1.2 * (1 - lu) * env; p.j.elL[0] += -0.6 * (1 - lu) * env;
    p.j.shR[0] += -1.2 * (1 - ru) * env; p.j.elR[0] += -0.6 * (1 - ru) * env;
    p.j.head[1] += hy;
    p.hipsY += -0.04 * env;
    setFace(p, 1, 'flat', 'wide', 0.3);
  },
};

// Reactions
function cheer(p, t, el) {
  const env = hump(t, 0.12, 0.85);
  p.j.shL[2] += (-2.6 + 0.2 * Math.sin(el * 22)) * env;
  p.j.shR[2] += (2.6 + 0.2 * Math.sin(el * 22 + 1)) * env;
  p.j.elL[2] += -0.3 * env; p.j.elR[2] += 0.3 * env;
  p.hipsY += 0.32 * Math.abs(Math.sin(t * TAU * 1.5)) * env;
  p.j.knL[0] += 0.5 * env * Math.abs(Math.sin(t * TAU * 1.5)); p.j.knR[0] += 0.5 * env * Math.abs(Math.sin(t * TAU * 1.5));
  p.j.hipL[0] += -0.3 * env * Math.abs(Math.sin(t * TAU * 1.5)); p.j.hipR[0] += -0.3 * env * Math.abs(Math.sin(t * TAU * 1.5));
  p.j.head[0] += -0.2 * env;
  p.tail += 1.5 * env;
  setFace(p, 3, 'grin', 'happy', 0.9);
}

function oops(p, t, el, ctx) {
  // 1) stumble and flail  2) wobble, dizzy  3) sheepish head scratch
  const a = hump(clamp01(t / 0.45), 0.25, 0.6);
  const flail = Math.sin(el * 24);
  p.j.torso[2] += 0.42 * a;
  p.j.torso[0] += -0.2 * a;
  p.j.head[0] += -0.25 * a;
  p.j.shL[2] += (-1.3 - 0.6 * flail) * a;
  p.j.shR[2] += (1.3 - 0.6 * flail) * a;
  p.j.hipR[0] += -0.7 * a; p.j.knR[0] += 0.6 * a;
  p.hipsY += 0.06 * a;
  const b = clamp01((t - 0.3) / 0.35) * (1 - smooth((t - 0.62) / 0.12));
  p.j.hips[2] += 0.18 * Math.sin(el * 9) * b;
  p.j.head[2] += 0.25 * Math.sin(el * 9 + 1) * b;
  const c = smooth((t - 0.55) / 0.15) * (1 - smooth((t - 0.9) / 0.1));
  p.j.shR[2] += 2.15 * c; p.j.elR[2] += -2.1 * c; p.j.elR[0] += -0.5 * c;
  p.j.haR[0] += 0.4 * Math.sin(el * 30) * c;
  p.j.head[2] += -0.22 * c;
  if (ctx && !ctx.dizzy && t > 0.2) { ctx.dizzy = true; ctx.monkey.emit('dizzy'); }
  if (t < 0.55) setFace(p, 3, 'o', 'wide', 1, 0);
  else setFace(p, 3, 'flat', 'open', 0.2, 1);
}

function pointAtYou(p, t) {
  const k = hump(t, 0.25, 0.75);
  p.j.shR[0] += -1.45 * k;
  p.j.shR[2] += -0.2 * k;
  p.j.elR[0] += 0.2 * k;
  p.j.head[2] += -0.12 * k;
  p.j.torso[1] += -0.12 * k;
  setFace(p, 2, 'grin', 'wink', 0.6);
}

function jumpLift(p, t) {
  p.hipsY += 0.42 * Math.sin(clamp01(t / 0.8) * Math.PI);
  p.j.shL[2] += -0.6 * Math.sin(t * Math.PI); p.j.shR[2] += 0.6 * Math.sin(t * Math.PI);
  setFace(p, 1, 'grin', 'happy', 0.8);
}

function hop(p, t) {
  p.hipsY += 0.14 * Math.sin(clamp01(t / 0.7) * Math.PI);
  setFace(p, 1, 'grin', 'happy', 0.8);
}

function sad(p, t, el) {
  const k = smooth(t * 4);
  p.j.torso[0] += 0.32 * k;
  p.j.head[0] += 0.42 * k;
  p.j.shL[2] += 0.22 * k; p.j.shR[2] += -0.22 * k;
  p.j.shL[0] += -0.25 * k; p.j.shR[0] += -0.25 * k;
  p.j.head[2] += 0.06 * Math.sin(el * 1.3) * k;
  p.hipsY += -0.08 * k;
  p.j.knL[0] += 0.2 * k; p.j.knR[0] += 0.2 * k; p.j.hipL[0] += -0.1 * k; p.j.hipR[0] += -0.1 * k;
  p.tail += -0.8 * k;
  setFace(p, 3, 'frown', 'open', -1, 1);
}

function scratch(p, t, el) {
  const c = hump(t, 0.2, 0.8);
  p.j.shL[2] += -2.15 * c; p.j.elL[2] += 2.1 * c; p.j.elL[0] += -0.5 * c;
  p.j.haL[0] += 0.4 * Math.sin(el * 26) * c;
  p.j.head[2] += 0.2 * c;
  setFace(p, 1, 'flat', 'open', 0.4, 1);
}

function waveHello(p, t, el) {
  const k = hump(t, 0.2, 0.8);
  p.j.shR[2] += 2.3 * k;
  p.j.elR[2] += (0.5 + 0.45 * Math.sin(el * 12)) * k;
  p.j.head[2] += -0.1 * k;
  setFace(p, 1, 'grin', 'happy', 0.6);
}

function stretchYawn(p, t) {
  const k = hump(t, 0.35, 0.7);
  p.j.shL[2] += -2.7 * k; p.j.shR[2] += 2.7 * k;
  p.j.elL[2] += 0.6 * k; p.j.elR[2] += -0.6 * k;
  p.j.torso[0] += -0.12 * k;
  p.j.head[0] += -0.25 * k;
  setFace(p, 1, 'o', 'closed', 0.5);
}

function turnAround(p, t) {
  // show off the back: turn, hold, turn back
  p.ry += Math.PI * hump(t, 0.3, 0.7);
  setFace(p, 1, 'grin', 'happy', 0.5);
}

const ACTIONS = {
  TURN: turnAround,
  LA: (p, t) => armUp(p, 'L', t),
  RA: (p, t) => armUp(p, 'R', t),
  LL: (p, t, el, ctx) => legStomp(p, 'L', t, el, ctx),
  RL: (p, t, el, ctx) => legStomp(p, 'R', t, el, ctx),
  HD: (p, t) => headBob(p, t),
  JUMP: jumpLift,
  HOP: hop,
  CHEER: cheer,
  OOPS: oops,
  POINT: pointAtYou,
  SAD: sad,
  SCRATCH: scratch,
  WAVE: waveHello,
  YAWN: stretchYawn,
};

// ---------------------------------------------------------------- the monkey

export class Monkey {
  constructor({ outlines = true } = {}) {
    this.outlines = true; // always built; setOutlines() shows or hides them
    this.outlinesOn = outlines;
    this.root = new THREE.Group();
    this.root.name = 'monkey';
    this.j = {};
    this.mats = {};
    this.anims = [];
    this.pose = newPose();
    this.flair = 'wiggle';
    this.listeners = {};
    this.look = new THREE.Vector2();
    this.lookTarget = new THREE.Vector2();
    this.blinkAt = 2;
    this.blinkT = 0;
    this.highlight = {};
    this.time = 0;
    this.danceAmp = 1;
    this.rainbow = false;
    this.gradient = makeGradient();
    this.geoCache = new Map();
    this.outlineMat = new THREE.MeshBasicMaterial({ color: 0x24140b, side: THREE.BackSide });
    this.extraGroups = [];
    this.skinFx = [];
    this.aura = null;
    this.build();
    this.setSkin('cocoa');
  }

  on(name, fn) { (this.listeners[name] = this.listeners[name] || []).push(fn); }
  emit(name, arg) { for (const fn of this.listeners[name] || []) fn(arg); }

  // ------------------------------------------------------------ building

  toon(color) {
    return new THREE.MeshToonMaterial({ color, gradientMap: this.gradient });
  }

  geo(kind, a, b = 0, extra = 0) {
    const key = `${kind}:${a}:${b}:${extra}`;
    let g = this.geoCache.get(key);
    if (!g) {
      if (kind === 'sph') g = new THREE.SphereGeometry(a + extra, 28, 20);
      else if (kind === 'cap') g = new THREE.CapsuleGeometry(a + extra, b, 8, 16);
      this.geoCache.set(key, g);
    }
    return g;
  }

  /** Add a shape (with its outline shell) to a parent group. */
  part(parent, kind, a, b, mat, pos, scale, rot, outline = true) {
    const m = new THREE.Mesh(this.geo(kind, a, b), mat);
    if (pos) m.position.set(...pos);
    if (scale) m.scale.set(...scale);
    if (rot) m.rotation.set(...rot);
    parent.add(m);
    if (outline && this.outlines) {
      const o = new THREE.Mesh(this.geo(kind, a, b, OUTLINE), this.outlineMat);
      o.position.copy(m.position);
      o.scale.copy(m.scale);
      o.rotation.copy(m.rotation);
      o.userData.outline = true;
      parent.add(o);
    }
    return m;
  }

  joint(name, parent, pos, rest = [0, 0, 0]) {
    const g = new THREE.Group();
    g.name = name;
    g.position.set(...pos);
    g.rotation.set(...rest);
    g.userData.rest = new THREE.Euler(...rest);
    parent.add(g);
    this.j[name] = g;
    return g;
  }

  regionMats(region) {
    const m = { fur: this.toon(0x8a5230), skin: this.toon(0xf3c9a0) };
    this.mats[region] = m;
    return m;
  }

  build() {
    const R = this.root;
    const body = this.regionMats('FL');
    const headM = this.regionMats('HD');
    const dark = this.toon(0x4a2a17);
    this.darkMat = dark;
    const white = new THREE.MeshBasicMaterial({ color: 0xffffff });
    const ink = new THREE.MeshBasicMaterial({ color: 0x1b0f08 });
    this.eyeWhiteMat = new THREE.MeshBasicMaterial({ color: 0xffffff }); // skins recolour these
    this.pupilMat = new THREE.MeshBasicMaterial({ color: 0x1b0f08 });
    const mouthMat = new THREE.MeshBasicMaterial({ color: 0x5a1a1a });
    const tongueMat = this.toon(0xff6f8a);
    const blush = new THREE.MeshBasicMaterial({ color: 0xff7a8a, transparent: true, opacity: 0.45, depthWrite: false });
    this.blushMat = blush;

    // hips + torso
    const hips = this.joint('hips', R, [0, 1.02, 0]);
    this.hipsRestY = 1.02;
    this.part(hips, 'sph', 0.44, 0, body.fur, [0, 0.02, 0], [1, 0.78, 0.86]);
    const torso = this.joint('torso', hips, [0, 0.12, 0]);
    this.part(torso, 'sph', 0.5, 0, body.fur, [0, 0.42, 0], [1, 1.12, 0.84]);
    this.part(torso, 'sph', 0.5, 0, body.skin, [0, 0.36, 0.035], [0.74, 0.86, 0.84], null, false);
    this.chest = torso;

    // head
    const head = this.joint('head', torso, [0, 0.92, 0.02]);
    this.part(head, 'sph', 0.56, 0, headM.fur, [0, 0.46, -0.04], [1, 0.97, 0.95]);
    // tuft
    this.part(head, 'sph', 0.11, 0, headM.fur, [0.0, 1.0, 0.0], [0.8, 1.4, 0.8], [0, 0, 0.3]);
    this.part(head, 'sph', 0.09, 0, headM.fur, [-0.1, 0.97, 0.02], [0.8, 1.3, 0.8], [0, 0, 0.7]);
    this.part(head, 'sph', 0.09, 0, headM.fur, [0.11, 0.96, 0.03], [0.8, 1.2, 0.8], [0, 0, -0.5]);
    // face plate: two eye lobes + muzzle
    this.part(head, 'sph', 0.25, 0, headM.skin, [-0.16, 0.56, 0.27], [1, 1.08, 0.85], null, false);
    this.part(head, 'sph', 0.25, 0, headM.skin, [0.16, 0.56, 0.27], [1, 1.08, 0.85], null, false);
    this.part(head, 'sph', 0.3, 0, headM.skin, [0, 0.3, 0.33], [1.25, 0.86, 0.85]);
    // nostrils
    this.part(head, 'sph', 0.028, 0, ink, [-0.06, 0.37, 0.6], [1, 0.7, 0.6], null, false);
    this.part(head, 'sph', 0.028, 0, ink, [0.06, 0.37, 0.6], [1, 0.7, 0.6], null, false);
    // cheeks
    this.part(head, 'sph', 0.08, 0, blush, [-0.31, 0.36, 0.42], [1, 0.7, 0.4], null, false);
    this.part(head, 'sph', 0.08, 0, blush, [0.31, 0.36, 0.42], [1, 0.7, 0.4], null, false);
    // ears
    for (const side of ['L', 'R']) {
      const s = SIDE[side];
      const ear = this.joint(side === 'L' ? 'earL' : 'earR', head, [s * 0.55, 0.5, -0.04], [0, s * 0.35, 0]);
      this.part(ear, 'sph', 0.21, 0, headM.fur, [s * 0.04, 0, 0], [0.45, 1, 1]);
      this.part(ear, 'sph', 0.14, 0, headM.skin, [s * 0.09, 0, 0.02], [0.3, 1, 1], null, false);
    }
    // eyes
    this.eyes = [];
    for (const side of ['L', 'R']) {
      const s = SIDE[side];
      const eye = new THREE.Group();
      eye.position.set(s * 0.165, 0.6, 0.44);
      head.add(eye);
      const w = this.part(eye, 'sph', 0.135, 0, this.eyeWhiteMat, [0, 0, 0], [1, 1.18, 0.62], null, false);
      const ring = new THREE.Mesh(this.geo('sph', 0.135, 0, 0.02), ink);
      ring.scale.set(w.scale.x, w.scale.y, w.scale.z * 0.55);
      ring.position.z = -0.02;
      eye.add(ring);
      const pupil = new THREE.Group();
      pupil.position.z = 0.058;
      eye.add(pupil);
      const pm = new THREE.Mesh(this.geo('sph', 0.07), this.pupilMat);
      pm.scale.set(1, 1.14, 0.5);
      pupil.add(pm);
      const hl = new THREE.Mesh(this.geo('sph', 0.026), white);
      hl.position.set(0.028, 0.04, 0.04);
      pupil.add(hl);
      const hl2 = new THREE.Mesh(this.geo('sph', 0.012), white);
      hl2.position.set(-0.022, -0.03, 0.04);
      pupil.add(hl2);
      // happy closed eye (^): an arc
      const arc = new THREE.Mesh(new THREE.TorusGeometry(0.085, 0.022, 8, 18, Math.PI), ink);
      arc.position.set(0, -0.02, 0.08);
      arc.visible = false;
      eye.add(arc);
      // brow
      const brow = new THREE.Mesh(this.geo('cap', 0.028, 0.13), dark);
      brow.rotation.z = Math.PI / 2;
      brow.position.set(s * 0.165, 0.8, 0.47);
      head.add(brow);
      this.eyes.push({ side, s, eye, white: w, ring, pupil, arc, brow, browBase: brow.position.y });
    }
    // mouths
    this.mouths = {};
    const smile = new THREE.Mesh(new THREE.TorusGeometry(0.12, 0.024, 8, 22, Math.PI), mouthMat);
    smile.rotation.z = Math.PI;
    smile.position.set(0, 0.27, 0.6);
    head.add(smile);
    this.mouths.smile = smile;
    const grin = new THREE.Group();
    grin.position.set(0, 0.22, 0.58);
    const gm = new THREE.Mesh(this.geo('sph', 0.13), mouthMat);
    gm.scale.set(1.2, 0.78, 0.45);
    grin.add(gm);
    const teeth = new THREE.Mesh(new THREE.BoxGeometry(0.17, 0.05, 0.05), white);
    teeth.position.set(0, 0.06, 0.04);
    grin.add(teeth);
    const tongue = new THREE.Mesh(this.geo('sph', 0.075), tongueMat);
    tongue.scale.set(1.2, 0.6, 0.6);
    tongue.position.set(0, -0.045, 0.035);
    grin.add(tongue);
    head.add(grin);
    this.mouths.grin = grin;
    const tongueOut = new THREE.Group();
    tongueOut.position.set(0, 0.27, 0.6);
    const s2 = new THREE.Mesh(new THREE.TorusGeometry(0.12, 0.024, 8, 22, Math.PI), mouthMat);
    s2.rotation.z = Math.PI;
    tongueOut.add(s2);
    const t2 = new THREE.Mesh(this.geo('sph', 0.07), tongueMat);
    t2.scale.set(0.9, 1.2, 0.5);
    t2.position.set(0.04, -0.13, 0.0);
    tongueOut.add(t2);
    head.add(tongueOut);
    this.mouths.tongue = tongueOut;
    const o = new THREE.Mesh(this.geo('sph', 0.075), mouthMat);
    o.scale.set(0.85, 1.15, 0.5);
    o.position.set(0, 0.22, 0.6);
    head.add(o);
    this.mouths.o = o;
    const frown = new THREE.Mesh(new THREE.TorusGeometry(0.1, 0.022, 8, 22, Math.PI), mouthMat);
    frown.position.set(0, 0.17, 0.6);
    head.add(frown);
    this.mouths.frown = frown;
    const flat = new THREE.Mesh(this.geo('cap', 0.022, 0.14), mouthMat);
    flat.rotation.z = Math.PI / 2 + 0.12;
    flat.position.set(0.01, 0.23, 0.62);
    head.add(flat);
    this.mouths.flat = flat;
    this.mouthName = 'smile';
    this.showMouth('smile');

    this.hatAnchor = new THREE.Group();
    this.hatAnchor.position.set(0, 0.98, -0.04);
    head.add(this.hatAnchor);
    this.eyesAnchor = new THREE.Group();
    this.eyesAnchor.position.set(0, 0.6, 0.5);
    head.add(this.eyesAnchor);
    this.neckAnchor = new THREE.Group();
    this.neckAnchor.position.set(0, 0.86, 0.06);
    torso.add(this.neckAnchor);
    this.backAnchor = new THREE.Group();
    this.backAnchor.position.set(0, 0.55, -0.42);
    torso.add(this.backAnchor);
    this.shoulderAnchor = new THREE.Group();
    this.shoulderAnchor.position.set(0.44, 0.88, -0.04);
    torso.add(this.shoulderAnchor);

    // arms
    for (const side of ['L', 'R']) {
      const s = SIDE[side];
      const m = this.regionMats(side === 'L' ? 'LA' : 'RA');
      const sh = this.joint('sh' + side, torso, [s * 0.47, 0.72, 0], [0, 0, s * 0.32]);
      this.part(sh, 'sph', 0.15, 0, m.fur, [0, -0.02, 0]);
      this.part(sh, 'cap', 0.115, 0.3, m.fur, [0, -0.24, 0]);
      const el = this.joint('el' + side, sh, [0, -0.46, 0], [-0.22, 0, 0]);
      this.part(el, 'cap', 0.105, 0.28, m.fur, [0, -0.2, 0]);
      const ha = this.joint('ha' + side, el, [0, -0.42, 0]);
      this.part(ha, 'sph', 0.15, 0, m.skin, [0, -0.05, 0.02], [1, 0.95, 0.72]);
      this.part(ha, 'sph', 0.06, 0, m.skin, [-s * 0.12, -0.0, 0.06], [1, 1.3, 1]);
    }
    // legs
    for (const side of ['L', 'R']) {
      const s = SIDE[side];
      const m = this.regionMats(side === 'L' ? 'LL' : 'RL');
      const hip = this.joint('hip' + side, hips, [s * 0.22, -0.08, 0], [0, 0, s * 0.05]);
      this.part(hip, 'cap', 0.135, 0.22, m.fur, [0, -0.2, 0]);
      const kn = this.joint('kn' + side, hip, [0, -0.4, 0]);
      this.part(kn, 'cap', 0.12, 0.2, m.fur, [0, -0.17, 0]);
      const ft = this.joint('ft' + side, kn, [0, -0.38, 0]);
      this.part(ft, 'sph', 0.17, 0, m.skin, [s * 0.02, -0.06, 0.1], [1, 0.52, 1.45]);
      // toes
      for (let k = -1; k <= 1; k++) this.part(ft, 'sph', 0.05, 0, m.skin, [s * 0.02 + k * 0.08, -0.06, 0.32], [1, 0.8, 1], null, false);
    }
    // tail: a chain of segments curling up behind
    this.tail = [];
    let parent = hips;
    const tailMat = body.fur;
    for (let i = 0; i < 9; i++) {
      const g = new THREE.Group();
      g.position.set(0, i === 0 ? -0.05 : 0.13, i === 0 ? -0.36 : 0);
      g.rotation.x = i === 0 ? -1.2 : 0.18;
      g.userData.baseX = g.rotation.x;
      parent.add(g);
      this.part(g, 'sph', 0.075 - i * 0.003, 0, tailMat, [0, 0.065, 0], [1, 1.25, 1]);
      this.tail.push(g);
      parent = g;
    }

    this.accessories = {};
    this.gearFx = {};
    this.gearAura = null;
    // pick points for tapping the monkey
    this.hitPoints = {
      LA: [this.j.haL, this.j.elL],
      RA: [this.j.haR, this.j.elR],
      LL: [this.j.ftL, this.j.knL],
      RL: [this.j.ftR, this.j.knR],
      HD: [head],
      FL: [hips, torso],
    };
    this.anchors = { LA: this.j.haL, RA: this.j.haR, LL: this.j.ftL, RL: this.j.ftR, HD: head, FL: hips };

    R.traverse((o) => { if (o.isMesh) o.frustumCulled = false; });
    // Remember which meshes wear fur or skin, so skins can swap their materials
    this.skinnables = [];
    R.traverse((o) => {
      if (!o.isMesh) return;
      for (const [region, r] of Object.entries(this.mats)) {
        if (o.material === r.fur) this.skinnables.push({ mesh: o, region, role: 'fur' });
        else if (o.material === r.skin) this.skinnables.push({ mesh: o, region, role: 'skin' });
      }
    });
  }

  // ------------------------------------------------------------ looks

  /** Wear a skin from js/skins.js (by id or definition). */
  setSkin(idOrSkin) {
    const skin = typeof idOrSkin === 'string' ? getSkin(idOrSkin) : idOrSkin;
    if (this.skin && this.skin.id === skin.id) return;
    applySkin(this, skin);
  }

  setFlair(id) {
    this.flair = FLAIRS[id] ? id : 'wiggle';
  }

  clearAccessory(slot) {
    for (const g of this.accessories[slot] || []) {
      if (g.parent) g.parent.remove(g);
      g.traverse((o) => {
        if (o.geometry) o.geometry.dispose();
        if (o.material && o.material !== this.outlineMat) o.material.dispose();
      });
    }
    this.accessories[slot] = null;
    this.gearFx[slot] = [];
  }

  anchorFor(name) {
    return {
      hat: this.hatAnchor, head: this.j.head, eyes: this.eyesAnchor, neck: this.neckAnchor,
      back: this.backAnchor, shoulder: this.shoulderAnchor,
      handL: this.j.haL, handR: this.j.haR, footL: this.j.ftL, footR: this.j.ftR,
    }[name];
  }

  /** Put gear (js/gear.js) in a slot; 'none' takes it off. */
  setAccessory(slot, id) {
    if (slot === 'aura') {
      const item = id && id !== 'none' ? getItem('aura', id) : null;
      this.gearAura = item ? { type: item.id, color: item.auraColor || '#ffffff' } : null;
      this.refreshAura();
      return;
    }
    this.clearAccessory(slot);
    const built = buildGear(slot, id, { gradient: this.gradient, outlineMat: this.outlineMat });
    if (built) {
      this.accessories[slot] = built.parts.map((p) => {
        const a = this.anchorFor(p.anchor);
        a.add(p.group);
        p.group.traverse((o) => { if (o.isMesh) o.frustumCulled = false; });
        return p.group;
      });
      this.gearFx[slot] = built.fx;
    }
    if (slot === 'back') {
      // a back item replaces the skin's own wings / cape / jetpack / fin
      const hide = !!built;
      if (hide !== !!this.hideBackExtras) {
        this.hideBackExtras = hide;
        refreshSkinExtras(this);
      }
    }
    this.setOutlines(this.outlinesOn);
  }

  /** Gear aura wins over the skin's aura. */
  refreshAura() {
    if (this.gearAura) setAura(this, this.gearAura.type, this.gearAura.color);
    else if (this.skin) setAura(this, this.skin.aura || null, this.skin.auraColor || '#ffffff');
  }

  /** Show or hide the cartoon outlines (hidden on Low graphics). */
  setOutlines(on) {
    this.outlinesOn = on;
    this.root.traverse((o) => {
      if (o.isMesh && o.material === this.outlineMat) o.visible = on;
    });
  }

  applyLook(equipped) {
    const before = this.skin;
    this.setSkin(equipped.skin || equipped.fur || 'cocoa');
    this.setFlair(equipped.flair);
    for (const slot of GEAR_SLOTS) {
      if (this.wearing && this.wearing[slot] === (equipped[slot] || 'none') && slot !== 'aura') continue;
      this.setAccessory(slot, equipped[slot] || 'none');
    }
    if (before !== this.skin) this.refreshAura();
    this.wearing = { ...equipped };
  }

  // ------------------------------------------------------------ playing moves

  /** Start an animation. dur in seconds; `at` is game time (defaults to now). */
  play(name, dur, at) {
    const fn = name === 'FL' ? FLAIRS[this.flair] : ACTIONS[name];
    if (!fn) return null;
    const a = { name, fn, start: at ?? this.time, dur: Math.max(0.15, dur), ctx: { monkey: this } };
    this.anims.push(a);
    return a;
  }

  /** Play one step (a move, or a combo of two). */
  playStep(step, dur, at) {
    for (const id of step) this.play(id, dur, at);
    if (step.length > 1) {
      const legs = step.includes('LL') && step.includes('RL');
      this.play(legs ? 'JUMP' : 'HOP', dur, at);
    }
    for (const id of step) this.flash(id, at);
  }

  flash(id, at) {
    this.highlight[id] = { at: at ?? this.time, color: new THREE.Color(MOVES[id].color) };
  }

  stop(name) {
    this.anims = this.anims.filter((a) => (name ? a.name !== name : false));
  }

  isBusy(names) {
    return this.anims.some((a) => names.includes(a.name));
  }

  setLook(x, y) {
    this.lookTarget.set(Math.max(-1, Math.min(1, x)), Math.max(-1, Math.min(1, y)));
  }

  showMouth(name) {
    if (this.mouthName === name && this.mouths[name].visible) return;
    for (const [k, m] of Object.entries(this.mouths)) m.visible = k === name;
    this.mouthName = name;
  }

  // ------------------------------------------------------------ per frame

  update(time, dt, beat) {
    this.time = time;
    const p = this.pose;
    resetPose(p);

    // idle groove on the beat
    const amp = this.danceAmp;
    const bf = beat - Math.floor(beat);
    const bob = (1 - Math.cos(bf * TAU)) / 2;
    p.hipsY += -0.045 * bob * amp;
    p.j.head[0] += 0.05 * bob * amp;
    p.j.knL[0] += 0.12 * bob * amp; p.j.knR[0] += 0.12 * bob * amp;
    p.j.hipL[0] += -0.06 * bob * amp; p.j.hipR[0] += -0.06 * bob * amp;
    const sway = Math.sin((beat / 2) * TAU);
    p.j.torso[2] += 0.04 * sway * amp;
    p.j.head[2] += -0.05 * sway * amp;
    p.j.shL[2] += -0.06 * (sway * 0.5 + 0.5) * amp;
    p.j.shR[2] += 0.06 * (0.5 - sway * 0.5) * amp;
    // breathing
    this.chest.scale.y = 1 + 0.012 * Math.sin(time * 2.1);

    // look at the player's taps
    this.look.lerp(this.lookTarget, Math.min(1, dt * 6));
    this.lookTarget.multiplyScalar(Math.max(0, 1 - dt * 0.6));
    p.j.head[1] += 0.28 * this.look.x;
    p.j.head[0] += -0.1 * this.look.y;

    // active animations
    for (let i = this.anims.length - 1; i >= 0; i--) {
      const a = this.anims[i];
      const el = time - a.start;
      if (el < 0) continue;
      const t = el / a.dur;
      if (t >= 1) {
        this.anims.splice(i, 1);
        this.emit('end', a.name);
        continue;
      }
      a.fn(p, t, el, a.ctx);
    }

    this.applyPose(p, time, dt);
    this.updateFace(p, time, dt);
    this.updateHighlights(time);
    if (this.rainbow) {
      const c = new THREE.Color().setHSL((time * 0.05) % 1, 0.65, 0.55);
      for (const [region, r] of Object.entries(this.mats)) {
        r.fur.userData.baseColor.copy(c);
        if (!this.highlight[region]) r.fur.color.copy(c);
      }
    }
    updateSkinFx(this, time, dt, Math.min(1, this.anims.length * 0.5));
    const energy = Math.min(1, this.anims.length * 0.5);
    for (const list of Object.values(this.gearFx)) if (list && list.length) updateGearFx(list, time, dt, energy, beat);
  }

  applyPose(p, time) {
    for (const n of JOINTS) {
      const g = this.j[n];
      const r = g.userData.rest;
      const v = p.j[n];
      g.rotation.set(r.x + v[0], r.y + v[1], r.z + v[2]);
    }
    this.j.hips.position.y = this.hipsRestY + p.hipsY;
    this.root.rotation.y = p.ry;
    const sq = p.squash;
    this.root.scale.set(1 + sq * 0.5, 1 - sq, 1 + sq * 0.5);
    // tail sway
    const amp = 0.12 + 0.12 * Math.max(-0.8, p.tail);
    for (let i = 0; i < this.tail.length; i++) {
      const g = this.tail[i];
      const droop = p.tail < 0 ? p.tail * 0.15 : 0;
      g.rotation.x = g.userData.baseX + (i > 0 ? Math.sin(time * 1.6 + i * 0.5) * 0.05 + droop : 0);
      g.rotation.z = Math.sin(time * 2.2 + i * 0.55) * amp * (i === 0 ? 0.6 : 1);
    }
  }

  updateFace(p, time, dt) {
    const f = p.face;
    this.showMouth(f.mouth || 'smile');
    // blinking
    let eyesMode = f.eyes || 'open';
    if (time > this.blinkAt) {
      this.blinkT = 0.13;
      this.blinkAt = time + 2 + Math.random() * 3.5;
    }
    let blink = 0;
    if (this.blinkT > 0) {
      this.blinkT -= dt;
      blink = Math.sin((1 - this.blinkT / 0.13) * Math.PI);
    }
    for (const e of this.eyes) {
      let mode = eyesMode;
      if (mode === 'wink') mode = e.side === 'R' ? 'happy' : 'open';
      const happy = mode === 'happy' || mode === 'closed';
      e.arc.visible = happy;
      e.white.visible = !happy;
      e.ring.visible = !happy;
      e.pupil.visible = !happy;
      e.arc.rotation.z = mode === 'closed' ? Math.PI : 0;
      e.arc.position.y = mode === 'closed' ? 0.02 : -0.02;
      const wide = mode === 'wide' ? 1.15 : 1;
      e.eye.scale.set(wide, happy ? 1 : wide * Math.max(0.08, 1 - blink), 1);
      e.pupil.position.x = this.look.x * 0.045;
      e.pupil.position.y = this.look.y * 0.045;
      const pupilScale = mode === 'wide' ? 0.8 : 1;
      e.pupil.scale.setScalar(pupilScale);
      // brows: raise, and tilt for worried (inner ends up)
      e.brow.position.y = e.browBase + f.brow * 0.05;
      // tilt > 0 lifts the inner ends (worried / sheepish)
      e.brow.rotation.z = Math.PI / 2 - e.s * (f.tilt * 0.38) + e.s * 0.05;
    }
    this.blushMat.opacity = f.eyes === 'happy' ? 0.65 : 0.4;
  }

  updateHighlights(time) {
    for (const [id, h] of Object.entries(this.highlight)) {
      const r = this.mats[id];
      const el = time - h.at;
      if (el < 0) continue;
      const k = Math.max(0, 1 - el / 0.55);
      if (r) {
        flashMaterial(r.fur, h.color, k);
        flashMaterial(r.skin, h.color, k * 0.7);
      }
      if (k <= 0) delete this.highlight[id];
    }
  }

  // ------------------------------------------------------------ picking

  anchorWorld(id, target = new THREE.Vector3()) {
    const g = this.anchors[id];
    return g ? g.getWorldPosition(target) : target.set(0, 1.5, 0);
  }

  /** Which body part is at screen point (x, y)? Returns a move id or null. */
  pick(x, y, camera, width, height) {
    const v = new THREE.Vector3();
    let best = null;
    let bestD = Infinity;
    const headPos = this.j.head.getWorldPosition(new THREE.Vector3()).add(new THREE.Vector3(0, 0.45, 0));
    const top = headPos.clone().project(camera);
    const bottom = new THREE.Vector3(0, 0, 0).project(camera);
    const scale = Math.abs(top.y - bottom.y) * height * 0.5; // monkey height in px
    for (const [id, groups] of Object.entries(this.hitPoints)) {
      for (const g of groups) {
        g.getWorldPosition(v);
        if (id === 'HD') v.y += 0.45;
        if (id === 'FL') v.y += 0.25;
        v.project(camera);
        const sx = (v.x * 0.5 + 0.5) * width;
        const sy = (-v.y * 0.5 + 0.5) * height;
        let d = Math.hypot(sx - x, sy - y);
        if (id === 'HD') d *= 0.6; // the head is big
        if (d < bestD) { bestD = d; best = id; }
      }
    }
    return bestD < scale * 0.2 ? best : null;
  }
}
