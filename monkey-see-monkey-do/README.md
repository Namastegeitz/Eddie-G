# Monkey See, Monkey Do · public beta

This folder is generated: do not edit it by hand. Its source is
`apps/monkey-see-monkey-do/beta/` (landing, privacy, support pages) and
`apps/monkey-see-monkey-do/dist/www` (the game, in `play/`), on the
repository's default branch.

Rebuild and publish from there:

    cd apps/monkey-see-monkey-do
    node scripts/build_web.mjs     # game + this site (dist/site)
    bash scripts/deploy_beta.sh    # copies it here and pushes gh-pages

Live at https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/
