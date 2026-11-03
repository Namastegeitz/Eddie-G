#!/usr/bin/env bash
# Publish the app to GitHub Pages: https://namastegeitz.github.io/Eddie-G/
# Copies the committed apps/off-grid-survival-kit/ folder to the root of the
# gh-pages branch (git subtree split) and pushes it. Commit your changes first.
# GitHub Pages turns on automatically for a gh-pages branch on a public repo;
# if it doesn't, set Settings -> Pages -> Source: "Deploy from a branch", gh-pages, / (root).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
python3 apps/off-grid-survival-kit/scripts/build_sw.py
if ! git diff --quiet -- apps/off-grid-survival-kit; then
  echo "sw.js or app files changed - commit them first, then run this again." >&2
  exit 1
fi
git subtree split --prefix=apps/off-grid-survival-kit -b gh-pages-publish
git push origin gh-pages-publish:gh-pages
git branch -D gh-pages-publish
echo "Published. GitHub Pages updates in about a minute: https://namastegeitz.github.io/Eddie-G/"
