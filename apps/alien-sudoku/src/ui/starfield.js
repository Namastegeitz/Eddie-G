/* Animated starfield on a canvas: twinkling stars in the theme's colors,
   slow parallax drift, occasional shooting stars and a rare UFO flyby.
   Runs at ~30 fps, pauses when the page is hidden, and draws one still
   frame when reduced motion is on. */

import { on } from '../core/events.js';
import { themeFor, currentTheme } from './theme.js';

let canvas, ctx, w = 0, h = 0, dpr = 1;
let stars = [];
let shooters = [];
let ufo = null;
let running = false;
let rafId = 0;
let last = 0;
let nextShooter = 0;
let nextUfo = 0;
let reduced = false;

const rand = (a, b) => a + Math.random() * (b - a);

export function initStarfield(host) {
  canvas = document.createElement('canvas');
  canvas.className = 'starfield-canvas';
  canvas.setAttribute('aria-hidden', 'true');
  host.appendChild(canvas);
  ctx = canvas.getContext('2d');
  if (!ctx) return;
  document.documentElement.classList.add('has-starfield');
  resize();
  window.addEventListener('resize', resize);
  document.addEventListener('visibilitychange', () => (document.hidden ? stop() : start()));
  on('theme', () => { recolor(); if (!running) drawFrame(0); });
  const mq = window.matchMedia?.('(prefers-reduced-motion: reduce)');
  setReducedMotion(!!mq?.matches);
  start();
}

export function setReducedMotion(on) {
  reduced = on || (window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false);
  if (!ctx) return;
  if (reduced) { stop(); drawFrame(0); } else start();
}

function palette() { return themeFor(currentTheme()).stars; }

function resize() {
  if (!canvas) return;
  dpr = Math.min(window.devicePixelRatio || 1, 2);
  w = window.innerWidth;
  h = window.innerHeight;
  canvas.width = Math.round(w * dpr);
  canvas.height = Math.round(h * dpr);
  canvas.style.width = `${w}px`;
  canvas.style.height = `${h}px`;
  const count = Math.min(240, Math.round((w * h) / 7000));
  const colors = palette();
  stars = Array.from({ length: count }, () => ({
    x: Math.random() * w,
    y: Math.random() * h,
    r: Math.random() < 0.08 ? rand(1.3, 2.1) : rand(0.4, 1.2),
    a: rand(0.35, 0.95),
    tw: rand(0.6, 2.4),
    ph: rand(0, Math.PI * 2),
    depth: rand(0.2, 1),
    c: colors[Math.floor(Math.random() * colors.length)],
  }));
  if (!running) drawFrame(0);
}

function recolor() {
  const colors = palette();
  for (const s of stars) s.c = colors[Math.floor(Math.random() * colors.length)];
}

function start() {
  if (running || reduced || !ctx || document.hidden) return;
  running = true;
  last = performance.now();
  nextShooter = last + rand(3000, 8000);
  nextUfo = last + rand(25000, 50000);
  rafId = requestAnimationFrame(loop);
}

function stop() {
  running = false;
  cancelAnimationFrame(rafId);
}

function loop(now) {
  if (!running) return;
  rafId = requestAnimationFrame(loop);
  const dt = now - last;
  if (dt < 33) return; // ~30 fps is plenty for ambience
  last = now;
  if (now > nextShooter) {
    spawnShooter();
    nextShooter = now + rand(5000, 13000);
  }
  if (!ufo && now > nextUfo) {
    spawnUfo();
    nextUfo = now + rand(45000, 90000);
  }
  update(dt / 1000);
  drawFrame(now / 1000);
}

function spawnShooter() {
  const fromLeft = Math.random() < 0.5;
  const speed = rand(500, 900);
  const angle = rand(0.25, 0.55) * (fromLeft ? 1 : -1);
  shooters.push({
    x: fromLeft ? rand(-50, w * 0.5) : rand(w * 0.5, w + 50),
    y: rand(-20, h * 0.35),
    vx: Math.cos(angle) * speed * (fromLeft ? 1 : -1),
    vy: Math.abs(Math.sin(angle)) * speed,
    life: 0,
    max: rand(0.7, 1.2),
  });
}

function spawnUfo() {
  const dir = Math.random() < 0.5 ? 1 : -1;
  ufo = { x: dir > 0 ? -60 : w + 60, y: rand(h * 0.08, h * 0.3), dir, speed: rand(60, 110), t: 0 };
}

function update(dt) {
  for (const s of stars) {
    s.x += s.depth * 2.2 * dt; // gentle drift to the right
    if (s.x > w + 2) s.x -= w + 4;
  }
  for (const s of shooters) {
    s.x += s.vx * dt;
    s.y += s.vy * dt;
    s.life += dt;
  }
  shooters = shooters.filter((s) => s.life < s.max);
  if (ufo) {
    ufo.t += dt;
    ufo.x += ufo.dir * ufo.speed * dt;
    if (ufo.x < -80 || ufo.x > w + 80) ufo = null;
  }
}

function drawFrame(t) {
  if (!ctx) return;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.clearRect(0, 0, w, h);
  for (const s of stars) {
    const tw = reduced ? 1 : 0.65 + 0.35 * Math.sin(t * s.tw + s.ph);
    ctx.globalAlpha = s.a * tw;
    ctx.fillStyle = s.c;
    ctx.beginPath();
    ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
    ctx.fill();
    if (s.r > 1.3) {
      // little cross sparkle on the brightest stars
      ctx.globalAlpha = s.a * tw * 0.5;
      ctx.fillRect(s.x - s.r * 3, s.y - 0.4, s.r * 6, 0.8);
      ctx.fillRect(s.x - 0.4, s.y - s.r * 3, 0.8, s.r * 6);
    }
  }
  ctx.globalAlpha = 1;
  for (const s of shooters) {
    const fade = 1 - s.life / s.max;
    const tail = 0.12;
    const g = ctx.createLinearGradient(s.x, s.y, s.x - s.vx * tail, s.y - s.vy * tail);
    g.addColorStop(0, `rgba(255,255,255,${0.9 * fade})`);
    g.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.strokeStyle = g;
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.moveTo(s.x, s.y);
    ctx.lineTo(s.x - s.vx * tail, s.y - s.vy * tail);
    ctx.stroke();
  }
  if (ufo) drawUfo(ufo, t);
}

function drawUfo(u, t) {
  const x = u.x;
  const y = u.y + Math.sin(u.t * 2.2) * 4;
  const c = palette()[1] || '#9ff';
  ctx.save();
  ctx.globalAlpha = 0.75;
  // beam
  const beam = ctx.createLinearGradient(0, y, 0, y + 70);
  beam.addColorStop(0, 'rgba(160,255,240,0.22)');
  beam.addColorStop(1, 'rgba(160,255,240,0)');
  ctx.fillStyle = beam;
  ctx.beginPath();
  ctx.moveTo(x - 6, y + 4);
  ctx.lineTo(x + 6, y + 4);
  ctx.lineTo(x + 20, y + 70);
  ctx.lineTo(x - 20, y + 70);
  ctx.closePath();
  ctx.fill();
  // dome
  ctx.fillStyle = 'rgba(190,240,255,0.65)';
  ctx.beginPath();
  ctx.ellipse(x, y - 3, 7, 6, 0, Math.PI, 0);
  ctx.fill();
  // saucer
  ctx.fillStyle = '#9aa7c7';
  ctx.beginPath();
  ctx.ellipse(x, y, 18, 5, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#5d6687';
  ctx.beginPath();
  ctx.ellipse(x, y + 1.5, 16, 2.5, 0, 0, Math.PI);
  ctx.fill();
  // blinking lights
  for (let k = -2; k <= 2; k++) {
    const on = Math.sin(t * 6 + k) > 0;
    ctx.fillStyle = on ? c : 'rgba(255,255,255,0.3)';
    ctx.beginPath();
    ctx.arc(x + k * 6, y + 0.5, 1.3, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.restore();
}
