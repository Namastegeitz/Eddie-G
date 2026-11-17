#!/usr/bin/env bash
# Publish the app to GitHub Pages: https://namastegeitz.github.io/Eddie-G/
# Copies the committed apps/off-grid-survival-kit/ folder to the root of the
# gh-pages branch (git subtree split) and pushes it, keeping the folders other
# projects publish there (monkey-see-monkey-do/). Commit your changes first.
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
# gh-pages also holds other projects' folders (monkey-see-monkey-do/, published
# by apps/monkey-see-monkey-do/scripts/deploy_beta.sh). Merge them in so this
# push stays a fast-forward and keeps them; on any clash this app's files win.
git fetch -q origin gh-pages || true
if git rev-parse -q --verify origin/gh-pages >/dev/null; then
  tmp="$(mktemp -d)"
  git worktree add -q "$tmp" gh-pages-publish
  git -C "$tmp" merge -q --no-edit -X ours -m "Off-Grid Survival Kit: publish (keep other projects' folders)" origin/gh-pages
  git worktree remove --force "$tmp"
fi
git push origin gh-pages-publish:gh-pages
git branch -D gh-pages-publish
echo "Published. GitHub Pages updates in about a minute: https://namastegeitz.github.io/Eddie-G/"
