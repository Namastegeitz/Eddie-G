import { AUDIO, dbToGain } from "./limits";

export type Bus = "listen" | "drive";

export interface RampRequest {
  kind: "in" | "out";
  seconds: number;
}

/** Fades are never shorter than the spec minimums (no instant starts or stops). */
export function guardRamp(r: RampRequest): number {
  return Math.max(r.seconds, r.kind === "in" ? AUDIO.minFadeInS : AUDIO.minFadeOutS);
}

export const MASTER_DEFAULT_GAIN = dbToGain(AUDIO.masterDefaultDbfs);
export const HARD_CEILING_GAIN = dbToGain(AUDIO.hardCeilingDbfs);

export function guardFrequency(bus: Bus, hz: number): { hz: number; clamped: boolean } {
  const [lo, hi] = bus === "drive" ? AUDIO.driveHz : AUDIO.listenHz;
  const v = Math.min(Math.max(hz, lo), hi);
  return { hz: v, clamped: v !== hz };
}

export function guardBinaural(carrierHz: number, beatHz: number): { carrierHz: number; beatHz: number; clamped: boolean } {
  const c = Math.min(Math.max(carrierHz, AUDIO.binauralCarrierHz[0]), AUDIO.binauralCarrierHz[1]);
  const b = Math.min(Math.max(beatHz, AUDIO.binauralBeatHz[0]), AUDIO.binauralBeatHz[1]);
  return { carrierHz: c, beatHz: b, clamped: c !== carrierHz || b !== beatHz };
}

/** Hard-clip guard for any sample block: nothing above -1 dBFS leaves the engine. */
export function hardClip(block: Float32Array): number {
  let clipped = 0;
  for (let i = 0; i < block.length; i++) {
    const v = block[i]!;
    if (v > HARD_CEILING_GAIN) {
      block[i] = HARD_CEILING_GAIN;
      clipped++;
    } else if (v < -HARD_CEILING_GAIN) {
      block[i] = -HARD_CEILING_GAIN;
      clipped++;
    }
  }
  return clipped;
}
