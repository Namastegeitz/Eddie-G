# 6. Public website and installable web app

**What it gives you:** a public link anyone can play. On phones it can be added to the
home screen and works offline like an app. It also gives you a place to host the
privacy policy and `app-ads.txt`. The current claude.ai link is private to you, and
artifacts can't run the offline/install part.

## Before you send it (pick one host)

- **GitHub Pages** (free; needs step 2 working): repository **Settings → Pages →
  Source: GitHub Actions**. The site will be https://namastegeitz.github.io/Eddie-G/.
- **surge.sh** (you already use it for NeuroForge): on your computer run
  `npx surge token` and keep the token ready to paste. Pick a name like
  `alien-sudoku.surge.sh`.
- **Netlify / Cloudflare Pages**: create a site and a deploy token.

## Prompt (say which host)

```
Publish the Alien Sudoku web build publicly on <GitHub Pages | surge as alien-sudoku.surge.sh |
Netlify>. Build with the service worker on so it installs and works offline, and add a
privacy.html made from docs/PRIVACY.md (my name: ..., email: ...) and app-ads.txt
(pub-... from AdMob). If it's GitHub Pages, add a pages job to the workflow. Give me the link.
```

For surge, paste the token only when Claude asks for it (it is a secret, so it
must not go into the repository).
