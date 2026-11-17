/**
 * Validity-preserving Sudoku transforms (the symmetry group used to turn one
 * base puzzle into millions of distinct-looking variants of equal difficulty).
 *
 * Descriptor (plain JSON):
 *   {
 *     digits:    [9]  relabel map, value v becomes digits[v - 1] (a permutation of 1..9)
 *     rows:      [9]  output row r is taken from source row rows[r]
 *     cols:      [9]  output col c is taken from source col cols[c]
 *     transpose: bool source is transposed before rows/cols are applied
 *   }
 * rows/cols always permute whole bands/stacks and rows/cols within them, so
 * every unit maps onto a unit: validity, uniqueness and logical difficulty are
 * preserved.
 */

function bandPermutation(rng) {
  const bands = rng.shuffle([0, 1, 2]);
  const out = [];
  for (const b of bands) for (const k of rng.shuffle([0, 1, 2])) out.push(b * 3 + k);
  return out;
}

/** A random transform descriptor. */
export function randomTransform(rng) {
  return {
    digits: rng.shuffle([1, 2, 3, 4, 5, 6, 7, 8, 9]),
    rows: bandPermutation(rng),
    cols: bandPermutation(rng),
    transpose: rng.next() < 0.5,
  };
}

/** The transform that changes nothing. */
export function identityTransform() {
  return {
    digits: [1, 2, 3, 4, 5, 6, 7, 8, 9],
    rows: [0, 1, 2, 3, 4, 5, 6, 7, 8],
    cols: [0, 1, 2, 3, 4, 5, 6, 7, 8],
    transpose: false,
  };
}

/** Apply a transform to an 81-int grid (0 stays 0). Returns a new array. */
export function applyTransform(grid, t) {
  const out = new Array(81);
  for (let r = 0; r < 9; r++) {
    const sr = t.rows[r];
    for (let c = 0; c < 9; c++) {
      const sc = t.cols[c];
      const v = grid[t.transpose ? sc * 9 + sr : sr * 9 + sc];
      out[r * 9 + c] = v ? t.digits[v - 1] : 0;
    }
  }
  return out;
}
