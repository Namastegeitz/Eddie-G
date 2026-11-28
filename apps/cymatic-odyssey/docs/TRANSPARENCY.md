# Transparency

Plain answers to: what this does, what it doesn't, what's real vs simulated, what data we keep, where AI is used, what each platform can't do, and where every claim comes from. Maintained with every phase (see `CHANGELOG.md`).

## 1. What it does, and what it doesn't

**Does:** drives a shallow layer of water with sound so it forms standing-wave patterns, lights it so the patterns become visible (on the water, on a wall, or on screen), lets you design and 3D-print geometric light-passage shapes, and runs calm audio-visual sessions for individuals and groups.

**Doesn't:** diagnose, treat or prevent anything. It isn't therapy and it isn't a medical device. It doesn't "structure" water, sync brain hemispheres, or do anything to your DNA. We attach **no** benefits to the "tradition" frequencies we include (solfeggio, 432 Hz).

## 2. Every number and picture is labelled

| Label | Meaning | Example |
|---|---|---|
| **Measured** | came from a sensor or camera on *your* chamber | the Bowl Fingerprint's ring spacing at 41.75 Hz |
| **Simulated** | computed from a physics model; every simulated image carries a visible **SIMULATION** watermark | the simulator, the style previews, the marketing videos |
| **Estimated** | a calculation with stated assumptions | predicted wavelength for 5 mm of 20 °C water |
| **Tradition (not science)** | a cultural practice or belief, offered as such | the solfeggio preset bank |

Simulations are never presented as real footage. The existing v1 assets (console, style previews, videos, manual) were labelled "simulated" in text; the manual rebuild (Nov 2026) adds a SIMULATION watermark on every simulated image, and so do the app's pictures (burned into each file), the console's live preview and its style thumbnails. The marketing videos still carry only their small "Simulated preview" footer; their posters in the app are marked.

## 3. Evidence grades (the claims register)

Every wellness-related sentence in the app, a session, or exported marketing must point to a claim ID in `packages/content/src/claims-register.json`:

| Grade | Meaning |
|---|---|
| A | physics, or consistent RCT / meta-analysis support |
| B | some RCTs, promising |
| C | mixed, small, uncontrolled or observational |
| D | no good evidence, or implausible |
| T | cultural tradition, not a scientific claim |

Claims not yet graded (e.g. `C-MIND-01`, mindfulness/relaxation, awaiting a current meta-analysis) are marked `needsReview` and can't be shown.

**The claims linter** (`pnpm claims:lint`, runs in CI) fails the build if scanned UI strings, show/session copy, captions, listings or customer docs contain any never-say term: *heal(s), cure(s), treat(s), detox, clinically proven, FDA, rewires DNA/brain, raises vibration, removes toxins, reduces anxiety/pain/depression, syncs your brain*, or the trademarks *Hemi-Sync, CymaScope, HeartMath, Dispenza / Dr Joe, Focus 10/12, Gateway Experience*. Passages that discuss these claims critically are allowlisted line by line with a reason (`packages/content/claims-lint.config.json`). This exists because a previous shop account was deactivated over health and energy claims.

## 4. Design decision: no strobe, no photic entrainment

**We will not build a strobe or photic-entrainment mode.** Flashing or flickering light between about 3 and 30 Hz (up to 60 Hz for some people) can trigger seizures in people with photosensitive epilepsy (claim `C-FLK-01`, grade A). The Safety Guardian (`packages/core-safety`) enforces, for every light, screen and projector output:

- no more than 3 luminance transitions (≥10 % change) in any 1-second window, i.e. at most 1.5 flashes per second;
- large swings become fades of at least 333 ms;
- any periodic modulation between 3 and 60 Hz is slowed to ≤3 Hz;
- stricter limits for saturated red (1 transition per second);
- **water-beat flicker:** two drive tones whose difference is 3-60 Hz make the reflected light flicker at that rate. The guard limits the weaker tone to 10 % amplitude, or shifts it out of the band, unless Lab mode is explicitly opted into. It also checks half the difference (the Faraday water response), which is stricter than the spec;
- the chamber firmware will enforce the same rules independently (P3).

**Known open question (not yet verified):** even a single tone makes a Faraday pattern that oscillates at half the drive frequency (5-100 Hz). The total light stays about constant (caustics move light around rather than switching it on and off), but local contrast oscillates in the 3-60 Hz band. We'll measure this with a photodiode/camera in P5 and apply the projection contrast and area caps from spec §9.1.

**Existing content that breaks the water-beat rule:** 12 of the 30 v1 styles, 52 show steps and 16 voyage steps use two-tone beats of 6-24 Hz. Until they are re-tuned, they play only through the guard (second tone limited to 10 %) or in Lab mode with a warning. Since Nov 2026 the Voyage console itself runs every tone through the Safety Guardian (the same `packages/core-safety` code, bundled into the page), and each style and show page in the app says whether it is guarded.

## 5. Data: what's collected and where it lives

- **Local-first.** Everything works offline with no account. Settings, atlases and journals live on your device (IndexedDB) when those features arrive.
- **Heart-rate / HRV data stays on the device** unless you explicitly opt in. In the EU this is health data (GDPR special category): explicit consent, minimisation, one-tap export and delete.
- **Studios** see anonymous aggregate counts only, with participant opt-in.
- **Today:** the app stores two things on the device: that you accepted the safety notice, and the console's pattern atlas if you log patterns (`localStorage`). Nothing is sent anywhere; there are no accounts, ads or analytics. The public privacy policy is at `/privacy/` on the app's site (source `apps/web/public/privacy/index.html`); have it reviewed before store submission. Big files (manual, zips, videos, APK) are served by GitHub Pages, which may log IP addresses under GitHub's own privacy statement.

## 6. Where AI is used

- **In the product today:** nowhere.
- **Planned (P9, optional, needs Eddie's go-ahead):** Session Composer, Claims Critic and Atlas Librarian agents called only from a server function, with spend caps, human approval before anything is saved or published, and evals that block a release if quality drops. AI output never auto-publishes.
- **In building it:** the code, docs and simulations are written with Claude (Anthropic) under Eddie's direction; generated assets (marketing videos, renders) are labelled as simulations.

## 7. Platform limits

See `docs/PLATFORM_LIMITS.md`. In short: iPhone/iPad browsers can't talk to chamber hardware (no Web Bluetooth/Serial), so they're listeners, remotes, Lab and Forge; hardware control on iOS needs the Capacitor app or a desktop/tablet hub.

## 8. Sources

- Binaural beats systematic review (Ingendoh et al., PLOS ONE 2023): https://pubmed.ncbi.nlm.nih.gov/37205669/ and https://pmc.ncbi.nlm.nih.gov/articles/PMC10198548
- Binaural beats for stress, systematic review of RCTs (2024): https://informahealthcare.com/doi/full/10.1080/18387357.2024.2374759
- Binaural beats and pain, systematic review (BMC 2024): https://doaj.org/article/dfa26072808643c6a6fca754b7c09caa
- Binaural vs monaural beats EEG (Orozco Perez et al.): https://pmc.ncbi.nlm.nih.gov/articles/PMC7082494
- Hemi-Sync trademark and history: https://en.wikipedia.org/wiki/Hemi-Sync
- Faraday quasipatterns (Edwards & Fauve, JFM 1994): https://www.cambridge.org/core/journals/journal-of-fluid-mechanics/article/patterns-and-quasipatterns-in-the-faraday-experiment/8FF2B22DE046BC52D144128237B9C194
- Quasipatterns, 8/10/12-fold (Rucklidge & Silber): https://arxiv.org/pdf/nlin/0610063 and https://arxiv.org/pdf/nlin/0209034
- Faraday waves overview (Univ. of Minnesota): https://www-users.cse.umn.edu/~vinals/research/fwaves/index.html
- Chladni's law: https://en.wikipedia.org/wiki/Chladni%27s_law and https://arxiv.org/pdf/1709.03650
- Photosensitive epilepsy (Epilepsy Society, 2025): https://epilepsysociety.org.uk/sites/default/files/2025-04/PhotosensitiveepilepsyApril2025.pdf
- Web accessibility and seizures (MDN): https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Seizure_disorders
- Visually sensitive seizures review (Epilepsy Foundation, 2022): https://repository.essex.ac.uk/34275/1/Epilepsia%20-%202022%20-%20Fisher%20-%20Visually%20sensitive%20seizures%20An%20updated%20review%20by%20the%20Epilepsy%20Foundation.pdf
- Resonance frequency assessment for HRV biofeedback: https://pmc.ncbi.nlm.nih.gov/articles/PMC7578229
- HRV biofeedback, how and why it works (Lehrer & Gevirtz): https://pmc.ncbi.nlm.nih.gov/articles/PMC4104929
- HRV biofeedback methods review (2023): https://link.springer.com/article/10.1007/s10484-023-09582-6
- HeartMath coherence frequencies study (2025): https://www.heartmath.org/?p=34692
- Coherence ratio method description: https://uhra.herts.ac.uk/id/eprint/15348/1/ARRC_2021_Beyond_HRV_web_material.pdf
- Cyclic sighing RCT (Balban et al., 2023): https://pmc.ncbi.nlm.nih.gov/articles/PMC9873947
- UC San Diego retreat study (2025): https://today.ucsd.edu/story/meditation-retreat-rapidly-reprograms-body-and-mind and disclosure: https://www.eurekalert.org/news-releases/1104876
- Critique of that study: https://edzardernst.com/2025/11/joe-dispenza-and-his-landmark-study-of-dr-joes-week-long-retreat/
- Solfeggio claims fact-check: https://science.feedback.org/review/no-evidence-support-claim-solfeggio-frequencies-remove-toxins-from-body/
- FTC Health Products Compliance Guidance: https://www.ftc.gov/system/files/ftc_gov/pdf/Health-Products-Compliance-Guidance.pdf
- Web Serial support: https://caniuse.com/web-serial · Web Bluetooth support: https://caniuse.com/web-bluetooth
- US Pilates & yoga studios (IBISWorld): https://www.ibisworld.com/united-states/number-of-businesses/pilates-yoga-studios/4185
- Sound therapy market (Coherent Market Insights): https://www.gii.co.jp/report/coh1747273-sound-therapy-market-by-type-by-application-by.html
- Sound healing app market: https://www.giiresearch.com/report/ires1946830-sound-healing-app-market-by-platform-revenue-model.html

These links come from the build spec; they haven't each been re-opened and checked in P0.
