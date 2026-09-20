# The Appointed · Design System

## Godot-First Implementation Rule

The playable game is now implemented in `godot/`.

The React/JavaScript code under `src/`, `archive_react/`, and `VaeltharChronicles.jsx` is reference material only unless the user explicitly asks for React work. New gameplay, UI screens, run systems, combat systems, and content integration should be built in Godot/GDScript.

Agents should read `CLAUDE.md`, `ARCHITECTURE.md`, `AI_TASK_PACKETS.md`, and `docs/systems/js-to-godot-migration-backlog.md` before starting implementation work.

> *Seven angels, assigned to embody the seven deadly sins,
> administer the trials of Purgatory — while being refined by those same trials.
> They don't know what they are yet.*
> *The loop isn't punishment. It is the curriculum.*

A complete design system for **The Appointed: As Above** — a theological tactics / roguelike RPG inspired by *Final Fantasy Tactics* but darker, with a costume-integrity narrative engine and a five-tier revelation system that bends the entire game's tone as the player advances.

This repo is a designer's reference: foundations (color, type, spacing), high-level guidance (content, visual, iconography), preview cards for every token group, and an interactive React UI kit that recreates the four core surfaces (Antechamber, Battle, Codex, Dialogue).

## Sources

- **Game codebase (read-only reference):** [github.com/Rando2020/ProjectTactic](https://github.com/Rando2020/ProjectTactic) — particularly the `src/game/` React reference build (the production target is now a Godot port under `godot/`, per `ARCHITECTURE.md`). Reading the source repo will give a richer design picture than this distillation; the `characters.js`, `hubCharacters.js`, `bossData.js`, and `narrativeReducer.js` files in particular are worth study before designing major surfaces.
- **Local mirrors of the most relevant repo files** sit at the root: `characters.js`, `hubCharacters.js`, `narrativeReducer.js`, `narrativeState.js`, `bossData.js`, `AGENTS.md`. The React reference component tree lives under `src/game/` (components, screens, styles).
- **Direction notes provided with the brief** were the source of truth for the brand intent — the React reference uses Inter and rounded corners, which contradicts the stated direction (Cinzel / Crimson Text / no rounding). This system follows the **stated brand intent**, not the legacy React styling.

## Index

| File / folder | What it is |
|---|---|
| **`README.md`** | This document. Read top-to-bottom for full system context. |
| **`SKILL.md`** | Agent-Skill manifest. Drop this folder into Claude Code's `~/.claude/skills/` to use it as an invocable skill. |
| **`colors_and_type.css`** | Single source of truth for all CSS variables. `@import` from any artifact. |
| **`fonts/README.md`** | Webfont families, sources, and substitution flags. |
| **`assets/README.md`** | Folder layout for game art + flagged asks for the user. **(Upstream assets are unpopulated stubs — see this file.)** |
| **`preview/`** | One HTML card per token group / component cluster. Used by the Design System tab. |
| **`ui_kits/the-appointed/`** | Interactive React recreation of the Antechamber, Battle, Codex, and Dialogue screens. |
| **`src/game/`** | Mirrored React reference components from the source repo. Treat as *reference for layout/data shape*, not visual truth. |
| **`characters.js`, `hubCharacters.js`, `bossData.js`, `narrativeReducer.js`, `narrativeState.js`, `AGENTS.md`** | Mirrored game-data files from the source repo. |

---

## CONTENT FUNDAMENTALS

### Tone

**Quiet, considered, theological — never preachy.** The game asks more than it tells. Copy should leave space; the reader does the meeting-in-the-middle. Long sentences are fine when they earn it. Many of the best lines in the source are 4–8 words.

Three reference voices from `characters.js` / `hubCharacters.js`:

> "The objective is clear. I don't understand why the others hesitate." — Aeryn, Tier 1

> "There was a moment in the last battle… one of them stopped. Just stopped. And looked at me. I don't know what I saw in its face." — Aeryn, Tier 2

> "It was never about whether I was right enough. I understand that now." — Aeryn, Tier 5

The same character. The same costume. Three tiers of self-recognition. UI copy should echo this arc — early-tier text is procedural, late-tier text is interior and italic.

### Casing & punctuation

- **Screen titles, eyebrows, button labels, menu items, status chips**: **UPPERCASE**, tracked (`letter-spacing: 0.18em+`). Cinzel does the heavy lifting here.
- **Body, dialogue, codex prose**: **Sentence case**, italic for spoken thought.
- **Numerics**: tabular lining figures (mono). HP and TMP always shown as `current / max`.
- **Em dashes** liberally — like this — for asides. Not en dashes, not hyphens.
- **No exclamation points** outside the reactive combat popups (`Shatter!`, `Freeze!`). Sacred and somber outside of combat.
- **Curly quotes** in dialogue. `"like this"`. Combat HUDs are fine with straight quotes.

### Voice

- **I / you / they** — first and second person carry weight. Characters speak in **first person** about themselves. The narrator (mostly absent) uses **second person sparingly** and only at tier-shift moments. Avoid "we".
- **No emoji.** Anywhere. There is one exception: the combat-event popups (`❄️ Freeze!`, `⚡ Electrify!`) inherited from the source repo's reaction system. Don't extend the emoji set into UI chrome.
- **No unicode dingbats** in chrome (`★`, `▶`, `→`). Use Cinzel arrow glyphs (`⟶`) only inside sacred contexts.
- **No marketing softeners.** No "delightful," no "powerful," no "amazing." If a UI string would feel at home on a SaaS landing page, rewrite it.

### Naming

- **Characters have two names**: a human name (revealed at run 1) and a true name (revealed at Tier 4). Until Tier 4, render the true name as `— unrevealed —` in italic ash. After, as `LUCIEL` in `.true-name` (Cinzel Decorative, sacred-gold glow).
- **Tiers are named, not numbered, when sacred:** "The War," "The Cracks," "The Fallen," "The Pattern," "The Ascent." Use `Tier 3 · The Fallen` when both registers are wanted.
- **Sins are capitalized as proper nouns:** Pride, Envy, Wrath. So are Virtues: Dignity, Justice. The Costume names (Righteousness, Holy Zeal) are also capitalized — they are stylized titles, not common nouns.

### Vibe in one paragraph

The Appointed is a game about people who built reasonable, holy-looking structures around the parts of themselves they couldn't bear to look at, and who are slowly being asked to see what those structures cost. The UI should be the architecture that holds that question: ironwork, candlelight, parchment text, brass accents — never decorated, never warm in a friendly way. Warmth here is *candle-warmth*, not friendly-warmth. Gold means something — use it like grace, sparingly.

---

## VISUAL FOUNDATIONS

### Color

- **Base palette** is two cold-warm pairs split by location: **Hub** (`#08090d → #c8a96e → #f0e8d0`) for the Antechamber, and **Mountain** (`#070a0f → #8fa3b8 → #c8dde8`) for the climb. See `preview/colors-hub.html`, `preview/colors-mountain.html`.
- **Each of The Seven owns one sin color** (`--pride-gold`, `--envy-verdigris`, `--wrath-crimson`, `--sloth-dusk`, `--greed-amber`, `--gluttony-ash`, `--lust-ivory`). These are the *only* legal accent colors when referring to that character — portraits, name labels, dialogue chrome, ability tints. See `preview/colors-seven-sins.html`.
- **A 5-step revelation ramp** (`--tier-1` cold-blue → `--tier-5` near-white) shifts the entire app's accent color as the player advances. Bind to a body-level class (`#app.tier-N`) — the existing UI kit reads this and recolors the tier badge, scene backgrounds, and breathing animation. See `preview/colors-tier-ramp.html` and `preview/tier-frames.html` for the same panel rendered at three tiers.
- **Sacred-gold (`#d4af37`) and crimson (`#9b2335`) are signals**, not decoration. Reserve gold for revelation, the run-begin CTA, true names, and keeper-dialogue speaker labels. Reserve crimson for danger, boss encounters, and sin-forward moments. See `preview/colors-sacred-danger.html`.
- **Combat semantic colors** (`--hp` muted green, `--tmp` burnt copper, `--eth` bruised violet) are deliberately *not* saturated. We are not painting Christmas lights. See `preview/colors-combat.html`.

### Type

- **Display & headers**: Cinzel Decorative (display) / Cinzel (header). UPPERCASE with tracked letter-spacing 0.04–0.32em — the spacing grows as the type shrinks. See `preview/type-display.html`, `preview/type-headers.html`.
- **Body**: Crimson Text at 17px / 1.55. Italic for spoken thought and flavor. See `preview/type-body.html`.
- **UI**: Cormorant Garamond at 13px for fine labels and inline meta.
- **Mono**: JetBrains Mono for numerics (HP, percentages, IDs) — tabular lining figures.
- **Sacred / scripture / true-name**: special classes (`.sacred`, `.scripture`, `.true-name`) for revelation moments — these are the *only* place sacred-gold glow appears on text. See `preview/type-sacred.html`.

### Backgrounds

- The base is `#08090d` — almost black, slightly warm. Never pure black.
- On top of base, two near-invisible textures: a 0.012-alpha 1px horizontal-rule pattern (parchment grain) and a low-opacity radial gradient anchored to one corner (gold from top-right at Tier 1–2; crimson from bottom-left at Tier 3). Both should mix-blend-overlay over the surface — never sit above content.
- **No full-bleed photographic backgrounds yet** — assets aren't available. The UI kit uses radial gradients to suggest space (candle pools, distant mist). When real environment art arrives, drop it in `assets/environments/` and use it as a fixed-position background-image at 6–12% opacity.

### Animation

- **Slow, candlelit.** Default duration is `240ms`; quick interactions `140ms`; sacred transitions (tier shifts, true-name reveal) `560ms`; Tier 4–5 "breathing" overlays `1400ms+`.
- **Easing**: `cubic-bezier(.4,.0,.2,1)` for stone (default), `cubic-bezier(.65,0,.35,1)` for breath (sacred). No bounces. No springs. The world does not spring.
- **Keyframe inventory**: one `breathe` (opacity 0.6 → 1 → 0.6) used by the Tier 5 overlay. That's it — resist adding more.

### Hover / press / focus

- **Hover**: border color shifts to `--hub-warm` and content brightens by ~15%. No background scaling. No shadow change.
- **Press**: `transform: translateY(1px)`. Reserve for buttons, never panels.
- **Focus**: outline `2px solid var(--sacred-gold)` with `outline-offset: 2px`. Visible for keyboard navigation; never hidden.
- **Disabled**: opacity 0.45, no border, cursor not-allowed, color shifts to `--fg-4`.

### Borders

- **`--border-thin`** (1px, brass 18%): the workhorse. Hairline separators, default panel borders.
- **`--border-iron`** (1px, `#2a2520`): structural panels — feels heavier, anchors layout.
- **`--border-sacred`** (1px, brass 55%) + 4px black halo offset: reserved for the run-begin CTA, dialogue boxes, the sacred frame. Combine with `--glow-sacred` only at Tier 4+.
- **`--border-double`** (3px double brass): used once or twice per screen at most, for tier-shift modal moments.
- See `preview/borders.html`.

### Shadows

- **No drop shadows.** This is a stone-and-iron world; nothing floats above a surface.
- Depth comes from **interior shadows** (`--inset-deep`, `--shadow-recess`) and **glows** (`--glow-sacred`, `--glow-crimson`, `--glow-violet`).
- The `--glow-sacred` halo is **the** revelation signal. Use it on Tier 4–5 panels, the run-begin button, true-name reveals — nowhere else. See `preview/shadows-glows.html`.

### Transparency & blur

- Used **only** for the full-screen dialogue overlay (`.scene`) and the floor-level forecast HUD. Both use `backdrop-filter: blur(8px)` over a 78%-opacity surface. Everywhere else is solid.
- **Glass surfaces never overlap chrome.** A modal sits on top of everything; a glass HUD is its own row. Don't layer glass on glass.

### Corners

- **No rounded corners on structural elements** (cards, panels, buttons, frames). This is the single most identifying brand rule. The world is iron and stone.
- Chips and tiny pills may use up to 2px. The few places that violate this in the React reference repo (`vaelthar.css`'s 28px-radius cards) are legacy — they do **not** match the brand direction.

### Cards (what they look like)

- 1px iron border, square corners
- `--surface-1` background (warm-tinted near-black)
- `--inset-deep` interior shadow
- 20px internal padding
- Optional `0 8px 32px rgba(0,0,0,0.4)` outer for floating sidebars
- A sacred variant adds `--line-hot` border + `0 0 32px rgba(212,175,55,0.18)` halo

### Layout rules

- **Top rail is fixed at 60–66px** with sticky position. Always shows the wordmark (left), screen nav (center-left), and the tier meter (right). Nothing else lives there.
- **Three-column layouts** dominate the hub-style screens: 280px rail / fluid main / 320px meta-col, 18px gutters.
- **Battle is 1fr / 320px** with the forecast HUD pinned to the bottom edge.
- **Codex is 260px nav / fluid detail.**
- Content max-widths: 64ch for body, 56ch for blurb, 44ch for dialogue lines.

### Color vibe of imagery

When real art arrives, target:

- **Warm-cool split.** Hub interiors are candlelit warm. Mountain exteriors are cold mist. The two should *never* be cross-tinted.
- **Low saturation.** Think *Dark Souls* concept art or *Disco Elysium* — desaturated, painterly, never garish. Saturation rises only in sacred / Tier 5 moments.
- **Grain.** Subtle film grain on everything. The existing CSS grain layer is a placeholder for this.
- **No HDR-pop highlights.** The brightest point in any frame should be candlelight, not chrome.

---

## ICONOGRAPHY

**There is no icon set yet.** The source repo's `assets/ui/` and `src/assets/icons/` are populated with 128-byte stub placeholders, not real assets. Neither a custom icon font nor a chosen SVG library is committed anywhere in the codebase. So this system makes no assumptions and uses no icons.

### Current approach

- **Initial-glyph portraits.** Characters render as a single uppercase letter in Cinzel Decorative inside a sin-colored bordered tile. This is a deliberate placeholder — see `assets/README.md` for what we're missing.
- **Combat reaction emoji** (`❄️ Freeze`, `⚡ Electrify`, `💥 Shatter`, etc.) are kept where they exist in the source repo's reaction system (`BattleScreen.jsx`'s `REACTION_EFFECTS`). Do not extend the emoji set elsewhere in the UI.
- **Cinzel arrow glyphs** (`⟶`) used in the Codex's Sin → Costume → Virtue display. That's the only typographic glyph used as a UI symbol.
- **Hairline rules** with the `.divider` class (`linear-gradient(transparent, var(--line-hot), transparent)`) substitute for separator icons.

### When you need an icon and don't have one

1. **Ask the user first.** A real asset is always better than a fake one.
2. **If you must ship an interim:** use [**Tabler Icons**](https://tabler-icons.io/) via CDN, recolored to brass (`color: var(--hub-warm)`) at 1.25–1.5 stroke. The stroked-and-filled set fits the iron aesthetic; the line-only set does not. **Flag the substitution explicitly to the user.**
3. **Never** auto-generate SVG icons. Never use emoji, geometric unicode, or dingbats outside the locations listed above.

### When you eventually have icons

Drop them in `assets/ui/icons/` named per the source repo's convention (`command-attack-icon.png` etc). Reference via CSS background-image or `<img>` — never inline-SVG them unless the icon needs to take a CSS color via `currentColor`.

---

## See also

- **[`SKILL.md`](./SKILL.md)** — Agent-Skill manifest. Read this if you're an agent looking at how to invoke this system.
- **[`ui_kits/the-appointed/README.md`](./ui_kits/the-appointed/README.md)** — UI kit anatomy and extension guide.
- **[Source repo](https://github.com/Rando2020/ProjectTactic)** — the codebase this system is built from. Worth exploring further, especially `characters.js` and `narrativeReducer.js`.
