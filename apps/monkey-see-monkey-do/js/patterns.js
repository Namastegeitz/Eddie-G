// Fur patterns, painted on a canvas. The same painter makes the 3D fur
// texture (wrapped around the monkey) and the 2D skin portraits in the
// Wardrobe, so what you see on the card is what you get on the monkey.
// Patterns tile left-to-right (they wrap around the body).

export const PATTERN_TYPES = [
  'solid', 'stripes', 'vstripes', 'pinstripe', 'spots', 'dots', 'specks', 'seeds', 'glitter',
  'leopard', 'tiger', 'zebra', 'giraffe', 'patches', 'camo', 'checker', 'zigzag', 'plaid', 'argyle',
  'hearts', 'stars', 'notes', 'confetti', 'sprinkles', 'leaves', 'bones', 'rainbow', 'gradient',
  'swirl', 'galaxy', 'lava', 'circuit', 'scanlines', 'scales', 'waves', 'lightning', 'flames',
  'pixels', 'velvet', 'lacquer',
];

// Patterns whose bright parts glow in the dark (they also get an emissive layer)
export const GLOW_PATTERNS = new Set(['galaxy', 'lava', 'circuit', 'scanlines', 'lightning', 'flames', 'bones']);

function hash(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 16777619);
  return h >>> 0;
}

function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Draw `fn(x)` at x and its wrapped copies so shapes tile around the body
function wrap(S, x, fn) {
  fn(x);
  if (x < S * 0.25) fn(x + S);
  if (x > S * 0.75) fn(x - S);
}

function heart(ctx, x, y, r) {
  ctx.beginPath();
  ctx.moveTo(x, y + r * 0.9);
  ctx.bezierCurveTo(x - r * 1.6, y - r * 0.2, x - r * 0.7, y - r * 1.3, x, y - r * 0.4);
  ctx.bezierCurveTo(x + r * 0.7, y - r * 1.3, x + r * 1.6, y - r * 0.2, x, y + r * 0.9);
  ctx.fill();
}

function star(ctx, x, y, r, points = 5, inner = 0.45, rot = -Math.PI / 2) {
  ctx.beginPath();
  for (let k = 0; k < points * 2; k++) {
    const rr = k % 2 ? r * inner : r;
    const a = rot + (k * Math.PI) / points;
    if (k === 0) ctx.moveTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr);
    else ctx.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr);
  }
  ctx.closePath();
  ctx.fill();
}

function note(ctx, x, y, r) {
  ctx.beginPath();
  ctx.ellipse(x, y, r * 0.7, r * 0.5, -0.4, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillRect(x + r * 0.45, y - r * 2.2, r * 0.25, r * 2.2);
  ctx.fillRect(x + r * 0.45, y - r * 2.2, r * 0.9, r * 0.35);
}

function leaf(ctx, x, y, r, a) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(a);
  ctx.beginPath();
  ctx.moveTo(0, -r);
  ctx.quadraticCurveTo(r * 0.8, 0, 0, r);
  ctx.quadraticCurveTo(-r * 0.8, 0, 0, -r);
  ctx.fill();
  ctx.restore();
}

function bone(ctx, x, y, r, a) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(a);
  ctx.fillRect(-r, -r * 0.18, r * 2, r * 0.36);
  for (const sx of [-1, 1]) for (const sy of [-1, 1]) {
    ctx.beginPath();
    ctx.arc(sx * r, sy * r * 0.22, r * 0.26, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.restore();
}

/**
 * Paint pattern `p` = { type, c: [colours], n: density } on a size S canvas.
 * glow = true paints only the parts that glow (on black), for emissive maps.
 */
export function drawPattern(ctx, S, p, glow = false) {
  const c = p.c || ['#8a5230'];
  const [c0, c1 = c0, c2 = c1, c3 = c2] = c;
  const n = p.n || 0;
  const rnd = rng(hash(p.type + c.join('') + n));
  const glowing = GLOW_PATTERNS.has(p.type);
  if (glow && !glowing) {
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, S, S);
    return;
  }
  ctx.save();
  ctx.fillStyle = glow ? '#000' : c0;
  ctx.fillRect(0, 0, S, S);
  const F = (col) => { ctx.fillStyle = col; };
  const L = (col, w) => { ctx.strokeStyle = col; ctx.lineWidth = w; ctx.lineCap = 'round'; ctx.lineJoin = 'round'; };
  switch (p.type) {
    case 'solid':
      break;
    case 'stripes': {
      const k = n || 8;
      F(c1);
      for (let i = 1; i < k; i += 2) ctx.fillRect(0, (i * S) / k, S, S / k);
      break;
    }
    case 'vstripes': {
      const k = n || 10;
      F(c1);
      for (let i = 1; i < k; i += 2) ctx.fillRect((i * S) / k, 0, S / k, S);
      break;
    }
    case 'pinstripe': {
      const k = n || 16;
      F(c1);
      for (let i = 0; i < k; i++) ctx.fillRect((i * S) / k, 0, Math.max(1.5, S / 120), S);
      break;
    }
    case 'spots': {
      const k = n || 6;
      const r = S / k / 3.2;
      F(c1);
      for (let i = 0; i < k; i++) for (let j = 0; j < k; j++) {
        const x = ((i + (j % 2) * 0.5) * S) / k;
        const y = ((j + 0.5) * S) / k;
        wrap(S, x, (xx) => { ctx.beginPath(); ctx.arc(xx, y, r, 0, Math.PI * 2); ctx.fill(); });
      }
      break;
    }
    case 'dots': {
      F(c1);
      for (let i = 0; i < (n || 30); i++) {
        const x = rnd() * S, y = rnd() * S, r = S * (0.02 + rnd() * 0.04);
        wrap(S, x, (xx) => { ctx.beginPath(); ctx.arc(xx, y, r, 0, Math.PI * 2); ctx.fill(); });
      }
      break;
    }
    case 'specks': {
      F(c1);
      for (let i = 0; i < (n || 140); i++) {
        const x = rnd() * S, y = rnd() * S;
        ctx.beginPath();
        ctx.ellipse(x, y, S * 0.008 + rnd() * S * 0.006, S * 0.004 + rnd() * S * 0.004, rnd() * 3, 0, Math.PI * 2);
        ctx.fill();
      }
      break;
    }
    case 'seeds': {
      const k = n || 9;
      F(c1);
      for (let i = 0; i < k; i++) for (let j = 0; j < k; j++) {
        const x = ((i + (j % 2) * 0.5) * S) / k, y = ((j + 0.5) * S) / k;
        ctx.beginPath();
        ctx.ellipse(x, y, S * 0.008, S * 0.015, 0, 0, Math.PI * 2);
        ctx.fill();
      }
      break;
    }
    case 'glitter': {
      for (let i = 0; i < (n || 260); i++) {
        F(rnd() < 0.7 ? c1 : (c2 !== c1 ? c2 : '#ffffff'));
        const x = rnd() * S, y = rnd() * S, r = S * (0.003 + rnd() * 0.007);
        ctx.fillRect(x, y, r * 2, r * 2);
      }
      break;
    }
    case 'leopard': {
      for (let i = 0; i < (n || 22); i++) {
        const x = rnd() * S, y = rnd() * S, r = S * (0.035 + rnd() * 0.025);
        wrap(S, x, (xx) => {
          F(c2);
          ctx.beginPath(); ctx.arc(xx, y, r * 0.8, 0, Math.PI * 2); ctx.fill();
          F(c1);
          for (let k = 0; k < 4; k++) {
            const a = (k / 4) * Math.PI * 2 + rnd();
            ctx.beginPath();
            ctx.ellipse(xx + Math.cos(a) * r, y + Math.sin(a) * r, r * 0.45, r * 0.25, a + Math.PI / 2, 0, Math.PI * 2);
            ctx.fill();
          }
        });
      }
      break;
    }
    case 'tiger':
    case 'zebra': {
      const k = n || (p.type === 'zebra' ? 14 : 10);
      F(c1);
      for (let i = 0; i < k; i++) {
        const x0 = ((i + 0.3 * rnd()) * S) / k;
        const w = (S / k) * (p.type === 'zebra' ? 0.42 : 0.3);
        const len = p.type === 'zebra' ? 1 : 0.55 + rnd() * 0.4;
        const top = p.type === 'zebra' ? 0 : rnd() * S * 0.3;
        wrap(S, x0, (xx) => {
          ctx.beginPath();
          const steps = 12;
          for (let s = 0; s <= steps; s++) {
            const y = top + (s / steps) * S * len;
            const taper = Math.sin((s / steps) * Math.PI) * 0.8 + 0.2;
            ctx.lineTo(xx + Math.sin(y * 0.05 + i) * S * 0.025 - w * taper, y);
          }
          for (let s = steps; s >= 0; s--) {
            const y = top + (s / steps) * S * len;
            const taper = Math.sin((s / steps) * Math.PI) * 0.8 + 0.2;
            ctx.lineTo(xx + Math.sin(y * 0.05 + i) * S * 0.025 + w * taper, y);
          }
          ctx.fill();
        });
      }
      break;
    }
    case 'giraffe': {
      const k = n || 5;
      F(c1);
      for (let i = 0; i < k; i++) for (let j = 0; j < k; j++) {
        const cx = ((i + 0.5 + (j % 2) * 0.5) * S) / k, cy = ((j + 0.5) * S) / k, r = (S / k) * 0.42;
        wrap(S, cx, (xx) => {
          ctx.beginPath();
          for (let v = 0; v < 6; v++) {
            const a = (v / 6) * Math.PI * 2 + rnd() * 0.4;
            const rr = r * (0.75 + rnd() * 0.3);
            ctx.lineTo(xx + Math.cos(a) * rr, cy + Math.sin(a) * rr);
          }
          ctx.closePath();
          ctx.fill();
        });
      }
      break;
    }
    case 'patches':
    case 'camo': {
      const cols = p.type === 'camo' ? [c1, c2, c3] : [c1];
      for (let i = 0; i < (n || (p.type === 'camo' ? 26 : 7)); i++) {
        F(cols[i % cols.length]);
        const x = rnd() * S, y = rnd() * S, r = S * (p.type === 'camo' ? 0.06 + rnd() * 0.06 : 0.09 + rnd() * 0.1);
        wrap(S, x, (xx) => {
          ctx.beginPath();
          for (let v = 0; v < 9; v++) {
            const a = (v / 9) * Math.PI * 2;
            const rr = r * (0.7 + rnd() * 0.5);
            ctx.lineTo(xx + Math.cos(a) * rr * 1.3, y + Math.sin(a) * rr);
          }
          ctx.closePath();
          ctx.fill();
        });
      }
      break;
    }
    case 'checker': {
      const k = n || 8;
      F(c1);
      for (let i = 0; i < k; i++) for (let j = 0; j < k; j++) if ((i + j) % 2) ctx.fillRect((i * S) / k, (j * S) / k, S / k, S / k);
      break;
    }
    case 'zigzag': {
      const k = n || 7;
      L(c1, S / k / 2.6);
      for (let j = 0; j < k; j++) {
        ctx.beginPath();
        const y = ((j + 0.5) * S) / k;
        for (let i = 0; i <= 12; i++) ctx.lineTo((i * S) / 12, y + (i % 2 ? 1 : -1) * (S / k) * 0.28);
        ctx.stroke();
      }
      break;
    }
    case 'plaid': {
      const k = n || 4;
      ctx.globalAlpha = 0.55;
      F(c1);
      for (let i = 0; i < k; i++) {
        ctx.fillRect((i * S) / k, 0, S / k / 2.2, S);
        ctx.fillRect(0, (i * S) / k, S, S / k / 2.2);
      }
      ctx.globalAlpha = 0.9;
      F(c2);
      for (let i = 0; i < k; i++) {
        ctx.fillRect(((i + 0.72) * S) / k, 0, S / 90, S);
        ctx.fillRect(0, ((i + 0.72) * S) / k, S, S / 90);
      }
      ctx.globalAlpha = 1;
      break;
    }
    case 'argyle': {
      const k = n || 4;
      F(c1);
      for (let i = 0; i < k; i++) for (let j = 0; j < k * 2; j++) {
        if ((i + j) % 2) continue;
        const x = ((i + 0.5) * S) / k, y = ((j + 0.5) * S) / (k * 2), w = S / k / 2, h = S / (k * 2);
        ctx.beginPath();
        ctx.moveTo(x, y - h); ctx.lineTo(x + w, y); ctx.lineTo(x, y + h); ctx.lineTo(x - w, y);
        ctx.fill();
      }
      L(c2, S / 160);
      ctx.setLineDash([S / 40, S / 50]);
      for (let i = -k; i < k * 2; i++) {
        ctx.beginPath(); ctx.moveTo((i * S) / k, 0); ctx.lineTo(((i + k) * S) / k, S * 2); ctx.stroke();
        ctx.beginPath(); ctx.moveTo((i * S) / k, 0); ctx.lineTo(((i - k) * S) / k, S * 2); ctx.stroke();
      }
      ctx.setLineDash([]);
      break;
    }
    case 'hearts':
    case 'stars':
    case 'notes':
    case 'leaves':
    case 'bones': {
      const k = n || 5;
      for (let i = 0; i < k; i++) for (let j = 0; j < k; j++) {
        const x = ((i + 0.5 + (j % 2) * 0.5 + (rnd() - 0.5) * 0.3) * S) / k;
        const y = ((j + 0.5 + (rnd() - 0.5) * 0.3) * S) / k;
        const r = (S / k) * (0.22 + rnd() * 0.08);
        F(j % 3 === 2 && c2 !== c1 ? c2 : c1);
        wrap(S, x, (xx) => {
          if (p.type === 'hearts') heart(ctx, xx, y, r);
          else if (p.type === 'stars') star(ctx, xx, y, r * 1.2);
          else if (p.type === 'notes') note(ctx, xx, y + r, r * 0.8);
          else if (p.type === 'leaves') leaf(ctx, xx, y, r * 1.3, rnd() * 6);
          else bone(ctx, xx, y, r * 1.1, rnd() * 6);
        });
      }
      break;
    }
    case 'confetti':
    case 'sprinkles': {
      const cols = c.slice(1).length ? c.slice(1) : ['#ff4f9a', '#ffd23f', '#2e8bff', '#1fb57a'];
      for (let i = 0; i < (n || 120); i++) {
        F(cols[i % cols.length]);
        const x = rnd() * S, y = rnd() * S;
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(rnd() * 6);
        if (p.type === 'sprinkles') ctx.fillRect(-S * 0.018, -S * 0.005, S * 0.036, S * 0.01);
        else ctx.fillRect(-S * 0.012, -S * 0.009, S * 0.024, S * 0.018);
        ctx.restore();
      }
      break;
    }
    case 'rainbow': {
      const cols = ['#ff4b4b', '#ff9a2e', '#ffd23f', '#4fd36a', '#2e8bff', '#8a5cff'];
      cols.forEach((col, i) => { F(col); ctx.fillRect(0, (i * S) / cols.length, S, S / cols.length + 1); });
      break;
    }
    case 'gradient': {
      const g = ctx.createLinearGradient(0, 0, 0, S);
      g.addColorStop(0, c0);
      g.addColorStop(1, c1);
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, S, S);
      break;
    }
    case 'swirl': {
      const k = n || 8;
      L(c1, S / k / 2);
      for (let i = -k; i < k * 2; i++) {
        ctx.beginPath();
        ctx.moveTo((i * S) / k, 0);
        ctx.lineTo(((i + k * 0.6) * S) / k, S);
        ctx.stroke();
      }
      break;
    }
    case 'galaxy': {
      if (!glow) {
        // nebula clouds use their own random numbers so the stars land in the
        // same places on the colour and glow layers
        const r2 = rng(hash('nebula' + c.join('')));
        for (let i = 0; i < 9; i++) {
          const x = r2() * S, y = r2() * S, r = S * (0.12 + r2() * 0.18);
          const col = i % 2 ? c1 : c2;
          wrap(S, x, (xx) => {
            const g = ctx.createRadialGradient(xx, y, 0, xx, y, r);
            g.addColorStop(0, col + 'aa');
            g.addColorStop(1, col + '00');
            ctx.fillStyle = g;
            ctx.fillRect(xx - r, y - r, r * 2, r * 2);
          });
        }
      }
      for (let i = 0; i < (n || 90); i++) {
        F(i % 7 === 0 ? (c3 !== c2 ? c3 : '#ffe9a8') : '#ffffff');
        const x = rnd() * S, y = rnd() * S, r = S * (0.003 + rnd() * 0.006);
        if (i % 11 === 0) star(ctx, x, y, r * 3, 4, 0.3, 0);
        else { ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill(); }
      }
      break;
    }
    case 'lava':
    case 'lightning': {
      const lines = n || (p.type === 'lava' ? 16 : 7);
      L(glow ? c1 : c1, p.type === 'lava' ? S * 0.018 : S * 0.022);
      if (!glow && p.type === 'lava') {
        const r2 = rng(hash('rocks' + c.join('')));
        for (let i = 0; i < 18; i++) {
          F(c2 !== c1 ? c2 : c0);
          const x = r2() * S, y = r2() * S;
          ctx.beginPath(); ctx.arc(x, y, S * (0.03 + r2() * 0.05), 0, Math.PI * 2); ctx.fill();
        }
      }
      for (let i = 0; i < lines; i++) {
        let x = rnd() * S, y = rnd() * S * 0.2;
        ctx.beginPath();
        ctx.moveTo(x, y);
        const segs = 6 + Math.floor(rnd() * 5);
        for (let s = 0; s < segs; s++) {
          x += (rnd() - 0.5) * S * (p.type === 'lava' ? 0.16 : 0.2);
          y += S * (p.type === 'lava' ? 0.05 + rnd() * 0.09 : 0.12);
          ctx.lineTo(x, y);
        }
        ctx.stroke();
      }
      break;
    }
    case 'circuit': {
      L(c1, S * 0.012);
      F(c1);
      for (let i = 0; i < (n || 22); i++) {
        let x = Math.round(rnd() * 16) * (S / 16), y = Math.round(rnd() * 16) * (S / 16);
        ctx.beginPath();
        ctx.moveTo(x, y);
        for (let s = 0; s < 3; s++) {
          if (rnd() < 0.5) x += (rnd() < 0.5 ? -1 : 1) * (S / 16) * (1 + Math.floor(rnd() * 3));
          else y += (rnd() < 0.5 ? -1 : 1) * (S / 16) * (1 + Math.floor(rnd() * 3));
          ctx.lineTo(x, y);
        }
        ctx.stroke();
        ctx.beginPath(); ctx.arc(x, y, S * 0.014, 0, Math.PI * 2); ctx.fill();
      }
      break;
    }
    case 'scanlines': {
      F(c1);
      const k = n || 40;
      for (let i = 0; i < k; i++) ctx.fillRect(0, (i * S) / k, S, S / k / 3);
      break;
    }
    case 'scales': {
      const k = n || 10;
      for (let j = k; j >= -1; j--) for (let i = -1; i <= k; i++) {
        const x = ((i + (j % 2) * 0.5) * S) / k, y = (j * S) / k, r = (S / k) * 0.62;
        F(j % 2 ? c0 : c2);
        ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI); ctx.fill();
        L(c1, S / 110);
        ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI); ctx.stroke();
      }
      break;
    }
    case 'waves': {
      const k = n || 9;
      for (let j = 0; j < k; j++) {
        L(j % 2 ? c1 : c2, S / k / 3.2);
        ctx.beginPath();
        for (let i = 0; i <= 40; i++) {
          const x = (i * S) / 40;
          ctx.lineTo(x, ((j + 0.5) * S) / k + Math.sin((i / 40) * Math.PI * 4) * (S / k) * 0.25);
        }
        ctx.stroke();
      }
      break;
    }
    case 'flames': {
      const g = ctx.createLinearGradient(0, 0, 0, S);
      g.addColorStop(0, glow ? '#000000' : c0);
      g.addColorStop(0.5, c1);
      g.addColorStop(1, c2);
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, S, S);
      F(glow ? c2 : c1);
      for (let i = 0; i < 10; i++) {
        const x = ((i + 0.5) * S) / 10, h = S * (0.25 + rnd() * 0.3);
        ctx.beginPath();
        ctx.moveTo(x - S * 0.05, S);
        ctx.quadraticCurveTo(x - S * 0.04, S - h * 0.6, x, S - h);
        ctx.quadraticCurveTo(x + S * 0.04, S - h * 0.6, x + S * 0.05, S);
        ctx.fill();
      }
      break;
    }
    case 'pixels': {
      const k = n || 12;
      const cols = c.length > 1 ? c : [c0, c1];
      for (let i = 0; i < k; i++) for (let j = 0; j < k; j++) {
        F(cols[Math.floor(rnd() * cols.length)]);
        ctx.fillRect((i * S) / k, (j * S) / k, S / k + 1, S / k + 1);
      }
      break;
    }
    case 'velvet': {
      for (let i = 0; i < 400; i++) {
        F(rnd() < 0.5 ? c1 : c0);
        ctx.globalAlpha = 0.25;
        ctx.beginPath(); ctx.arc(rnd() * S, rnd() * S, S * 0.02, 0, Math.PI * 2); ctx.fill();
      }
      ctx.globalAlpha = 1;
      F(c2);
      ctx.fillRect(0, S * 0.94, S, S * 0.06);
      ctx.fillRect(0, 0, S, S * 0.03);
      break;
    }
    case 'lacquer': {
      const k = n || 6;
      for (let j = 0; j < k; j++) {
        F(j % 2 ? c0 : c2 !== c1 ? c2 : c0);
        ctx.fillRect(0, (j * S) / k, S, S / k);
        F(c1);
        ctx.fillRect(0, ((j + 1) * S) / k - S / 90, S, S / 90);
        for (let i = 0; i < 8; i++) {
          ctx.beginPath(); ctx.arc(((i + 0.5) * S) / 8, ((j + 0.5) * S) / k, S / 140, 0, Math.PI * 2); ctx.fill();
        }
      }
      break;
    }
    default:
      break;
  }
  ctx.restore();
}

/** A canvas with the pattern painted on it (cached by key). */
const cache = new Map();
export function patternCanvas(p, S = 256, glow = false) {
  const key = JSON.stringify(p) + S + glow;
  if (cache.has(key)) return cache.get(key);
  const cv = document.createElement('canvas');
  cv.width = cv.height = S;
  drawPattern(cv.getContext('2d'), S, p, glow);
  if (S > 256) return cv; // big ones (the 3D monkey's fur) aren't kept: 1 MB each
  if (cache.size > 60) cache.delete(cache.keys().next().value);
  cache.set(key, cv);
  return cv;
}

// ---------------------------------------------------------------- portraits

function shade(hex, f) {
  const h = hex.replace('#', '');
  const v = [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16));
  const out = v.map((x) => Math.max(0, Math.min(255, Math.round(f > 1 ? x + (255 - x) * (f - 1) : x * f))));
  return '#' + out.map((x) => x.toString(16).padStart(2, '0')).join('');
}

/**
 * A 2D head-and-shoulders portrait of a skin for Wardrobe cards.
 * rarityColor tints the background.
 */
export function drawPortrait(cv, skin, rarityColor = '#2b7a55') {
  const S = cv.width;
  const ctx = cv.getContext('2d');
  ctx.clearRect(0, 0, S, S);
  const bg = ctx.createRadialGradient(S / 2, S * 0.45, S * 0.1, S / 2, S / 2, S * 0.7);
  bg.addColorStop(0, shade(rarityColor, 1.35));
  bg.addColorStop(1, shade(rarityColor, 0.55));
  ctx.fillStyle = bg;
  ctx.fillRect(0, 0, S, S);
  const pat = skin.pattern || { type: 'solid', c: [skin.fur] };
  const tex = patternCanvas(pat, 128);
  const furFill = ctx.createPattern(tex, 'repeat');
  const extras = skin.extras || [];
  const has = (name) => extras.find((e) => e.split(':')[0] === name);
  const arg = (name, i = 1) => { const e = has(name); return e ? e.split(':')[i] : null; };
  const cx = S / 2, cy = S * 0.58, R = S * 0.3;
  const ink = '#23160c';
  const outline = () => { ctx.lineWidth = S * 0.025; ctx.strokeStyle = ink; ctx.stroke(); };

  // aura sparkle behind
  if (skin.aura) {
    ctx.fillStyle = skin.auraColor || '#ffffff';
    ctx.globalAlpha = 0.85;
    for (let i = 0; i < 7; i++) {
      const a = (i / 7) * Math.PI * 2 + 0.4;
      star(ctx, cx + Math.cos(a) * R * 1.45, cy + Math.sin(a) * R * 1.3 - S * 0.04, S * 0.03, 4, 0.35, 0);
    }
    ctx.globalAlpha = 1;
  }
  // wings / cape behind
  const wings = has('wings');
  if (wings) {
    const kind = arg('wings');
    const col = arg('wings', 2) || (kind === 'angel' ? '#ffffff' : kind === 'phoenix' ? '#ff7a1a' : kind === 'fairy' ? '#ffb3e6' : '#2a6a3a');
    ctx.fillStyle = col;
    for (const s of [-1, 1]) {
      ctx.beginPath();
      ctx.moveTo(cx + s * R * 0.4, cy + R * 0.6);
      ctx.quadraticCurveTo(cx + s * R * 1.9, cy - R * 1.2, cx + s * R * 1.6, cy + R * 0.9);
      ctx.closePath();
      ctx.globalAlpha = kind === 'fairy' ? 0.75 : 1;
      ctx.fill();
      ctx.globalAlpha = 1;
      outline();
    }
  }
  if (has('cape')) {
    ctx.fillStyle = arg('cape') || '#c8302a';
    ctx.beginPath();
    ctx.moveTo(cx - R * 0.9, cy + R * 0.7);
    ctx.lineTo(cx + R * 0.9, cy + R * 0.7);
    ctx.lineTo(cx + R * 1.3, S);
    ctx.lineTo(cx - R * 1.3, S);
    ctx.closePath();
    ctx.fill();
  }
  // shoulders
  ctx.fillStyle = furFill;
  ctx.beginPath();
  ctx.ellipse(cx, S * 1.02, R * 1.15, R * 0.75, 0, 0, Math.PI * 2);
  ctx.fill();
  outline();

  ctx.save();
  if (skin.finish === 'ghost') ctx.globalAlpha = 0.7;
  if (skin.glow || skin.finish === 'glow') { ctx.shadowColor = skin.glowColor || skin.fur; ctx.shadowBlur = S * 0.12; }
  // ears
  for (const s of [-1, 1]) {
    ctx.fillStyle = furFill;
    ctx.beginPath(); ctx.arc(cx + s * R * 1.02, cy - R * 0.05, R * 0.36, 0, Math.PI * 2); ctx.fill(); outline();
    ctx.fillStyle = skin.skin;
    ctx.beginPath(); ctx.arc(cx + s * R * 1.02, cy - R * 0.05, R * 0.2, 0, Math.PI * 2); ctx.fill();
  }
  // head
  ctx.fillStyle = furFill;
  ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.fill();
  ctx.shadowBlur = 0;
  outline();
  if (skin.finish === 'metal') {
    const g = ctx.createRadialGradient(cx - R * 0.35, cy - R * 0.45, 0, cx, cy, R);
    g.addColorStop(0, 'rgba(255,255,255,0.85)');
    g.addColorStop(0.35, 'rgba(255,255,255,0.15)');
    g.addColorStop(1, 'rgba(0,0,0,0.35)');
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.fill();
  }
  ctx.restore();
  // mask behind the eyes
  if (has('mask')) {
    ctx.fillStyle = arg('mask') || '#1a1a22';
    for (const s of [-1, 1]) { ctx.beginPath(); ctx.ellipse(cx + s * R * 0.33, cy - R * 0.05, R * 0.38, R * 0.3, 0, 0, Math.PI * 2); ctx.fill(); }
  }
  // face plate + muzzle
  ctx.fillStyle = skin.skin;
  for (const s of [-1, 1]) { ctx.beginPath(); ctx.arc(cx + s * R * 0.3, cy - R * 0.08, R * 0.42, 0, Math.PI * 2); ctx.fill(); }
  if (has('mask')) {
    ctx.fillStyle = arg('mask') || '#1a1a22';
    for (const s of [-1, 1]) { ctx.beginPath(); ctx.ellipse(cx + s * R * 0.33, cy - R * 0.08, R * 0.3, R * 0.25, 0, 0, Math.PI * 2); ctx.fill(); }
  }
  ctx.fillStyle = skin.skin;
  ctx.beginPath(); ctx.ellipse(cx, cy + R * 0.42, R * 0.58, R * 0.42, 0, 0, Math.PI * 2); ctx.fill();
  // eyes
  const eyes = skin.eyes || {};
  for (const s of [-1, 1]) {
    const ex = cx + s * R * 0.3, ey = cy - R * 0.12;
    ctx.fillStyle = eyes.white || '#ffffff';
    ctx.beginPath(); ctx.ellipse(ex, ey, R * 0.22, R * 0.27, 0, 0, Math.PI * 2); ctx.fill();
    ctx.lineWidth = S * 0.015; ctx.strokeStyle = ink; ctx.stroke();
    if (eyes.glow) { ctx.shadowColor = eyes.pupil; ctx.shadowBlur = S * 0.08; }
    ctx.fillStyle = eyes.pupil || '#1b0f08';
    ctx.beginPath(); ctx.ellipse(ex + s * R * 0.02, ey + R * 0.03, R * 0.12, R * 0.15, 0, 0, Math.PI * 2); ctx.fill();
    ctx.shadowBlur = 0;
    ctx.fillStyle = '#ffffff';
    ctx.beginPath(); ctx.arc(ex + R * 0.06, ey - R * 0.04, R * 0.045, 0, Math.PI * 2); ctx.fill();
  }
  if (has('eyepatch')) {
    ctx.strokeStyle = '#1a1a1a'; ctx.lineWidth = S * 0.02;
    ctx.beginPath(); ctx.moveTo(cx - R, cy - R * 0.55); ctx.lineTo(cx + R, cy + R * 0.1); ctx.stroke();
    ctx.fillStyle = '#1a1a1a';
    ctx.beginPath(); ctx.ellipse(cx + R * 0.3, cy - R * 0.12, R * 0.26, R * 0.3, 0, 0, Math.PI * 2); ctx.fill();
  }
  // nose + smile
  ctx.fillStyle = ink;
  for (const s of [-1, 1]) { ctx.beginPath(); ctx.arc(cx + s * R * 0.09, cy + R * 0.3, R * 0.04, 0, Math.PI * 2); ctx.fill(); }
  ctx.strokeStyle = '#5a1a1a'; ctx.lineWidth = S * 0.02;
  ctx.beginPath(); ctx.arc(cx, cy + R * 0.42, R * 0.22, 0.2, Math.PI - 0.2); ctx.stroke();
  // head extras
  if (has('horns')) {
    ctx.fillStyle = arg('horns') || '#f4e4c0';
    for (const s of [-1, 1]) {
      ctx.beginPath(); ctx.moveTo(cx + s * R * 0.35, cy - R * 0.85); ctx.lineTo(cx + s * R * 0.75, cy - R * 1.45); ctx.lineTo(cx + s * R * 0.7, cy - R * 0.7); ctx.closePath(); ctx.fill(); outline();
    }
  }
  if (has('unihorn')) {
    ctx.fillStyle = '#ffe9a8';
    ctx.beginPath(); ctx.moveTo(cx - R * 0.14, cy - R * 0.82); ctx.lineTo(cx, cy - R * 1.6); ctx.lineTo(cx + R * 0.14, cy - R * 0.82); ctx.closePath(); ctx.fill(); outline();
  }
  if (has('mane')) {
    ['#ff6fae', '#ffd23f', '#4fd8ff', '#b07cff'].forEach((col, i) => {
      ctx.fillStyle = col; ctx.beginPath(); ctx.arc(cx - R * 0.45 + i * R * 0.3, cy - R * 0.92, R * 0.18, 0, Math.PI * 2); ctx.fill();
    });
  }
  if (has('antenna')) {
    const col = arg('antenna') || '#7bff5a';
    for (const s of [-1, 1]) {
      ctx.strokeStyle = ink; ctx.lineWidth = S * 0.02;
      ctx.beginPath(); ctx.moveTo(cx + s * R * 0.3, cy - R * 0.85); ctx.lineTo(cx + s * R * 0.55, cy - R * 1.4); ctx.stroke();
      ctx.fillStyle = col; ctx.beginPath(); ctx.arc(cx + s * R * 0.55, cy - R * 1.45, R * 0.12, 0, Math.PI * 2); ctx.fill();
    }
  }
  if (has('halo')) {
    ctx.strokeStyle = '#ffd23f'; ctx.lineWidth = S * 0.03;
    ctx.beginPath(); ctx.ellipse(cx, cy - R * 1.25, R * 0.55, R * 0.16, 0, 0, Math.PI * 2); ctx.stroke();
  }
}
