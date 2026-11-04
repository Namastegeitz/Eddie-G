// The game loop: Watch (the monkey dances a routine) -> Your turn (copy it)
// -> cheer or oops. Runs Adventure levels, Endless and Free Dance.
// Timing runs on the beat clock in audio.js so moves land on the music.
import { MOVES, chordFor, stepName, moveName } from './moves.js';
import { RULES, gradeTiming, stepPoints, streakMult, starsFor, levelBananas, endlessBananas, timeLimit } from './rules.js';
import { LEVELS, WORLDS, getLevel, generateRound, extendEndless, expectedSteps, watchSchedule, makeRng, newSeed, endlessBpm, levelNews } from './levels.js';
import { Save } from './save.js';

const FIDGETS = ['WAVE', 'SCRATCH', 'YAWN'];

export class Game {
  constructor({ audio, monkey, stage, ui }) {
    this.audio = audio;
    this.monkey = monkey;
    this.stage = stage;
    this.ui = ui;
    this.mode = 'menu';
    this.phase = 'idle';
    this.events = [];
    this.run = null;
    this.paused = false;
    this.lastActivity = 0;
    this.nextFidget = 8;
    monkey.on('stomp', (side) => {
      const id = side === 'L' ? 'LL' : 'RL';
      this.stage.dust(this.monkey.anchorWorld(id));
      this.stage.shake(0.05);
      this.audio.sfx('stomp');
    });
    monkey.on('dizzy', () => this.stage.dizzy(1.3));
  }

  get s() {
    return Save.settings;
  }

  now() {
    return this.audio.now();
  }

  at(t, fn) {
    this.events.push({ t, fn });
  }

  clearEvents() {
    this.events = [];
  }

  effBpm(bpm) {
    return Math.max(50, Math.round(bpm * (this.s.speed || 1)));
  }

  stageFor(level) {
    const eq = Save.data.equipped.stage;
    if (eq && eq !== 'auto') return eq;
    if (level) return WORLDS[level.world - 1].stage;
    return 'jungle';
  }

  setScene(level, bpm, menu = false) {
    const env = this.stageFor(level);
    this.stage.setEnvironment(env);
    const style = menu && env === 'jungle' ? 'menu' : this.stage.musicFor(env);
    this.audio.startMusic(style, bpm);
  }

  haptic(pattern) {
    if (this.s.haptics && navigator.vibrate) {
      try { navigator.vibrate(pattern); } catch { /* not supported */ }
    }
  }

  // ------------------------------------------------------------ modes

  toMenu() {
    this.clearEvents();
    this.mode = 'menu';
    this.phase = 'idle';
    this.run = null;
    this.paused = false;
    this.monkey.anims = [];
    this.setScene(null, 96, true);
  }

  /** Show the level card; the level starts when the player taps Start. */
  openLevel(id) {
    const level = getLevel(id);
    if (!level) return;
    this.clearEvents();
    this.mode = 'adventure';
    this.phase = 'intro';
    this.paused = false;
    this.monkey.anims = [];
    this.run = this.newRun(level);
    this.setScene(level, this.effBpm(level.bpm));
    this.introQueue = levelNews(level).filter((n) => n.kind === 'move' || n.kind === 'chord');
    this.introIdx = 0;
    Save.stat('levelsPlayed');
    this.ui.showIntro(level, {
      bpm: this.effBpm(level.bpm),
      timers: level.rounds.map((n) => timeLimit(n, this.effBpm(level.bpm), this.s.timer)),
      news: levelNews(level),
      info: Save.levelInfo(level.id),
    });
  }

  newRun(level) {
    return {
      level,
      round: 0,
      rounds: [],
      steps: null,
      twist: null,
      expected: null,
      idx: 0,
      partial: null,
      lives: RULES.startLives,
      livesLost: 0,
      usedContinue: false,
      score: 0,
      streak: 0,
      bestStreak: 0,
      onBeat: 0,
      stepsDone: 0,
      roundStepsCleared: 0,
      hintIndex: -1,
      replayUsed: false,
      seed: newSeed(),
      seeds: [],
      bananas: 0,
      startedAt: this.now(),
    };
  }

  startRun() {
    if (!this.run) return;
    this.phase = 'starting';
    this.ui.showHud(this.mode, this.run);
    this.beginRound(false);
  }

  startEndless() {
    this.clearEvents();
    this.mode = 'endless';
    this.paused = false;
    this.monkey.anims = [];
    this.run = this.newRun(null);
    this.run.lives = 1;
    this.run.rng = makeRng(this.run.seed);
    Save.data.endless.plays++;
    Save.persist();
    this.setScene(null, this.effBpm(endlessBpm(0)));
    this.ui.showHud('endless', this.run);
    this.beginRound(false);
  }

  startFree() {
    this.clearEvents();
    this.mode = 'free';
    this.phase = 'free';
    this.paused = false;
    this.monkey.anims = [];
    this.run = { moves: 0, last: null };
    this.setScene(null, this.effBpm(100));
    this.ui.showHud('free', this.run);
    this.ui.setPhase('free');
    this.ui.padMode('free', Object.keys(MOVES));
  }

  // ------------------------------------------------------------ a round

  roundBpm() {
    const r = this.run;
    return this.mode === 'endless' ? this.effBpm(endlessBpm(r.round)) : this.effBpm(r.level.bpm);
  }

  beginRound(retry) {
    const r = this.run;
    if (!retry) {
      if (this.mode === 'adventure') {
        const prev = r.round > 0 ? r.rounds[r.round - 1].steps : null;
        const seed = (r.seed + r.round * 7919) >>> 0;
        const gen = generateRound(r.level, r.round, seed, prev);
        r.rounds[r.round] = gen;
        r.steps = gen.steps;
        r.twist = gen.twist;
        r.seeds[r.round] = seed;
      } else {
        r.steps = extendEndless(r.rng, r.steps || [], r.round);
        r.twist = null;
      }
      r.hintIndex = -1;
      r.replayUsed = false;
    }
    r.expected = expectedSteps(r.steps, r.twist);
    r.idx = 0;
    r.partial = null;
    const bpm = this.roundBpm();
    if (Math.abs(this.audio.bpm - bpm) > 0.5) this.audio.setTempo(bpm);
    this.ui.hudRound(this.mode, r);
    this.startWatch();
  }

  startWatch() {
    this.clearEvents();
    const r = this.run;
    this.phase = 'countin';
    const bd = this.audio.beatDur;
    const n = r.steps.length;
    this.ui.setPhase('watch', r.twist);
    this.ui.setSteps(n);
    this.ui.padMode('watch', this.allowedMoves());
    this.ui.hintPad(null);
    this.ui.timer(null);
    this.ui.replayButton(false);
    this.ui.caption('');
    this.monkey.setLook(0, 0);
    const t0 = this.audio.nextBeatTime(this.now() + 0.3);
    for (let k = 0; k < 2; k++) {
      const t = t0 + k * bd;
      this.at(t - 0.12, () => this.audio.sfx(k ? 'go' : 'tick', t));
      this.at(t - 0.01, () => this.ui.countIn(k));
    }
    const sched = watchSchedule(n, r.twist);
    const tStart = t0 + 2 * bd;
    r.stepTimes = [];
    sched.offsets.forEach((off, i) => {
      const t = tStart + off * bd;
      const gap = ((i < n - 1 ? sched.offsets[i + 1] : sched.length) - off) * bd;
      const step = r.steps[i];
      r.stepTimes.push(t);
      this.at(t - 0.13, () => this.audio.playMove(step, t));
      this.at(t - 0.02, () => {
        this.phase = 'watch';
        this.monkey.playStep(step, Math.max(0.3, Math.min(0.75, gap * 0.92)), t);
        for (const id of step) {
          this.stage.ring(this.monkey.anchorWorld(id), MOVES[id].color, t);
          this.stage.lightPad(id, t);
        }
        this.ui.padLightStep(step);
        this.ui.watchStep(i, step);
        if (this.s.captions) this.ui.caption(stepName(step, this.s.naming), step);
        if (this.s.voice) this.audio.speak(stepName(step, this.s.naming).replace('!', ''));
      });
    });
    const tEnd = tStart + sched.length * bd;
    this.at(tEnd - 0.04, () => this.startRespond(tEnd));
  }

  startRespond(t) {
    const r = this.run;
    this.phase = 'respond';
    r.respondAt = t;
    r.idx = 0;
    r.partial = null;
    r.limit = timeLimit(r.expected.length, this.roundBpm(), this.s.timer);
    r.deadline = t + r.limit;
    this.ui.setPhase('respond', r.twist);
    this.ui.setSteps(r.expected.length);
    this.ui.caption('');
    this.ui.padMode('respond', this.allowedMoves());
    this.ui.replayButton(true, this.s.assist ? 0 : RULES.replayCost, !r.replayUsed);
    this.ui.timer(1, r.limit);
    this.monkey.play('POINT', 0.9);
    this.updateHint();
    this.ui.announce(r.twist === 'reverse' ? 'Your turn. Backwards!' : 'Your turn');
  }

  allowedMoves() {
    if (this.mode !== 'adventure') return Object.keys(MOVES);
    return this.run.level.moves;
  }

  guided() {
    const r = this.run;
    return this.mode === 'adventure' && r.level.guided && !Save.data.tutorialDone && r.round === 0;
  }

  updateHint() {
    const r = this.run;
    if (this.phase !== 'respond') return this.ui.hintPad(null);
    const step = r.expected[r.idx];
    const hint = this.guided() || (this.s.assist && r.hintIndex === r.idx);
    this.ui.hintPad(hint && step ? step : null, this.guided());
  }

  // ------------------------------------------------------------ input

  onInput(id, t) {
    this.lastActivity = this.now();
    if (this.paused) return;
    if (this.mode === 'free') return this.freeMove(id, t);
    if (this.mode === 'menu' || this.mode === 'shop') {
      // Tapping the monkey on menus makes it dance
      this.echo(id);
      return;
    }
    if (this.phase === 'watch' || this.phase === 'countin') {
      this.ui.nudge();
      return;
    }
    if (this.phase !== 'respond') return;
    const r = this.run;
    if (t < r.respondAt - 0.15) return;
    const step = r.expected[r.idx];
    this.haptic(8);
    if (step.length === 1) {
      if (id === step[0]) {
        this.echo(id);
        this.stepDone(step, t);
      } else {
        this.mistake('wrong', id);
      }
      return;
    }
    // a combo: both moves inside the combo window
    if (!step.includes(id)) return this.mistake('wrong', id);
    if (!r.partial) {
      const win = (this.s.assist ? RULES.assistChordWindowMs : RULES.chordWindowMs) / 1000;
      r.partial = { got: new Set([id]), t0: t, deadline: this.now() + win };
      this.echo(id);
      this.ui.partialStep(r.idx, [...r.partial.got]);
    } else if (!r.partial.got.has(id)) {
      r.partial.got.add(id);
      this.echo(id);
    }
    if (r.partial.got.size === step.length) {
      const t0 = r.partial.t0;
      r.partial = null;
      const legs = step.includes('LL') && step.includes('RL');
      this.monkey.play(legs ? 'JUMP' : 'HOP', Math.max(0.35, this.audio.beatDur * 0.9));
      this.stepDone(step, t0);
    }
  }

  /** Make the monkey do a move right now (player input, menus, free dance). */
  echo(id) {
    const dur = Math.max(0.36, Math.min(0.7, this.audio.beatDur * 0.9));
    this.monkey.stop(id);
    this.monkey.play(id, dur);
    this.monkey.flash(id);
    this.audio.playMove(id);
    this.stage.ring(this.monkey.anchorWorld(id), MOVES[id].color);
    this.stage.lightPad(id);
    this.ui.padLight(id, true);
  }

  freeMove(id, t) {
    const r = this.run;
    this.echo(id);
    r.moves++;
    // two different moves almost together = a combo
    if (r.last && r.last.id !== id && t - r.last.t < 0.15) {
      const c = chordFor([r.last.id, id]);
      if (c) {
        const legs = c.id === 'BL';
        this.monkey.play(legs ? 'JUMP' : 'HOP', 0.5);
        this.ui.grade('combo', 0, 1, c.name);
      }
    }
    r.last = { id, t };
    this.ui.freeCount(r.moves);
  }

  stepDone(step, t) {
    const r = this.run;
    const lat = (this.s.latencyMs || 0) / 1000;
    const off = this.audio.beatOffset(t - lat);
    const grade = gradeTiming(off);
    r.streak++;
    r.bestStreak = Math.max(r.bestStreak, r.streak);
    const pts = stepPoints(grade, r.streak);
    r.score += pts;
    if (grade !== 'good') r.onBeat++;
    r.stepsDone++;
    Save.moveResult(step, null, true);
    Save.stat('stepsCorrect');
    if (grade === 'perfect') Save.stat('perfects');
    if (grade === 'great') Save.stat('greats');
    if (r.streak > Save.data.stats.bestStreak) Save.data.stats.bestStreak = r.streak;
    this.ui.fillStep(r.idx, step);
    this.ui.grade(grade, pts, streakMult(r.streak), null, off);
    this.ui.score(r.score, r.streak);
    r.idx++;
    if (r.idx >= r.expected.length) this.roundCleared();
    else this.updateHint();
  }

  mistake(kind, tapped) {
    if (this.phase !== 'respond') return;
    const r = this.run;
    this.phase = 'oops';
    this.clearEvents();
    const expected = r.expected[r.idx];
    r.streak = 0;
    r.lives--;
    r.livesLost++;
    r.hintIndex = r.idx;
    Save.moveResult(expected, tapped, false);
    Save.stat(kind === 'timeout' ? 'timeouts' : 'mistakes');
    Save.persist();
    this.monkey.anims = [];
    if (tapped) this.monkey.flash(tapped);
    this.monkey.play('OOPS', 1.9);
    this.audio.sfx('wrong');
    this.haptic([60, 40, 60]);
    this.stage.shake(0.07);
    this.ui.timer(null);
    this.ui.replayButton(false);
    this.ui.hintPad(null);
    this.ui.padMode('off', this.allowedMoves());
    this.ui.lives(r.lives, this.mode === 'endless' ? 1 : RULES.startLives);
    this.ui.score(r.score, 0);
    const info = { kind, expected, tapped, index: r.idx, total: r.expected.length, twist: r.twist, lives: r.lives, mode: this.mode, naming: this.s.naming };
    let next;
    if (this.mode === 'endless') next = () => this.endlessOver();
    else if (r.lives > 0) next = () => this.beginRound(true);
    else next = () => this.levelFailed();
    const go = () => {
      if (this.phase !== 'oops') return;
      this.ui.hideMistake();
      next();
    };
    this.ui.mistake(info, go, r.lives > 0 && this.mode !== 'endless' ? 3.2 : 2.2);
    this.at(this.now() + (r.lives > 0 && this.mode !== 'endless' ? 3.2 : 2.2), go);
  }

  roundCleared() {
    const r = this.run;
    this.phase = 'cheer';
    this.clearEvents();
    const n = r.expected.length;
    r.score += RULES.roundBonus;
    Save.stat('roundsCleared');
    this.audio.sfx('round');
    this.audio.sfx('cheer', this.now() + 0.1);
    this.monkey.play('CHEER', 1.5, this.now() + 0.1);
    this.stage.confetti(0.35);
    this.ui.timer(null);
    this.ui.replayButton(false);
    this.ui.hintPad(null);
    this.ui.padMode('off', this.allowedMoves());
    this.ui.score(r.score, r.streak);
    if (this.mode === 'adventure') {
      const bananas = n * RULES.bananasPerStep;
      r.roundStepsCleared += n;
      r.bananas += bananas;
      Save.addBananas(bananas, `Level ${r.level.id}, round ${r.round + 1}`);
      this.ui.bananaBurst(bananas);
      this.audio.sfx('coin', this.now() + 0.35);
      r.round++;
      const last = r.round >= r.level.rounds.length;
      this.ui.roundClear(last ? 'Level clear!' : `Round ${r.round + 1} of ${r.level.rounds.length} next`);
      this.at(this.now() + (last ? 1.5 : 1.8), () => (last ? this.levelComplete() : this.beginRound(false)));
    } else {
      r.round++;
      this.ui.roundClear(`Round ${r.round + 1}: one more move`);
      this.at(this.now() + 1.5, () => this.beginRound(false));
    }
    Save.persist();
  }

  levelComplete() {
    const r = this.run;
    const level = r.level;
    this.phase = 'result';
    this.clearEvents();
    const stars = starsFor({ livesLost: r.livesLost, onBeat: r.onBeat, steps: r.stepsDone });
    const wasReached = Save.worldReached();
    const rec = Save.recordLevel(level.id, stars, r.score);
    const bn = levelBananas({ stepsCleared: r.roundStepsCleared, stars, firstClear: rec.firstClear });
    const extra = bn.total - r.bananas;
    Save.addBananas(extra, `Level ${level.id} cleared (${stars} star${stars > 1 ? 's' : ''})`);
    if (level.id === 1) Save.data.tutorialDone = true;
    Save.persist();
    const next = getLevel(level.id + 1);
    const newWorld = Save.worldReached() > wasReached ? WORLDS[Save.worldReached() - 1] : null;
    this.audio.sfx('level');
    this.stage.confetti(1);
    this.victoryDance();
    this.ui.showResult({
      level, stars, prevStars: rec.prevStars, score: r.score, prevBest: rec.prevBest,
      items: bn.items, total: bn.total, alreadyAdded: r.bananas,
      onBeat: r.onBeat, steps: r.stepsDone, livesLost: r.livesLost, bestStreak: r.bestStreak,
      seeds: r.seeds, next, newWorld,
    });
  }

  victoryDance() {
    const seq = [['CHEER', 1.5], ['FL', 1.0], ['BA', 0.8], ['HD', 0.7], ['CHEER', 1.5]];
    let t = this.now() + 0.3;
    for (const [name, dur] of seq) {
      const tt = t;
      this.at(tt, () => {
        if (this.phase !== 'result') return;
        if (name === 'BA') this.monkey.playStep(['LA', 'RA'], dur);
        else this.monkey.play(name, dur);
      });
      t += dur + 0.15;
    }
  }

  levelFailed() {
    const r = this.run;
    this.phase = 'failed';
    this.clearEvents();
    this.monkey.anims = [];
    this.monkey.play('SAD', 600);
    this.audio.sfx('fail');
    this.ui.showFail({
      level: r.level,
      round: r.round + 1,
      rounds: r.level.rounds.length,
      score: r.score,
      canContinue: !r.usedContinue,
      cost: RULES.continueCost,
      bananas: Save.data.bananas,
    });
  }

  continueRun() {
    const r = this.run;
    if (!r || this.phase !== 'failed' || r.usedContinue) return false;
    if (!Save.spend(RULES.continueCost, `Continue on level ${r.level.id}`)) return false;
    r.usedContinue = true;
    r.lives = 1;
    this.monkey.anims = [];
    this.ui.hideOverlays();
    this.ui.showHud(this.mode, r);
    this.ui.lives(r.lives, RULES.startLives);
    this.beginRound(true);
    return true;
  }

  endlessOver() {
    const r = this.run;
    this.phase = 'result';
    this.clearEvents();
    const rounds = r.round;
    const e = Save.data.endless;
    const newBest = rounds > e.bestRounds;
    e.bestRounds = Math.max(e.bestRounds, rounds);
    e.bestScore = Math.max(e.bestScore, r.score);
    const bn = endlessBananas({ rounds, newBest });
    Save.addBananas(bn.total, `Endless: ${rounds} round${rounds === 1 ? '' : 's'}`);
    Save.persist();
    if (newBest) {
      this.stage.confetti(0.8);
      this.audio.sfx('level');
    }
    this.ui.showEndless({ rounds, score: r.score, bestRounds: e.bestRounds, bestScore: e.bestScore, newBest, items: bn.items, total: bn.total, longest: r.steps.length, bestStreak: r.bestStreak, seed: r.seed });
  }

  replay() {
    const r = this.run;
    if (!r || this.phase !== 'respond' || r.replayUsed || this.paused) return;
    const cost = this.s.assist ? 0 : RULES.replayCost;
    if (cost > 0 && !Save.spend(cost, 'Watch again')) {
      this.ui.toast(`You need ${cost} bananas to watch again.`);
      return;
    }
    r.replayUsed = true;
    this.ui.updateBananas();
    this.startWatch();
  }

  // ------------------------------------------------------------ pause

  canPause() {
    return (this.mode === 'adventure' || this.mode === 'endless' || this.mode === 'free') && ['countin', 'watch', 'respond', 'cheer', 'oops', 'free', 'starting'].includes(this.phase);
  }

  pause() {
    if (this.paused || !this.canPause()) return false;
    this.paused = true;
    this.pausedAt = this.now();
    this.pausedPhase = this.phase;
    this.ui.showPause(this.mode);
    return true;
  }

  resume() {
    if (!this.paused) return;
    this.paused = false;
    const dur = this.now() - this.pausedAt;
    this.ui.hidePause();
    const ph = this.pausedPhase;
    if (ph === 'countin' || ph === 'watch') {
      this.monkey.anims = [];
      this.startWatch();
    } else if (ph === 'respond') {
      const r = this.run;
      r.deadline += dur;
      r.respondAt += dur;
      if (r.partial) r.partial.deadline += dur;
    } else {
      for (const e of this.events) e.t += dur;
    }
  }

  // ------------------------------------------------------------ per frame

  update(now) {
    if (this.paused) return;
    if (this.events.length) {
      const due = this.events.filter((e) => e.t <= now).sort((a, b) => a.t - b.t);
      if (due.length) {
        this.events = this.events.filter((e) => e.t > now);
        for (const e of due) e.fn();
      }
    }
    if (this.phase === 'respond') {
      const r = this.run;
      if (r.partial && now > r.partial.deadline) {
        r.partial = null;
        this.mistake('combo', null);
        return;
      }
      if (now > r.deadline) {
        this.mistake('timeout', null);
        return;
      }
      if (Number.isFinite(r.limit)) this.ui.timer((r.deadline - now) / r.limit, r.deadline - now);
    }
    if ((this.mode === 'menu') && now > this.nextFidget && now - this.lastActivity > 6 && !this.monkey.anims.length) {
      this.monkey.play(FIDGETS[Math.floor(Math.random() * FIDGETS.length)], 1.8);
      this.nextFidget = now + 9 + Math.random() * 6;
    }
  }

  /** Called on every whole beat of the music. */
  onBeat(n) {
    if (this.paused) return;
    if (this.mode === 'menu' && this.ui.current === 'title' && n % 2 === 0 && !this.monkey.anims.length && Math.random() < 0.45) {
      const ids = ['LA', 'RA', 'LL', 'RL', 'HD', 'FL'];
      const id = ids[Math.floor(Math.random() * ids.length)];
      this.monkey.play(id, Math.min(0.7, this.audio.beatDur * 0.95));
      this.stage.lightPad(id);
    }
    if (this.phase === 'intro' && this.introQueue && this.introQueue.length && n % 2 === 0) {
      const item = this.introQueue[this.introIdx++ % this.introQueue.length];
      const step = item.kind === 'chord' ? (item.id === 'BA' ? ['LA', 'RA'] : item.id === 'BL' ? ['LL', 'RL'] : item.id === 'XL' ? ['LA', 'RL'] : ['RA', 'LL']) : [item.id];
      this.monkey.playStep(step, Math.min(0.75, this.audio.beatDur * 0.95));
      for (const id of step) this.stage.lightPad(id);
      this.audio.playMove(step);
      this.ui.introDemo(item.id);
    }
  }

  quit() {
    this.paused = false;
    this.ui.hidePause();
    this.toMenu();
  }

  describeStep(step) {
    return stepName(step, this.s.naming);
  }

  moveLabel(id) {
    return moveName(id, this.s.naming);
  }
}

export { LEVELS };
