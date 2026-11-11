Build me a Windows desktop application called "Behemoth's Mountain Lion."

=== WHAT IT IS ===
A dual-prompted music generator — a remix AND remake engine that runs on unlimited
files. It takes two separate songs and fuses them into ONE intertwined track. Two
becometh one. The vocals from one song are extracted and then harnessed against the
musical properties of the other song — key, tempo, groove, chord movement, timbre,
energy curve — so the voice from Song A is genuinely performed inside the body of
Song B, not just layered on top of it. Both songs are present in the final piece,
performed together as a single song.

On top of that, it has a prompted-vocal layer: I can type a plain-English vocal
direction (example: "Borat-style vocals for 'I was born in the mountains'") and the
app generates or re-styles the vocal performance to match that direction before it
gets fused into the blend. So the fusion can run three ways:
  1. Song A vocals  +  Song B instrumental/properties
  2. Song B vocals  +  Song A properties
  3. Prompted AI vocals (my typed direction) + the fused bed of both songs

=== THE BARS ===
The main screen is live and reactive. Three bars:

  BAR 1 — SONG A  (search bar: type to search my local library, or paste a file path,
                   or drag a file onto it; live-filters results as I type, shows
                   waveform + detected BPM/key the moment it loads)
  BAR 2 — SONG B  (identical behavior)
  BAR 3 — VOCAL PROMPT (free text: style, accent, character, delivery, lyrics,
                        timestamps — e.g. "Borat-style vocals, verse only, enter at
                        0:42" — optional; leave empty and it uses the real vocals)

Under the bars: a FUSE button, a perspective selector, and a live preview player that
plays the blend before rendering. Everything updates live — change a bar, the preview
re-analyzes.

=== THE FUSION ENGINE (the actual work) ===
Pipeline, run per pair:
  1. Analyze both songs: BPM, key/scale, downbeats, bar grid, song sections
     (intro/verse/chorus/bridge), loudness curve, spectral profile.
  2. Stem-separate both into vocals / drums / bass / other (Demucs).
  3. Decide the host: whichever song supplies the musical body. The other supplies
     the voice. (I can flip this, or let it auto-pick by which has the stronger bed.)
  4. Harness the properties: time-stretch and pitch-shift the donor vocal to the
     host's BPM and key, align its phrases to the host's downbeats and section
     boundaries, match its formants/EQ/reverb space to the host's sonic character so
     it sounds recorded in the same room.
  5. If BAR 3 has a prompt: synthesize or voice-convert the vocal to that direction
     first, then run it through step 4.
  6. Re-weave the beds — don't just mute Song B. Blend both instrumentals: take the
     drums from one, the bass/harmony from the other, cross-fade the "other" stems,
     keep both songs audible and interlocked.
  7. Arrange, mix, auto-gain-stage, master to a consistent LUFS target.
  8. Render to WAV + MP3 at full quality.

=== PERSPECTIVES ===
Every fused pair can be rendered in multiple "perspectives" — different readings of
the same two songs. At minimum:
  - A-on-B (A's voice in B's body)
  - B-on-A (B's voice in A's body)
  - Interwoven (both vocals trading bars/sections)
  - Prompted (BAR 3 vocal over the fused bed)
  - Instrumental fusion (no vocals, both beds married)
  - Slowed / sped / half-time / double-time variants
Each perspective renders as its own file, clearly named.

=== UNLIMITED BATCH ===
A batch mode that takes a whole folder (or two folders) and runs every pairing —
unlimited files, queued, resumable, with progress per job. It never stops at a file
count. If it crashes or I close it, it picks up exactly where it left off.

=== FOLDERS ON MY DESKTOP ===
On first run, create this on my Desktop and own it completely:

  Desktop/Behemoth's Mountain Lion/
    ├── OG Bars/            <- every source song that goes into Bar 1 or Bar 2 gets
    │     ├── A/               copied in here and filed into A–Z subfolders by title,
    │     ├── B/               alphabetically. This is the original library.
    │     └── ... Z/           Auto-tagged, deduped, never modified.
    ├── Remixed/            <- every rendered fusion lands here, in its own subfolder
    │     └── [SongA x SongB]/   named for the pair, with each perspective inside
    │           ├── A-on-B.wav
    │           ├── B-on-A.wav
    │           ├── Interwoven.wav
    │           ├── Prompted.wav
    │           └── recipe.json   <- exact settings used, so it's reproducible
    ├── Stems/              <- cached separated stems so re-renders are instant
    └── Library.db          <- SQLite index: every song, its analysis, every render

The Remixed folder is generated FROM the OG Bars. Second-pass remixing is allowed —
a track in Remixed can be fed back into Bar 1 or Bar 2 to generate further
perspectives, and those nest under their own pair folder so the lineage is traceable.

=== THE SCOUT AGENT (always running) ===
A background agent that runs continuously and scrubs the internet for tools — free
and open-source audio software, separation models, voice-conversion models, vocal
synthesis models, mastering tools, plugins, datasets, new releases. It:
  - maintains a catalog of what it finds, with license, quality notes, and whether
    it's genuinely free
  - flags anything better than what the app currently uses
  - can install and wire in a new backend behind the existing interface without me
    rebuilding anything (pluggable engine adapters — separation, voice conversion,
    synthesis, mastering are all swappable modules)
  - logs everything to a Discoveries panel in the app so I can see what it found and
    approve a swap with one click
It respects robots.txt and rate limits, only pulls from legitimate sources (GitHub,
Hugging Face, project sites), and never auto-installs anything without showing me
first.

=== STACK — FREE AND LOCAL ONLY ===
No paid APIs, no subscriptions, no cloud dependency. Everything runs on my machine.
  - Python 3.11+ backend, PySide6 (Qt) desktop UI — dark theme, big waveforms
  - Demucs for stem separation
  - librosa / essentia / madmom for BPM, key, beat and section detection
  - pyrubberband + FFmpeg for time-stretch, pitch-shift, format handling
  - RVC or so-vits-svc for voice conversion; Coqui XTTS / Bark for prompted vocal
    synthesis from BAR 3
  - pedalboard (Spotify) for EQ, reverb matching, compression
  - matchering for final mastering
  - SQLite for the library index
  - GPU acceleration when available, graceful CPU fallback
Bundle it as a single installer so it runs standalone with no Python setup on my end.

=== UI ===
Dark, heavy, confident — the name is Behemoth's Mountain Lion, make it feel like that.
Three bars stacked at the top, waveforms with detected key/BPM badges, a big FUSE
button, perspective checkboxes, a live preview transport, a batch queue panel, a
Discoveries panel for the scout agent, and a library browser showing the OG Bars A–Z
tree and the Remixed tree side by side.

=== BUILD ORDER ===
1. Folder structure, library index, A–Z filing, and the two search bars working live
2. Analysis (BPM/key/sections) + stem separation + waveform display
3. The fusion engine — one perspective end to end, rendering to the Remixed folder
4. All perspectives + recipe.json + second-pass remixing
5. BAR 3 prompted vocals wired into the pipeline
6. Batch mode, resumable queue
7. The scout agent + pluggable engine adapters + Discoveries panel
8. Installer

Only process audio I own or have the rights to use — add a one-time notice on first
run and keep every render local to my machine.

Start with step 1. Show me the folder structure and the working search bars before
moving on.
