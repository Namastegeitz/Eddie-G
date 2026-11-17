/* Particle bursts over the board: sparks in a glyph's color when it is
   placed, a bigger shower when a row/column/box completes, fireworks on a
   win. The canvas only animates while particles are alive. */

export function createParticles(host) {
  const canvas = document.createElement('canvas');
  canvas.className = 'fx-canvas';
  canvas.setAttribute('aria-hidden', 'true');
  host.appendChild(canvas);
  const ctx = canvas.getContext('2d');
  const PAD = 28; // the canvas overhangs the board by this much on every side (matches .fx-canvas)
  let parts = [];
  let raf = 0;
  let last = 0;
  let enabled = true;
  let dpr = 1;

  function size() {
    const r = host.getBoundingClientRect();
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round((r.width + PAD * 2) * dpr);
    canvas.height = Math.round((r.height + PAD * 2) * dpr);
  }

  function spawn(x, y, color, n, power, kind = 'spark') {
    for (let i = 0; i < n; i++) {
      const a = Math.random() * Math.PI * 2;
      const v = power * (0.35 + Math.random() * 0.65);
      parts.push({
        x: x + PAD, y: y + PAD,
        vx: Math.cos(a) * v, vy: Math.sin(a) * v - power * 0.25,
        life: 0, max: 0.5 + Math.random() * 0.5,
        size: kind === 'star' ? 2.5 + Math.random() * 2.5 : 1.2 + Math.random() * 2,
        color: Math.random() < 0.25 ? '#ffffff' : color,
        kind: Math.random() < 0.3 ? 'star' : kind,
        spin: Math.random() * 6,
      });
    }
    if (!raf) { last = performance.now(); raf = requestAnimationFrame(tick); }
  }

  function tick(now) {
    const dt = Math.min(0.05, (now - last) / 1000);
    last = now;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr);
    for (const p of parts) {
      p.life += dt;
      p.vy += 260 * dt;
      p.vx *= 0.985;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      const k = 1 - p.life / p.max;
      if (k <= 0) continue;
      ctx.globalAlpha = Math.min(1, k * 1.4);
      ctx.fillStyle = p.color;
      if (p.kind === 'star') {
        const s = p.size * (0.6 + 0.4 * k);
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate(p.spin * p.life);
        ctx.beginPath();
        for (let j = 0; j < 8; j++) {
          const rr = j % 2 === 0 ? s : s * 0.35;
          const aa = (j / 8) * Math.PI * 2;
          ctx.lineTo(Math.cos(aa) * rr, Math.sin(aa) * rr);
        }
        ctx.closePath();
        ctx.fill();
        ctx.restore();
      } else {
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size * k + 0.3, 0, Math.PI * 2);
        ctx.fill();
      }
    }
    ctx.globalAlpha = 1;
    parts = parts.filter((p) => p.life < p.max);
    raf = parts.length ? requestAnimationFrame(tick) : 0;
    if (!raf) ctx.clearRect(0, 0, canvas.width, canvas.height);
  }

  return {
    resize: size,
    setEnabled(on) { enabled = on; if (!on) parts = []; },
    /** Small burst at a point (board-relative px). */
    burst(x, y, color, n = 14) { if (enabled) spawn(x, y, color, n, 170); },
    /** One burst per cell rect center, e.g. for a completed unit. */
    shower(points, color) { if (enabled) for (const [x, y] of points) spawn(x, y, color, 5, 140); },
    /** Win fireworks over the whole board. */
    fireworks(colors, w, h) {
      if (!enabled) return;
      for (let i = 0; i < 6; i++) {
        setTimeout(() => spawn(w * (0.15 + Math.random() * 0.7), h * (0.15 + Math.random() * 0.6), colors[i % colors.length], 34, 260, 'star'), i * 180);
      }
    },
    destroy() { cancelAnimationFrame(raf); parts = []; canvas.remove(); },
  };
}
