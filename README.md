# ProjectTactic: Vaelthar, Eidolon Chronicles

ProjectTactic is a tactical RPG prototype inspired by classic isometric tactics games, darker grounded fantasy, character-job progression, elemental terrain reactions, Guardian resonance, and roguelite run structure.

The project currently has two implementation tracks:

1. **Browser prototype, primary path**: React + Vite tactical RPG shell under `src/game/`.
2. **Godot implementation sandbox, secondary path**: Godot 4 tactical RPG demo under `godot/`.

The browser prototype remains the source of truth for proving the playable loop first. Godot work should support, validate, or eventually port that loop, not replace the browser-first direction until the tactics loop is fun and stable.

---

## Current State Snapshot

### What is playable on `main`

```txt
Main Menu
→ World Map
→ Town Hub
→ Tactical Battle
→ Results Screen
→ Character Sheets
→ Job Tree
→ Save / Load
```

The browser battle screen supports a first command loop:

```txt
Select player unit
→ Choose Move / Attack / Ability / Item / Wait
→ Resolve the action
→ Defeat all enemies
→ Claim Victory
→ Apply rewards
```

Current battle behavior includes:

- Battle maps rendered from `BATTLE_MAPS`.
- Terrain, height, player units, and enemies shown on the tactical board.
- Player commands for Move, Attack, Ability, Item, and Wait.
- Basic enemy phase handling.
- Basic enemy AI action selection.
- Objective completion for `defeat_all` missions.
- Post-battle XP, JP, gold, items, mission flags, and story flags.
- Local save/load through browser storage.

### What is represented in data and systems

The repo already contains strong foundations for:

- Character levels, XP, JP, job levels, job unlock requirements, mastered jobs, and ascended jobs.
- Temper and Ether armor as separate physical and magical defense layers.
- Facing-based damage modifiers for front, side, and back attacks.
- Ability data with MP costs, ranges, target types, elements, and effects.
- Terrain definitions with movement costs, blocked tiles, hazards, tags, and elemental reactions.
- Pathfinding helpers that account for Move, Jump, terrain movement costs, blocking, and occupied tiles.
- Enemy AI helpers that choose attacks or move toward the closest target.
- Asset registry scaffolding for browser and Godot asset mapping.
- Art direction, asset prompt libraries, and production documentation.

### What is partially implemented but not yet fully integrated

These systems exist conceptually or partially in code, but need better runtime integration:

- Full player movement range using the pathfinding helper.
- CT-style turn order and projected timeline UI.
- Damage preview and hit confirmation.
- Enemy intent preview.
- Real inventory consumption during battle item use.
- Terrain reactions that actually mutate battlefield tiles.
- Job abilities that define tactical identity per class.
- Pre-battle deployment using map deployment zones.
- End-turn facing selection.
- Animation/event queues for readable action playback.

### What is not yet implemented

These are major missing pieces for making this a unique tactics roguelite:

- Roguelite run state.
- Run seed generation.
- Branching run map.
- Post-battle draft rewards.
- Temporary run boons, relics, curses, and Guardian pacts.
- Meta-progression after failed or completed runs.
- Run-specific enemy, terrain, and elemental modifiers.
- Shops, shrines, camps, events, elite fights, and boss nodes.
- Accessibility, keyboard/controller support, remappable input, and localization hooks.
- Automated tests beyond the Vite build check.

---

## Local Browser Setup

```bash
npm install
npm run dev
```

Open:

```txt
http://localhost:5173
```

Developer-only alternate prototype tabs are available with:

```txt
http://localhost:5173?dev
```

---

## Browser Build

```bash
npm run build
npm run preview
```

Build output goes to:

```txt
dist/
```

The app can be deployed as a static site after a successful Vite build.

---

## Godot Sandbox Setup

A Godot implementation track exists under:

```txt
godot/
```

Open the project file in Godot 4:

```txt
godot/project.godot
```

The configured main scene is:

```txt
res://scenes/StageSelect.tscn
```

Use this track as a playable engine sandbox. Do not let Godot work fragment the core design until the browser tactics loop is stable.

---

## Key Browser Runtime Files

```txt
src/main.jsx
src/App.jsx
src/game/GameShell.jsx
src/game/VaeltharChronicles.jsx
src/game/screens/MainMenu.jsx
src/game/screens/WorldMapScreen.jsx
src/game/screens/TownScreen.jsx
src/game/screens/BattleScreen.jsx
src/game/screens/ResultsScreen.jsx
src/game/screens/CharacterSheetScreen.jsx
src/game/screens/JobTreeScreen.jsx
src/game/components/TacticalGrid.jsx
src/game/components/CommandMenu.jsx
src/game/systems/grid.js
src/game/systems/pathfinding.js
src/game/systems/aiController.js
src/game/systems/combatResolver.js
src/game/systems/damageFormula.js
src/game/systems/objectives.js
src/game/state/initialGameState.js
src/game/state/progressionReducer.js
src/game/state/saveSystem.js
src/game/styles/gameShell.css
```

---

## Key Data Files

```txt
src/game/data/abilities.js
src/game/data/maps.js
src/game/data/missions.js
src/game/data/progression.js
src/game/data/quests.js
src/game/data/story.js
src/game/data/terrain.js
src/game/data/towns.js
src/game/data/units.js
src/game/data/loadingTips.js
src/assets/assetRegistry.js
```

---

## Key Godot Files

```txt
godot/project.godot
godot/scripts/grid/TacticalGrid.gd
godot/scripts/battle/BattleScene.gd
godot/scripts/data/AssetRegistry.gd
godot/scripts/data/MapData.gd
godot/scripts/systems/GameState.gd
godot/scripts/units/Unit.gd
godot/scripts/ui/CharacterScreen.gd
```

---

## Documentation and Production Files

```txt
ARCHITECTURE.md
ASSET_PIPELINE.md
AI_TASK_PACKETS.md
SAVE_SCHEMA.md
docs/COMBAT_SYSTEM_SPEC.md
docs/architecture/game-shell.md
docs/architecture/asset-registry.md
docs/design/art-direction.md
docs/design/tile-manifest.md
docs/design/sprite-manifest.md
docs/prompts/
docs/characters/
docs/lore/
docs/mechanics/
docs/production/
```

---

## Core Design Pillars

### 1. Browser-first tactical RPG

The first milestone is a fun, readable browser tactics loop. Keep systems small, modular, and data-driven.

### 2. FFT-style tactics readability without copying assets or code

Use original systems, original names, original assets, and original lore. The goal is to capture tactical clarity, not clone copyrighted material.

### 3. Roguelite replayability

Every run should force different tactical choices through elemental conditions, Guardian pacts, terrain mutations, job drafts, relics, and risk-reward modifiers.

### 4. Tactical terrain as a build system

Terrain should not be cosmetic. Wet, burning, frozen, electrified, shrine, void, and high-ground tiles should shape builds, enemy behavior, and run strategy.

### 5. Temper and Ether as identity

Physical and magical armor should create tactical decisions before HP damage matters. Breaking Temper or Ether should open windows for status effects, burst damage, or Guardian resonance.

### 6. Guardian resonance as the unique hook

Guardians should not just be summons. They should be run-defining powers with risk, corruption, resonance windows, terrain effects, and story consequences.

---

## Current System Reality Check

| Area | Current State | Gap |
|---|---|---|
| Browser shell | Working vertical-slice shell exists | Needs polish, stronger routing, and more guided onboarding |
| Battle loop | Basic command loop exists | Needs CT turns, preview, pathing integration, facing, and intent |
| Movement | Grid and pathfinding helpers exist | Player UI still needs full movement range integration |
| Combat math | Damage preview logic exists | Needs confirmation UI and consistent use across attacks and abilities |
| Terrain | Rich terrain data exists | Reactions need to mutate tiles and affect battle state |
| Jobs | Strong progression data exists | Job abilities need to define actual tactical roles |
| Items | Inventory exists | Battle item use must consume inventory and target correctly |
| Enemy AI | Basic AI exists | Needs readable intent and archetype-specific behavior |
| Assets | Registry scaffolding exists | Runtime UI still uses many CSS/placeholders |
| Roguelite | Design direction exists | Run map, draft rewards, boons, relics, and meta progression are missing |
| Godot | Sandbox exists | Should not become the main production path until browser loop stabilizes |
| QA | Vite build workflow exists | Needs unit tests, reducer tests, and data validation scripts |

---

## Current Production Priorities

### Priority 1: Stabilize the tactics core

Target outcome:

```txt
Player selects a unit
→ sees valid movement range
→ previews path
→ selects action
→ sees damage and status preview
→ confirms action
→ selects end-facing
→ CT timeline advances
→ enemy intent remains readable
```

Implementation targets:

- Full movement range from existing pathfinding helpers.
- CT turn order and timeline UI.
- Damage preview panel.
- Attack and ability confirmation flow.
- End-turn facing selector.
- Enemy intent preview.
- Battle reducer to move state transitions out of `BattleScreen.jsx`.

### Priority 2: Add the roguelite run loop

Target outcome:

```txt
Start Run
→ Choose route node
→ Fight battle
→ Pick 1 of 3 rewards
→ Continue route
→ Fight elite or boss
→ End run
→ Apply meta progression
```

Implementation targets:

```txt
src/game/data/runNodes.js
src/game/data/runRewards.js
src/game/data/runModifiers.js
src/game/systems/run/createRun.js
src/game/systems/run/advanceRun.js
src/game/systems/run/applyDraftReward.js
src/game/screens/RunMapScreen.jsx
src/game/screens/RewardDraftScreen.jsx
docs/systems/roguelite-run-loop.md
```

### Priority 3: Make the unique hook visible

Target outcome:

The game should feel like a tactics roguelite where elemental terrain, armor layers, and Guardian pacts mutate every run.

Implementation targets:

- Terrain reaction mutation.
- Guardian pact draft rewards.
- Void corruption timer.
- Temper/Ether break bonuses.
- SURGE/DEFLECT timing prompts.
- Run-specific elemental modifiers.

### Priority 4: Wire asset registry into runtime UI

Target outcome:

Replace purely symbolic/CSS presentation with consistent placeholder art references.

Implementation targets:

- Unit portraits.
- Unit idle sprites.
- Enemy sprites.
- Terrain tiles.
- Tile overlays.
- Command icons.
- Damage numbers.
- Spell/VFX sheets.

### Priority 5: Add validation and tests

Target outcome:

Codex and Claude can safely modify systems without breaking the prototype silently.

Implementation targets:

- Data validation script for maps, units, terrain, abilities, jobs, and assets.
- Unit tests for pathfinding, damage preview, job unlocks, mission rewards, and run rewards.
- Build workflow updated to run validation before build.

---

## Recommended Next Branches

```txt
feature/stabilize-tactics-core
feature/roguelite-run-loop
feature/guardian-terrain-identity
feature/runtime-asset-registry-wiring
fix/build-and-data-validation
```

Do not stack all of this into one PR. Each feature should be reviewable, buildable, and reversible.

---

## Open Work To Reconcile

There are existing open PRs that appear to overlap with current next steps. Before creating more competing feature branches, inspect and either merge, close, or rebuild their best pieces:

- PR #12: tactics presentation and movement range.
- PR #13: tactics combat core architecture.
- PR #17: Godot battle architecture.

Recommended handling:

1. Review PR #12 and PR #13 first because they affect the browser tactics core.
2. Extract the cleanest pieces into one fresh `feature/stabilize-tactics-core` branch if the PRs are stale or conflicted.
3. Keep PR #17 secondary unless the immediate goal is Godot-specific.

---

## Architecture Rules

| Path | Purpose |
|---|---|
| `src/game/data/` | Static game content: jobs, units, enemies, maps, terrain, story, towns, missions |
| `src/game/systems/` | Pure gameplay logic: grid math, combat math, timing, status, combo, AI, progression, objectives |
| `src/game/state/` | Initial state, save/load, reducers, campaign progression |
| `src/game/screens/` | Full screen flows: menu, world, town, battle, results, character, jobs, run map |
| `src/game/components/` | Reusable React UI and battle components |
| `src/assets/` | Browser placeholder and final game assets |
| `godot/` | Godot implementation sandbox |
| `docs/` | Architecture, production, lore, mechanics, QA, roadmap, art direction |
| `docs/prompts/` | AI prompt recipes for legal placeholder asset generation |
| `tools/` | Asset processing, validation, and repo support scripts |

Do not add major new systems directly to a root prototype file unless it is explicitly marked as a temporary spike.

---

## Build and Quality Gates

Current workflow:

```txt
.github/workflows/build.yml
```

Current build check:

```bash
npm install
npm run build
```

Needed next quality gates:

```bash
npm run validate:data
npm run test
npm run build
```

These scripts do not all exist yet. Add them only when the underlying validation/test files are implemented.

---

## Next Best Action

The next best action is to stabilize the browser tactics core before adding more art or lore.

Recommended sequence:

1. Reconcile PR #12 and PR #13.
2. Create or update `feature/stabilize-tactics-core`.
3. Add full player movement range, CT turn order, damage preview, enemy intent, and facing selection.
4. Confirm the browser build passes.
5. Then create `feature/roguelite-run-loop` for run state, run nodes, and draft rewards.
