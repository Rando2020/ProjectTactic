# The Appointed · UI Kit

Interactive recreation of the core surfaces of **The Appointed: As Above** — with synthesised audio.

## What's in here

| File | Purpose |
|---|---|
| `index.html` | Entry point. Loads React 18 + Babel-standalone, the audio engine, and mounts `<App />`. |
| `the-appointed.css` | UI-kit styles. Layered on top of root `colors_and_type.css`. |
| `data.jsx` | Fixtures — `THE_SEVEN`, `HUB_LOCATIONS`, `BOSSES`, `TIER_NAMES`, `ABILITIES`, `BATTLE_UNITS`, `TILE_MAP`. Sourced from `/characters.js`, `/hubCharacters.js`, `/bossData.js`. |
| `audio.js` | **Synthesised SFX engine.** Plain JS, no JSX. Web-Audio oscillators + filtered noise + feedback delay tail — no audio files. Exposes `window.Sfx.play(name)`. Eight sounds: `nav`, `select`, `confirm`, `cancel`, `page`, `sacred`, `tick`, `crack`. Mute persists to localStorage. |
| `chrome.jsx` | `<TopRail>` (wordmark, screen nav, mute toggle, tier meter) + `<MuteToggle>`. |
| `Title.jsx` | `<TitleScreen>` — main-menu / title-card. |
| `Antechamber.jsx` | Hub screen. Party rail (costume integrity) · keepers grid · run CTA · selected-character pane · run progress. |
| `Battle.jsx` | Tactical grid + `<CommandMenu>` + `<UnitPane>` + `<ForecastHud>` + `<TurnOrder>`. |
| `Codex.jsx` | Character sheet / lore explorer. Sin → Costume → Virtue. Wound surfaces at Tier 2, Crack Event at Tier 3, Resolution at Tier 5, true name reveals at Tier 4. |
| `Chapter.jsx` | FFT-style loop transition on aged parchment. Aeryn quote shifts with tier. |
| `Dialogue.jsx` | Keeper-dialogue overlay. **Tier 1–3:** dark glass panel. **Tier 4–5:** parchment unfurls (680ms scale-in) with illuminated red drop-capital, brass corners, italic ink line; sacred bell chord on mount. |
| `app.jsx` | `<App>` — screen router + tier state. Sets `#app.tier-N` class so CSS can react. |

## Sound palette

All eight SFX are synthesised on demand from Web Audio primitives. Click the **bell glyph** in the top rail to mute/unmute (persists to localStorage). Browsers block AudioContext before a user gesture, so audio kicks in on the first click.

| Cue | When it plays | Synthesis |
|---|---|---|
| `nav`     | Top-rail nav button | 1.2 kHz triangle pip, 80 ms, high-pass to remove body |
| `select`  | Party card, codex item, "Press further" | C5 + E5 dyad, sine + triangle, 200 ms |
| `confirm` | "Begin Descent" / "Begin First Loop" / "Give a gift" | C-major triad swell, slow attack, ~500 ms |
| `cancel`  | Dialogue "Leave" | 440→220 Hz triangle glide, 200 ms |
| `page`    | Location card click (paper rustle) | Two band-passed noise bursts, 1.8 kHz + 2.6 kHz |
| `sacred`  | Parchment unfurl mount (tier 4+) | E G♯ B D major-7 voicing, staggered attacks, ~1.4 s, lowpass damp + reverb tail |
| `tick`    | Battle command select | Sharp band-passed noise burst at 2.4 kHz Q5, 40 ms |
| `crack`   | Tier-meter pip click (tier shift) | Low sawtooth + filtered noise rumble, 400 ms |

Every cue runs through the master bus's short feedback delay (180 ms, 32% feedback, 2.4 kHz damping) which gives the whole palette its candle-lit hall reverb.

## Interactions to try

- **Bump the tier meter** (top-right pips) from 1 → 5. Each click plays `crack`. Watch:
  - The Antechamber blurb changes per tier.
  - The Threshold / Deep Pool / Dark Corners locations seal/unseal.
  - In the Codex, Wound surfaces at Tier 2+, Crack Event at Tier 3+, Resolution at Tier 5, true name reveals at Tier 4.
- **Click any keeper card** in the Antechamber. Tier 1–3 = dark glass panel + `page` rustle. Tier 4–5 = parchment unfurls + `sacred` bell chord.
- **Chronicle tab** renders the FFT chapter card at the current tier; Aeryn's epigraph rotates with the revelation.
- **Battle screen** demonstrates Aeryn casting *Judgment Stroke* on *Veriel*. Click any command button for `tick`.
- **Tier 5 + Antechamber + click a keeper** = the full sacred composition: parchment scroll, embers drifting, bell chord, antechamber bleeding through behind.

## What's deliberately omitted

- Real turn flow, AI, save state — this is a UI kit, not a runnable game.
- Item / inventory / job-tree screens — out of scope; sketch from the same primitives if needed.
- All character art is rendered as initial-glyph portraits because the upstream `assets/` folder contains only 128-byte stub placeholders. When real art arrives, swap the portrait initials for `<img>`.

## How to extend

Reusable utility classes (all defined in `the-appointed.css` or `colors_and_type.css`):

- `.btn` / `.btn-sacred` / `.btn-crimson` / `.btn-ghost` / `.parchment-btn` (+ `.primary`)
- `.chip` (+ `.gold` / `.crimson` / `.violet` / `.envy`)
- `.bar-track` / `.bar-fill` (+ `.tmp`, `.eth`)
- `.parchment` (turns any container into an aged page with brass corners — drop `.scroll-unfurl` for the 680ms animation)
- `.scene` / `.scene-sacred` (dark glass overlay vs sacred parchment composition)
- `.eyebrow` / `.label` / `.copy` / `.scripture` / `.sacred` / `.true-name` / `.rubric` / `.ink` / `.brass`
- `.ember` (gold rising speck — see Dialogue.jsx for the tier-5 swarm)

For audio in your own components: `window.Sfx?.play('confirm')`. The `?.` matters because audio.js loads as a regular script and may not be defined in test environments.

Always layer ON TOP of `colors_and_type.css` — never invent new color or font tokens locally.
