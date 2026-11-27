# FLOWSMITH data files

All content lives in plain JSON so it can be checked by `node tests/validate-data.mjs`
and edited without touching code. Text is plain text (no HTML, no Markdown); the app
renders it with `textContent`. Use straight quotes, UTF-8, and keep ids lowercase
`a-z0-9-` and unique within their file.

Prompt fragments (`prompt` fields) are written for **Google Flow Music (Lyria 3.5)**:

- Describe what you WANT. Lyria has no negative prompts, so never write "no X" or "without X"
  in a fragment. (The one allowed phrase is "instrumental" for no vocals.)
- No artist, band, producer or song names, no trademarked song titles. Describe the sound
  instead ("dusty SP-1200 drums" is fine: gear names are allowed; "like J Dilla" is not).
- Fragments are lowercase-first noun phrases that read well after a comma, e.g.
  `"punchy TR-808 kick with a long, tuned sub tail"`. 4 to 25 words.
- Concrete beats vague: name the instrument, its tone, its role and how it is played.

## chips-*.json (Studio buttons and Library cards)

```json
{
  "chips": [
    {
      "id": "dr-tr808",
      "cat": "drums",
      "group": "Drum machines",
      "label": "TR-808",
      "prompt": "Roland TR-808 drum machine: booming tuned kick, snappy snare, crisp closed hats and handclaps",
      "desc": "1980 analog drum machine. The sound of hip-hop, trap, Miami bass and electro. Its kick doubles as a sub bass.",
      "bpm": [70, 150],
      "pairs": ["ba-808-sub", "g-trap"]
    }
  ]
}
```

| field | required | notes |
|---|---|---|
| id | yes | prefix by category: `g-` genre, `er-` era, `mo-` mood, `en-` energy, `gr-` groove, `ke-` key/scale, `dr-` drums, `ba-` bass, `sy-` synths, `kb-` keys, `gt-` guitars, `or-` orchestral, `wo-` world, `vo-` vocals, `st-` structure, `pr-` production, `tu-` tuning, `us-` use case |
| cat | yes | one of the category ids below |
| group | yes | sub-heading inside the category (e.g. "Hip-hop", "Drum machines") |
| label | yes | button text, 1 to 4 words |
| prompt | yes | the fragment inserted into the Flow prompt |
| desc | yes | 1 to 3 plain sentences: what it is / what it sounds like / where it's used |
| bpm | no | `[min, max]` typical tempo, integers 40 to 220 |
| pairs | no | up to 6 ids of chips that go well with it (may point into other chips files) |

Category ids and where they land in Google's prompt order
(genre & style, then mood, instruments, tempo & rhythm, vocals, then structure/mix):

| cat | label | slot |
|---|---|---|
| genre | Genre & style | genre |
| era | Era | genre |
| mood | Mood | mood |
| energy | Energy | mood |
| groove | Groove & rhythm | tempo |
| key | Key, scale & mode | tempo |
| drums | Drums & percussion | instruments |
| bass | Bass | instruments |
| synths | Synths | instruments |
| keys | Keys & piano | instruments |
| guitars | Guitars | instruments |
| orchestral | Strings, brass, winds & choir | instruments |
| world | World instruments | instruments |
| vocals | Vocals | vocals |
| structure | Song structure | structure |
| production | Production & mix | production |
| tuning | Tunings | instruments |
| usecase | Use it for | genre |

## beats.json (drum patterns, shown as step grids)

```json
{
  "patterns": [
    {
      "id": "bt-boom-bap",
      "name": "Boom bap",
      "genre": "Hip-hop",
      "bpm": [84, 96],
      "timeSig": "4/4",
      "steps": 16,
      "swing": 58,
      "lanes": [
        { "inst": "Kick",  "hits": "x.....x...x....." },
        { "inst": "Snare", "hits": "....x.......x..." },
        { "inst": "Hat",   "hits": "x.x.x.x.x.x.x.x." }
      ],
      "desc": "Kick on 1 and the 'and' of 2/3, hard snare on 2 and 4, swung eighth hats.",
      "prompt": "boom bap drum groove: heavy kick, cracking snare on 2 and 4, swung eighth-note hats, about 90 BPM"
    }
  ]
}
```

`hits` is a string of exactly `steps` characters: `x` hit, `X` accent, `o` ghost/soft, `.` rest.
`swing` is 50 (straight) to 75 (heavy). `steps` is 12, 16 or 32 (12 for 6/8 and 12/8).

## recipes.json (ready-made prompts)

```json
{
  "recipes": [
    { "id": "rc-lofi-study", "title": "Lo-fi study beat", "genre": "Lo-fi hip-hop",
      "bpm": 80, "key": "F major", "vocals": false,
      "prompt": "full Flow Music prompt, 40 to 110 words, Google's order",
      "lyricsHint": "", "tags": ["chill","study"], "why": "one sentence: why it works" }
  ],
  "tunings": [
    { "id": "tn-drop-d", "label": "Drop D", "instrument": "Guitar", "notes": "D A D G B E",
      "prompt": "fragment", "desc": "1 to 2 sentences, genres that use it" }
  ],
  "edits": [
    { "id": "ed-extend-outro", "mode": "extend", "label": "Extend with an outro",
      "template": "text with {placeholders} the app fills or the user edits",
      "example": "filled-in example", "when": "one sentence" }
  ]
}
```

`mode` is one of `new`, `compose`, `extend`, `cover`, `replace`, `stems`, `lyrics`.

## learn.json (lessons)

```json
{
  "sections": [
    { "id": "theory", "title": "Music theory", "articles": [
      { "id": "th-intervals", "title": "Intervals", "summary": "one sentence",
        "body": [
          { "type": "p", "text": "..." },
          { "type": "h", "text": "Subheading" },
          { "type": "list", "items": ["...", "..."] },
          { "type": "table", "head": ["Interval", "Semitones", "Feel"], "rows": [["Minor 3rd", "3", "sad, dark"]] },
          { "type": "tip", "text": "Flow Music tip: ..." },
          { "type": "prompt", "text": "a copyable Flow Music prompt fragment" }
        ] }
    ] }
  ]
}
```
