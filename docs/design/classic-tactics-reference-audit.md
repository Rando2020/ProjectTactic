# Classic Tactics Reference Audit

This document evaluates the current ProjectTactic repo against the presentation and systems expectations of a premium classic tactical RPG. The goal is to become strongly inspired by the design language of genre-defining tactical RPGs without copying proprietary files, sprites, maps, music, UI, scripts, names, animations, or data.

## Legal and creative boundary

ProjectTactic should not import or reuse Final Fantasy Tactics files, ripped assets, map data, audio, fonts, scripts, sprites, UI textures, portraits, or proprietary extracted data.

Acceptable references:

- Grid-based tactical combat readability
- Isometric camera language
- Pre-battle formation flow
- Job unlock philosophy
- Command menu pacing
- Turn order timeline clarity
- Height, facing, elevation, and terrain advantage concepts
- Ornate medieval manuscript-inspired UI mood
- Compact character sheets and job progression readability

Not acceptable:

- Direct use of Square Enix assets or files
- Recreated FFT maps tile-for-tile
- Copied class names, ability names, formulas, or scripts
- Extracted animation frames or sound effects
- UI panels traced from screenshots

## Current repo strengths

| Area | Current state | Evaluation |
|---|---|---|
| Browser-first architecture | React + Vite shell is present | Strong foundation |
| Screen flow | Menu, world map, town, battle, results, character sheet, job tree | Correct game-scale skeleton |
| Data separation | Maps, terrain, units, story, missions, progression data live under `src/game/data/` | Good direction |
| Job progression | Character level, JP, job levels, unlock requirements, ascended jobs | Good systems foundation |
| Pre-battle metadata | Maps include deployment zones, max party size, required and recommended units | Good data foundation |
| Battle command menu | Move, Attack, Ability, Item, Wait exist as commands | Correct tactical RPG vocabulary |
| Save/load | Local save system exists | Good prototype need |

## Core issue

The repo is architecturally moving toward a tactics RPG, but visually and experientially it still reads like a web app prototype.

The current battle grid uses flat rectangular HTML buttons, coordinate labels, simple color blocks, and symbol-based units. That is useful for debugging, but it does not yet communicate the emotional feel of a classic tactical RPG battlefield.

## Gap analysis

### 1. Camera and battlefield presentation

Current state:

- Top-down rectangular grid
- Flat terrain colors
- Height shown as text
- No camera angle or tile depth illusion

Target direction:

- Isometric or pseudo-isometric tactical board
- Diamond tiles with visible height faces
- Tile shadows and height bands
- Terrain art registry connected to tile types
- Optional debug overlay for coordinates and height

Priority: Critical

Recommended implementation:

- Add `IsoTacticalGrid.jsx` as a production-facing battlefield view.
- Preserve `TacticalGrid.jsx` as a debug grid.
- Add a view toggle: Tactical View / Debug View.
- Represent each tile with CSS transform or SVG diamond geometry before committing to full pixel art.

### 2. Pre-battle formation

Current state:

- Map data already includes deployment zones.
- Battle screen currently starts units directly from `playerSpawns`.

Target direction:

- Dedicated deployment screen before battle.
- Party roster on one side.
- Map preview with allowed deployment tiles.
- Unit placement, facing selection, and confirm battle.
- Required units locked into party.

Priority: Critical

Recommended implementation:

- Add `DeploymentScreen.jsx`.
- Add `deploymentReducer.js` or `deploymentSystem.js`.
- Store selected party and tile placement in battle initialization state.
- Support required and optional slots.

### 3. Command menu and action pacing

Current state:

- Command menu exists.
- Move and attack work in a basic way.
- Ability targeting is placeholder.

Target direction:

- Phase-based input: Select Unit → Command → Target → Preview → Confirm → Resolve → Facing → Wait.
- Each action should have a preview before execution.
- Player should see damage, hit chance, armor impact, status chance, JP reward estimate, and counter risk.

Priority: Critical

Recommended implementation:

- Add `battlePhase` state machine.
- Add `ActionPreviewPanel.jsx`.
- Add `combatPreview.js` system.
- Add facing selection after action or wait.

### 4. CT turn order and timeline

Current state:

- Units have `acted` flags.
- There is no proper CT, speed, wait time, or timeline UI.

Target direction:

- CT-based initiative loop.
- Speed determines CT gain.
- Acting consumes CT.
- Wait and movement choices affect next turn timing.
- Timeline visible in sidebar.

Priority: Critical

Recommended implementation:

- Add `turnOrderSystem.js`.
- Add `TurnTimeline.jsx`.
- Replace per-round acted flags with CT thresholds.
- Support statuses that modify CT gain later.

### 5. Job system usability

Current state:

- Strong progression data exists.
- Jobs have unlock requirements and ascended paths.

Target direction:

- Job tree should feel like a progression board, not a card list.
- Show base, advanced, and ascended paths clearly.
- Show missing requirements inline.
- Show learned abilities by job level.
- Support equipping current job and previewing stat deltas.

Priority: High

Recommended implementation:

- Add `jobAbilities.js`.
- Add `JobTreeGraph.jsx`.
- Add `JobDetailPanel.jsx`.
- Add `equipJob(characterId, jobId)` reducer action.

### 6. Character and sprite presentation

Current state:

- Units render as text/symbols.
- Character data exists, but visual identity is not yet strong.

Target direction:

- Placeholder original sprites with consistent scale.
- Directional idle frames: N, S, E, W.
- Battlefield facing indicators.
- Portraits in character sheets and deployment menu.
- Distinct silhouettes by job type.

Priority: High

Recommended implementation:

- Add `assetRegistry.js`.
- Add original placeholder sprite manifests.
- Generate legally safe original sprite sheets.
- Add fallback silhouettes for missing assets.

### 7. UI art direction

Current state:

- UI uses modern rounded cards, gradients, and pill buttons.
- This is readable but not genre-authentic.

Target direction:

- Dark parchment, carved stone, antique gold, muted ink, wax seal accents.
- Square or beveled panels rather than SaaS-style cards.
- Compact serif headings, readable sans/body fallback.
- Ornamentation should support clarity, not overwhelm it.

Priority: High

Recommended implementation:

- Add design tokens in `gameShell.css`.
- Add reusable `TacticsPanel`, `TacticsButton`, `TacticsStatBar`, `TacticsBadge` components.
- Replace global button styles with scoped game UI components.

### 8. Terrain and map design

Current state:

- Maps have terrain and height.
- Maps are small and readable but not yet tactical puzzles.

Target direction:

- Each map needs an identity and tactical problem.
- Terrain should create decisions: choke points, elevation, water risk, flank lanes, cover, hazards.
- Deployment zones should create strategic tradeoffs.

Priority: High

Recommended implementation:

- Add map design schema: objective, pressure source, enemy plan, terrain hook, deployment dilemma.
- Add at least three larger maps: road ambush, marsh reactor, ruined keep.
- Add enemy intent metadata.

### 9. Enemy AI intent

Current state:

- Enemy units exist, but AI behavior is not meaningful yet.

Target direction:

- Preview enemy intent before enemy turn.
- Enemy archetypes: striker, archer, caster, bruiser, healer, disruptor.
- AI should prioritize reachable kills, exposed casters, objectives, and terrain combos.

Priority: High

Recommended implementation:

- Add `enemyAiSystem.js`.
- Add `IntentPreview.jsx`.
- Add `enemyArchetypes.js`.

### 10. Battle result flow

Current state:

- Claim Victory button exists once objective is complete.
- Rewards are applied through the progression reducer.

Target direction:

- Post-battle results with EXP, JP, job level-ups, loot, flags, story unlocks.
- Character-by-character progression reveal.
- New job unlocked callout.

Priority: Medium

Recommended implementation:

- Expand `ResultsScreen.jsx`.
- Add reward breakdown models.
- Add unlock banners.

## Recommended next implementation sequence

### Phase 1: Make it look like a tactics game

1. Add pseudo-isometric battlefield renderer.
2. Add tactics-style UI components and visual tokens.
3. Add asset registry and placeholder sprite support.
4. Add deployment screen using existing deployment data.

### Phase 2: Make it play like a tactics game

1. Add battle phase state machine.
2. Add movement range pathfinding.
3. Add attack/ability preview.
4. Add facing selection.
5. Add CT turn order timeline.

### Phase 3: Make progression feel addictive

1. Add job abilities by level.
2. Add job equip flow.
3. Add job unlock reveal screen.
4. Add results screen progression reveals.

### Phase 4: Make it modern 2026

1. Enemy intent preview.
2. Damage forecast and counter risk.
3. Accessibility toggles.
4. Controller-friendly command flow.
5. Speed controls and animation skip.
6. Save slots and quick resume.
7. Codex/tutorial overlays.

## Asset direction

Use original placeholder assets that evoke the design grammar of classic tactical RPGs without copying.

Recommended original asset set:

| Asset set | Needed now | Notes |
|---|---:|---|
| Terrain tiles | Yes | Grass, road, stone, water, shrine, wall, high ground |
| Unit sprites | Yes | 4-direction idle placeholders for each starting unit and enemy |
| UI panels | Yes | Dark parchment, antique gold, stone trim |
| Portraits | Soon | Character sheets and deployment menu |
| Ability VFX | Soon | Use original elemental cast/hit/dissipate frames |
| Icons | Yes | Move, attack, ability, item, wait, facing, height |

## Best practice vs pragmatic workaround

### Best practice

Build a true isometric renderer, asset atlas, animation controller, CT scheduler, and command state machine.

### Pragmatic workaround

Use CSS/SVG pseudo-isometric tiles, emoji-free silhouettes, and a data-backed deployment screen first. This gets the game looking much closer without blocking on final art or engine-level rendering.

## Acceptance criteria for the next PR

The next implementation PR should be considered successful if:

- Battle no longer looks like a plain web grid.
- Units have visual identity beyond text labels.
- Deployment happens before battle start.
- Command flow has a visible phase and preview step.
- Debug coordinates can be toggled off.
- UI panels feel like fantasy tactics UI, not SaaS cards.
- No copyrighted files are imported.

## Blunt assessment

ProjectTactic has the bones of a tactical RPG, but not the body language yet. The repo says tactics. The screen still says prototype dashboard. The fastest credibility jump is visual and interaction architecture, not more lore or more job names.

## Next best action

Create an implementation branch for `feature/tactics-presentation-layer` and build:

1. `IsoTacticalGrid.jsx`
2. `DeploymentScreen.jsx`
3. `TacticsPanel.jsx`
4. `assetRegistry.js`
5. `battlePhaseSystem.js`
6. `combatPreview.js`
7. updated `gameShell.css` tokens

This should be done before generating large numbers of assets, because the renderer and registry need to define asset size, naming, facing, and animation expectations.
