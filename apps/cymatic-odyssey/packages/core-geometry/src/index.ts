/**
 * @clc/core-geometry - shape families and STL/3MF export (spec 6).
 * Status (P0): LEGACY ADAPTER ONLY. The Python generator in tools/ stays the source of truth and keeps
 * running in CI. This adapter exposes its catalog to the new app. TypeScript families + manifold-3d (WASM)
 * arrive in P4, each with a parity test against the Python output.
 */
export { legacyCatalog, legacyStyles, legacySummary } from "./legacy";
export type { LegacyEntry, LegacyStyle } from "./legacy";
export const STATUS = { phase: "P4", implemented: false, legacyAdapter: true } as const;
