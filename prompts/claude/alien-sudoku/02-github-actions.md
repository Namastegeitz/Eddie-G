# 2. Automatic builds (GitHub Actions)

**What it gives you:** every push builds and tests everything and publishes an
`alien-sudoku-latest` GitHub release. The release has the Android APK (and a signed
AAB for Google Play once step 4 is set up), an iOS build, Windows/Mac/Linux
installers, and the web build. The iOS build is a simulator build until step 5,
then it uploads to TestFlight. The workflow is already in
`.github/workflows/alien-sudoku.yml`.

**Why it is waiting:** on Nov 3, 2026, every job (even a one-line `echo` test) was
refused before a machine started. That is an account-level block, usually billing.

## Before you send it

1. On github.com (logged in as Namastegeitz): **Settings → Billing and plans**. Fix
   any failed payment, and check that Actions isn't blocked by a $0 spending
   limit with an unpaid balance. Public repositories get free Actions minutes.
2. In the repository, **Settings → Actions → General**: "Allow all actions and
   reusable workflows" must be selected.
3. Optional check: Actions tab → **Alien Sudoku** → the latest run → **Re-run all jobs**.
   If jobs now show steps, it works.

## Prompt

```
GitHub Actions should work now. Re-run the "Alien Sudoku" workflow on my Claude branch,
watch it, and fix any job that fails (web, android, ios, desktop, release) until the
alien-sudoku-latest release has the APK, iOS simulator zip, Windows/Mac/Linux installers
and the web zip. Tell me the release link.
```
