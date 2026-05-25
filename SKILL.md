---
name: the-appointed-design
description: Use this skill to generate well-branded interfaces and assets for The Appointed — a theological tactics / roguelike RPG with stone-and-iron aesthetics, sacred gold accents, sin-colored characters, and a 5-tier revelation system that shifts the UI's color temperature and weight as the player advances. Use for production-leaning mocks, throwaway prototypes, marketing pages, codex layouts, or any artifact that needs to feel like The Appointed: As Above.
user-invocable: true
---

# The Appointed · Design Skill

Read `README.md` first — it covers the world, the seven characters, the tier system, content tone, and visual foundations. Then explore:

- **`colors_and_type.css`** — the single source of truth for color and type tokens. Import this from anywhere; do not redeclare or invent new tokens locally.
- **`preview/`** — small HTML cards demonstrating every color group, type specimen, spacing rule, and component pattern in context.
- **`ui_kits/the-appointed/`** — interactive recreation of the four core surfaces (Antechamber, Battle, Codex, Dialogue). The CSS file there is the canonical example of how to layer UI-specific styles on top of the foundation.
- **`assets/`** — logos, icons, and other visual assets (see `assets/README.md`).
- **`fonts/README.md`** — what families are loaded and from where.
- **`characters.js` / `hubCharacters.js` / `bossData.js` / `narrativeReducer.js` / `src/`** — original game data and React reference components, imported from the source repo. Mine these for character names, true names, dialogue cadence, sin/virtue/costume mappings, costume integrity rules, boss talk-path requirements, and revelation-tier thresholds.

## When invoked

If the user asks for visual artifacts (slides, throwaway mocks, codex prototypes, screen recreations), build static HTML and copy assets out of `assets/` rather than referencing them by URL. Reuse `colors_and_type.css` verbatim — `@import` it from the artifact, then add component-level styles on top.

If the user is working on production code (the Godot game under `godot/`, the React reference under `src/`, or any new surface), apply the rules in `README.md`'s CONTENT FUNDAMENTALS and VISUAL FOUNDATIONS sections directly. Quote the tier-color-shift principle and the sin-color assignments back at the user when ambiguity arises — those are the load-bearing pieces of the system.

If the user invokes this skill with no other guidance, ask what they want to build or design, ask focused questions (which screen? which tier? whose arc?), and act as an expert designer who outputs HTML artifacts *or* production code, depending on the need.

## Principles to honor

1. **Stone and iron.** Sharp edges. No rounded corners on structural elements (cards, panels, buttons, frames). Reserve corner rounding for chips / tiny pills only, ≤ 2px.
2. **The tier system runs everything.** Tier 1 = tactical, cold, distant. Tier 5 = transcendent, near-white, breathing. Color temperature, typography weight, and even motion duration shift upward across the ramp.
3. **Sacred glow is rare.** A gold halo is a *moment* — true-name reveal, resolution, the run-begin button, the dialogue line of a keeper. Don't decorate with it.
4. **The sin is never attacked directly.** Mirror it. Costume integrity is a metaphor about the character seeing themselves, not a "weak point" the player exploits. Copy and UI should reflect that.
5. **Restraint with iconography.** The brand has no icon set yet. Use initial-glyph portraits, hairline rules, and typography. Don't generate SVG icons — request real assets, or use a CDN substitute and flag it.
