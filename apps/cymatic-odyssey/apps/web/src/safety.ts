import { SafetyGuardian } from "@clc/core-safety";

/** One guardian for the whole app: every output registers with it, FADE ALL reaches everything. */
export const guardian = new SafetyGuardian();
