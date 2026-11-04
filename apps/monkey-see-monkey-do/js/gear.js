// Every piece of wearable gear, built from simple shapes. buildGear()
// returns parts, each for one spot on the monkey:
//   hat (top of head), head, eyes, neck, back, shoulder,
//   handL / handR, footL / footR
// plus little animations (fx). The same builders draw the Wardrobe
// thumbnails (see gearThumb), so cards always match the monkey.
import * as THREE from './vendor/three.module.min.js';
import { matcap, wingShape } from './skinlook.js';

const TAU = Math.PI * 2;
const OUT = 1.07;

function star(r = 0.1, inner = 0.45, points = 5) {
  const s = new THREE.Shape();
  for (let k = 0; k < points * 2; k++) {
    const rr = k % 2 ? r * inner : r;
    const a = Math.PI / 2 + (k * Math.PI) / points;
    if (k === 0) s.moveTo(Math.cos(a) * rr, Math.sin(a) * rr);
    else s.lineTo(Math.cos(a) * rr, Math.sin(a) * rr);
  }
  return s;
}

function heart(r = 0.1) {
  const s = new THREE.Shape();
  s.moveTo(0, -r * 0.9);
  s.bezierCurveTo(-r * 1.6, r * 0.2, -r * 0.7, r * 1.3, 0, r * 0.4);
  s.bezierCurveTo(r * 0.7, r * 1.3, r * 1.6, r * 0.2, 0, -r * 0.9);
  return s;
}

/**
 * Build gear `slot`/`id`. kit = { gradient, outlineMat }.
 * Returns { parts: [{ anchor, group }], fx: [...] } or null for "none".
 */
export function buildGear(slot, id, kit) {
  if (!id || id === 'none') return null;
  const parts = [];
  const fx = [];
  const toon = (c, o = {}) => new THREE.MeshToonMaterial({ color: c, gradientMap: kit.gradient, ...o });
  const metal = (c) => new THREE.MeshMatcapMaterial({ matcap: matcap(c) });
  const basic = (c, o = {}) => new THREE.MeshBasicMaterial({ color: c, ...o });
  const part = (anchor) => {
    const group = new THREE.Group();
    parts.push({ anchor, group });
    const add = (geo, mat, pos, rot, scale, outline = true, parent = group) => {
      const m = new THREE.Mesh(geo, mat);
      if (pos) m.position.set(...pos);
      if (rot) m.rotation.set(...rot);
      if (scale) m.scale.set(...scale);
      parent.add(m);
      if (outline) {
        const o = new THREE.Mesh(geo, kit.outlineMat);
        o.position.copy(m.position);
        o.rotation.copy(m.rotation);
        o.scale.copy(m.scale).multiplyScalar(OUT);
        parent.add(o);
      }
      return m;
    };
    return { group, add };
  };
  const both = (anchorL, anchorR, fn) => { fn(part(anchorL), -1); fn(part(anchorR), 1); };
  const sph = (r, ws = 18, hs = 12) => new THREE.SphereGeometry(r, ws, hs);
  const dome = (r) => new THREE.SphereGeometry(r, 24, 12, 0, TAU, 0, Math.PI / 2);
  const cyl = (rt, rb, h, seg = 18, open = false) => new THREE.CylinderGeometry(rt, rb, h, seg, 1, open);

  // ------------------------------------------------------------ hats
  if (slot === 'hat') {
    const { group: g, add } = part('hat');
    switch (id) {
      case 'party':
        add(new THREE.ConeGeometry(0.24, 0.6, 24), toon(0xff4f9a), [0.05, 0.26, 0], [0, 0, -0.18]);
        add(sph(0.08), toon(0xffd23f), [0.15, 0.56, 0]);
        add(new THREE.TorusGeometry(0.2, 0.03, 8, 24), toon(0xffd23f), [0.02, 0.1, 0], [Math.PI / 2, 0.18, 0]);
        break;
      case 'flower': {
        const cols = [0xff6fae, 0xffd23f, 0xffffff, 0xff8a1f, 0xb07cff, 0x55d0ff];
        for (let k = 0; k < 9; k++) {
          const a = (k / 9) * TAU;
          const x = Math.sin(a) * 0.46, z = Math.cos(a) * 0.43;
          add(sph(0.075, 12, 8), toon(cols[k % cols.length]), [x, -0.12, z]);
          add(sph(0.03, 8, 6), toon(0xffe066), [x * 1.08, -0.12, z * 1.08], null, null, false);
        }
        add(new THREE.TorusGeometry(0.45, 0.025, 6, 30), toon(0x3f9a3a), [0, -0.12, 0], [Math.PI / 2, 0, 0]);
        break;
      }
      case 'propeller': {
        add(dome(0.42), toon(0x2e8bff, { side: THREE.DoubleSide }), [0, -0.12, 0], null, [1, 0.62, 1]);
        add(cyl(0.3, 0.3, 0.02, 20), toon(0xffd23f), [0, -0.1, 0.28], null, [1, 1, 0.8]);
        add(cyl(0.02, 0.02, 0.16, 8), toon(0x333333), [0, 0.2, 0]);
        const prop = new THREE.Group();
        prop.position.set(0, 0.28, 0);
        prop.add(new THREE.Mesh(new THREE.BoxGeometry(0.62, 0.015, 0.08), toon(0xff4f4f)));
        prop.add(new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.015, 0.62), toon(0xffd23f)));
        g.add(prop);
        fx.push({ type: 'spin', obj: prop });
        break;
      }
      case 'headphones':
        add(new THREE.TorusGeometry(0.6, 0.045, 8, 28, Math.PI), toon(0x2b2b38), [0, -0.45, -0.02]);
        for (const s of [-1, 1]) {
          add(cyl(0.17, 0.17, 0.14, 20), toon(0xff4f9a), [s * 0.62, -0.47, -0.02], [0, 0, Math.PI / 2]);
          add(cyl(0.12, 0.12, 0.15, 20), toon(0x2b2b38), [s * 0.66, -0.47, -0.02], [0, 0, Math.PI / 2], null, false);
        }
        break;
      case 'tophat':
        add(cyl(0.28, 0.3, 0.5, 24), toon(0x1f1f2a), [0, 0.18, 0], [-0.08, 0, 0.06]);
        add(cyl(0.46, 0.46, 0.04, 28), toon(0x1f1f2a), [0, -0.06, 0], [-0.08, 0, 0.06]);
        add(cyl(0.295, 0.305, 0.09, 24), toon(0xd33a3a), [0, 0, 0], [-0.08, 0, 0.06], null, false);
        break;
      case 'crown': {
        const gold = toon(0xffc928);
        add(cyl(0.3, 0.27, 0.18, 24, true), toon(0xffc928, { side: THREE.DoubleSide }));
        for (let k = 0; k < 6; k++) {
          const a = (k / 6) * TAU;
          add(new THREE.ConeGeometry(0.07, 0.18, 10), gold, [Math.sin(a) * 0.28, 0.17, Math.cos(a) * 0.28]);
          add(sph(0.035, 10, 8), toon(k % 2 ? 0x2e8bff : 0xff3b5c), [Math.sin(a) * 0.295, 0, Math.cos(a) * 0.295], null, null, false);
        }
        g.rotation.z = 0.12;
        break;
      }
      case 'beanie':
        add(dome(0.5), toon(0x2e8bff), [0, -0.24, 0], null, [1, 0.72, 1]);
        add(new THREE.TorusGeometry(0.5, 0.075, 10, 32), toon(0xffd23f), [0, -0.24, 0], [Math.PI / 2, 0, 0]);
        add(sph(0.11), toon(0xffffff), [0, 0.16, 0]);
        break;
      case 'cap':
        add(dome(0.48), toon(0xd8302a), [0, -0.18, 0], null, [1, 0.58, 1]);
        add(new THREE.CylinderGeometry(0.34, 0.34, 0.03, 24, 1, false, Math.PI * 0.55, Math.PI * 0.9), toon(0xffffff), [0, -0.17, -0.2], [-0.12, 0, 0], [1, 1, 1.3]);
        add(sph(0.05), toon(0xffffff), [0, 0.1, 0]);
        break;
      case 'beret':
        add(sph(0.42, 24, 14), toon(0xd33a5a), [0.08, -0.04, 0], [0, 0, -0.25], [1.12, 0.3, 1.05]);
        add(cyl(0.02, 0.03, 0.08, 8), toon(0xd33a5a), [0.1, 0.1, 0], [0, 0, -0.25]);
        break;
      case 'chef':
        add(cyl(0.4, 0.42, 0.2, 24), toon(0xffffff), [0, -0.06, 0]);
        for (const [x, z] of [[-0.18, 0.05], [0.18, 0.05], [0, -0.16], [0, 0.18]]) add(sph(0.24), toon(0xffffff), [x, 0.2, z]);
        add(sph(0.28), toon(0xffffff), [0, 0.32, 0]);
        break;
      case 'cowboy':
        add(cyl(0.26, 0.33, 0.36, 24), toon(0xa8682a), [0, 0.1, 0]);
        add(cyl(0.34, 0.34, 0.07, 24), toon(0x3a2010), [0, -0.02, 0], null, null, false);
        add(new THREE.TorusGeometry(0.52, 0.09, 8, 32), toon(0xa8682a), [0, -0.1, 0], [Math.PI / 2, 0, 0], [1, 1, 0.45]);
        add(cyl(0.5, 0.5, 0.03, 32), toon(0xa8682a), [0, -0.1, 0]);
        break;
      case 'safari':
        add(cyl(0.3, 0.34, 0.26, 24), toon(0xd8c08a), [0, 0.04, 0]);
        add(cyl(0.58, 0.58, 0.03, 32), toon(0xd8c08a), [0, -0.1, 0], [-0.05, 0, 0]);
        add(cyl(0.345, 0.345, 0.06, 24), toon(0x6a4a2a), [0, -0.04, 0], null, null, false);
        break;
      case 'bunny':
        for (const s of [-1, 1]) {
          add(sph(0.12), toon(0xf4f4f4), [s * 0.16, 0.3, 0], [0, 0, -s * 0.18], [0.6, 2.4, 0.42]);
          add(sph(0.12), toon(0xffb0c8), [s * 0.165, 0.3, 0.03], [0, 0, -s * 0.18], [0.35, 1.9, 0.3], false);
        }
        add(new THREE.TorusGeometry(0.5, 0.03, 8, 30, Math.PI), toon(0xf4f4f4), [0, -0.42, 0]);
        break;
      case 'catears':
        add(new THREE.TorusGeometry(0.5, 0.035, 8, 30, Math.PI), toon(0xff8ab0), [0, -0.4, 0]);
        for (const s of [-1, 1]) {
          add(new THREE.ConeGeometry(0.17, 0.36, 4), toon(0x9aa0aa), [s * 0.3, 0.06, 0], [0, Math.PI / 4, -s * 0.38]);
          add(new THREE.ConeGeometry(0.09, 0.22, 4), toon(0xff8ab0), [s * 0.3, 0.04, 0.07], [0, Math.PI / 4, -s * 0.38], null, false);
        }
        break;
      case 'santa':
        add(new THREE.ConeGeometry(0.36, 0.72, 24), toon(0xd8202a), [0.08, 0.24, 0], [0, 0, -0.55]);
        add(sph(0.1), toon(0xffffff), [0.42, 0.42, 0]);
        add(new THREE.TorusGeometry(0.38, 0.09, 10, 28), toon(0xffffff), [0, -0.08, 0], [Math.PI / 2, 0, 0]);
        break;
      case 'grad':
        add(dome(0.42), toon(0x1a1a22), [0, -0.14, 0], null, [1, 0.5, 1]);
        add(new THREE.BoxGeometry(0.85, 0.04, 0.85), toon(0x1a1a22), [0, 0.1, 0], [0, Math.PI / 4, 0]);
        add(sph(0.035), toon(0xffc928), [0, 0.13, 0], null, null, false);
        add(cyl(0.012, 0.012, 0.42, 6), toon(0xffc928), [0.2, 0.13, 0.2], [Math.PI / 2, 0, -Math.PI / 4], null, false);
        add(cyl(0.035, 0.02, 0.18, 8), toon(0xffc928), [0.38, 0.02, 0.0], null, null, false);
        break;
      case 'pirate':
        add(dome(0.42), toon(0x1a1a22), [0, -0.12, 0], null, [1, 0.62, 1]);
        add(new THREE.TorusGeometry(0.5, 0.16, 6, 3), toon(0x1a1a22), [0, -0.04, 0.02], [Math.PI / 2, 0, Math.PI / 2], [1, 1, 1.1]);
        add(new THREE.TorusGeometry(0.62, 0.03, 4, 3), toon(0xffc928), [0, 0.06, 0.02], [Math.PI / 2, 0, Math.PI / 2], null, false);
        add(sph(0.08), toon(0xffffff), [0, 0.06, 0.5], null, [1, 1, 0.4], false);
        add(sph(0.025, 8, 6), basic(0x1a1a1a), [-0.03, 0.08, 0.53], null, null, false);
        add(sph(0.025, 8, 6), basic(0x1a1a1a), [0.03, 0.08, 0.53], null, null, false);
        add(new THREE.CapsuleGeometry(0.04, 0.35, 4, 8), toon(0xffffff), [0.3, 0.25, -0.1], [0.3, 0, -0.8]);
        break;
      case 'wizard': {
        add(new THREE.ConeGeometry(0.38, 0.85, 24), toon(0x3a2a8a), [0, 0.36, 0], [0, 0, 0.12]);
        add(new THREE.ConeGeometry(0.12, 0.3, 12), toon(0x3a2a8a), [-0.18, 0.85, 0], [0, 0, 0.9]);
        add(cyl(0.62, 0.62, 0.03, 32), toon(0x3a2a8a), [0, -0.06, 0]);
        const st = new THREE.ShapeGeometry(star(0.06));
        for (const [x, y, z, r] of [[0.1, 0.2, 0.3, 0.3], [-0.12, 0.45, 0.2, -0.2], [0.05, 0.62, 0.12, 0.1]]) add(st, basic(0xffd23f, { side: THREE.DoubleSide }), [x, y, z], [0.2, 0, r], null, false);
        break;
      }
      case 'viking':
        add(dome(0.5), metal('#c8ccd4'), [0, -0.2, 0], null, [1, 0.72, 1]);
        add(new THREE.TorusGeometry(0.5, 0.05, 8, 32), metal('#c07a3a'), [0, -0.2, 0], [Math.PI / 2, 0, 0]);
        for (const s of [-1, 1]) add(new THREE.ConeGeometry(0.09, 0.42, 14), toon(0xf4e8cc), [s * 0.5, 0.02, 0], [0, 0, -s * 1.05]);
        break;
      case 'pilot':
        add(dome(0.52), toon(0x7a4a2a), [0, -0.22, 0], null, [1, 0.75, 1]);
        for (const s of [-1, 1]) {
          add(sph(0.15), toon(0x7a4a2a), [s * 0.5, -0.4, 0], null, [0.4, 1, 0.9]);
          add(new THREE.TorusGeometry(0.09, 0.028, 8, 18), toon(0x5a5a62), [s * 0.13, -0.1, 0.4], [-0.5, 0, 0]);
          add(sph(0.08), basic(0x7fdcff, { transparent: true, opacity: 0.75 }), [s * 0.13, -0.1, 0.41], [-0.5, 0, 0], [1, 1, 0.3], false);
        }
        break;
      case 'tiara': {
        const gold = metal('#ffd060');
        add(new THREE.TorusGeometry(0.4, 0.035, 8, 24, Math.PI), gold, [0, -0.24, 0.16], [-0.35, 0, 0]);
        for (let k = 0; k < 5; k++) {
          const a = (k / 4) * Math.PI;
          add(new THREE.ConeGeometry(0.05, 0.16 + (k === 2 ? 0.12 : 0), 8), gold, [Math.cos(a) * 0.4, -0.24 + Math.sin(a) * 0.37 + 0.09, 0.16 - Math.sin(a) * 0.13], [-0.35, 0, 0], null, false);
        }
        add(sph(0.075), toon(0xff4fd8, { emissive: new THREE.Color(0xa01a80), emissiveIntensity: 0.3 }), [0, 0.18, 0.04], null, null, false);
        break;
      }
      case 'spacehelmet': {
        parts.pop();
        const { add: h } = part('head');
        h(sph(0.8, 32, 20), basic(0xbfe8ff, { transparent: true, opacity: 0.16, depthWrite: false }), [0, 0.46, -0.04], null, null, false);
        h(new THREE.TorusGeometry(0.62, 0.08, 10, 36), metal('#e8ecf4'), [0, -0.04, -0.04], [Math.PI / 2, 0, 0]);
        h(new THREE.TorusGeometry(0.5, 0.03, 6, 24, 1.2), basic(0xffffff, { transparent: true, opacity: 0.55 }), [0, 0.62, 0.42], [0, 0, 1.0], null, false);
        break;
      }
      default:
        break;
    }
  }

  // ------------------------------------------------------------ glasses
  if (slot === 'eyes') {
    const { add } = part('eyes');
    const lens = (c, o = 0.85) => basic(c, { transparent: true, opacity: o });
    switch (id) {
      case 'round': {
        const frame = toon(0x3a2a1a);
        for (const s of [-1, 1]) add(new THREE.TorusGeometry(0.15, 0.02, 8, 26), frame, [s * 0.165, 0, 0]);
        add(cyl(0.015, 0.015, 0.06, 6), frame, [0, 0.02, 0], [0, 0, Math.PI / 2]);
        break;
      }
      case 'shades': {
        const m = toon(0x111122);
        for (const s of [-1, 1]) add(sph(0.16, 20, 12), m, [s * 0.175, 0, 0], null, [1.15, 0.8, 0.25]);
        add(new THREE.BoxGeometry(0.12, 0.03, 0.03), m, [0, 0.03, 0.02]);
        add(sph(0.035, 8, 6), basic(0xffffff), [-0.12, 0.05, 0.05], null, null, false);
        break;
      }
      case 'stars': {
        const geo = new THREE.ExtrudeGeometry(star(0.19, 0.42), { depth: 0.03, bevelEnabled: false });
        for (const s of [-1, 1]) add(geo, toon(s < 0 ? 0xff4f9a : 0xffc926), [s * 0.18, 0, -0.01]);
        add(new THREE.BoxGeometry(0.08, 0.025, 0.025), toon(0xffffff), [0, 0.03, 0.01]);
        break;
      }
      case 'nerd':
        for (const s of [-1, 1]) add(new THREE.TorusGeometry(0.16, 0.035, 6, 4), toon(0x15151a), [s * 0.175, 0, 0], [0, 0, Math.PI / 4]);
        add(new THREE.BoxGeometry(0.1, 0.03, 0.03), toon(0x15151a), [0, 0.03, 0]);
        add(new THREE.BoxGeometry(0.06, 0.04, 0.03), toon(0xffffff), [0, 0.0, 0.03], null, null, false);
        break;
      case 'hippie':
        for (const s of [-1, 1]) {
          add(new THREE.TorusGeometry(0.1, 0.012, 8, 24), metal('#ffd060'), [s * 0.16, 0, 0]);
          add(sph(0.1), lens(0x7a3aa8, 0.85), [s * 0.16, 0, -0.005], null, [1, 1, 0.22], false);
        }
        add(cyl(0.01, 0.01, 0.12, 6), metal('#ffd060'), [0, 0.01, 0], [0, 0, Math.PI / 2], null, false);
        break;
      case 'cateye':
        for (const s of [-1, 1]) {
          add(new THREE.TorusGeometry(0.15, 0.03, 8, 26), toon(0xff4f9a), [s * 0.17, 0, 0], null, [1.1, 0.85, 1]);
          add(new THREE.ConeGeometry(0.05, 0.14, 4), toon(0xff4f9a), [s * 0.33, 0.1, 0], [0, 0, -s * 0.9]);
        }
        add(new THREE.BoxGeometry(0.08, 0.03, 0.03), toon(0xff4f9a), [0, 0.03, 0]);
        break;
      case 'threed':
        add(new THREE.BoxGeometry(0.66, 0.24, 0.03), toon(0xf4f4f4), [0, 0, -0.01]);
        add(new THREE.PlaneGeometry(0.24, 0.16), lens(0xff2a3a, 0.9), [-0.17, 0, 0.012], null, null, false);
        add(new THREE.PlaneGeometry(0.24, 0.16), lens(0x2ab0ff, 0.9), [0.17, 0, 0.012], null, null, false);
        break;
      case 'hearts': {
        const geo = new THREE.ExtrudeGeometry(heart(0.13), { depth: 0.03, bevelEnabled: false });
        for (const s of [-1, 1]) add(geo, toon(0xff3b6a), [s * 0.18, 0.02, -0.01]);
        add(new THREE.BoxGeometry(0.08, 0.025, 0.025), toon(0xff3b6a), [0, 0.04, 0.01]);
        break;
      }
      case 'aviators':
        for (const s of [-1, 1]) {
          add(sph(0.15, 20, 12), lens(0x24323e, 0.95), [s * 0.18, -0.02, 0], [0, 0, s * 0.25], [1.1, 1, 0.22], false);
          add(new THREE.TorusGeometry(0.155, 0.012, 6, 28), metal('#ffd060'), [s * 0.18, -0.02, 0.01], [0, 0, s * 0.25], [1.1, 1, 1]);
        }
        add(cyl(0.01, 0.01, 0.12, 6), metal('#ffd060'), [0, 0.06, 0.01], [0, 0, Math.PI / 2], null, false);
        add(cyl(0.01, 0.01, 0.1, 6), metal('#ffd060'), [0, 0.02, 0.01], [0, 0, Math.PI / 2], null, false);
        break;
      case 'monocle': {
        add(new THREE.TorusGeometry(0.15, 0.02, 8, 26), metal('#ffd060'), [0.165, 0, 0]);
        add(sph(0.14), lens(0xd8f0ff, 0.3), [0.165, 0, 0], null, [1, 1, 0.15], false);
        const curve = new THREE.CatmullRomCurve3([new THREE.Vector3(0.3, -0.05, 0), new THREE.Vector3(0.36, -0.3, -0.05), new THREE.Vector3(0.3, -0.55, -0.08)]);
        add(new THREE.TubeGeometry(curve, 16, 0.008, 5), metal('#ffd060'), null, null, null, false);
        break;
      }
      case 'goggles':
        add(new THREE.CapsuleGeometry(0.15, 0.3, 6, 16), toon(0x1a1a22), [0, 0, -0.02], [0, 0, Math.PI / 2], [1, 1, 0.35]);
        add(new THREE.CapsuleGeometry(0.12, 0.26, 6, 16), basic(0xff9a2e), [0, 0, 0.02], [0, 0, Math.PI / 2], [1, 1, 0.25], false);
        add(new THREE.TorusGeometry(0.6, 0.03, 6, 48), toon(0x2e8bff), [0, -0.02, -0.52], [Math.PI / 2, 0, 0], null, false);
        break;
      case 'visor': {
        const geo = new THREE.TorusGeometry(0.58, 0.07, 6, 28, 1.5);
        geo.rotateZ(Math.PI / 2 - 0.75);
        geo.rotateX(Math.PI / 2);
        add(geo, basic(0x2ae8ff, { transparent: true, opacity: 0.62 }), [0, 0, -0.5], null, [1, 1.4, 1], false);
        fx.push({ type: 'glow', obj: parts[parts.length - 1].group.children[0] });
        break;
      }
      default:
        break;
    }
  }

  // ------------------------------------------------------------ neck
  if (slot === 'neck') {
    const { group: g, add } = part('neck');
    switch (id) {
      case 'bowtie': {
        const red = toon(0xe0303f);
        add(new THREE.ConeGeometry(0.12, 0.2, 4), red, [-0.11, 0, 0.12], [0, 0, -Math.PI / 2], [1, 1, 0.5]);
        add(new THREE.ConeGeometry(0.12, 0.2, 4), red, [0.11, 0, 0.12], [0, 0, Math.PI / 2], [1, 1, 0.5]);
        add(sph(0.06), red, [0, 0, 0.15]);
        break;
      }
      case 'scarf': {
        const c = toon(0x2e8bff);
        add(new THREE.TorusGeometry(0.33, 0.085, 10, 26), c, [0, 0, -0.05], [Math.PI / 2 - 0.15, 0, 0]);
        const tail = new THREE.Group();
        tail.position.set(0.16, -0.02, 0.26);
        const tm = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.42, 0.05), c);
        tm.position.y = -0.2;
        tail.add(tm);
        const stripe = new THREE.Mesh(new THREE.BoxGeometry(0.145, 0.05, 0.055), toon(0xffd23f));
        stripe.position.y = -0.33;
        tail.add(stripe);
        g.add(tail);
        fx.push({ type: 'flap', obj: tail });
        break;
      }
      case 'lei': {
        const cols = [0xff4f9a, 0xffd23f, 0xff8a1f, 0xffffff, 0xb07cff];
        for (let k = 0; k < 16; k++) {
          const a = (k / 16) * TAU;
          add(sph(0.065, 10, 8), toon(cols[k % cols.length]), [Math.sin(a) * 0.36, -0.02 + Math.cos(a) * 0.06, Math.cos(a) * 0.3 - 0.04]);
        }
        break;
      }
      case 'chain': {
        const gold = toon(0xffc928);
        add(new THREE.TorusGeometry(0.34, 0.025, 8, 30), gold, [0, -0.04, -0.03], [Math.PI / 2 - 0.35, 0, 0]);
        add(new THREE.TorusGeometry(0.09, 0.035, 8, 16, Math.PI * 0.9), gold, [0, -0.2, 0.3], [0, 0, 2.6]);
        break;
      }
      case 'tie': {
        const blue = toon(0x2e5ad8);
        add(sph(0.06), blue, [0, -0.02, 0.32], null, [1.2, 1, 0.7]);
        const s = new THREE.Shape();
        s.moveTo(-0.05, 0); s.lineTo(0.05, 0); s.lineTo(0.09, -0.36); s.lineTo(0, -0.46); s.lineTo(-0.09, -0.36); s.closePath();
        add(new THREE.ExtrudeGeometry(s, { depth: 0.02, bevelEnabled: false }), blue, [0, -0.05, 0.33], [-0.25, 0, 0]);
        add(new THREE.BoxGeometry(0.15, 0.025, 0.03), toon(0xffd23f), [0, -0.2, 0.34], [-0.25, 0, 0.5], null, false);
        break;
      }
      case 'bandana': {
        const red = toon(0xc8302a, { side: THREE.DoubleSide });
        add(new THREE.TorusGeometry(0.33, 0.04, 8, 26), toon(0xc8302a), [0, 0, -0.03], [Math.PI / 2 - 0.15, 0, 0]);
        const s = new THREE.Shape();
        s.moveTo(-0.28, 0); s.lineTo(0.28, 0); s.lineTo(0, -0.32); s.closePath();
        add(new THREE.ShapeGeometry(s), red, [0, -0.02, 0.32], [-0.3, 0, 0]);
        for (const [x, y] of [[-0.12, -0.07], [0.1, -0.08], [0, -0.18]]) add(sph(0.022, 8, 6), toon(0xffffff), [x, y, 0.335], null, [1, 1, 0.3], false);
        break;
      }
      case 'whistle':
        add(new THREE.TorusGeometry(0.34, 0.012, 6, 30), toon(0x2e8bff), [0, -0.04, -0.03], [Math.PI / 2 - 0.4, 0, 0]);
        add(cyl(0.035, 0.035, 0.12, 12), metal('#d8dde6'), [0, -0.3, 0.34], [0, 0, Math.PI / 2]);
        add(sph(0.05), metal('#d8dde6'), [0.06, -0.31, 0.34]);
        break;
      case 'bell':
        add(new THREE.TorusGeometry(0.33, 0.05, 8, 28), toon(0xe0303f), [0, 0, -0.04], [Math.PI / 2 - 0.15, 0, 0]);
        add(sph(0.075), metal('#ffd060'), [0, -0.08, 0.34]);
        add(new THREE.BoxGeometry(0.08, 0.01, 0.02), basic(0x5a3a00), [0, -0.1, 0.41], null, null, false);
        break;
      case 'pearls':
        for (let k = 0; k < 20; k++) {
          const a = (k / 20) * TAU;
          add(sph(0.042, 10, 8), metal('#fff4f0'), [Math.sin(a) * 0.35, -0.04 + Math.cos(a) * 0.1, Math.cos(a) * 0.3 - 0.03], null, null, false);
        }
        break;
      case 'medal':
        for (const s of [-1, 1]) add(new THREE.BoxGeometry(0.07, 0.36, 0.02), toon(s < 0 ? 0xe0303f : 0x2e5ad8), [s * 0.1, -0.13, 0.32], [-0.25, 0, s * 0.45]);
        add(cyl(0.1, 0.1, 0.025, 24), metal('#ffd060'), [0, -0.33, 0.37], [Math.PI / 2 - 0.25, 0, 0]);
        add(new THREE.ShapeGeometry(star(0.055)), basic(0xfff2a8), [0, -0.33, 0.385], [-0.25, 0, 0], null, false);
        break;
      case 'boa': {
        const cols = [0xff6fbf, 0xff9ad2, 0xff4fa8];
        for (let k = 0; k < 26; k++) {
          const a = (k / 26) * TAU;
          add(sph(0.08 + (k % 3) * 0.01, 10, 8), toon(cols[k % 3]), [Math.sin(a) * 0.37, -0.03 + Math.cos(a) * 0.08 + Math.sin(k * 2.1) * 0.02, Math.cos(a) * 0.31 - 0.03], null, null, false);
        }
        break;
      }
      default:
        break;
    }
  }

  // ------------------------------------------------------------ back and shoulder
  if (slot === 'back') {
    if (id === 'parrot') {
      const { group: g, add } = part('shoulder');
      const body = new THREE.Group();
      g.add(body);
      add(sph(0.1), toon(0xe0303f), [0, 0.08, 0], null, [1, 1.3, 1], true, body);
      add(sph(0.075), toon(0xe0303f), [0, 0.24, 0.03], null, null, true, body);
      add(new THREE.ConeGeometry(0.03, 0.08, 8), toon(0xffd23f), [0, 0.22, 0.12], [Math.PI / 2 + 0.4, 0, 0], null, true, body);
      for (const s of [-1, 1]) {
        add(sph(0.016, 8, 6), basic(0x111111), [s * 0.045, 0.26, 0.08], null, null, false, body);
        add(sph(0.08), toon(0x2e8bff), [s * 0.08, 0.08, -0.02], [0, 0, s * 0.3], [0.35, 1.1, 0.9], true, body);
      }
      add(new THREE.BoxGeometry(0.06, 0.24, 0.02), toon(0xffd23f), [0, -0.08, -0.08], [-0.5, 0, 0], null, true, body);
      fx.push({ type: 'bob', obj: body, base: 0 });
    } else {
      const { group: g, add } = part('back');
      switch (id) {
        case 'backpack':
          add(new THREE.BoxGeometry(0.5, 0.56, 0.22), toon(0xff8a1f), [0, 0, -0.08]);
          add(new THREE.BoxGeometry(0.34, 0.2, 0.08), toon(0xffd23f), [0, -0.12, -0.21]);
          for (const s of [-1, 1]) {
            add(new THREE.TorusGeometry(0.3, 0.035, 6, 16, Math.PI), toon(0x7a4a1a), [s * 0.22, 0.2, 0.42], [0, Math.PI / 2, 0], null, false);
            add(new THREE.BoxGeometry(0.07, 0.5, 0.03), toon(0x7a4a1a), [s * 0.22, -0.04, 0.84], [-0.18, 0, 0], null, false);
          }
          break;
        case 'skateboard': {
          const b = new THREE.Group();
          b.position.set(-0.05, 0.25, -0.16);
          b.rotation.z = 0.6;
          b.scale.setScalar(1.25);
          g.add(b);
          add(new THREE.CapsuleGeometry(0.13, 0.72, 6, 16), toon(0x2e8bff), null, null, [1, 1, 0.18], true, b);
          add(new THREE.BoxGeometry(0.1, 0.72, 0.01), toon(0xffd23f), [0, 0, -0.03], null, null, false, b);
          for (const y of [-0.32, 0.32]) for (const x of [-0.1, 0.1]) add(cyl(0.045, 0.045, 0.05, 12), toon(0xf4f4f4), [x, y, -0.06], [0, 0, Math.PI / 2], null, true, b);
          break;
        }
        case 'guitar': {
          const gt = new THREE.Group();
          gt.position.set(-0.12, -0.05, -0.14);
          gt.rotation.z = -0.75;
          gt.scale.setScalar(1.3);
          add(new THREE.TorusGeometry(0.42, 0.025, 6, 20, Math.PI), toon(0x3a2010), [0.08, 0.3, 0.42], [0, Math.PI / 2, -0.7], null, false);
          g.add(gt);
          add(sph(0.22), toon(0xd8302a), [0, -0.12, 0], null, [1, 1, 0.3], true, gt);
          add(sph(0.17), toon(0xd8302a), [0, 0.12, 0], null, [1, 1, 0.3], true, gt);
          add(new THREE.CircleGeometry(0.06, 16), basic(0x1a1a1a), [0, 0.02, -0.07], [0, Math.PI, 0], null, false, gt);
          add(new THREE.BoxGeometry(0.06, 0.55, 0.04), toon(0x7a4a1a), [0, 0.5, 0], null, null, true, gt);
          add(new THREE.BoxGeometry(0.1, 0.13, 0.04), toon(0x3a2010), [0, 0.82, 0], null, null, true, gt);
          break;
        }
        case 'shell': {
          add(dome(0.58), toon(0x3f9a3a), [0, -0.1, 0.02], [-Math.PI / 2, 0, 0], [1, 1.12, 0.85]);
          for (const [x, y] of [[0, 0], [-0.2, 0.15], [0.2, 0.15], [-0.2, -0.2], [0.2, -0.2], [0, 0.3], [0, -0.32]]) {
            add(cyl(0.11, 0.11, 0.05, 6), toon(0x8ad05a), [x, y - 0.1, 0.0 - 0.5 * Math.sqrt(Math.max(0.05, 1 - (x * x + y * y) / 0.3))], [Math.PI / 2, 0, 0], null, true);
          }
          break;
        }
        case 'cape': {
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
          const c = new THREE.Group();
          c.position.set(0, 0.32, 0.06);
          g.add(c);
          c.add(new THREE.Mesh(geo, toon(0xe0303f, { side: THREE.DoubleSide })));
          fx.push({ type: 'cape', obj: c });
          break;
        }
        case 'jetpack': {
          for (const s of [-1, 1]) {
            const tank = new THREE.Group();
            tank.position.set(s * 0.42, -0.05, 0.08);
            g.add(tank);
            add(cyl(0.11, 0.11, 0.48, 16), metal('#ffb020'), null, null, null, true, tank);
            add(new THREE.ConeGeometry(0.08, 0.12, 12), metal('#9aa2ae'), [0, -0.3, 0], [Math.PI, 0, 0], null, false, tank);
            const flame = new THREE.Mesh(new THREE.ConeGeometry(0.07, 0.3, 12), basic(0x2ae8ff, { transparent: true, opacity: 0.9, blending: THREE.AdditiveBlending, depthWrite: false }));
            flame.position.y = -0.5;
            flame.rotation.x = Math.PI;
            tank.add(flame);
            fx.push({ type: 'flame', obj: flame, k: s });
          }
          break;
        }
        case 'angelwings':
        case 'batwings':
        case 'butterfly': {
          const kind = id === 'angelwings' ? 'angel' : id === 'batwings' ? 'dragon' : 'fairy';
          const color = id === 'angelwings' ? 0xffffff : id === 'batwings' ? 0x2a1a3a : 0x7fd8ff;
          const geo = new THREE.ShapeGeometry(wingShape(kind), 12);
          const opts = { side: THREE.DoubleSide };
          if (kind === 'fairy') Object.assign(opts, { transparent: true, opacity: 0.75, emissive: new THREE.Color(0xb07cff), emissiveIntensity: 0.3 });
          const mat = toon(color, opts);
          for (const s of [-1, 1]) {
            const w = new THREE.Group();
            w.position.set(s * 0.16, 0.18, 0.04);
            g.add(w);
            const mesh = new THREE.Mesh(geo, mat);
            mesh.scale.set(s * 0.95, 0.95, 1);
            w.add(mesh);
            if (kind !== 'fairy') {
              const o = new THREE.Mesh(geo, kit.outlineMat);
              o.scale.set(s * 0.99, 0.99, 1);
              o.position.z = -0.01;
              w.add(o);
            }
            fx.push({ type: 'wing', obj: w, s });
          }
          break;
        }
        default:
          break;
      }
    }
  }

  // ------------------------------------------------------------ hands
  if (slot === 'hands') {
    const one = (side, fn) => fn(part(side === 'R' ? 'handR' : 'handL'));
    switch (id) {
      case 'banana':
        one('R', ({ add }) => {
          add(new THREE.TorusGeometry(0.16, 0.05, 8, 14, Math.PI * 0.8), toon(0xffd23f), [0.02, -0.12, 0.1], [0, Math.PI / 2, 1.2]);
          add(sph(0.03, 8, 6), toon(0x6b4423), [0.02, -0.02, 0.22], null, null, false);
        });
        break;
      case 'maracas':
        both('handL', 'handR', ({ add }, s) => {
          add(cyl(0.025, 0.03, 0.22, 8), toon(0x7a4a1a), [0, -0.17, 0.05]);
          add(sph(0.1), toon(s < 0 ? 0xff4f4f : 0x2ec4b6), [0, -0.32, 0.05]);
          add(new THREE.TorusGeometry(0.1, 0.018, 6, 20), toon(0xffd23f), [0, -0.32, 0.05], [Math.PI / 2, 0, 0], null, false);
        });
        break;
      case 'tambourine':
        one('L', ({ add }) => {
          add(new THREE.TorusGeometry(0.15, 0.035, 8, 24), toon(0xc8302a), [0, -0.16, 0.1], [0, Math.PI / 2, 0]);
          add(new THREE.CircleGeometry(0.14, 24), toon(0xfff2dc, { side: THREE.DoubleSide }), [0, -0.16, 0.1], [0, Math.PI / 2, 0], null, false);
          for (let k = 0; k < 6; k++) {
            const a = (k / 6) * TAU;
            add(cyl(0.035, 0.035, 0.012, 12), metal('#ffd060'), [0, -0.16 + Math.sin(a) * 0.16, 0.1 + Math.cos(a) * 0.16], [0, 0, Math.PI / 2], null, false);
          }
        });
        break;
      case 'drumsticks':
        both('handL', 'handR', ({ add }) => {
          add(cyl(0.018, 0.022, 0.48, 8), toon(0xd8a060), [0, -0.2, 0.14], [0.6, 0, 0]);
          add(sph(0.03, 8, 6), toon(0xd8a060), [0, -0.4, 0.27], null, null, false);
        });
        break;
      case 'mic':
        one('R', ({ add }) => {
          add(cyl(0.035, 0.025, 0.24, 12), toon(0x1a1a22), [0, -0.06, 0.12], [-1.15, 0, 0]);
          add(sph(0.075), metal('#c8ccd4'), [0, 0.0, 0.24]);
        });
        break;
      case 'spyglass':
        one('R', ({ add }) => {
          add(cyl(0.05, 0.05, 0.18, 14), metal('#d8a040'), [0, -0.06, 0.14], [-1.2, 0, 0]);
          add(cyl(0.04, 0.04, 0.16, 14), metal('#d8a040'), [0, 0.0, 0.28], [-1.2, 0, 0]);
          add(cyl(0.03, 0.03, 0.12, 14), metal('#d8a040'), [0, 0.05, 0.4], [-1.2, 0, 0]);
        });
        break;
      case 'candy':
        one('L', ({ add }) => {
          add(sph(0.16, 16, 12), toon(0xff8a1f), [0, -0.33, 0.06], null, [1, 0.85, 1]);
          add(new THREE.TorusGeometry(0.13, 0.015, 6, 16, Math.PI), toon(0x1a1a1a), [0, -0.25, 0.06], null, null, false);
          for (const s of [-1, 1]) add(new THREE.ConeGeometry(0.03, 0.05, 3), basic(0x1a1a1a), [s * 0.05, -0.3, 0.2], [Math.PI / 2, 0, 0], null, false);
        });
        break;
      case 'trophy':
        one('R', ({ add }) => {
          add(cyl(0.11, 0.05, 0.16, 18), metal('#ffd060'), [0, -0.06, 0.14]);
          for (const s of [-1, 1]) add(new THREE.TorusGeometry(0.045, 0.012, 6, 12), metal('#ffd060'), [s * 0.12, -0.05, 0.14], null, null, false);
          add(cyl(0.02, 0.02, 0.08, 8), metal('#ffd060'), [0, -0.18, 0.14], null, null, false);
          add(new THREE.BoxGeometry(0.12, 0.04, 0.12), toon(0x3a2010), [0, -0.23, 0.14]);
        });
        break;
      case 'wand':
        one('R', ({ group, add }) => {
          add(cyl(0.015, 0.015, 0.42, 8), toon(0x1a1a1a), [0, -0.05, 0.2], [-1.0, 0, 0]);
          const tip = add(new THREE.ShapeGeometry(star(0.08)), basic(0xffd23f, { side: THREE.DoubleSide }), [0, 0.12, 0.36], null, null, false);
          fx.push({ type: 'twinkle', obj: tip });
          void group;
        });
        break;
      case 'scepter':
        one('R', ({ add }) => {
          add(cyl(0.025, 0.025, 0.55, 10), metal('#ffd060'), [0, -0.05, 0.18], [-0.9, 0, 0]);
          add(sph(0.075), toon(0x8a3ae0, { emissive: new THREE.Color(0x5a1aa0), emissiveIntensity: 0.4 }), [0, 0.17, 0.4]);
          add(new THREE.TorusGeometry(0.06, 0.015, 6, 16), metal('#ffd060'), [0, 0.12, 0.36], [-0.9, 0, 0], null, false);
        });
        break;
      case 'glowsticks':
        both('handL', 'handR', ({ add }, s) => {
          const m = add(cyl(0.024, 0.024, 0.34, 10), basic(s < 0 ? 0xff2ad8 : 0x2ae8ff), [0, -0.18, 0.08], [0.3, 0, 0], null, false);
          fx.push({ type: 'pulse', obj: m, base: new THREE.Color(s < 0 ? 0xff2ad8 : 0x2ae8ff) });
        });
        break;
      default:
        break;
    }
  }

  // ------------------------------------------------------------ feet
  if (slot === 'feet') {
    const looks = {
      sneakers: { shoe: 0xff4f4f, sole: 0xffffff },
      hightops: { shoe: 0x2e5ad8, sole: 0xffffff },
      rainboots: { shoe: 0xffd23f, sole: 0x3a3a3a },
      flippers: { shoe: 0x1fb57a, sole: 0x1fb57a },
      skates: { shoe: 0xffffff, sole: 0xff4f9a },
      rocketboots: { shoe: 'metal', sole: 0x3a4250 },
    };
    const L = looks[id];
    if (L) {
      both('footL', 'footR', ({ group, add }, s) => {
        const shoeMat = L.shoe === 'metal' ? metal('#c8ccd4') : toon(L.shoe);
        add(sph(0.19, 20, 14), shoeMat, [s * 0.02, -0.05, 0.1], null, [1.05, 0.58, 1.48]);
        add(cyl(0.19, 0.19, 0.05, 20), toon(L.sole), [s * 0.02, -0.13, 0.1], null, [1.05, 1, 1.5], false);
        if (id === 'sneakers' || id === 'hightops') {
          for (let k = 0; k < 3; k++) add(new THREE.CapsuleGeometry(0.012, 0.07, 4, 6), toon(0xffffff), [s * 0.02, 0.02, 0.12 + k * 0.06], [0, 0, Math.PI / 2], null, false);
        }
        if (id === 'hightops') {
          add(cyl(0.15, 0.17, 0.2, 18), toon(L.shoe), [0, 0.05, 0.0]);
          add(new THREE.CircleGeometry(0.05, 16), toon(0xffffff), [s * 0.16, 0.05, 0], [0, s * Math.PI / 2, 0], null, false);
        }
        if (id === 'rainboots') add(cyl(0.14, 0.15, 0.32, 18), toon(L.shoe), [0, 0.12, 0.0]);
        if (id === 'flippers') {
          const f = new THREE.Shape();
          f.moveTo(-0.14, 0); f.lineTo(0.14, 0); f.quadraticCurveTo(0.3, 0.45, 0.2, 0.6); f.lineTo(-0.2, 0.6); f.quadraticCurveTo(-0.3, 0.45, -0.14, 0);
          add(new THREE.ShapeGeometry(f), toon(0x1fb57a, { side: THREE.DoubleSide }), [s * 0.02, -0.15, 0.2], [Math.PI / 2, 0, 0]);
        }
        if (id === 'skates') {
          add(new THREE.BoxGeometry(0.24, 0.03, 0.46), metal('#9aa2ae'), [s * 0.02, -0.17, 0.1], null, null, false);
          for (const z of [-0.06, 0.26]) for (const x of [-0.09, 0.09]) add(cyl(0.05, 0.05, 0.04, 12), toon(0xff4f9a), [s * 0.02 + x, -0.22, z], [0, 0, Math.PI / 2]);
        }
        if (id === 'rocketboots') {
          const flame = new THREE.Mesh(new THREE.ConeGeometry(0.08, 0.3, 12), basic(0xffa020, { transparent: true, opacity: 0.9, blending: THREE.AdditiveBlending, depthWrite: false }));
          flame.position.set(s * 0.02, -0.32, 0.0);
          flame.rotation.x = Math.PI;
          group.add(flame);
          fx.push({ type: 'flame', obj: flame, k: s });
        }
      });
    }
  }

  // ------------------------------------------------------------ face (head space)
  if (slot === 'face') {
    const { add } = part('head');
    switch (id) {
      case 'mustache':
        for (const s of [-1, 1]) {
          add(new THREE.CapsuleGeometry(0.035, 0.14, 4, 8), toon(0x3a2010), [s * 0.09, 0.31, 0.63], [0, 0, s * 1.25]);
          add(new THREE.TorusGeometry(0.03, 0.015, 6, 10, Math.PI * 1.3), toon(0x3a2010), [s * 0.18, 0.33, 0.6], [0, 0, s > 0 ? -0.6 : 2.0], null, false);
        }
        break;
      case 'clownnose':
        add(sph(0.08), toon(0xe0202a), [0, 0.38, 0.63]);
        add(sph(0.02, 8, 6), basic(0xffffff), [-0.025, 0.41, 0.7], null, null, false);
        break;
      case 'whiskers':
        for (const s of [-1, 1]) for (let k = -1; k <= 1; k++) {
          add(cyl(0.006, 0.006, 0.3, 4), basic(0x2a1a10), [s * 0.3, 0.32 + k * 0.035, 0.52], [0, s * 0.5, Math.PI / 2 + k * 0.18], null, false);
        }
        break;
      case 'starpaint':
        add(new THREE.ShapeGeometry(star(0.07)), basic(0xffc928, { side: THREE.DoubleSide, polygonOffset: true, polygonOffsetFactor: -2 }), [0.33, 0.46, 0.475], [0, 0.6, 0.2], null, false);
        add(new THREE.ShapeGeometry(star(0.035)), basic(0xff4f9a, { side: THREE.DoubleSide }), [0.27, 0.36, 0.53], [0, 0.5, -0.3], null, false);
        break;
      case 'heartpaint':
        add(new THREE.ShapeGeometry(heart(0.06)), basic(0xff3b6a, { side: THREE.DoubleSide }), [-0.33, 0.46, 0.475], [0, -0.6, 0], null, false);
        break;
      case 'gum': {
        const b = add(sph(0.12, 18, 12), toon(0xff8ac8, { transparent: true, opacity: 0.92 }), [0, 0.2, 0.7], null, null, false);
        fx.push({ type: 'gum', obj: b });
        break;
      }
      default:
        break;
    }
  }

  if (slot === 'hands') for (const p of parts) p.group.scale.setScalar(1.45);
  return parts.length ? { parts, fx } : null;
}

/** Per-frame gear animations. */
export function updateGearFx(list, time, dt, energy, beat) {
  for (const f of list) {
    const o = f.obj;
    if (f.type === 'spin') o.rotation.y += dt * (4 + 14 * energy);
    else if (f.type === 'flap') o.rotation.x = 0.1 + 0.25 * Math.sin(time * 6) * (0.2 + energy);
    else if (f.type === 'cape') o.rotation.x = 0.12 + 0.08 * Math.sin(time * 2.2) + energy * 0.25;
    else if (f.type === 'wing') o.rotation.y = f.s * (-0.45 - 0.28 * Math.sin(time * (3 + energy * 6)));
    else if (f.type === 'flame') o.scale.set(1, 0.8 + 0.35 * Math.abs(Math.sin(time * 23 + f.k)) + energy * 0.6, 1);
    else if (f.type === 'bob') o.position.y = f.base + Math.abs(Math.sin(beat * Math.PI)) * 0.04;
    else if (f.type === 'twinkle') { o.rotation.z = time * 2; o.scale.setScalar(1 + 0.15 * Math.sin(time * 8)); }
    else if (f.type === 'glow') o.material.opacity = 0.5 + 0.2 * Math.sin(time * 4);
    else if (f.type === 'pulse') {
      const k = Math.pow(1 - (beat - Math.floor(beat)), 2);
      o.material.color.copy(f.base).multiplyScalar(0.7 + 0.6 * k);
    } else if (f.type === 'gum') {
      const c = (time % 3.2) / 3.2;
      const sc = c < 0.8 ? 0.25 + (c / 0.8) * 1.6 : 0.01;
      o.scale.setScalar(sc);
    }
  }
}

// ---------------------------------------------------------------- thumbnails

let thumb = null;
/** Paint a 3D thumbnail of a gear item into a canvas element. */
export function gearThumb(canvasEl, slot, id, kit) {
  try {
    if (!thumb) {
      const cv = document.createElement('canvas');
      cv.width = cv.height = 128;
      const renderer = new THREE.WebGLRenderer({ canvas: cv, alpha: true, antialias: true, preserveDrawingBuffer: true });
      renderer.setPixelRatio(1);
      renderer.setSize(128, 128, false);
      const scene = new THREE.Scene();
      scene.add(new THREE.HemisphereLight(0xffffff, 0x445544, 1.8));
      const dl = new THREE.DirectionalLight(0xffffff, 2.2);
      dl.position.set(2, 3, 4);
      scene.add(dl);
      const cam = new THREE.PerspectiveCamera(30, 1, 0.01, 50);
      thumb = { renderer, scene, cam, cv };
    }
    const built = buildGear(slot, id, kit);
    const ctx = canvasEl.getContext('2d');
    ctx.clearRect(0, 0, canvasEl.width, canvasEl.height);
    if (!built) return;
    const root = new THREE.Group();
    const paired = built.parts.length === 2 && /L$/.test(built.parts[0].anchor);
    built.parts.forEach((p, i) => {
      if (paired) p.group.position.x += i === 0 ? -0.28 : 0.28;
      root.add(p.group);
    });
    root.rotation.set(0.35, slot === 'back' ? Math.PI + 0.5 : 0.5, 0);
    thumb.scene.add(root);
    const box = new THREE.Box3().setFromObject(root);
    const size = box.getSize(new THREE.Vector3());
    const center = box.getCenter(new THREE.Vector3());
    const r = Math.max(size.x, size.y, size.z) * 0.62 + 0.02;
    thumb.cam.position.set(center.x, center.y, center.z + r / Math.tan((15 * Math.PI) / 180));
    thumb.cam.lookAt(center);
    thumb.renderer.render(thumb.scene, thumb.cam);
    ctx.drawImage(thumb.cv, 0, 0, canvasEl.width, canvasEl.height);
    thumb.scene.remove(root);
    root.traverse((o) => {
      if (o.geometry) o.geometry.dispose();
      if (o.material && o.material !== kit.outlineMat) o.material.dispose();
    });
  } catch {
    /* a thumbnail is never worth breaking the shop for */
  }
}
