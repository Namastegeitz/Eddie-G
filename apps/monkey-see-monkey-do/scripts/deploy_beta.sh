#!/usr/bin/env bash
# Publishes the beta website (dist/site, made by scripts/build_web.mjs) to
# GitHub Pages: https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/
#
# GitHub Pages serves the gh-pages branch. Its root is the Off-Grid Survival
# Kit (apps/off-grid-survival-kit/scripts/publish_pages.sh); this game lives in
# its own monkey-see-monkey-do/ folder there. This script replaces only that
# folder, commits on top of the current gh-pages and pushes (never forced).
#   bash scripts/deploy_beta.sh ["extra commit message lines"]
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
site="$here/dist/site"
[ -f "$site/index.html" ] && [ -f "$site/play/index.html" ] || { echo "dist/site is missing: run node scripts/build_web.mjs first" >&2; exit 1; }
cd "$(git -C "$here" rev-parse --show-toplevel)"

git fetch -q origin gh-pages
tmp="$(mktemp -d)"
trap 'git worktree remove --force "$tmp" >/dev/null 2>&1 || rm -rf "$tmp"' EXIT
git worktree add -q --detach "$tmp" origin/gh-pages
rm -rf "$tmp/monkey-see-monkey-do"
cp -R "$site" "$tmp/monkey-see-monkey-do"
git -C "$tmp" add -A monkey-see-monkey-do
if git -C "$tmp" diff --cached --quiet; then
  echo "The live beta already matches dist/site: nothing to publish."
  exit 0
fi
build="$(sed -n 's/.*Beta build \([^<]*\) · <a.*/\1/p' "$site/index.html" | head -1)"
msg="Monkey See, Monkey Do: public beta ${build}"
[ $# -gt 0 ] && msg="$msg"$'\n\n'"$*"
git -C "$tmp" commit -q -m "$msg"
for i in 1 2 3 4; do
  git -C "$tmp" push -q origin HEAD:gh-pages && break
  [ "$i" = 4 ] && { echo "Push failed. If gh-pages moved on, run this script again." >&2; exit 1; }
  sleep $((2 ** i))
done
echo "Published. GitHub Pages updates in about a minute:"
echo "  https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/"
