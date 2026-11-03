#!/usr/bin/env node
/**
 * Generate the graded puzzle pools: src/data/puzzle-pool.json
 *
 *   npm run gen:puzzles -- [--easy=300] [--medium=300] [--hard=250] [--alien=150]
 *                          [--seed=alien-sudoku-v1] [--workers=N] [--batch=50]
 *                          [--medium-tier2=0.4] [--out=src/data/puzzle-pool.json]
 *
 * Work is split into numbered batches; batch k of a band always uses the RNG
 * seed `${seed}:${band}:${k}` and results are consumed in batch order, so the
 * output depends only on the seed and counts, not on the number of workers.
 *
 * Every stored puzzle has exactly one solution, is fully solved by the logic
 * engine (whose every placement matches the true solution), and passes
 * poolBand() for its band (see the rules at the top of src/engine/logic.js).
 * Each band is sorted by grade score (easiest first) so the campaign can ramp.
 */
import { Worker, isMainThread, parentPort } from 'node:worker_threads';
import { availableParallelism } from 'node:os';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRng } from '../src/engine/rng.js';
import {
  generatePuzzle,
  countSolutions,
  solve,
  parseGrid,
  gridToString,
  computeCandidates,
} from '../src/engine/sudoku.js';
import { gradePuzzle, poolBand, findNextStep, applyStep } from '../src/engine/logic.js';

const BANDS = ['easy', 'medium', 'hard', 'alien'];

/** Carving parameters per band (symmetric carving stops at target or target - 1). */
function carve(rng, band) {
  switch (band) {
    case 'easy':
      return generatePuzzle(rng, { targetClues: 37 + rng.int(4), symmetric: true }); // 36-40
    case 'medium':
      return generatePuzzle(rng, { targetClues: 31 + rng.int(4), symmetric: true }); // 30-34
    case 'hard': {
      // Half symmetric (lands on 25-29 or a minimal puzzle), half free carving to 25-28.
      const symmetric = rng.next() < 0.5;
      return generatePuzzle(rng, { targetClues: (symmetric ? 26 : 25) + rng.int(4), symmetric });
    }
    default:
      return generatePuzzle(rng, { targetClues: 22, symmetric: false }); // minimal, usually 22-26
  }
}

/** Solve with the logic engine only; true if every step agrees with the true solution. */
function logicAgreesWithSolution(puzzle, solution) {
  const g = puzzle.slice();
  const cand = computeCandidates(g);
  for (;;) {
    const step = findNextStep(g, cand);
    if (!step) break;
    if (step.placement && solution[step.placement.idx] !== step.placement.value) return false;
    for (const e of step.eliminations) if (solution[e.idx] === e.value) return false;
    applyStep(g, cand, step);
  }
  return g.every((v, i) => v === solution[i]);
}

/** Full acceptance check for one puzzle string; returns the grade or null. */
function verify(str, band) {
  const puzzle = parseGrid(str);
  if (countSolutions(puzzle, 2) !== 1) return null;
  const grade = gradePuzzle(puzzle);
  if (!grade.solved || grade.difficulty !== band || poolBand(grade) !== band) return null;
  if (!logicAgreesWithSolution(puzzle, solve(puzzle))) return null;
  return grade;
}

// ------------------------------------------------------------------ worker

if (!isMainThread) {
  parentPort.on('message', ({ band, batch, seed, size }) => {
    const rng = createRng(`${seed}:${band}:${batch}`);
    const items = [];
    for (let k = 0; k < size; k++) {
      const { puzzle } = carve(rng, band);
      const grade = gradePuzzle(puzzle);
      if (poolBand(grade) !== band) continue;
      const str = gridToString(puzzle);
      const full = verify(str, band);
      if (!full) throw new Error(`verification failed for accepted ${band} puzzle ${str}`);
      items.push({ str, maxTier: full.maxTier, score: full.score, clues: full.clues });
    }
    parentPort.postMessage({ band, batch, items, attempts: size });
  });
}

// -------------------------------------------------------------------- main

function parseArgs(argv) {
  const args = {
    easy: 300,
    medium: 300,
    hard: 250,
    alien: 150,
    seed: 'alien-sudoku-v1',
    workers: availableParallelism(),
    batch: 50,
    'medium-tier2': 0.4,
    out: 'src/data/puzzle-pool.json',
  };
  for (const a of argv) {
    const m = /^--([\w-]+)=(.*)$/.exec(a);
    if (!m || !(m[1] in args)) {
      console.error(`Unknown argument: ${a}`);
      process.exit(1);
    }
    args[m[1]] = typeof args[m[1]] === 'number' ? Number(m[2]) : m[2];
  }
  return args;
}

/** Acceptance quotas inside a band (medium mixes tier-1 and tier-2 puzzles). */
function makeQuota(band, count, args) {
  if (band === 'medium') {
    const t2 = Math.round(count * args['medium-tier2']);
    const left = { 1: count - t2, 2: t2 };
    return { take: (it) => (left[it.maxTier] > 0 ? (left[it.maxTier]--, true) : false) };
  }
  return { take: () => true };
}

async function generateBand(band, count, args, workers, seen) {
  const start = performance.now();
  const accepted = [];
  if (count <= 0) return { list: accepted, ms: 0, attempts: 0 };
  const quota = makeQuota(band, count, args);
  const pending = new Map();
  let nextBatch = 0;
  let nextToConsume = 0;
  let attempts = 0;
  let lastLog = 0;

  return new Promise((resolvePromise, reject) => {
    let finished = false;
    let inFlight = 0;
    const dispatch = (w) => {
      if (finished) return;
      inFlight++;
      w.postMessage({ band, batch: nextBatch++, seed: args.seed, size: args.batch });
    };
    const onMessage = (w) => (msg) => {
      inFlight--;
      if (msg.band !== band) return;
      pending.set(msg.batch, msg);
      const wasFinished = finished;
      while (!finished && pending.has(nextToConsume)) {
        const res = pending.get(nextToConsume);
        pending.delete(nextToConsume++);
        attempts += res.attempts;
        for (const it of res.items) {
          if (accepted.length >= count) break;
          if (seen.has(it.str)) continue;
          if (!quota.take(it)) continue;
          seen.add(it.str);
          accepted.push(it);
        }
        if (accepted.length >= count) finished = true;
      }
      const now = performance.now();
      if ((finished && !wasFinished) || (!finished && now - lastLog > 1000)) {
        lastLog = now;
        const secs = ((now - start) / 1000).toFixed(1);
        process.stdout.write(`  ${band.padEnd(6)} ${String(accepted.length).padStart(4)}/${count}  attempts ${attempts}  ${secs}s\n`);
      }
      if (!finished) dispatch(w);
      else if (inFlight === 0) done();
    };
    const done = () => {
      for (const w of workers) {
        w.removeAllListeners('message');
        w.removeAllListeners('error');
      }
      resolvePromise({ list: accepted, ms: performance.now() - start, attempts });
    };
    for (const w of workers) {
      w.on('message', onMessage(w));
      w.on('error', reject);
      dispatch(w);
      dispatch(w); // keep two batches queued per worker
    }
  });
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
  const outPath = resolve(root, args.out);
  const nWorkers = Math.max(1, args.workers | 0);
  console.log(`Generating puzzle pools with ${nWorkers} workers, seed "${args.seed}"`);
  const workers = Array.from({ length: nWorkers }, () => new Worker(fileURLToPath(import.meta.url)));
  const seen = new Set();
  const pool = { version: 1, seed: args.seed };
  const totalStart = performance.now();
  const timings = [];
  try {
    for (const band of BANDS) {
      const { list, ms, attempts } = await generateBand(band, args[band] | 0, args, workers, seen);
      // Easiest first (stable), so campaign levels can ramp within a band.
      list.sort((a, b) => a.score - b.score);
      pool[band] = list.map((it) => it.str);
      const tiers = {};
      for (const it of list) tiers[`T${it.maxTier}`] = (tiers[`T${it.maxTier}`] || 0) + 1;
      const clues = list.map((it) => it.clues);
      timings.push(
        `${band.padEnd(6)} ${String(list.length).padStart(4)} puzzles in ${(ms / 1000).toFixed(2)}s ` +
          `(${attempts} attempts, clues ${Math.min(...clues)}-${Math.max(...clues)}, tiers ${JSON.stringify(tiers)})`,
      );
    }
  } finally {
    await Promise.all(workers.map((w) => w.terminate()));
  }

  // Final independent check of everything that is written.
  const checkStart = performance.now();
  for (const band of BANDS) {
    for (const str of pool[band]) {
      if (!verify(str, band)) throw new Error(`final check failed: ${band} ${str}`);
    }
  }
  const checkMs = performance.now() - checkStart;

  const body = [
    '{',
    `  "version": 1,`,
    `  "seed": ${JSON.stringify(args.seed)},`,
    ...BANDS.map(
      (band, k) =>
        `  "${band}": [\n${pool[band].map((s) => `    "${s}"`).join(',\n')}\n  ]${k < BANDS.length - 1 ? ',' : ''}`,
    ),
    '}',
    '',
  ].join('\n');
  mkdirSync(dirname(outPath), { recursive: true });
  writeFileSync(outPath, body);

  console.log('\nPer-difficulty timing:');
  for (const line of timings) console.log(`  ${line}`);
  console.log(`  final verification ${(checkMs / 1000).toFixed(2)}s`);
  console.log(`Total ${((performance.now() - totalStart) / 1000).toFixed(2)}s -> ${outPath}`);
}

if (isMainThread) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
